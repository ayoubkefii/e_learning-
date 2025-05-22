<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Headers
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    // Include database and object files
    include_once '../../config/database.php';
    include_once '../../models/Lesson.php';

    // Get database connection
    $database = new Database();
    $db = $database->getConnection();

    // Initialize lesson object
    $lesson = new Lesson($db);

    // Set module_id property of record to read
    if (!isset($_GET['module_id'])) {
        throw new Exception("Module ID is required");
    }

    $lesson->module_id = $_GET['module_id'];

    // Read lessons by module
    $stmt = $lesson->readByModule();
    $num = $stmt->rowCount();

    // Initialize response array
    $lessons_arr = array();
    $lessons_arr["records"] = array();

    if ($num > 0) {
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $lesson_item = array(
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
                $lesson_item['content'] = $content['text'];
                $lesson_item['documents'] = $content['documents'];
            }

            array_push($lessons_arr["records"], $lesson_item);
        }
    }

    // Set response code - 200 OK
    http_response_code(200);
    echo json_encode($lessons_arr);

} catch (Exception $e) {
    // Set response code - 500 Internal Server Error
    http_response_code(500);
    echo json_encode(array(
        "message" => "Error: " . $e->getMessage(),
        "records" => array()
    ));
}
?> 