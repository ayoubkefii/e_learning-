<?php
require_once '../../config/cors.php';
require_once '../../config/database.php';
require_once '../../models/Course.php';

try {
    // Initialize database connection
    $database = new Database();
    $db = $database->getConnection();
    
    if (!$db) {
        throw new Exception("Database connection failed");
    }
    
    // Create course instance
    $course = new Course($db);
    
    // Get all courses
    $result = $course->readAll();
    
    // Debug information
    error_log("Fetching courses...");
    error_log("Number of courses found: " . count($result));
    
    if ($result && count($result) > 0) {
        http_response_code(200);
        echo json_encode(['records' => $result]);
    } else {
        error_log("No courses found in database");
        http_response_code(404);
        echo json_encode(['message' => 'No courses found.']);
    }
} catch (PDOException $e) {
    error_log("Database error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'message' => 'Database error occurred',
        'error' => $e->getMessage()
    ]);
} catch (Exception $e) {
    error_log("General error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'message' => 'Error occurred',
        'error' => $e->getMessage()
    ]);
}
?> 