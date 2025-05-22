<?php
// Enable error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Set CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

// Get the image path from the query string
$imagePath = isset($_GET['path']) ? $_GET['path'] : '';

if (empty($imagePath)) {
    header('HTTP/1.1 400 Bad Request');
    echo json_encode(['error' => 'No image path provided']);
    exit;
}

// Construct the full path to the image
$fullPath = __DIR__ . '/../../' . $imagePath;

// Check if the file exists
if (!file_exists($fullPath)) {
    header('HTTP/1.1 404 Not Found');
    echo json_encode(['error' => 'Image not found']);
    exit;
}

// Get the file extension
$extension = strtolower(pathinfo($fullPath, PATHINFO_EXTENSION));

// Set the appropriate content type
switch ($extension) {
    case 'jpg':
    case 'jpeg':
        header('Content-Type: image/jpeg');
        break;
    case 'png':
        header('Content-Type: image/png');
        break;
    case 'gif':
        header('Content-Type: image/gif');
        break;
    default:
        header('HTTP/1.1 400 Bad Request');
        echo json_encode(['error' => 'Unsupported image type']);
        exit;
}

// Output the image
readfile($fullPath); 