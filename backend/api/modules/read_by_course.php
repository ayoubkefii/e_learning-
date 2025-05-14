<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once '../../config/database.php';
include_once '../../models/Module.php';

$database = new Database();
$db = $database->getConnection();

$module = new Module($db);

$module->course_id = isset($_GET['course_id']) ? $_GET['course_id'] : die();

$stmt = $module->readByCourse();
$num = $stmt->rowCount();

if ($num > 0) {
    $modules_arr = array();
    $modules_arr["records"] = array();

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        extract($row);

        $module_item = array(
            "id" => $id,
            "course_id" => $course_id,
            "title" => $title,
            "description" => $description,
            "order_number" => $order_number,
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