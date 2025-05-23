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

    // Get quiz ID from query parameters
    $quiz_id = isset($_GET['quiz_id']) ? (int)$_GET['quiz_id'] : 0;
    if ($quiz_id <= 0) {
        throw new Exception("Invalid quiz ID");
    }

    // Get attempts for the quiz
    $query = "SELECT qa.*, 
                     (SELECT COUNT(*) FROM quiz_answers qans 
                      WHERE qans.attempt_id = qa.id AND qans.is_correct = 1) as correct_answers,
                     (SELECT COUNT(*) FROM quiz_answers qans 
                      WHERE qans.attempt_id = qa.id) as total_answers
              FROM quiz_attempts qa 
              WHERE qa.user_id = ? AND qa.quiz_id = ?
              ORDER BY qa.started_at DESC";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("ii", $user_id, $quiz_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $attempts = [];

    while ($attempt = $result->fetch_assoc()) {
        $attempts[] = [
            'id' => (int)$attempt['id'],
            'user_id' => (int)$attempt['user_id'],
            'quiz_id' => (int)$attempt['quiz_id'],
            'score' => (int)$attempt['score'],
            'passed' => (bool)$attempt['passed'],
            'started_at' => $attempt['started_at'],
            'completed_at' => $attempt['completed_at'],
            'correct_answers' => (int)$attempt['correct_answers'],
            'total_answers' => (int)$attempt['total_answers']
        ];
    }

    echo json_encode([
        'status' => 'success',
        'attempts' => $attempts
    ]);

} catch (Exception $e) {
    http_response_code(401);
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}
?> 