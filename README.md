# Software Requirements Specification (SRS)

## Canteen Management System

**Technology Stack:** Flutter, FastAPI, PostgreSQL
**Frontend:** Flutter
**Backend:** FastAPI
**Database:** PostgreSQL
**Document Version:** 1.0

---

# 1. Introduction

## 1.1 Purpose

The purpose of the Canteen Management System is to provide a digital platform for managing canteen operations such as food items, menus, customer orders, order status, payments, inventory, and user management.

The system will provide a Flutter-based application for users and a FastAPI-based backend for handling business logic, authentication, data management, and communication with the database.

The system is intended to reduce manual work, improve order management, maintain accurate records, and provide a convenient way for users to interact with the canteen.

---

## 1.2 Scope

The system will provide functionality for:

* User registration and login
* User profile management
* Viewing available food items
* Viewing the canteen menu
* Searching and filtering food items
* Adding items to a cart
* Placing orders
* Viewing order details
* Tracking order status
* Order history
* Canteen/admin management
* Food item management
* Menu management
* Inventory management
* Basic sales and order information
* Notifications related to orders
* Database-backed persistent storage

The system will use a REST API between the Flutter frontend and FastAPI backend.

---

# 2. Overall Description

## 2.1 Product Perspective

The system follows a client-server architecture.

```text
┌──────────────────────┐
│     Flutter App      │
│      Frontend        │
└──────────┬───────────┘
           │
           │ REST API / JSON
           ▼
┌──────────────────────┐
│      FastAPI         │
│       Backend        │
├──────────────────────┤
│ Authentication       │
│ Business Logic       │
│ API Routes           │
│ Validation           │
└──────────┬───────────┘
           │
           │ SQL / ORM
           ▼
┌──────────────────────┐
│     PostgreSQL       │
│       Database       │
└──────────────────────┘
```

---

## 2.2 User Classes

### Customer

Customers can:

* Register and log in
* Browse the menu
* Search for food items
* View food details
* Add items to cart
* Place orders
* View current orders
* Track order status
* View previous orders
* Manage their profile

### Canteen Staff / Admin

Staff or administrators can:

* Log in to the management system
* Add food items
* Update food items
* Remove food items
* Manage menu availability
* View incoming orders
* Update order status
* Manage inventory
* View order and sales information
* Manage users where authorized

---

# 3. Functional Requirements

## FR-01: User Registration

The system shall allow a new customer to create an account.

Required information may include:

* Name
* Email
* Password
* Phone number

The system shall validate the submitted information before creating the account.

---

## FR-02: User Authentication

The system shall allow registered users to log in using their credentials.

The backend shall authenticate the user and provide an authentication token.

The system shall restrict protected operations to authenticated users.

---

## FR-03: User Profile

Authenticated users shall be able to:

* View their profile
* Update their profile information
* Change their password where supported

---

## FR-04: Food Item Management

The system shall maintain information about food items.

Each food item may contain:

* Item ID
* Name
* Description
* Price
* Category
* Image
* Availability status
* Quantity/inventory information

Administrators shall be able to create, update, and remove food items.

---

## FR-05: Menu Management

The system shall provide a menu containing available food items.

Administrators shall be able to:

* Add items to the menu
* Remove items from the menu
* Change item availability
* Update item information

Customers shall only be able to order items that are available.

---

## FR-06: Food Search and Filtering

Customers shall be able to search for food items.

The system may provide filtering based on:

* Category
* Availability
* Price
* Food name

---

## FR-07: Cart Management

Customers shall be able to add food items to a cart.

The cart shall support:

* Adding an item
* Removing an item
* Increasing quantity
* Decreasing quantity
* Viewing subtotal
* Viewing total amount

The system shall validate item availability before checkout.

---

## FR-08: Order Placement

Customers shall be able to place an order using the items in their cart.

An order shall contain:

* Order ID
* Customer ID
* Ordered items
* Item quantities
* Total amount
* Order date/time
* Order status

The system shall generate a unique order identifier.

---

## FR-09: Order Status

The system shall support order status tracking.

Possible statuses include:

```text
Placed
   ↓
Accepted
   ↓
Preparing
   ↓
Ready
   ↓
Completed
```

An order may also be marked as:

```text
Cancelled
```

Only authorized users shall be able to change order status.

---

## FR-10: Order History

