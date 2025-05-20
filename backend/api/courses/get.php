<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// CORS headers
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Max-Age: 3600');
header('Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../config/database.php';

// Get course ID
if (!isset($_GET['id'])) {
    http_response_code(400);
    echo json_encode(['message' => 'Course ID is required.']);
    exit();
}

try {
    $database = new Database();
    $db = $database->getConnection();
    
    // Create query
    $query = "SELECT c.*, u.username as trainer_name
              FROM courses c
              LEFT JOIN users u ON c.trainer_id = u.id
              WHERE c.id = :id";

    // Prepare statement
    $stmt = $db->prepare($query);
    
    // Bind ID
    $id = htmlspecialchars(strip_tags($_GET['id']));
    $stmt->bindParam(':id', $id);
    
    // Execute query
    $stmt->execute();
    
    if ($stmt->rowCount() > 0) {
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        http_response_code(200);
        echo json_encode($row);
    } else {
        http_response_code(404);
        echo json_encode(['message' => 'Course not found.']);
    }
} catch (Exception $e) {
    error_log("Error getting course: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['message' => 'Error: ' . $e->getMessage()]);
}
?> 