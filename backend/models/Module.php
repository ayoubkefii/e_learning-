<?php
class Module {
    private $conn;
    private $table_name = "modules";

    public $id;
    public $course_id;
    public $title;
    public $description;
    public $order_index;
    public $created_at;
    public $updated_at;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create() {
        $query = "INSERT INTO " . $this->table_name . "
                (course_id, title, description, order_index)
                VALUES
                (:course_id, :title, :description, :order_index)";

        $stmt = $this->conn->prepare($query);

        $this->title = htmlspecialchars(strip_tags($this->title));
        $this->description = htmlspecialchars(strip_tags($this->description));
        $this->course_id = htmlspecialchars(strip_tags($this->course_id));
        $this->order_index = htmlspecialchars(strip_tags($this->order_index));

        $stmt->bindParam(":course_id", $this->course_id);
        $stmt->bindParam(":title", $this->title);
        $stmt->bindParam(":description", $this->description);
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

    public function readByCourse() {
        $query = "SELECT * FROM " . $this->table_name . "
                WHERE course_id = :course_id
                ORDER BY order_index ASC";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":course_id", $this->course_id);
        $stmt->execute();

        return $stmt;
    }

    public function update() {
        $query = "UPDATE " . $this->table_name . "
                SET
                    title = :title,
                    description = :description,
                    order_index = :order_index
                WHERE
                    id = :id AND course_id = :course_id";

        $stmt = $this->conn->prepare($query);

        $this->title = htmlspecialchars(strip_tags($this->title));
        $this->description = htmlspecialchars(strip_tags($this->description));
        $this->order_index = htmlspecialchars(strip_tags($this->order_index));
        $this->id = htmlspecialchars(strip_tags($this->id));
        $this->course_id = htmlspecialchars(strip_tags($this->course_id));

        $stmt->bindParam(":title", $this->title);
        $stmt->bindParam(":description", $this->description);
        $stmt->bindParam(":order_index", $this->order_index);
        $stmt->bindParam(":id", $this->id);
        $stmt->bindParam(":course_id", $this->course_id);

        if ($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function delete() {
        $query = "DELETE FROM " . $this->table_name . "
                WHERE id = :id AND course_id = :course_id";

        $stmt = $this->conn->prepare($query);

        $this->id = htmlspecialchars(strip_tags($this->id));
        $this->course_id = htmlspecialchars(strip_tags($this->course_id));

        $stmt->bindParam(":id", $this->id);
        $stmt->bindParam(":course_id", $this->course_id);

        if ($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function getNextOrderNumber() {
        $query = "SELECT MAX(order_index) as max_order FROM " . $this->table_name . "
                WHERE course_id = :course_id";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":course_id", $this->course_id);
        $stmt->execute();

        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row['max_order'] ? $row['max_order'] + 1 : 1;
    }
}
?> 