Customers shall be able to view their previous orders.

Each order shall display relevant information such as:

* Order ID
* Date
* Ordered items
* Quantity
* Total amount
* Final status

---

## FR-11: Order Management

Canteen staff shall be able to:

* View new orders
* View order details
* Accept orders
* Update preparation status
* Mark orders as ready
* Complete orders
* Cancel orders where permitted

---

## FR-12: Inventory Management

The system shall maintain inventory information for applicable food items or ingredients.

The system shall allow authorized staff to:

* Add inventory
* Update inventory
* View current stock
* Mark items unavailable when stock is insufficient

Inventory-related functionality may be expanded depending on the final project requirements.

---

## FR-13: Notifications

The system may notify customers when an important order status changes.

For example:

```text
Order Placed
Order Accepted
Order Preparing
Order Ready
Order Completed
```

---

## FR-14: Admin Management

Authorized administrators shall be able to manage the operational data of the canteen.

Administrative operations may include:

* Food management
* Menu management
* Order management
* Inventory management
* User management
* Basic reports

---

# 4. Non-Functional Requirements

## NFR-01: Performance

The backend should respond to normal API requests within an acceptable response time under normal system load.

Database queries should be designed to avoid unnecessary operations.

---

## NFR-02: Security

The system shall:

* Store passwords securely using hashing
* Authenticate protected API requests
* Validate user input
* Restrict administrative operations
* Avoid exposing sensitive information through API responses
* Store secrets and credentials outside source code

---

## NFR-03: Reliability

The system should maintain consistent order and inventory information.

Database operations involving orders should avoid partial or inconsistent updates.

---

## NFR-04: Usability

The Flutter application should provide:

* Clear navigation
* Simple ordering workflow
* Readable information
* Appropriate validation messages
* Clear order status indicators

---

## NFR-05: Maintainability

The backend should use a modular architecture.

The frontend and backend should be organized into logical modules so that new functionality can be added without significantly modifying unrelated components.

---

## NFR-06: Scalability

The backend architecture should allow additional users, food items, and orders to be handled without requiring major changes to the system architecture.

---

## NFR-07: Data Persistence

Application data shall be stored in a persistent relational database.

Data shall remain available after application or server restarts.

---

# 5. System Architecture

The system will use three primary layers.

## 5.1 Presentation Layer

Implemented using Flutter.

Responsibilities:

* User interface
* Navigation
* Form handling
* Displaying API data
* Sending API requests
* Local UI state

---

## 5.2 Application/API Layer

Implemented using FastAPI.

Responsibilities:

* REST API endpoints
* Authentication
* Authorization
* Request validation
* Business logic
* Error handling
* Communication with the database

---

## 5.3 Data Layer

Implemented using PostgreSQL.

Responsibilities:

* User data
* Food items
* Categories
* Orders
* Order items
* Inventory
* Other persistent application data

---

# 6. Preliminary Database Entities

The initial database design may contain the following entities:

```text
User
 │
 └────< Order
          │
          └────< OrderItem >──── FoodItem
                                  │
                                  └──── Category

FoodItem
   │
   └──── Inventory
```

### User

Possible fields:

* id
* name
* email
* password_hash
* phone
* role
* created_at

### Category

Possible fields:

* id
* name
* description

### FoodItem

Possible fields:

* id
* name
* description
* price
* category_id
* image_url
* is_available
* created_at

### Order

Possible fields:

* id
* user_id
* total_amount
* status
* created_at
* updated_at

### OrderItem

Possible fields:

* id
* order_id
* food_item_id
* quantity
* unit_price
* subtotal

### Inventory

Possible fields:

* id
* food_item_id
* quantity
* updated_at

The final database schema will be finalized before implementing the database layer.

---

# 7. API Requirements

The FastAPI backend will expose RESTful endpoints.

A preliminary API structure is:

```text
/api
│
├── /auth
│   ├── POST /register
│   └── POST /login
│
├── /users
│   ├── GET /me
│   └── PUT /me
│
├── /food-items
│   ├── GET /
│   ├── GET /{id}
│   ├── POST /
│   ├── PUT /{id}
│   └── DELETE /{id}
│
├── /categories
│   ├── GET /
│   ├── POST /
│   ├── PUT /{id}
│   └── DELETE /{id}
│
├── /cart
│   ├── GET /
│   ├── POST /
│   ├── PUT /{id}
│   └── DELETE /{id}
│
├── /orders
│   ├── POST /
│   ├── GET /
│   ├── GET /{id}
│   └── PATCH /{id}/status
│
└── /inventory
    ├── GET /
    ├── POST /
    └── PUT /{id}
```

