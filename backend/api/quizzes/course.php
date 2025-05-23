<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");
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

    // Get course ID from query parameters
    $course_id = isset($_GET['course_id']) ? (int)$_GET['course_id'] : 0;
    if ($course_id <= 0) {
        throw new Exception("Invalid course ID");
    }

    // Verify user has access to the course
    $query = "SELECT * FROM courses WHERE id = ? AND (user_id = ? OR id IN (SELECT course_id FROM enrollments WHERE user_id = ?))";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("iii", $course_id, $user_id, $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception("You don't have access to this course");
    }

    // Get quizzes for the course
    $query = "SELECT q.*, 
                     (SELECT COUNT(*) FROM questions WHERE quiz_id = q.id) as question_count
              FROM quizzes q 
              JOIN lessons l ON q.lesson_id = l.id 
              JOIN modules m ON l.module_id = m.id 
              WHERE m.course_id = ?
              ORDER BY q.created_at DESC";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $course_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $quizzes = [];

    while ($quiz = $result->fetch_assoc()) {
        // Get questions for each quiz
        $query = "SELECT * FROM questions WHERE quiz_id = ? ORDER BY id";
        $stmt2 = $conn->prepare($query);
        $stmt2->bind_param("i", $quiz['id']);
        $stmt2->execute();
        $questions_result = $stmt2->get_result();
        $questions = [];

        while ($question = $questions_result->fetch_assoc()) {
            // Get answers for each question
            $query = "SELECT * FROM answers WHERE question_id = ? ORDER BY id";
            $stmt3 = $conn->prepare($query);
            $stmt3->bind_param("i", $question['id']);
            $stmt3->execute();
            $answers_result = $stmt3->get_result();
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

        $quizzes[] = [
            'id' => (int)$quiz['id'],
            'lesson_id' => (int)$quiz['lesson_id'],
            'title' => $quiz['title'],
            'description' => $quiz['description'],
            'passing_score' => (int)$quiz['passing_score'],
            'created_at' => $quiz['created_at'],
            'updated_at' => $quiz['updated_at'],
            'questions' => $questions
        ];
    }

    echo json_encode([
        'status' => 'success',
        'quizzes' => $quizzes
    ]);

} catch (Exception $e) {
    http_response_code(401);
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}
?> 