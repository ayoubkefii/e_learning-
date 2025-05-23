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

// Log the request data for debugging
$requestData = file_get_contents("php://input");
error_log("Request data: " . $requestData);

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
    $data = json_decode($requestData, true);
    
    if (!isset($data['course_id']) || !isset($data['title']) || !isset($data['passing_score'])) {
        throw new Exception("Missing required fields");
    }

    // Verify user is the course owner
    $query = "SELECT user_id FROM courses WHERE id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $data['course_id']);
    $stmt->execute();
    $result = $stmt->get_result();
    $course = $result->fetch_assoc();

    if (!$course) {
        throw new Exception("Course not found");
    }

    if ($course['user_id'] != $user_id) {
        throw new Exception("You don't have permission to create quizzes for this course");
    }

    // Start transaction
    $conn->begin_transaction();

    try {
        // Create quiz
        $query = "INSERT INTO quizzes (course_id, title, description, passing_score) VALUES (?, ?, ?, ?)";
        $stmt = $conn->prepare($query);
        $stmt->bind_param(
            "issi",
            $data['course_id'],
            $data['title'],
            $data['description'],
            $data['passing_score']
        );
        $stmt->execute();
        $quiz_id = $conn->insert_id;

        // Create questions and answers
        if (isset($data['questions']) && is_array($data['questions'])) {
            foreach ($data['questions'] as $question) {
                // Create question
                $query = "INSERT INTO questions (quiz_id, question_text, question_type, points) VALUES (?, ?, ?, ?)";
                $stmt = $conn->prepare($query);
                $stmt->bind_param(
                    "issi",
                    $quiz_id,
                    $question['question_text'],
                    $question['question_type'],
                    $question['points']
                );
                $stmt->execute();
                $question_id = $conn->insert_id;

                // Create answers
                if (isset($question['answers']) && is_array($question['answers'])) {
                    foreach ($question['answers'] as $answer) {
                        $query = "INSERT INTO answers (question_id, answer_text, is_correct) VALUES (?, ?, ?)";
                        $stmt = $conn->prepare($query);
                        $stmt->bind_param(
                            "isi",
                            $question_id,
                            $answer['answer_text'],
                            $answer['is_correct']
                        );
                        $stmt->execute();
                    }
                }
            }
        }

        // Commit transaction
        $conn->commit();

        // Get the created quiz with questions and answers
        $query = "SELECT * FROM quizzes WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $quiz_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $quiz = $result->fetch_assoc();

        // Get questions
        $query = "SELECT * FROM questions WHERE quiz_id = ? ORDER BY id";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $quiz_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $questions = [];

        while ($question = $result->fetch_assoc()) {
            // Get answers
            $query = "SELECT * FROM answers WHERE question_id = ? ORDER BY id";
            $stmt2 = $conn->prepare($query);
            $stmt2->bind_param("i", $question['id']);
            $stmt2->execute();
            $answers_result = $stmt2->get_result();
            $answers = [];

            while ($answer = $answers_result->fetch_assoc()) {
                $answers[] = [
                    'id' => (int)$answer['id'],
                    'question_id' => (int)$answer['question_id'],
                    'answer_text' => $answer['answer_text'],
                    'is_correct' => (bool)$answer['is_correct'],
                    'created_at' => $answer['created_at'],
                    'updated_at' => $answer['updated_at']
                ];
            }

            $questions[] = [
                'id' => (int)$question['id'],
                'quiz_id' => (int)$question['quiz_id'],
                'question_text' => $question['question_text'],
                'question_type' => $question['question_type'],
                'points' => (int)$question['points'],
                'created_at' => $question['created_at'],
                'updated_at' => $question['updated_at'],
                'answers' => $answers
            ];
        }

        // Prepare response
        $response = [
            'id' => (int)$quiz['id'],
            'course_id' => (int)$quiz['course_id'],
            'title' => $quiz['title'],
            'description' => $quiz['description'],
            'passing_score' => (int)$quiz['passing_score'],
            'created_at' => $quiz['created_at'],
            'updated_at' => $quiz['updated_at'],
            'questions' => $questions
        ];

        http_response_code(201);
        echo json_encode($response);

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