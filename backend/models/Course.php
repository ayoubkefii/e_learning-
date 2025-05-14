<?php
class Course {
    private $conn;
    private $table_name = "courses";

    public $id;
    public $title;
    public $description;
    public $trainer_id;
    public $created_at;
    public $updated_at;
    public $trainer_name;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create() {
        $query = "INSERT INTO " . $this->table_name . "
                (title, description, trainer_id)
                VALUES
                (:title, :description, :trainer_id)";

        $stmt = $this->conn->prepare($query);

        $this->title = htmlspecialchars(strip_tags($this->title));
        $this->description = htmlspecialchars(strip_tags($this->description));
        $this->trainer_id = htmlspecialchars(strip_tags($this->trainer_id));

        $stmt->bindParam(":title", $this->title);
        $stmt->bindParam(":description", $this->description);
        $stmt->bindParam(":trainer_id", $this->trainer_id);

        if ($stmt->execute()) {
            $this->id = $this->conn->lastInsertId();
            return true;
        }
        return false;
    }

    public function readOne() {
        $query = "SELECT c.*, u.username as trainer_name
                FROM " . $this->table_name . " c
                LEFT JOIN users u ON c.trainer_id = u.id
                WHERE c.id = :id";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":id", $this->id);
        $stmt->execute();

        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($row) {
            $this->title = $row['title'];
            $this->description = $row['description'];
            $this->trainer_id = $row['trainer_id'];
            $this->created_at = $row['created_at'];
            $this->updated_at = $row['updated_at'];
            $this->trainer_name = $row['trainer_name'];
            return $row;
        }
        return false;
    }

    public function readAll() {
        $query = "SELECT c.*, u.username as trainer_name
                FROM " . $this->table_name . " c
                LEFT JOIN users u ON c.trainer_id = u.id
                ORDER BY c.created_at DESC";

        $stmt = $this->conn->prepare($query);
        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function readByTrainer() {
        $query = "SELECT c.*, u.username as trainer_name
                FROM " . $this->table_name . " c
                LEFT JOIN users u ON c.trainer_id = u.id
                WHERE c.trainer_id = :trainer_id
                ORDER BY c.created_at DESC";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":trainer_id", $this->trainer_id);
        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function update() {
        $query = "UPDATE " . $this->table_name . "
                SET
                    title = :title,
                    description = :description
                WHERE
                    id = :id AND trainer_id = :trainer_id";

        $stmt = $this->conn->prepare($query);

        $this->title = htmlspecialchars(strip_tags($this->title));
        $this->description = htmlspecialchars(strip_tags($this->description));
        $this->id = htmlspecialchars(strip_tags($this->id));
        $this->trainer_id = htmlspecialchars(strip_tags($this->trainer_id));

        $stmt->bindParam(":title", $this->title);
        $stmt->bindParam(":description", $this->description);
        $stmt->bindParam(":id", $this->id);
        $stmt->bindParam(":trainer_id", $this->trainer_id);

        if ($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function delete() {
        $query = "DELETE FROM " . $this->table_name . "
                WHERE id = :id AND trainer_id = :trainer_id";

        $stmt = $this->conn->prepare($query);

        $this->id = htmlspecialchars(strip_tags($this->id));
        $this->trainer_id = htmlspecialchars(strip_tags($this->trainer_id));

        $stmt->bindParam(":id", $this->id);
        $stmt->bindParam(":trainer_id", $this->trainer_id);

        if ($stmt->execute()) {
            return true;
        }
        return false;
    }
}
?> 