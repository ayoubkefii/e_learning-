<?php
// Headers
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Include database and object files
include_once '../../config/database.php';
include_once '../../models/Lesson.php';

// Get database connection
$database = new Database();
$db = $database->getConnection();

// Initialize lesson object
$lesson = new Lesson($db);

// Get posted data
$data = array_merge($_POST, json_decode(file_get_contents("php://input"), true) ?? []);

// Make sure we have required data
if (
    !empty($data['module_id']) &&
    !empty($data['title']) &&
    !empty($data['content'])
) {
    // Set lesson property values
    $lesson->module_id = $data['module_id'];
    $lesson->title = $data['title'];
    $lesson->content = $data['content'];
    $lesson->duration = !empty($data['duration']) ? $data['duration'] : null;
    $lesson->order_index = 0; // You might want to implement proper ordering

    // Handle video upload
    $video_url = null;
    if (!empty($_FILES['video'])) {
        $video_file = $_FILES['video'];
        $video_ext = pathinfo($video_file['name'], PATHINFO_EXTENSION);
        $video_filename = uniqid() . '.' . $video_ext;
        $video_path = '../../uploads/videos/' . $video_filename;

        if (move_uploaded_file($video_file['tmp_name'], $video_path)) {
            $video_url = 'uploads/videos/' . $video_filename;
        }
    }
    $lesson->video_url = $video_url;

    // Handle document uploads
    $documents = [];
    if (!empty($_FILES['documents'])) {
        $document_files = $_FILES['documents'];
        $file_count = is_array($document_files['name']) ? count($document_files['name']) : 0;

        for ($i = 0; $i < $file_count; $i++) {
            $doc_ext = pathinfo($document_files['name'][$i], PATHINFO_EXTENSION);
            $doc_filename = uniqid() . '.' . $doc_ext;
            $doc_path = '../../uploads/documents/' . $doc_filename;

            if (move_uploaded_file($document_files['tmp_name'][$i], $doc_path)) {
                $documents[] = 'uploads/documents/' . $doc_filename;
            }
        }
    }

    // If we have documents, store them in the content as JSON
    if (!empty($documents)) {
        $content_data = [
            'text' => $lesson->content,
            'documents' => $documents
        ];
        $lesson->content = json_encode($content_data);
    }

    // Create the lesson
    if ($lesson->create()) {
        // Set response code - 201 created
        http_response_code(201);

        // Tell the user
        echo json_encode(array(
            "message" => "Lesson was created.",
            "id" => $lesson->id,
            "module_id" => $lesson->module_id,
            "title" => $lesson->title,
            "content" => $lesson->content,
            "video_url" => $lesson->video_url,
            "duration" => $lesson->duration,
            "order_index" => $lesson->order_index,
            "created_at" => $lesson->created_at,
            "updated_at" => $lesson->updated_at
        ));
    } else {
        // Set response code - 503 service unavailable
        http_response_code(503);

        // Tell the user
        echo json_encode(array("message" => "Unable to create lesson."));
    }
} else {
    // Set response code - 400 bad request
    http_response_code(400);

    // Tell the user
    echo json_encode(array("message" => "Unable to create lesson. Data is incomplete."));
}
?> 