<?php
require_once '../../config/cors.php';
require_once '../../config/database.php';
require_once '../../models/Course.php';

handleCors();

try {
    $database = new Database();
    $db = $database->getConnection();
    
    $course = new Course($db);
    $result = $course->readAll();
    
    if ($result) {
        http_response_code(200);
        echo json_encode(['records' => $result]);
    } else {
        http_response_code(404);
        echo json_encode(['message' => 'No courses found.']);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['message' => 'Error: ' . $e->getMessage()]);
}
?> 