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

    // Get quiz ID from request body
    $data = json_decode(file_get_contents("php://input"), true);
    $quiz_id = isset($data['quiz_id']) ? (int)$data['quiz_id'] : 0;
    
    if ($quiz_id <= 0) {
        throw new Exception("Invalid quiz ID");
    }

    // Check if quiz exists
    $query = "SELECT * FROM quizzes WHERE id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $quiz_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception("Quiz not found");
    }

    // Check if user has an active attempt
    $query = "SELECT * FROM quiz_attempts 
              WHERE user_id = ? AND quiz_id = ? 
              AND completed_at IS NULL";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("ii", $user_id, $quiz_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        // Return existing attempt
        $attempt = $result->fetch_assoc();
        echo json_encode([
            'id' => (int)$attempt['id'],
            'user_id' => (int)$attempt['user_id'],
            'quiz_id' => (int)$attempt['quiz_id'],
            'score' => $attempt['score'],
            'passed' => (bool)$attempt['passed'],
            'started_at' => $attempt['started_at'],
            'completed_at' => $attempt['completed_at']
        ]);
        exit;
    }

    // Create new attempt
    $query = "INSERT INTO quiz_attempts (user_id, quiz_id) VALUES (?, ?)";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("ii", $user_id, $quiz_id);
    
    if (!$stmt->execute()) {
        throw new Exception("Failed to create quiz attempt");
    }

    $attempt_id = $conn->insert_id;

    // Return the new attempt
    echo json_encode([
        'id' => (int)$attempt_id,
        'user_id' => (int)$user_id,
        'quiz_id' => (int)$quiz_id,
        'score' => null,
        'passed' => false,
        'started_at' => date('Y-m-d H:i:s'),
        'completed_at' => null
    ]);

} catch (Exception $e) {
    http_response_code(401);
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}
?> 