This API list is preliminary and will be adjusted when the final features and database design are decided.

---

# 8. Flutter Application Requirements

The Flutter application may contain the following screens:

```text
Splash Screen
     ↓
Login / Register
     ↓
Home
 ┌───┼───────────────┐
 ↓   ↓               ↓
Menu Search        Profile
 ↓
Food Details
 ↓
Cart
 ↓
Checkout
 ↓
Order Confirmation
 ↓
Order Tracking
 ↓
Order History
```

Administrative functionality may use separate screens based on the user's role.

---

# 9. Authentication and Authorization

The system shall use token-based authentication.

A typical authentication flow will be:

```text
Flutter
   │
   │ Login credentials
   ▼
FastAPI
   │
   │ Validate credentials
   ▼
Database
   │
   │
   ▼
FastAPI
   │
   │ Authentication token
   ▼
Flutter
```

Protected API requests will include the authentication token.

Role-based authorization will determine whether a user can perform administrative operations.

Example roles:

```text
CUSTOMER
ADMIN
STAFF
```

The final role structure will be decided during implementation.

---

# 10. Error Handling

The backend shall return appropriate HTTP status codes.

Examples:

```text
200 OK
201 Created
400 Bad Request
401 Unauthorized
403 Forbidden
404 Not Found
409 Conflict
422 Validation Error
500 Internal Server Error
```

The Flutter application shall display user-friendly messages instead of exposing internal backend errors.

---

# 11. Development and Version Control

The project will use Git and GitHub.

The repository will contain:

```text
Canteen-Management-System/
│
├── frontend/
├── backend/
├── docs/
└── README.md
```

The main branches will be:

```text
main
dev
```

Feature development will use feature branches:

```text
feature/flutter-setup
feature/fastapi-setup
feature/auth
feature/food-management
feature/order-management
```

Feature branches will be merged into `dev` through Pull Requests.

The `main` branch will contain stable versions of the project.

---

# 12. Technology Requirements

## Frontend

* Flutter
* Dart
* HTTP/REST API communication

## Backend

* Python
* FastAPI
* Uvicorn
* Pydantic
* SQLAlchemy

## Database

* PostgreSQL

## Version Control

* Git
* GitHub

## Development Tools

* Visual Studio Code / Android Studio
* Android Emulator or physical Android device
* Postman or equivalent API testing tool

---

# 13. Constraints

* The system requires network communication between the Flutter client and FastAPI server during normal operation.
* Administrative operations must require appropriate authorization.
* Database credentials and secret keys must not be committed to GitHub.
* The system should initially focus on core canteen operations rather than unnecessary additional features.
* The final implementation should remain consistent with the approved project requirements.

---

# 14. Future Enhancements

The following features may be considered after the core system is completed:

* Online payment integration
* QR-based ordering
* Digital receipts
* Advanced sales analytics
* Push notifications
* Multiple canteen support
* Recommendation system
* AI-based food recommendations
* Demand prediction
* Inventory demand forecasting

These features are outside the initial core scope unless explicitly added later.

---

# 15. Acceptance Criteria

The initial system will be considered functional when:

1. A customer can register and log in.
2. Authenticated users can view available food items.
3. Users can add food items to a cart.
4. Users can place an order.
5. The order is persisted in the database.
6. Staff/admin can view orders.
7. Staff/admin can update order status.
8. Customers can view updated order status.
9. Food availability is correctly reflected in the application.
10. Unauthorized users cannot access protected administrative operations.
11. Flutter communicates successfully with the FastAPI backend.
12. Backend data remains persistent after server restarts.
13. The application handles invalid input and common API errors appropriately.

---

# 16. Conclusion

The Canteen Management System will provide a centralized digital solution for managing food items, customer orders, users, inventory, and canteen operations.

The Flutter frontend will provide the user-facing application, while FastAPI will provide the backend REST API and business logic. PostgreSQL will provide persistent storage.

The architecture is designed to keep the frontend, backend, and database layers separate, making the system easier to develop, test, maintain, and extend.
