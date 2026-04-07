-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Apr 06, 2026 at 04:18 PM
-- Server version: 8.4.7
-- PHP Version: 8.3.28

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `thuoc_da_lieu`
--

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `sp_allocate_order_fefo`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_allocate_order_fefo` (IN `p_order_id` INT, IN `p_product_id` INT, IN `p_quantity` INT, IN `p_price` DECIMAL(15,2))   BEGIN
    DECLARE v_remaining INT DEFAULT p_quantity;
    DECLARE v_batch_id INT;
    DECLARE v_batch_stock INT;
    DECLARE v_take INT;
    DECLARE done INT DEFAULT FALSE;
    
    DECLARE cur CURSOR FOR 
        SELECT id, remaining_quantity 
        FROM batches 
        WHERE product_id = p_product_id AND remaining_quantity > 0 
        ORDER BY expiry_date ASC
        FOR UPDATE;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;
    
    allocation_loop:LOOP
        FETCH cur INTO v_batch_id, v_batch_stock;
        
        IF done THEN
            LEAVE allocation_loop;
        END IF;
        
        IF v_batch_stock >= v_remaining THEN
            SET v_take = v_remaining;
        ELSE
            SET v_take = v_batch_stock;
        END IF;
        
        INSERT INTO order_items (order_id, product_id, batch_id, quantity, price, total)
        VALUES (p_order_id, p_product_id, v_batch_id, v_take, p_price, v_take * p_price);
        
        SET v_remaining = v_remaining - v_take;
        
        IF v_remaining <= 0 THEN
            LEAVE allocation_loop;
        END IF;
        
    END LOOP;
    
    CLOSE cur;
    
    IF v_remaining > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Không đủ số lượng hàng hợp lệ trong kho!';
    END IF;
    
END$$

DROP PROCEDURE IF EXISTS `sp_generate_warehouse_alerts`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_generate_warehouse_alerts` ()   BEGIN
    INSERT INTO warehouse_alerts (product_id, alert_type, message, is_resolved)
    SELECT id, 'low_stock', CONCAT('Sản phẩm sắp hết hàng (còn ', stock_quantity, ')'), 0
    FROM products p
    WHERE stock_quantity <= stock_warning AND is_active = 1
      AND NOT EXISTS (SELECT 1 FROM warehouse_alerts w WHERE w.product_id = p.id AND w.alert_type='low_stock' AND w.is_resolved=0);
      
    INSERT INTO warehouse_alerts (product_id, alert_type, message, is_resolved)
    SELECT b.product_id, 'expired', CONCAT('Lô ', b.batch_code, ' đã hết hạn !'), 0
    FROM batches b JOIN products pt ON b.product_id = pt.id
    WHERE b.expiry_date < CURDATE() AND b.remaining_quantity > 0
      AND NOT EXISTS (SELECT 1 FROM warehouse_alerts w WHERE w.product_id = pt.id AND w.alert_type='expired' AND w.message LIKE CONCAT('%', b.batch_code, '%') AND w.is_resolved=0);

    INSERT INTO warehouse_alerts (product_id, alert_type, message, is_resolved)
    SELECT b.product_id, 'expiring_soon', CONCAT('Lô ', b.batch_code, ' hết hạn vào ', DATE_FORMAT(b.expiry_date, '%d/%m/%Y')), 0
    FROM batches b JOIN products pt ON b.product_id = pt.id
    WHERE b.expiry_date >= CURDATE() AND b.expiry_date <= DATE_ADD(CURDATE(), INTERVAL 90 DAY) AND b.remaining_quantity > 0
      AND NOT EXISTS (SELECT 1 FROM warehouse_alerts w WHERE w.product_id = pt.id AND w.alert_type='expiring_soon' AND w.message LIKE CONCAT('%', b.batch_code, '%') AND w.is_resolved=0);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `batches`
--

