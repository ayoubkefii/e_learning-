<?php
require_once '../../config/cors.php';
require_once '../../config/database.php';
require_once '../../models/Module.php';

try {
    // Get posted data
    $data = json_decode(file_get_contents("php://input"));

    if (!isset($data->id) || !isset($data->course_id) || !isset($data->title) || !isset($data->description)) {
        http_response_code(400);
        echo json_encode(array("message" => "Missing required fields."));
        exit();
    }

    $database = new Database();
    $db = $database->getConnection();

    $module = new Module($db);

    // Set module properties
    $module->id = $data->id;
    $module->course_id = $data->course_id;
    $module->title = $data->title;
    $module->description = $data->description;
    $module->order_index = $data->order_index;

    if ($module->update()) {
        http_response_code(200);
        echo json_encode(array("message" => "Module was updated."));
    } else {
        http_response_code(503);
        echo json_encode(array("message" => "Unable to update module."));
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(array("message" => "Error: " . $e->getMessage()));
}
?> 