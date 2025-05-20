<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// CORS headers
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Max-Age: 3600');
header('Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../config/database.php';

// Get posted data
$raw_data = file_get_contents("php://input");
error_log("Received data: " . $raw_data);

$data = json_decode($raw_data);
if (json_last_error() !== JSON_ERROR_NONE) {
    error_log("JSON decode error: " . json_last_error_msg());
    http_response_code(400);
    echo json_encode(array("message" => "Invalid JSON data: " . json_last_error_msg()));
    exit();
}

// Validate data
if (!isset($data->id)) {
    error_log("Missing course ID");
    http_response_code(400);
    echo json_encode(array("message" => "Course ID is required"));
    exit();
}

try {
    $database = new Database();
    $db = $database->getConnection();
    
    // First check if the course exists
    $query = "SELECT id FROM courses WHERE id = :id";
    $stmt = $db->prepare($query);
    $stmt->bindParam(":id", $data->id);
    $stmt->execute();
    
    if ($stmt->rowCount() === 0) {
        error_log("Course not found: " . $data->id);
        http_response_code(404);
        echo json_encode(array("message" => "Course not found"));
        exit();
    }
    
    // Delete the course
    $query = "DELETE FROM courses WHERE id = :id";
    $stmt = $db->prepare($query);
    $stmt->bindParam(":id", $data->id);
    
    if ($stmt->execute()) {
        http_response_code(200);
        echo json_encode(array(
            "message" => "Course deleted successfully",
            "id" => $data->id
        ));
    } else {
        error_log("Database error: " . print_r($stmt->errorInfo(), true));
        throw new Exception("Unable to delete course: " . implode(", ", $stmt->errorInfo()));
    }
} catch (Exception $e) {
    error_log("Exception: " . $e->getMessage());
    http_response_code(503);
    echo json_encode(array("message" => "Unable to delete course: " . $e->getMessage()));
}
?> 