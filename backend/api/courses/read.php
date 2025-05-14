<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once '../../config/database.php';
include_once '../../models/Course.php';

$database = new Database();
$db = $database->getConnection();

$course = new Course($db);

$stmt = $course->readAll();
$num = $stmt->rowCount();

if ($num > 0) {
    $courses_arr = array();
    $courses_arr["records"] = array();

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        extract($row);

        $course_item = array(
            "id" => $id,
            "title" => $title,
            "description" => $description,
            "trainer_id" => $trainer_id,
            "trainer_name" => $trainer_name,
            "created_at" => $created_at,
            "updated_at" => $updated_at
        );

        array_push($courses_arr["records"], $course_item);
    }

    http_response_code(200);
    echo json_encode($courses_arr);
} else {
    http_response_code(404);
    echo json_encode(array("message" => "No courses found."));
}
?> 