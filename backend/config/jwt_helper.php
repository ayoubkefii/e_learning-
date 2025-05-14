<?php
require_once 'vendor/autoload.php';
use \Firebase\JWT\JWT;

class JwtHelper {
    private static $key = "your_secret_key_here"; // Change this to a secure key
    private static $algorithm = 'HS256';

    public static function generateToken($user_id, $role) {
        $issued_at = time();
        $expiration = $issued_at + (60 * 60 * 24); // 24 hours

        $payload = array(
            "iat" => $issued_at,
            "exp" => $expiration,
            "user_id" => $user_id,
            "role" => $role
        );

        return JWT::encode($payload, self::$key, self::$algorithm);
    }

    /**
     * @param string $token
     * @return array|false
     */
    public static function validateToken($token) {
        try {
            $decoded = JWT::decode($token, self::$key, array(self::$algorithm));
            return (array) $decoded;
        } catch(Exception $e) {
            return false;
        }
    }
}
?> 