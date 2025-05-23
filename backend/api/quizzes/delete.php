<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: DELETE");
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
    $quiz_id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    
    if ($quiz_id <= 0) {
        throw new Exception("Invalid quiz ID");
    }

    // Verify user is the course owner
    $query = "SELECT c.user_id 
              FROM courses c 
              JOIN modules m ON c.id = m.course_id 
              JOIN lessons l ON m.id = l.module_id 
              JOIN quizzes q ON l.id = q.lesson_id 
              WHERE q.id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $quiz_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $course = $result->fetch_assoc();

    if (!$course || $course['user_id'] != $user_id) {
        throw new Exception("You don't have permission to delete this quiz");
    }

    // Start transaction
    $conn->begin_transaction();

    try {
        // Delete quiz attempts and answers
        $query = "DELETE FROM quiz_answers WHERE quiz_attempt_id IN (SELECT id FROM quiz_attempts WHERE quiz_id = ?)";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $quiz_id);
        $stmt->execute();

        $query = "DELETE FROM quiz_attempts WHERE quiz_id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $quiz_id);
        $stmt->execute();

        // Delete questions and answers
        $query = "DELETE FROM answers WHERE question_id IN (SELECT id FROM questions WHERE quiz_id = ?)";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $quiz_id);
        $stmt->execute();

        $query = "DELETE FROM questions WHERE quiz_id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $quiz_id);
        $stmt->execute();

        // Delete quiz
        $query = "DELETE FROM quizzes WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $quiz_id);
        $stmt->execute();

        // Commit transaction
        $conn->commit();

        http_response_code(200);
        echo json_encode([
            'status' => 'success',
            'message' => 'Quiz deleted successfully'
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