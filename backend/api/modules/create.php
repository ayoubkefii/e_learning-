<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

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

// Validate required fields
if (!isset($data->course_id) || !isset($data->title) || !isset($data->description)) {
    error_log("Missing required fields");
    http_response_code(400);
    echo json_encode(array("message" => "Missing required fields. Need course_id, title, and description."));
    exit();
}

try {
    $database = new Database();
    $db = $database->getConnection();

    // First check if the course exists
    $course_check = "SELECT id FROM courses WHERE id = :course_id";
    $check_stmt = $db->prepare($course_check);
    $check_stmt->bindParam(":course_id", $data->course_id);
    $check_stmt->execute();

    if ($check_stmt->rowCount() === 0) {
        error_log("Course not found: " . $data->course_id);
        http_response_code(404);
        echo json_encode(array("message" => "Course not found"));
        exit();
    }

    // Get the next order number
    $order_query = "SELECT COALESCE(MAX(order_index), 0) + 1 as next_order 
                   FROM modules 
                   WHERE course_id = :course_id";
    $order_stmt = $db->prepare($order_query);
    $order_stmt->bindParam(":course_id", $data->course_id);
    $order_stmt->execute();
    $next_order = $order_stmt->fetch(PDO::FETCH_ASSOC)['next_order'];

    // Create the module
    $query = "INSERT INTO modules (course_id, title, description, order_index, created_at) 
              VALUES (:course_id, :title, :description, :order_index, NOW())";

    $stmt = $db->prepare($query);

    // Clean and bind data
    $title = htmlspecialchars(strip_tags($data->title));
    $description = htmlspecialchars(strip_tags($data->description));
    
    $stmt->bindParam(":course_id", $data->course_id);
    $stmt->bindParam(":title", $title);
    $stmt->bindParam(":description", $description);
    $stmt->bindParam(":order_index", $next_order);

    if ($stmt->execute()) {
        $module_id = $db->lastInsertId();
        
        // Fetch the created module
        $fetch_query = "SELECT * FROM modules WHERE id = :id";
        $fetch_stmt = $db->prepare($fetch_query);
        $fetch_stmt->bindParam(":id", $module_id);
        $fetch_stmt->execute();
        
        $module = $fetch_stmt->fetch(PDO::FETCH_ASSOC);
        
        http_response_code(201);
        echo json_encode($module);
    } else {
        error_log("Database error: " . print_r($stmt->errorInfo(), true));
        throw new Exception("Unable to create module: " . implode(", ", $stmt->errorInfo()));
    }
} catch (Exception $e) {
    error_log("Exception: " . $e->getMessage());
    http_response_code(503);
    echo json_encode(array("message" => "Unable to create module: " . $e->getMessage()));
}
?> 