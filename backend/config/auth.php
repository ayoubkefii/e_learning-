<?php
require_once 'vendor/autoload.php';
use \Firebase\JWT\JWT;
use \Firebase\JWT\Key;

function verifyToken($token) {
    try {
        $key = "your_secret_key"; // Replace with your actual secret key
        $decoded = JWT::decode($token, new Key($key, 'HS256'));
        return $decoded;
    } catch (Exception $e) {
        throw new Exception('Invalid token');
    }
}

function generateToken($user) {
    $key = "your_secret_key"; // Replace with your actual secret key
    $payload = array(
        "user_id" => $user['id'],
        "email" => $user['email'],
        "role" => $user['role'],
        "iat" => time(),
        "exp" => time() + (60 * 60 * 24) // 24 hours
    );
    
    return JWT::encode($payload, $key, 'HS256');
}
?> 