<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

require_once '../config/database.php';
require_once '../models/Course.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if (!isset($_GET['id'])) {
    http_response_code(400);
    echo json_encode(['message' => 'Course ID is required.']);
    exit();
}

try {
    $database = new Database();
    $db = $database->getConnection();
    
    $course = new Course($db);
    $course->id = $_GET['id'];
    $result = $course->readOne();
    
    if ($result) {
        http_response_code(200);
        echo json_encode($result);
    } else {
        http_response_code(404);
        echo json_encode(['message' => 'Course not found.']);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['message' => 'Error: ' . $e->getMessage()]);
}
?> 