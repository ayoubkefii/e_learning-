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

// Log the request
error_log("Request method: " . $_SERVER['REQUEST_METHOD']);
error_log("Request headers: " . json_encode(getallheaders()));

try {
    // Get the authorization header
    $headers = getallheaders();
    $auth_header = isset($headers['Authorization']) ? $headers['Authorization'] : '';
    
    if (empty($auth_header)) {
        error_log("No authorization header found");
        throw new Exception("No authorization header found");
    }

    // Extract the token
    $token = str_replace('Bearer ', '', $auth_header);
    error_log("Token received: " . $token);

    // Verify the token
    $decoded = verifyToken($token);
    error_log("Token decoded: " . json_encode($decoded));

    // Check if user is a trainer
    if ($decoded->role !== 'trainer') {
        error_log("Access denied: User is not a trainer");
        throw new Exception("Access denied: Only trainers can view all users");
    }

    // Get all users
    $query = "SELECT 
                u.id,
                u.username,
                u.email,
                u.role,
                COALESCE(u.name, '') as name,
                COALESCE(u.is_active, 1) as is_active,
                CASE 
                    WHEN EXISTS (
                        SELECT 1 FROM enrollments e 
                        WHERE e.user_id = u.id 
                        AND e.status = 'active'
                    ) THEN 1 
                    ELSE 0 
                END as is_enrolled
              FROM users u
              ORDER BY u.id DESC";

    $stmt = $conn->prepare($query);
    $stmt->execute();
    $result = $stmt->get_result();
    $users = [];

    while ($row = $result->fetch_assoc()) {
        $users[] = [
            'id' => (int)$row['id'],
            'username' => $row['username'],
            'email' => $row['email'],
            'role' => $row['role'],
            'name' => $row['name'],
            'is_active' => (bool)$row['is_active'],
            'is_enrolled' => (bool)$row['is_enrolled']
        ];
    }

    // Return the users
    echo json_encode([
        'status' => 'success',
        'records' => $users
    ]);

} catch (Exception $e) {
    error_log("Error in users/list.php: " . $e->getMessage());
    http_response_code(401);
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}
?> 