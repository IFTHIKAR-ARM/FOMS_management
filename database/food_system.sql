-- Create database
CREATE DATABASE IF NOT EXISTS food_system;
USE food_system;

-- Customers table
CREATE TABLE customers (
    phone VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('customer','delivery','admin') NOT NULL DEFAULT 'customer'
);

-- Orders table (multiple orders, no ID)
CREATE TABLE orders (
    customer_phone VARCHAR(20) NOT NULL,
    items TEXT NOT NULL,
    address TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (customer_phone, created_at),

    FOREIGN KEY (customer_phone) REFERENCES customers(phone) 
        ON DELETE CASCADE
);

-- Delivery boy table (no ID)
CREATE TABLE delivery_boy (
    name VARCHAR(100) PRIMARY KEY,
    available BOOLEAN DEFAULT TRUE
);

-- Admin table
CREATE TABLE admin (
    username VARCHAR(50) PRIMARY KEY,
    password VARCHAR(255) NOT NULL
);

-- Menu items table
CREATE TABLE menu_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    price DECIMAL(10,2) NOT NULL,
    image_path VARCHAR(255) NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1
);

-- Insert default admin (safe for repeated imports)
INSERT INTO admin (username, password)
VALUES ('restaurant', MD5('password123'))
ON DUPLICATE KEY UPDATE password = VALUES(password);

-- Insert delivery boy
INSERT INTO delivery_boy (name)
VALUES ('Delivery Boy');

-- Insert default menu
INSERT INTO menu_items (name, price, image_path, is_active) VALUES
('Chicken Kottu', 1200, '/FOMS/public_assets/images/chicken.jpeg', 1),
('Fish Curry Rice', 1100, '/FOMS/public_assets/images/fish.jpg', 1),
('Beef Fried Rice', 1300, '/FOMS/public_assets/images/beef.jpeg', 1),
('Veg Noodles', 900, '/FOMS/public_assets/images/veg.jpeg', 1),
('Egg Fried Rice', 950, '/FOMS/public_assets/images/egg.webp', 1)
ON DUPLICATE KEY UPDATE
price = VALUES(price),
image_path = VALUES(image_path),
is_active = VALUES(is_active);

