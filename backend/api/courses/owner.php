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
    $course_id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    
    if ($course_id <= 0) {
        throw new Exception("Invalid course ID");
    }

    // Check if user is the course owner
    $query = "SELECT user_id FROM courses WHERE id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $course_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $course = $result->fetch_assoc();

    $is_owner = $course && $course['user_id'] == $user_id;

    http_response_code(200);
    echo json_encode([
        'status' => 'success',
        'is_owner' => $is_owner
    ]);

} catch (Exception $e) {
    http_response_code(401);
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}
?> 