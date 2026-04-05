<?php

require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

DB::unprepared("DROP TRIGGER IF EXISTS after_batch_insert;");
DB::unprepared("
CREATE TRIGGER after_batch_insert
AFTER INSERT ON batches
FOR EACH ROW
BEGIN
    UPDATE products 
    SET stock_quantity = (SELECT COALESCE(SUM(remaining_quantity), 0) FROM batches WHERE product_id = NEW.product_id)
    WHERE id = NEW.product_id;
END;
");

DB::unprepared("DROP TRIGGER IF EXISTS after_batch_update;");
DB::unprepared("
CREATE TRIGGER after_batch_update
AFTER UPDATE ON batches
FOR EACH ROW
BEGIN
    UPDATE products 
    SET stock_quantity = (SELECT COALESCE(SUM(remaining_quantity), 0) FROM batches WHERE product_id = NEW.product_id)
    WHERE id = NEW.product_id;
END;
");

DB::unprepared("DROP TRIGGER IF EXISTS after_batch_delete;");
DB::unprepared("
CREATE TRIGGER after_batch_delete
AFTER DELETE ON batches
FOR EACH ROW
BEGIN
    UPDATE products 
    SET stock_quantity = (SELECT COALESCE(SUM(remaining_quantity), 0) FROM batches WHERE product_id = OLD.product_id)
    WHERE id = OLD.product_id;
END;
");

DB::unprepared("DROP TRIGGER IF EXISTS after_order_item_insert;");
DB::unprepared("
CREATE TRIGGER after_order_item_insert
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE products
    SET sold_count = sold_count + NEW.quantity
    WHERE id = NEW.product_id;

    UPDATE batches
    SET remaining_quantity = remaining_quantity - NEW.quantity
    WHERE id = NEW.batch_id;
END;
");

DB::unprepared("DROP PROCEDURE IF EXISTS sp_allocate_order_fefo;");
DB::unprepared("
CREATE PROCEDURE sp_allocate_order_fefo(IN p_order_id INT, IN p_product_id INT, IN p_quantity INT, IN p_price DECIMAL(15,2))
BEGIN
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
    
    allocation_loop: LOOP
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
    
END;
");

DB::unprepared("DROP PROCEDURE IF EXISTS sp_generate_warehouse_alerts;");
DB::unprepared("
CREATE PROCEDURE sp_generate_warehouse_alerts()
BEGIN
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
END;
");

DB::unprepared("DROP EVENT IF EXISTS daily_warehouse_scan;");
DB::unprepared("
CREATE EVENT daily_warehouse_scan
ON SCHEDULE EVERY 1 DAY STARTS (TIMESTAMP(CURDATE()) + INTERVAL 1 DAY)
DO
BEGIN
    CALL sp_generate_warehouse_alerts();
END;
");

echo "Triggers and Procedures created successfully.\n";