DROP TABLE IF EXISTS `batches`;
CREATE TABLE IF NOT EXISTS `batches` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` int UNSIGNED NOT NULL,
  `batch_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiry_date` date NOT NULL,
  `quantity` int NOT NULL,
  `remaining_quantity` int NOT NULL,
  `created_by` int UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `batch_code` (`batch_code`),
  KEY `created_by` (`created_by`),
  KEY `idx_batches_product_id` (`product_id`),
  KEY `idx_batches_expiry_date` (`expiry_date`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `batches`
--

INSERT INTO `batches` (`id`, `product_id`, `batch_code`, `expiry_date`, `quantity`, `remaining_quantity`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 1, 'CER-2026A', '2026-10-01', 100, 96, 2, '2026-04-05 08:16:29', '2026-04-06 09:55:36'),
(2, 1, 'CER-2027B', '2027-05-01', 50, 50, 2, '2026-04-05 08:16:29', '2026-04-05 08:16:29'),
(3, 2, 'LRP-DUO-99', '2026-12-31', 80, 74, 2, '2026-04-05 08:16:29', '2026-04-06 10:39:16'),
(4, 3, 'VIC-SUN-01', '2028-01-15', 100, 100, 2, '2026-04-05 08:16:29', '2026-04-05 08:16:29'),
(5, 4, 'CET-CREAM-X1', '2026-08-15', 30, 30, 2, '2026-04-05 08:16:29', '2026-04-05 08:16:29'),
(6, 4, 'CET-CREAM-X2', '2027-11-20', 20, 20, 2, '2026-04-05 08:16:29', '2026-04-05 08:16:29'),
(7, 5, 'BIO-2027X', '2027-12-01', 200, 200, 2, '2026-04-05 08:16:38', '2026-04-05 08:16:38'),
(8, 6, 'PC-BHA-25Y', '2025-10-30', 50, 50, 2, '2026-04-05 08:16:38', '2026-04-05 08:16:38');

--
-- Triggers `batches`
--
DROP TRIGGER IF EXISTS `after_batch_delete`;
DELIMITER $$
CREATE TRIGGER `after_batch_delete` AFTER DELETE ON `batches` FOR EACH ROW BEGIN
    UPDATE products 
    SET stock_quantity = (SELECT COALESCE(SUM(remaining_quantity), 0) FROM batches WHERE product_id = OLD.product_id)
    WHERE id = OLD.product_id;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `after_batch_insert`;
DELIMITER $$
CREATE TRIGGER `after_batch_insert` AFTER INSERT ON `batches` FOR EACH ROW BEGIN
    UPDATE products 
    SET stock_quantity = (SELECT COALESCE(SUM(remaining_quantity), 0) FROM batches WHERE product_id = NEW.product_id)
    WHERE id = NEW.product_id;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `after_batch_update`;
DELIMITER $$
CREATE TRIGGER `after_batch_update` AFTER UPDATE ON `batches` FOR EACH ROW BEGIN
    UPDATE products 
    SET stock_quantity = (SELECT COALESCE(SUM(remaining_quantity), 0) FROM batches WHERE product_id = NEW.product_id)
    WHERE id = NEW.product_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `brands`
--

DROP TABLE IF EXISTS `brands`;
CREATE TABLE IF NOT EXISTS `brands` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`),
  KEY `idx_brands_slug` (`slug`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `brands`
--

INSERT INTO `brands` (`id`, `name`, `slug`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'La Roche-Posay', 'la-roche-posay', 1, '2026-04-05 08:16:29', '2026-04-05 08:16:29'),
(2, 'CeraVe', 'cerave', 1, '2026-04-05 08:16:29', '2026-04-05 08:16:29'),
(3, 'Vichy', 'vichy', 1, '2026-04-05 08:16:29', '2026-04-05 08:16:29'),
(4, 'Cetaphil', 'cetaphil', 1, '2026-04-05 08:16:29', '2026-04-05 08:16:29'),
(5, 'Bioderma', 'bioderma', 1, '2026-04-05 08:16:38', '2026-04-05 08:16:38'),
(6, 'Paula\'s Choice', 'paulas-choice', 1, '2026-04-05 08:16:38', '2026-04-05 08:16:38');

-- --------------------------------------------------------

--
-- Table structure for table `carts`
--

DROP TABLE IF EXISTS `carts`;
CREATE TABLE IF NOT EXISTS `carts` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` int UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_carts_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cart_items`
--

DROP TABLE IF EXISTS `cart_items`;
CREATE TABLE IF NOT EXISTS `cart_items` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `cart_id` int UNSIGNED NOT NULL,
  `product_id` int UNSIGNED NOT NULL,
  `quantity` int NOT NULL DEFAULT '1',
  `price` decimal(15,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_cart_product` (`cart_id`,`product_id`),
  KEY `product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

DROP TABLE IF EXISTS `categories`;
CREATE TABLE IF NOT EXISTS `categories` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`),
  KEY `idx_categories_slug` (`slug`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`id`, `name`, `slug`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Sữa rửa mặt', 'sua-rua-mat', 1, '2026-04-05 08:16:29', '2026-04-05 08:16:29'),
(2, 'Kem trị mụn', 'kem-tri-mun', 1, '2026-04-05 08:16:29', '2026-04-05 08:16:29'),
(3, 'Kem chống nắng', 'kem-chong-nang', 1, '2026-04-05 08:16:29', '2026-04-05 08:16:29'),
(4, 'Kem dưỡng phục hồi', 'kem-duong-phuc-hoi', 1, '2026-04-05 08:16:29', '2026-04-05 08:16:29'),
(5, 'Nước tẩy trang', 'nuoc-tay-trang', 1, '2026-04-05 08:16:38', '2026-04-05 08:16:38'),
(6, 'Tẩy tế bào chết', 'tay-te-bao-chet', 1, '2026-04-05 08:16:38', '2026-04-05 08:16:38');

-- --------------------------------------------------------

--
-- Table structure for table `email_verifications`
--

DROP TABLE IF EXISTS `email_verifications`;
CREATE TABLE IF NOT EXISTS `email_verifications` (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(6) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` timestamp NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `email_verifications_email_index` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `inventory_transactions`
--

DROP TABLE IF EXISTS `inventory_transactions`;
CREATE TABLE IF NOT EXISTS `inventory_transactions` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` int UNSIGNED NOT NULL,
  `batch_id` int UNSIGNED NOT NULL,
  `type` enum('import','export','adjustment') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'import: nhập, export: xuất, adjustment: kiểm kê',
  `quantity` int NOT NULL,
  `reference_id` int DEFAULT NULL COMMENT 'order_id nếu export, null nếu import',
  `note` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_by` int UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `batch_id` (`batch_id`),
  KEY `created_by` (`created_by`),
  KEY `idx_inventory_transactions_product_id` (`product_id`),
  KEY `idx_inventory_transactions_type` (`type`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `inventory_transactions`
--

INSERT INTO `inventory_transactions` (`id`, `product_id`, `batch_id`, `type`, `quantity`, `reference_id`, `note`, `created_by`, `created_at`) VALUES
(1, 1, 1, 'import', 100, NULL, 'Nhập kho lần 1 CeraVe Foaming Cleanser', 2, '2026-04-05 08:16:29'),
(2, 1, 2, 'import', 50, NULL, 'Nhập kho bổ sung CeraVe date 2027', 2, '2026-04-05 08:16:29'),
(3, 2, 3, 'import', 80, NULL, 'Nhập lô hàng La Roche-Posay mới', 2, '2026-04-05 08:16:29'),
(4, 3, 4, 'import', 100, NULL, 'Nhập kem chống nắng mùa hè', 2, '2026-04-05 08:16:29'),
(5, 4, 5, 'import', 30, NULL, 'Nhập Cetaphil lô cận date', 2, '2026-04-05 08:16:29'),
(6, 4, 6, 'import', 20, NULL, 'Nhập bổ sung Cetaphil lô date xa', 2, '2026-04-05 08:16:29'),
(7, 5, 7, 'import', 200, NULL, 'Nhập lô tẩy trang Bioderma nắp hồng', 2, '2026-04-05 08:16:38'),
(8, 6, 8, 'import', 50, NULL, 'Nhập BHA Paula\'s choice', 2, '2026-04-05 08:16:38'),
(9, 1, 1, 'export', 1, 1, 'Xuất kho tự động cho đơn hàng ORD-LC-8899', 2, '2026-04-05 08:16:38'),
(10, 2, 3, 'export', 1, 1, 'Xuất kho tự động cho đơn hàng ORD-LC-8899', 2, '2026-04-05 08:16:38'),
(11, 1, 1, 'export', 3, 2, 'Xuất kho cho đơn hàng ORD-UJP91Z3ESS', 5, '2026-04-06 09:55:36'),
(12, 2, 3, 'export', 2, 2, 'Xuất kho cho đơn hàng ORD-UJP91Z3ESS', 5, '2026-04-06 09:55:36'),
(13, 2, 3, 'export', 1, 3, 'Xuất kho cho đơn hàng ORD-BYX44K6VEL', 1, '2026-04-06 09:58:10'),
(14, 2, 3, 'export', 1, 4, 'Xuất kho cho đơn hàng ORD-QFBOAYOVOB', 1, '2026-04-06 10:33:22'),
(23, 2, 3, 'export', 1, 9, 'Xuất kho cho đơn hàng ORD-JGL6AA3H5T', 1, '2026-04-06 10:39:16');

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

DROP TABLE IF EXISTS `migrations`;
CREATE TABLE IF NOT EXISTS `migrations` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `migration` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch` int NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '2025_11_26_083054_create_personal_access_tokens_table', 1);

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
CREATE TABLE IF NOT EXISTS `orders` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` int UNSIGNED NOT NULL,
  `address_id` int UNSIGNED NOT NULL,
  `order_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_amount` decimal(15,2) NOT NULL,
  `shipping_fee` decimal(15,2) NOT NULL DEFAULT '0.00',
  `final_amount` decimal(15,2) NOT NULL,
  `order_status` enum('pending','confirmed','packing','shipping','delivered','cancelled') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `payment_status` enum('unpaid','paid') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'unpaid',
  `payment_method` enum('bank_transfer','vnpay','momo') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `note` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `order_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `paid_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `order_code` (`order_code`),
  KEY `address_id` (`address_id`),
  KEY `idx_orders_user_id` (`user_id`),
  KEY `idx_orders_order_code` (`order_code`),
  KEY `idx_orders_order_status` (`order_status`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `user_id`, `address_id`, `order_code`, `total_amount`, `shipping_fee`, `final_amount`, `order_status`, `payment_status`, `payment_method`, `note`, `order_date`, `paid_at`, `created_at`, `updated_at`) VALUES
(1, 3, 1, 'ORD-LC-8899', 775000.00, 25000.00, 800000.00, 'delivered', 'paid', 'vnpay', 'Giao hàng trong giờ hành chính giúp em', '2026-04-05 03:00:00', NULL, '2026-04-05 08:16:38', '2026-04-05 08:16:38'),
(2, 5, 2, 'ORD-UJP91Z3ESS', 1900000.00, 0.00, 1900000.00, 'pending', 'unpaid', 'bank_transfer', '31', '2026-04-06 09:55:36', NULL, '2026-04-06 02:55:36', '2026-04-06 02:55:36'),
(3, 1, 3, 'ORD-BYX44K6VEL', 425000.00, 0.00, 425000.00, 'delivered', 'unpaid', 'bank_transfer', 'dw', '2026-04-06 09:58:10', NULL, '2026-04-06 02:58:10', '2026-04-06 03:04:38'),
(4, 1, 4, 'ORD-QFBOAYOVOB', 425000.00, 0.00, 425000.00, 'pending', 'unpaid', 'bank_transfer', '[TK: OCB - 2313 1231 2312 3123 - NGUYEN HAI DANG] d', '2026-04-06 10:33:22', NULL, '2026-04-06 03:33:22', '2026-04-06 03:33:22'),
(9, 1, 9, 'ORD-JGL6AA3H5T', 425000.00, 0.00, 425000.00, 'pending', 'unpaid', 'vnpay', 'w', '2026-04-06 10:39:16', NULL, '2026-04-06 03:39:16', '2026-04-06 03:39:16');

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

DROP TABLE IF EXISTS `order_items`;
CREATE TABLE IF NOT EXISTS `order_items` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` int UNSIGNED NOT NULL,
  `product_id` int UNSIGNED NOT NULL,
  `batch_id` int UNSIGNED NOT NULL,
  `quantity` int NOT NULL,
  `price` decimal(15,2) NOT NULL,
  `total` decimal(15,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `product_id` (`product_id`),
  KEY `batch_id` (`batch_id`),
  KEY `idx_order_items_order_id` (`order_id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `order_items`
--

INSERT INTO `order_items` (`id`, `order_id`, `product_id`, `batch_id`, `quantity`, `price`, `total`, `created_at`) VALUES
(1, 1, 1, 1, 1, 350000.00, 350000.00, '2026-04-05 08:16:38'),
(2, 1, 2, 3, 1, 425000.00, 425000.00, '2026-04-05 08:16:38'),
(3, 2, 1, 1, 3, 350000.00, 1050000.00, '2026-04-06 09:55:36'),
(4, 2, 2, 3, 2, 425000.00, 850000.00, '2026-04-06 09:55:36'),
(5, 3, 2, 3, 1, 425000.00, 425000.00, '2026-04-06 09:58:10'),
(6, 4, 2, 3, 1, 425000.00, 425000.00, '2026-04-06 10:33:22'),
(15, 9, 2, 3, 1, 425000.00, 425000.00, '2026-04-06 10:39:16');

--
-- Triggers `order_items`
--
DROP TRIGGER IF EXISTS `after_order_item_insert`;
DELIMITER $$
CREATE TRIGGER `after_order_item_insert` AFTER INSERT ON `order_items` FOR EACH ROW BEGIN
    UPDATE products
    SET sold_count = sold_count + NEW.quantity
    WHERE id = NEW.product_id;

    UPDATE batches
    SET remaining_quantity = remaining_quantity - NEW.quantity
    WHERE id = NEW.batch_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

DROP TABLE IF EXISTS `payments`;
CREATE TABLE IF NOT EXISTS `payments` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` int UNSIGNED NOT NULL,
  `transaction_code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `amount` decimal(15,2) NOT NULL,
  `payment_method` enum('bank_transfer','vnpay','momo') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('pending','success','failed') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `paid_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_payments_order_id` (`order_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `payments`
--

INSERT INTO `payments` (`id`, `order_id`, `transaction_code`, `amount`, `payment_method`, `status`, `paid_at`, `created_at`, `updated_at`) VALUES
(1, 1, 'VNPAY-9988776655', 800000.00, 'vnpay', 'success', NULL, '2026-04-05 08:16:38', '2026-04-05 08:16:38'),
(2, 2, NULL, 1900000.00, 'bank_transfer', 'pending', NULL, '2026-04-06 02:55:36', '2026-04-06 02:55:36'),
(3, 3, NULL, 425000.00, 'bank_transfer', 'pending', NULL, '2026-04-06 02:58:10', '2026-04-06 02:58:10'),
(4, 4, NULL, 425000.00, 'bank_transfer', 'pending', NULL, '2026-04-06 03:33:22', '2026-04-06 03:33:22'),
(9, 9, NULL, 425000.00, 'vnpay', 'pending', NULL, '2026-04-06 03:39:16', '2026-04-06 03:39:16');

-- --------------------------------------------------------

--
-- Table structure for table `personal_access_tokens`
--

DROP TABLE IF EXISTS `personal_access_tokens`;
CREATE TABLE IF NOT EXISTS `personal_access_tokens` (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `tokenable_type` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tokenable_id` bigint UNSIGNED NOT NULL,
  `name` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `abilities` text COLLATE utf8mb4_unicode_ci,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  KEY `personal_access_tokens_expires_at_index` (`expires_at`)
) ENGINE=MyISAM AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `personal_access_tokens`
--

INSERT INTO `personal_access_tokens` (`id`, `tokenable_type`, `tokenable_id`, `name`, `token`, `abilities`, `last_used_at`, `expires_at`, `created_at`, `updated_at`) VALUES
(7, 'App\\Models\\User', 1, 'auth_token', '95e68bf0e1d9cd45a06ef49cb68b60f7dd808eabb9a263462053666899f364c1', '[\"*\"]', '2026-04-06 09:17:07', NULL, '2026-04-06 02:56:09', '2026-04-06 09:17:07');

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

DROP TABLE IF EXISTS `products`;
CREATE TABLE IF NOT EXISTS `products` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `category_id` int UNSIGNED NOT NULL,
  `brand_id` int UNSIGNED DEFAULT NULL,
  `name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `image` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `price_listed` decimal(15,2) NOT NULL,
  `dosage_form` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `volume` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `stock_quantity` int NOT NULL DEFAULT '0',
  `stock_warning` int NOT NULL DEFAULT '10',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `sold_count` int NOT NULL DEFAULT '0',
  `created_by` int UNSIGNED NOT NULL,
  `updated_by` int UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`),
  KEY `brand_id` (`brand_id`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`),
  KEY `idx_products_slug` (`slug`),
  KEY `idx_products_category_id` (`category_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`id`, `category_id`, `brand_id`, `name`, `slug`, `image`, `description`, `price_listed`, `dosage_form`, `volume`, `stock_quantity`, `stock_warning`, `is_active`, `sold_count`, `created_by`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 1, 2, 'Sữa Rửa Mặt CeraVe Foaming Cleanser', 'cerave-foaming-cleanser', 'cerave-cleanser.jpg', 'Sữa rửa mặt tạo bọt dành cho da dầu mụn.', 350000.00, 'Chai', '236ml', 146, 20, 1, 4, 1, NULL, '2026-04-05 08:16:29', '2026-04-06 09:55:36'),
(2, 2, 1, 'Kem Trị Mụn La Roche-Posay Effaclar Duo+', 'la-roche-posay-effaclar-duo', 'laroche-duo.jpg', 'Kem giảm mụn, ngừa vết thâm, thông thoáng lỗ chân lông.', 425000.00, 'Tuýp', '40ml', 74, 15, 1, 6, 1, NULL, '2026-04-05 08:16:29', '2026-04-06 10:39:16'),
(3, 3, 3, 'Kem Chống Nắng Vichy Capital Soleil', 'vichy-capital-soleil', 'vichy-sunscreen.jpg', 'Kem chống nắng kiểm soát dầu không nhờn rít.', 485000.00, 'Tuýp', '50ml', 100, 10, 1, 0, 1, NULL, '2026-04-05 08:16:29', '2026-04-05 08:16:29'),
(4, 4, 4, 'Kem Dưỡng Ẩm Cetaphil Moisturizing Cream', 'cetaphil-moisturizing-cream', 'cetaphil-cream.jpg', 'Kem dưỡng ẩm phục hồi hàng rào bảo vệ da mặt và cơ thể.', 250000.00, 'Hũ', '50g', 50, 10, 1, 0, 1, NULL, '2026-04-05 08:16:29', '2026-04-05 08:16:29'),
(5, 5, 5, 'Nước Tẩy Trang Bioderma Sensibio H2O', 'bioderma-sensibio-h2o', 'bioderma-h2o.jpg', 'Nước tẩy trang làm sạch sâu dành cho da nhạy cảm.', 430000.00, 'Chai', '500ml', 200, 20, 1, 0, 1, NULL, '2026-04-05 08:16:38', '2026-04-05 08:16:38'),
(6, 6, 6, 'Dung Dịch Tẩy Tế Bào Chết Paula\'s Choice 2% BHA', 'paulas-choice-2-bha', 'paulas-choice-bha.jpg', 'Tẩy tế bào chết hóa học, giảm mụn ẩn, thu nhỏ lỗ chân lông.', 899000.00, 'Chai', '118ml', 50, 10, 1, 0, 1, NULL, '2026-04-05 08:16:38', '2026-04-05 08:16:38');

-- --------------------------------------------------------

--
-- Table structure for table `product_tag`
--

DROP TABLE IF EXISTS `product_tag`;
CREATE TABLE IF NOT EXISTS `product_tag` (
  `product_id` int UNSIGNED NOT NULL,
  `tag_id` int UNSIGNED NOT NULL,
  PRIMARY KEY (`product_id`,`tag_id`),
  KEY `tag_id` (`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `product_tag`
--

INSERT INTO `product_tag` (`product_id`, `tag_id`) VALUES
(1, 1),
(2, 1),
(6, 1),
(2, 2),
(4, 2),
(5, 2),
(1, 3),
(3, 3),
(6, 3),
(1, 4),
(3, 4),
(5, 4),
(6, 4);

-- --------------------------------------------------------

--
-- Table structure for table `settings`
--

DROP TABLE IF EXISTS `settings`;
CREATE TABLE IF NOT EXISTS `settings` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `key` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `key` (`key`),
  KEY `idx_settings_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tags`
--

DROP TABLE IF EXISTS `tags`;
CREATE TABLE IF NOT EXISTS `tags` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tags`
--

INSERT INTO `tags` (`id`, `name`, `slug`, `created_at`) VALUES
(1, 'Da mụn', 'da-mun', '2026-04-05 08:16:29'),
(2, 'Da nhạy cảm', 'da-nhay-cam', '2026-04-05 08:16:29'),
(3, 'Da dầu', 'da-dau', '2026-04-05 08:16:29'),
(4, 'Dược mỹ phẩm', 'duoc-my-pham', '2026-04-05 08:16:29');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE IF NOT EXISTS `users` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('admin','warehouse','customer') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'customer',
  `status` enum('active','inactive') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active',
  `remember_token` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  KEY `idx_users_email` (`email`),
  KEY `idx_users_role` (`role`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `password`, `phone`, `role`, `status`, `remember_token`, `created_at`, `updated_at`) VALUES
(1, 'Admin', 'admin@test.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '0123456789', 'admin', 'active', NULL, '2026-04-02 12:37:39', '2026-04-02 12:37:39'),
(2, 'Warehouse', 'warehouse@test.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '0987654321', 'warehouse', 'active', NULL, '2026-04-02 12:37:39', '2026-04-02 12:37:39'),
(3, 'Nguyen Thi Cam Tu', 'customer@test.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '0909123456', 'customer', 'active', NULL, '2026-04-02 12:37:39', '2026-04-02 12:37:39'),
(5, 'Hải Đăng Nguyễn', 'haidang40021181@gmail.com', '$2y$12$i0B.Z3CuE8RX7iHCHn6FsOLXx4qHr/P.RaOcc.TlKqMqQGBYKFd5K', '1234567890', 'customer', 'active', NULL, '2026-04-06 02:16:39', '2026-04-06 02:16:39');

-- --------------------------------------------------------

--
-- Table structure for table `user_addresses`
--

DROP TABLE IF EXISTS `user_addresses`;
CREATE TABLE IF NOT EXISTS `user_addresses` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` int UNSIGNED NOT NULL,
  `full_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `address_line` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `ward` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `district` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `city` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_addresses_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_addresses`
--

INSERT INTO `user_addresses` (`id`, `user_id`, `full_name`, `phone`, `address_line`, `ward`, `district`, `city`, `is_default`, `created_at`, `updated_at`) VALUES
(1, 3, 'Nguyễn Thị Cẩm Tú', '0909123456', 'Số 18, Đường Cao Lỗ', 'Phường 4', 'Quận 8', 'Hồ Chí Minh', 1, '2026-04-05 08:16:38', '2026-04-05 08:16:38'),
(2, 5, 'Hải Đăng Nguyễn', '1234567890', '21', '31', '312', '31', 0, '2026-04-06 02:55:36', '2026-04-06 02:55:36'),
(3, 1, 'Hải Đăng Nguyễn', '1234567890', 'dwa', 'dwa', 'đ', 'wad', 0, '2026-04-06 02:58:10', '2026-04-06 02:58:10'),
(4, 1, 'Admin', '0123456789', 'd', 'd', 'd', 'd', 0, '2026-04-06 03:33:22', '2026-04-06 03:33:22'),
(9, 1, 'Admin', '0123456789', 'w', 'w', 'w', 'w', 0, '2026-04-06 03:39:16', '2026-04-06 03:39:16');

-- --------------------------------------------------------

--
-- Table structure for table `warehouse_alerts`
--

DROP TABLE IF EXISTS `warehouse_alerts`;
CREATE TABLE IF NOT EXISTS `warehouse_alerts` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` int UNSIGNED NOT NULL,
  `alert_type` enum('low_stock','expiring_soon','expired') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `message` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_resolved` tinyint(1) NOT NULL DEFAULT '0',
  `resolved_by` int UNSIGNED DEFAULT NULL,
  `resolved_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `resolved_by` (`resolved_by`),
  KEY `idx_warehouse_alerts_product_id` (`product_id`),
  KEY `idx_warehouse_alerts_is_resolved` (`is_resolved`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `warehouse_alerts`
--

INSERT INTO `warehouse_alerts` (`id`, `product_id`, `alert_type`, `message`, `is_resolved`, `resolved_by`, `resolved_at`, `created_at`) VALUES
(1, 4, 'low_stock', 'Sản phẩm Kem Dưỡng Ẩm Cetaphil sắp chạm mức cảnh báo tồn kho', 0, NULL, NULL, '2026-04-05 08:16:38'),
(2, 6, 'expiring_soon', 'Lô PC-BHA-25Y của Paula\'s Choice 2% BHA sắp hết hạn (30/10/2025)', 0, NULL, NULL, '2026-04-05 08:16:38'),
(3, 6, 'expired', 'Lô PC-BHA-25Y đã hết hạn !', 1, 1, '2026-04-06 01:33:24', '2026-04-06 06:19:34');

--
-- Constraints for dumped tables
--

--
-- Constraints for table `batches`
--
ALTER TABLE `batches`
  ADD CONSTRAINT `batches_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `batches_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `carts`
--
ALTER TABLE `carts`
  ADD CONSTRAINT `carts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `cart_items`
--
ALTER TABLE `cart_items`
  ADD CONSTRAINT `cart_items_ibfk_1` FOREIGN KEY (`cart_id`) REFERENCES `carts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `cart_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`);

--
-- Constraints for table `inventory_transactions`
--
ALTER TABLE `inventory_transactions`
  ADD CONSTRAINT `inventory_transactions_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`),
  ADD CONSTRAINT `inventory_transactions_ibfk_2` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`id`),
  ADD CONSTRAINT `inventory_transactions_ibfk_3` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`address_id`) REFERENCES `user_addresses` (`id`);

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`),
  ADD CONSTRAINT `order_items_ibfk_3` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`id`);

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`);

--
-- Constraints for table `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `products_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`),
  ADD CONSTRAINT `products_ibfk_2` FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `products_ibfk_3` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `products_ibfk_4` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `product_tag`
--
ALTER TABLE `product_tag`
  ADD CONSTRAINT `product_tag_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `product_tag_ibfk_2` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_addresses`
--
ALTER TABLE `user_addresses`
  ADD CONSTRAINT `user_addresses_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `warehouse_alerts`
--
ALTER TABLE `warehouse_alerts`
  ADD CONSTRAINT `warehouse_alerts_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`),
  ADD CONSTRAINT `warehouse_alerts_ibfk_2` FOREIGN KEY (`resolved_by`) REFERENCES `users` (`id`);

DELIMITER $$
--
-- Events
--
DROP EVENT IF EXISTS `daily_warehouse_scan`$$
CREATE DEFINER=`root`@`localhost` EVENT `daily_warehouse_scan` ON SCHEDULE EVERY 1 DAY STARTS '2026-04-06 00:00:00' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    CALL sp_generate_warehouse_alerts();
END$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
