<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include_once '../../config/database.php';
include_once '../../models/Module.php';

$database = new Database();
$db = $database->getConnection();

$module = new Module($db);

$data = json_decode(file_get_contents("php://input"));

if (
    !empty($data->course_id) &&
    !empty($data->title) &&
    !empty($data->description)
) {
    $module->course_id = $data->course_id;
    $module->title = $data->title;
    $module->description = $data->description;
    $module->order_number = $module->getNextOrderNumber();

    if ($module->create()) {
        http_response_code(201);
        echo json_encode(array("message" => "Module was created successfully."));
    } else {
        http_response_code(503);
        echo json_encode(array("message" => "Unable to create module."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Unable to create module. Data is incomplete."));
}
?> 