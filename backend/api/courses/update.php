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
if (!isset($data->id) || !isset($data->title) || !isset($data->description) || !isset($data->trainer_id)) {
    error_log("Missing required fields");
    http_response_code(400);
    echo json_encode(array("message" => "Missing required fields"));
    exit();
}

try {
    $database = new Database();
    $db = $database->getConnection();
    
    // Create query
    $query = "UPDATE courses 
              SET title = :title, 
                  description = :description,
                  updated_at = NOW()
              WHERE id = :id AND trainer_id = :trainer_id";

    // Prepare statement
    $stmt = $db->prepare($query);

    // Clean data
    $id = htmlspecialchars(strip_tags($data->id));
    $title = htmlspecialchars(strip_tags($data->title));
    $description = htmlspecialchars(strip_tags($data->description));
    $trainer_id = htmlspecialchars(strip_tags($data->trainer_id));

    // Bind data
    $stmt->bindParam(":id", $id);
    $stmt->bindParam(":title", $title);
    $stmt->bindParam(":description", $description);
    $stmt->bindParam(":trainer_id", $trainer_id);

    // Execute query
    if ($stmt->execute()) {
        // Get updated course data
        $query = "SELECT c.*, u.username as trainer_name
                 FROM courses c
                 LEFT JOIN users u ON c.trainer_id = u.id
                 WHERE c.id = :id";
        
        $stmt = $db->prepare($query);
        $stmt->bindParam(":id", $id);
        $stmt->execute();
        
        if ($stmt->rowCount() > 0) {
            $course = $stmt->fetch(PDO::FETCH_ASSOC);
            http_response_code(200);
            echo json_encode($course);
        } else {
            throw new Exception("Course not found after update");
        }
    } else {
        error_log("Database error: " . print_r($stmt->errorInfo(), true));
        throw new Exception("Unable to update course: " . implode(", ", $stmt->errorInfo()));
    }
} catch (Exception $e) {
    error_log("Exception: " . $e->getMessage());
    http_response_code(503);
    echo json_encode(array("message" => "Unable to update course: " . $e->getMessage()));
}
?> 