<?php
// Allow from any origin
if (isset($_SERVER['HTTP_ORIGIN'])) {
    header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Max-Age: 86400');    // cache for 1 day
}

// Access-Control headers are received during OPTIONS requests
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_METHOD']))
        header("Access-Control-Allow-Methods: GET, POST, OPTIONS");         

    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']))
        header("Access-Control-Allow-Headers: {$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']}");

    exit(0);
}

header("Content-Type: application/json; charset=UTF-8");

// Enable error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

include_once '../../config/database.php';
include_once '../../models/user.php';

// Log the raw input
$raw_input = file_get_contents("php://input");
error_log("Raw input: " . $raw_input);

$database = new Database();
$db = $database->getConnection();

$user = new User($db);

$data = json_decode($raw_input);

// Log the decoded data
error_log("Decoded data: " . print_r($data, true));

if (
    !empty($data->username) &&
    !empty($data->email) &&
    !empty($data->password) &&
    !empty($data->role)
) {
    $user->username = $data->username;
    $user->email = $data->email;
    $user->password = $data->password;
    $user->role = $data->role;

    // Check if email already exists
    if ($user->emailExists()) {
        http_response_code(400);
        echo json_encode(array("message" => "Email already exists."));
        exit();
    }

    // Check if username already exists
    if ($user->usernameExists()) {
        http_response_code(400);
        echo json_encode(array("message" => "Username already exists."));
        exit();
    }

    // Create the user
    if ($user->create()) {
        http_response_code(201);
        echo json_encode(array("message" => "User was created successfully."));
    } else {
        http_response_code(503);
        echo json_encode(array("message" => "Unable to create user."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Unable to create user. Data is incomplete."));
}
?> 