<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/database.php';
require_once '../config/auth.php';

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Log the request
error_log("Received request to students/list.php");
error_log("Request method: " . $_SERVER['REQUEST_METHOD']);
error_log("Request headers: " . json_encode(getallheaders()));

// Verify JWT token
$headers = getallheaders();
$token = isset($headers['Authorization']) ? str_replace('Bearer ', '', $headers['Authorization']) : null;

if (!$token) {
    error_log("No token provided");
    http_response_code(401);
    echo json_encode(['error' => 'No token provided']);
    exit();
}

try {
    error_log("Verifying token: " . $token);
    $decoded = verifyToken($token);
    error_log("Token verified. User role: " . $decoded->role);
    
    // Check if user is a trainer
    if ($decoded->role !== 'trainer') {
        error_log("Access denied: User is not a trainer");
        http_response_code(403);
        echo json_encode(['error' => 'Only trainers can access this endpoint']);
        exit();
    }

    // Get all students
    $query = "SELECT u.id, u.username, u.email, u.name, u.role, 
                     CASE WHEN e.id IS NOT NULL THEN 1 ELSE 0 END as is_enrolled,
                     COALESCE(u.is_active, 1) as is_active
              FROM users u
              LEFT JOIN enrollments e ON u.id = e.student_id
              WHERE u.role = 'student'
              GROUP BY u.id";
              
    error_log("Executing query: " . $query);
    $stmt = $conn->prepare($query);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $students = [];
    while ($row = $result->fetch_assoc()) {
        $students[] = [
            'id' => (int)$row['id'],
            'username' => $row['username'],
            'email' => $row['email'],
            'name' => $row['name'] ?? '',
            'role' => $row['role'],
            'is_enrolled' => (bool)$row['is_enrolled'],
            'is_active' => (bool)$row['is_active']
        ];
    }
    
    error_log("Found " . count($students) . " students");
    echo json_encode(['records' => $students]);
    
} catch (Exception $e) {
    error_log("Error in students/list.php: " . $e->getMessage());
    http_response_code(401);
    echo json_encode(['error' => 'Invalid token: ' . $e->getMessage()]);
}
?> 