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

    // Get quiz ID from query parameters
    $quiz_id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    if ($quiz_id <= 0) {
        throw new Exception("Invalid quiz ID");
    }

    // Get quiz details
    $query = "SELECT q.*, l.title as lesson_title 
              FROM quizzes q 
              JOIN lessons l ON q.lesson_id = l.id 
              WHERE q.id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $quiz_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $quiz = $result->fetch_assoc();

    if (!$quiz) {
        throw new Exception("Quiz not found");
    }

    // Get questions for the quiz
    $query = "SELECT * FROM questions WHERE quiz_id = ? ORDER BY id";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $quiz_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $questions = [];

    while ($question = $result->fetch_assoc()) {
        // Get answers for each question
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

    // Prepare the response
    $response = [
        'id' => (int)$quiz['id'],
        'lesson_id' => (int)$quiz['lesson_id'],
        'title' => $quiz['title'],
        'description' => $quiz['description'],
        'passing_score' => (int)$quiz['passing_score'],
        'created_at' => $quiz['created_at'],
        'updated_at' => $quiz['updated_at'],
        'questions' => $questions
    ];

    echo json_encode($response);

} catch (Exception $e) {
    http_response_code(401);
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}
?> 