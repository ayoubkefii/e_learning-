<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once '../config/database.php';
require_once '../config/jwt.php';

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

try {
    // Get the authorization header
    $headers = getallheaders();
    $auth_header = isset($headers['Authorization']) ? $headers['Authorization'] : '';
    
    if (empty($auth_header)) {
        throw new Exception("No authorization header found");
    }

    // Extract the token
    $token = str_replace('Bearer ', '', $auth_header);
    
    // Verify the token
    $decoded = verifyToken($token);
    $user_id = $decoded->user_id;

    // Get request data
    $data = json_decode(file_get_contents("php://input"), true);
    $attempt_id = isset($data['attempt_id']) ? (int)$data['attempt_id'] : 0;
    $answers = isset($data['answers']) ? $data['answers'] : [];
    
    if ($attempt_id <= 0 || empty($answers)) {
        throw new Exception("Invalid attempt ID or answers");
    }

    // Start transaction
    $conn->begin_transaction();

    try {
        // Verify attempt belongs to user
        $query = "SELECT qa.*, q.passing_score 
                 FROM quiz_attempts qa 
                 JOIN quizzes q ON qa.quiz_id = q.id 
                 WHERE qa.id = ? AND qa.user_id = ? AND qa.completed_at IS NULL";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("ii", $attempt_id, $user_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            throw new Exception("Invalid or completed attempt");
        }

        $attempt = $result->fetch_assoc();
        $quiz_id = $attempt['quiz_id'];
        $passing_score = $attempt['passing_score'];

        // Get total points possible
        $query = "SELECT SUM(points) as total_points FROM questions WHERE quiz_id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $quiz_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $total_points = $result->fetch_assoc()['total_points'];

        // Process answers
        $earned_points = 0;
        foreach ($answers as $answer) {
            $question_id = (int)$answer['question_id'];
            $selected_answer_id = (int)$answer['selected_answer_id'];

            // Verify answer is correct
            $query = "SELECT a.is_correct, q.points 
                     FROM answers a 
                     JOIN questions q ON a.question_id = q.id 
                     WHERE a.id = ? AND a.question_id = ?";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("ii", $selected_answer_id, $question_id);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows === 0) {
                throw new Exception("Invalid answer");
            }

            $answer_data = $result->fetch_assoc();
            $is_correct = (bool)$answer_data['is_correct'];
            $points = (int)$answer_data['points'];

            if ($is_correct) {
                $earned_points += $points;
            }

            // Store answer
            $query = "INSERT INTO quiz_answers 
                     (attempt_id, question_id, selected_answer_id, is_correct) 
                     VALUES (?, ?, ?, ?)";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("iiii", $attempt_id, $question_id, $selected_answer_id, $is_correct);
            $stmt->execute();
        }

        // Calculate score percentage
        $score_percentage = ($total_points > 0) ? 
            round(($earned_points / $total_points) * 100) : 0;
        $passed = $score_percentage >= $passing_score;

        // Update attempt
        $query = "UPDATE quiz_attempts 
                 SET score = ?, passed = ?, completed_at = NOW() 
                 WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("iii", $score_percentage, $passed, $attempt_id);
        $stmt->execute();

        // If passed, create certificate
        if ($passed) {
            $certificate_number = 'CERT-' . strtoupper(uniqid());
            $query = "INSERT INTO certificates 
                     (user_id, course_id, quiz_id, certificate_number) 
                     SELECT ?, c.id, ?, ? 
                     FROM quizzes q 
                     JOIN lessons l ON q.lesson_id = l.id 
                     JOIN modules m ON l.module_id = m.id 
                     JOIN courses c ON m.course_id = c.id 
                     WHERE q.id = ?";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("iiss", $user_id, $quiz_id, $certificate_number, $quiz_id);
            $stmt->execute();
        }

        // Commit transaction
        $conn->commit();

        // Return updated attempt
        $query = "SELECT * FROM quiz_attempts WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $attempt_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $attempt = $result->fetch_assoc();

        echo json_encode([
            'id' => (int)$attempt['id'],
            'user_id' => (int)$attempt['user_id'],
            'quiz_id' => (int)$attempt['quiz_id'],
            'score' => (int)$attempt['score'],
            'passed' => (bool)$attempt['passed'],
            'started_at' => $attempt['started_at'],
            'completed_at' => $attempt['completed_at']
        ]);

    } catch (Exception $e) {
        $conn->rollback();
        throw $e;
    }

} catch (Exception $e) {
    http_response_code(401);
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}
?> 