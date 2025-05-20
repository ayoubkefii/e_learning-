<?php
require_once '../../config/cors.php';
include_once '../../config/database.php';
include_once '../../models/Module.php';

$database = new Database();
$db = $database->getConnection();

$module = new Module($db);

// Debug: Print the received course_id
$course_id = isset($_GET['course_id']) ? $_GET['course_id'] : null;
error_log("Received course_id: " . $course_id);

if ($course_id === null) {
    http_response_code(400);
    echo json_encode(array("message" => "Missing course_id parameter"));
    exit();
}

$module->course_id = $course_id;

$stmt = $module->readByCourse();
$num = $stmt->rowCount();

// Debug: Print the number of modules found
error_log("Found $num modules for course_id: $course_id");

if ($num > 0) {
    $modules_arr = array();
    $modules_arr["records"] = array();

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        extract($row);
        
        // Debug: Print each module's data
        error_log("Module found - ID: $id, Title: $title");

        $module_item = array(
            "id" => $id,
            "course_id" => $course_id,
            "title" => $title,
            "description" => $description,
            "order_index" => $order_index,
            "created_at" => $created_at,
            "updated_at" => $updated_at
        );

        array_push($modules_arr["records"], $module_item);
    }

    http_response_code(200);
    echo json_encode($modules_arr);
} else {
    http_response_code(404);
    echo json_encode(array("message" => "No modules found."));
}
?> 