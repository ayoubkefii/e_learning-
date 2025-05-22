<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Allow from any origin
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../config/database.php';

// Initialize database connection
$database = new Database();
$conn = $database->getConnection();

// Accept both JSON and form-data
$data = array_merge($_POST, json_decode(file_get_contents("php://input"), true) ?? []);

// Validate data
if (!isset($data['title']) || !isset($data['description']) || !isset($data['trainer_id'])) {
    http_response_code(400);
    echo json_encode(array("message" => "Missing required fields"));
    exit();
}

$image_url = null;
// Handle image upload if present
if (!empty($_FILES['image'])) {
    $image_file = $_FILES['image'];
    $image_ext = pathinfo($image_file['name'], PATHINFO_EXTENSION);
    $image_filename = uniqid() . '.' . $image_ext;
    $image_path = '../../uploads/course_images/' . $image_filename;
    if (!file_exists('../../uploads/course_images/')) {
        mkdir('../../uploads/course_images/', 0777, true);
    }
    if (move_uploaded_file($image_file['tmp_name'], $image_path)) {
        $image_url = 'uploads/course_images/' . $image_filename;
    }
}

try {
    // Create query
    $query = "INSERT INTO courses (title, description, trainer_id, image_url, created_at, updated_at) 
              VALUES (:title, :description, :trainer_id, :image_url, NOW(), NOW())";

    // Prepare statement
    $stmt = $conn->prepare($query);

    // Clean data
    $title = htmlspecialchars(strip_tags($data['title']));
    $description = htmlspecialchars(strip_tags($data['description']));
    $trainer_id = htmlspecialchars(strip_tags($data['trainer_id']));

    // Bind data
    $stmt->bindParam(":title", $title);
    $stmt->bindParam(":description", $description);
    $stmt->bindParam(":trainer_id", $trainer_id);
    $stmt->bindParam(":image_url", $image_url);

    // Execute query
    if ($stmt->execute()) {
        // Get the last inserted ID
        $course_id = $conn->lastInsertId();

        // Get trainer name
        $trainer_query = "SELECT username FROM users WHERE id = :trainer_id";
        $trainer_stmt = $conn->prepare($trainer_query);
        $trainer_stmt->bindParam(":trainer_id", $trainer_id);
        $trainer_stmt->execute();
        $trainer = $trainer_stmt->fetch(PDO::FETCH_ASSOC);

        // Create response object
        $response = array(
            "id" => $course_id,
            "title" => $title,
            "description" => $description,
            "trainer_id" => $trainer_id,
            "trainer_name" => $trainer['username'],
            "image_url" => $image_url,
            "created_at" => date('Y-m-d H:i:s'),
            "updated_at" => date('Y-m-d H:i:s')
        );

        // Set response code - 201 created
        http_response_code(201);
        echo json_encode($response);
    } else {
        throw new Exception("Unable to create course: " . implode(", ", $stmt->errorInfo()));
    }
} catch (Exception $e) {
    http_response_code(503);
    echo json_encode(array("message" => "Unable to create course: " . $e->getMessage()));
}
?> 