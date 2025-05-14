# FlutterLearn Backend API

This is the backend API for the FlutterLearn e-learning platform, built with PHP and MySQL.

## Requirements

- PHP 7.4 or higher
- MySQL 5.7 or higher
- Composer (PHP package manager)

## Setup Instructions

1. Clone the repository
2. Navigate to the backend directory
3. Install dependencies:
   ```bash
   composer install
   ```
4. Create a MySQL database named `flutter_learn`
5. Import the database schema:
   ```bash
   mysql -u your_username -p flutter_learn < database/schema.sql
   ```
6. Configure the database connection in `config/database.php`
7. Update the JWT secret key in `config/jwt_helper.php`

## API Endpoints

### Authentication

- POST `/api/auth/signup` - Register a new user
  - Required fields: username, email, password, role (trainer/learner)
- POST `/api/auth/login` - Login user
  - Required fields: email, password
  - Returns: JWT token and user data

### Courses

- GET `/api/courses` - List all courses
- POST `/api/courses` - Create a new course (trainer only)
- GET `/api/courses/{id}` - Get course details
- PUT `/api/courses/{id}` - Update course (trainer only)
- DELETE `/api/courses/{id}` - Delete course (trainer only)

### Modules

- GET `/api/modules` - List all modules
- POST `/api/modules` - Create a new module (trainer only)
- GET `/api/modules/{id}` - Get module details
- PUT `/api/modules/{id}` - Update module (trainer only)
- DELETE `/api/modules/{id}` - Delete module (trainer only)

### Lessons

- GET `/api/lessons` - List all lessons
- POST `/api/lessons` - Create a new lesson (trainer only)
- GET `/api/lessons/{id}` - Get lesson details
- PUT `/api/lessons/{id}` - Update lesson (trainer only)
- DELETE `/api/lessons/{id}` - Delete lesson (trainer only)

### Quizzes

- GET `/api/quizzes` - List all quizzes
- POST `/api/quizzes` - Create a new quiz (trainer only)
- GET `/api/quizzes/{id}` - Get quiz details
- PUT `/api/quizzes/{id}` - Update quiz (trainer only)
- DELETE `/api/quizzes/{id}` - Delete quiz (trainer only)

### Progress

- GET `/api/progress` - Get user's learning progress
- POST `/api/progress` - Update lesson progress
- GET `/api/progress/quiz/{id}` - Get quiz attempt history
- POST `/api/progress/quiz/{id}` - Submit quiz attempt

## Security

- All endpoints except login and signup require JWT authentication
- Include the JWT token in the Authorization header:
  ```
  Authorization: Bearer <your_token>
  ```
- File uploads are restricted to specific file types and sizes
- Input validation and sanitization is implemented for all endpoints

## Error Handling

The API uses standard HTTP status codes:

- 200: Success
- 201: Created
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 500: Internal Server Error

Error responses include a message explaining the error:

```json
{
  "message": "Error description"
}
```
