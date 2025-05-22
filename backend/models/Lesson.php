<?php
class Lesson {
    private $conn;
    private $table_name = "lessons";

    public $id;
    public $module_id;
    public $title;
    public $content;
    public $video_url;
    public $duration;
    public $order_index;
    public $created_at;
    public $updated_at;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create() {
        $query = "INSERT INTO " . $this->table_name . "
                (module_id, title, content, video_url, duration, order_index)
                VALUES
                (:module_id, :title, :content, :video_url, :duration, :order_index)";

        $stmt = $this->conn->prepare($query);

        // Sanitize input
        $this->module_id = htmlspecialchars(strip_tags($this->module_id));
        $this->title = htmlspecialchars(strip_tags($this->title));
        $this->content = htmlspecialchars(strip_tags($this->content));
        $this->video_url = $this->video_url ? htmlspecialchars(strip_tags($this->video_url)) : null;
        $this->duration = $this->duration ? htmlspecialchars(strip_tags($this->duration)) : null;
        $this->order_index = $this->order_index ? htmlspecialchars(strip_tags($this->order_index)) : 0;

        // Bind values
        $stmt->bindParam(":module_id", $this->module_id);
        $stmt->bindParam(":title", $this->title);
        $stmt->bindParam(":content", $this->content);
        $stmt->bindParam(":video_url", $this->video_url);
        $stmt->bindParam(":duration", $this->duration);
        $stmt->bindParam(":order_index", $this->order_index);

        if ($stmt->execute()) {
            $this->id = $this->conn->lastInsertId();
            return true;
        }
        return false;
    }

    public function read() {
        $query = "SELECT * FROM " . $this->table_name . "
                WHERE id = :id";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":id", $this->id);
        $stmt->execute();

        return $stmt;
    }

    public function readByModule() {
        $query = "SELECT * FROM " . $this->table_name . "
                WHERE module_id = :module_id
                ORDER BY order_index ASC";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":module_id", $this->module_id);
        $stmt->execute();

        return $stmt;
    }

    public function update() {
        $query = "UPDATE " . $this->table_name . "
                SET
                    title = :title,
                    content = :content,
                    video_url = :video_url,
                    duration = :duration,
                    order_index = :order_index
                WHERE
                    id = :id AND module_id = :module_id";

        $stmt = $this->conn->prepare($query);

        // Sanitize input
        $this->title = htmlspecialchars(strip_tags($this->title));
        $this->content = htmlspecialchars(strip_tags($this->content));
        $this->video_url = $this->video_url ? htmlspecialchars(strip_tags($this->video_url)) : null;
        $this->duration = $this->duration ? htmlspecialchars(strip_tags($this->duration)) : null;
        $this->order_index = $this->order_index ? htmlspecialchars(strip_tags($this->order_index)) : 0;
        $this->id = htmlspecialchars(strip_tags($this->id));
        $this->module_id = htmlspecialchars(strip_tags($this->module_id));

        // Bind values
        $stmt->bindParam(":title", $this->title);
        $stmt->bindParam(":content", $this->content);
        $stmt->bindParam(":video_url", $this->video_url);
        $stmt->bindParam(":duration", $this->duration);
        $stmt->bindParam(":order_index", $this->order_index);
        $stmt->bindParam(":id", $this->id);
        $stmt->bindParam(":module_id", $this->module_id);

        if ($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function delete() {
        $query = "DELETE FROM " . $this->table_name . "
                WHERE id = :id AND module_id = :module_id";

        $stmt = $this->conn->prepare($query);

        $this->id = htmlspecialchars(strip_tags($this->id));
        $this->module_id = htmlspecialchars(strip_tags($this->module_id));

        $stmt->bindParam(":id", $this->id);
        $stmt->bindParam(":module_id", $this->module_id);

        if ($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function uploadFile($file, $type) {
        $upload_dir = '../../uploads/';
        if ($type === 'video') {
            $upload_dir .= 'videos/';
        } else {
            $upload_dir .= 'documents/';
        }

        // Create directory if it doesn't exist
        if (!file_exists($upload_dir)) {
            mkdir($upload_dir, 0777, true);
        }

        $file_ext = pathinfo($file['name'], PATHINFO_EXTENSION);
        $file_name = uniqid() . '.' . $file_ext;
        $target_path = $upload_dir . $file_name;

        if (move_uploaded_file($file['tmp_name'], $target_path)) {
            return 'uploads/' . ($type === 'video' ? 'videos/' : 'documents/') . $file_name;
        }
        return null;
    }
}
?> 