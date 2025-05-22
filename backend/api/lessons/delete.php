<?php
// Headers
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include database and object files
include_once '../../config/database.php';
include_once '../../models/Lesson.php';

// Get database connection
$database = new Database();
$db = $database->getConnection();

// Initialize lesson object
$lesson = new Lesson($db);

// Accept both JSON and form-data
$data = array_merge($_POST, json_decode(file_get_contents("php://input"), true) ?? []);

// Check for required fields
if (
    empty($data['id']) ||
    empty($data['module_id'])
) {
    http_response_code(400);
    echo json_encode(array("message" => "Unable to delete lesson. Required data is incomplete."));
    exit();
}

// Set lesson id and module_id
$lesson->id = $data['id'];
$lesson->module_id = $data['module_id'];

// Delete the lesson
if ($lesson->delete()) {
    // Set response code - 200 ok
    http_response_code(200);
    
    // Tell the user
    echo json_encode(array("message" => "Lesson was deleted successfully."));
} else {
    // Set response code - 503 service unavailable
    http_response_code(503);
    
    // Tell the user
    echo json_encode(array("message" => "Unable to delete lesson."));
}
?> 