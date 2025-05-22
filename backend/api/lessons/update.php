<?php
// Headers
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

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
    empty($data['module_id']) ||
    empty($data['title'])
) {
    http_response_code(400);
    echo json_encode(array("message" => "Unable to update lesson. Required data is incomplete."));
    exit();
}

// Set lesson property values
$lesson->id = $data['id'];
$lesson->module_id = $data['module_id'];
$lesson->title = $data['title'];
$lesson->content = $data['content'] ?? "";
$lesson->duration = !empty($data['duration']) ? $data['duration'] : 0;
$lesson->order_index = $data['order_index'] ?? null;

// Get current lesson data for file management
$stmt = $lesson->read();
$current_lesson = $stmt->fetch(PDO::FETCH_ASSOC);

// Handle video file update if present
if (!empty($_FILES['video'])) {
    // Delete old video if exists
    if (!empty($current_lesson['video_url']) && file_exists($current_lesson['video_url'])) {
        unlink($current_lesson['video_url']);
    }
    $video_path = $lesson->uploadFile($_FILES['video'], 'video');
    if ($video_path) {
        $lesson->video_url = $video_path;
    }
} else {
    // Keep existing video URL
    $lesson->video_url = $current_lesson['video_url'];
}

// Update the lesson
if ($lesson->update()) {
    // Handle document files if present
    if (!empty($_FILES['documents'])) {
        $uploaded_files = array();
        // Get existing documents if any
        $existing_content = json_decode($current_lesson['content'], true);
        if ($existing_content && isset($existing_content['documents'])) {
            $uploaded_files = $existing_content['documents'];
        }
        // Handle multiple document uploads
        $file_count = is_array($_FILES['documents']['name']) ? count($_FILES['documents']['name']) : 0;
        for ($i = 0; $i < $file_count; $i++) {
            $file = array(
                'name' => $_FILES['documents']['name'][$i],
                'type' => $_FILES['documents']['type'][$i],
                'tmp_name' => $_FILES['documents']['tmp_name'][$i],
                'error' => $_FILES['documents']['error'][$i],
                'size' => $_FILES['documents']['size'][$i]
            );
            $doc_path = $lesson->uploadFile($file, 'document');
            if ($doc_path) {
                $uploaded_files[] = $doc_path;
            }
        }
        // Update lesson with document paths
        $lesson->content = json_encode(array(
            'text' => $lesson->content,
            'documents' => $uploaded_files
        ));
        $lesson->update();
    }
    // Return success response
    http_response_code(200);
    echo json_encode(array(
        "message" => "Lesson was updated successfully.",
        "id" => $lesson->id,
        "title" => $lesson->title,
        "video_url" => $lesson->video_url,
        "content" => $lesson->content
    ));
} else {
    // Return error response
    http_response_code(503);
    echo json_encode(array("message" => "Unable to update lesson."));
}
?> 