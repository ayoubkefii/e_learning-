<?php
// Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: access");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Credentials: true");
header("Content-Type: application/json");

// Include database and object files
include_once '../../config/database.php';
include_once '../../models/Lesson.php';

// Get database connection
$database = new Database();
$db = $database->getConnection();

// Initialize lesson object
$lesson = new Lesson($db);

// Set ID property of record to read
$lesson->id = isset($_GET['id']) ? $_GET['id'] : die();

// Read the details of lesson
$stmt = $lesson->read();
$num = $stmt->rowCount();

if ($num > 0) {
    // Get retrieved row
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Create array
    $lesson_arr = array(
        "id" => $row['id'],
        "module_id" => $row['module_id'],
        "title" => $row['title'],
        "content" => $row['content'],
        "video_url" => $row['video_url'],
        "duration" => $row['duration'],
        "order_index" => $row['order_index'],
        "created_at" => $row['created_at'],
        "updated_at" => $row['updated_at']
    );

    // Check if content contains JSON (for documents)
    if ($content = json_decode($row['content'], true)) {
        $lesson_arr['content'] = $content['text'];
        $lesson_arr['documents'] = $content['documents'];
    }

    // Set response code - 200 OK
    http_response_code(200);

    // Make it json format
    echo json_encode($lesson_arr);
} else {
    // Set response code - 404 Not found
    http_response_code(404);

    // Tell the user lesson does not exist
    echo json_encode(array("message" => "Lesson does not exist."));
}
?> 