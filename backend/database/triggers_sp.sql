DELIMITER //

-- =========================================================================
-- 1. TRIGGERS ĐỒNG BỘ TỒN KHO VÀO BẢNG PRODUCTS TỪ BATCHES
-- =========================================================================

-- Trigger After Insert Batch
DROP TRIGGER IF EXISTS after_batch_insert //
CREATE TRIGGER after_batch_insert
AFTER INSERT ON batches
FOR EACH ROW
BEGIN
    UPDATE products 
    SET stock_quantity = (SELECT COALESCE(SUM(remaining_quantity), 0) FROM batches WHERE product_id = NEW.product_id)
    WHERE id = NEW.product_id;
END //

-- Trigger After Update Batch
DROP TRIGGER IF EXISTS after_batch_update //
CREATE TRIGGER after_batch_update
AFTER UPDATE ON batches
FOR EACH ROW
BEGIN
    UPDATE products 
    SET stock_quantity = (SELECT COALESCE(SUM(remaining_quantity), 0) FROM batches WHERE product_id = NEW.product_id)
    WHERE id = NEW.product_id;
END //

-- Trigger After Delete Batch
DROP TRIGGER IF EXISTS after_batch_delete //
CREATE TRIGGER after_batch_delete
AFTER DELETE ON batches
FOR EACH ROW
BEGIN
    UPDATE products 
    SET stock_quantity = (SELECT COALESCE(SUM(remaining_quantity), 0) FROM batches WHERE product_id = OLD.product_id)
    WHERE id = OLD.product_id;
END //


-- =========================================================================
-- 2. TRIGGER UPDATE SOLD_COUNT VÀ BATCH REMAINING KHI THÊM ORDER ITEM
-- =========================================================================
DROP TRIGGER IF EXISTS after_order_item_insert //
CREATE TRIGGER after_order_item_insert
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    -- Cập nhật sold_count cho product
    UPDATE products
    SET sold_count = sold_count + NEW.quantity
    WHERE id = NEW.product_id;

    -- Trừ lượng hàng đã lấy khỏi lô batch tương ứng.
    -- (Việc này sẽ kích hoạt sau trigger 'after_batch_update' để trừ tổng stock_quantity ở bảng products)
    UPDATE batches
    SET remaining_quantity = remaining_quantity - NEW.quantity
    WHERE id = NEW.batch_id;
END //


-- =========================================================================
-- 3. STORED PROCEDURE PHÂN BỔ ĐƠN HÀNG THEO CHUẨN FEFO
-- =========================================================================
-- Nó sẽ tự loop qua các lô hàng cận date, trừ dần và tạo records ở order_items
DROP PROCEDURE IF EXISTS sp_allocate_order_fefo //
CREATE PROCEDURE sp_allocate_order_fefo(IN p_order_id INT, IN p_product_id INT, IN p_quantity INT, IN p_price DECIMAL(15,2))
BEGIN
    DECLARE v_remaining INT DEFAULT p_quantity;
    DECLARE v_batch_id INT;
    DECLARE v_batch_stock INT;
    DECLARE v_take INT;
    DECLARE done INT DEFAULT FALSE;
    
    -- Lấy danh sách các lô có sẵn theo hạn sử dụng tăng dần (Cận date xuất trước)
    DECLARE cur CURSOR FOR 
        SELECT id, remaining_quantity 
        FROM batches 
        WHERE product_id = p_product_id AND remaining_quantity > 0 
        ORDER BY expiry_date ASC
        FOR UPDATE; -- Khóa dòng để an toàn đồng thời
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Bắt đầu duyệt Cursor
    OPEN cur;
    
    allocation_loop: LOOP
        FETCH cur INTO v_batch_id, v_batch_stock;
        
        IF done THEN
            LEAVE allocation_loop;
        END IF;
        
        -- Xác định số lượng lấy từ lô này
        IF v_batch_stock >= v_remaining THEN
            SET v_take = v_remaining;
        ELSE
            SET v_take = v_batch_stock;
        END IF;
        
        -- Insert trực tiếp vào order_items
        -- (TRIGGER after_order_item_insert sẽ được gọi và tự động trừ số lượng vào batches table)
        INSERT INTO order_items (order_id, product_id, batch_id, quantity, price, total)
        VALUES (p_order_id, p_product_id, v_batch_id, v_take, p_price, v_take * p_price);
        
        -- Giảm số lượng còn phải chiết tách theo FEFO
        SET v_remaining = v_remaining - v_take;
        
        IF v_remaining <= 0 THEN
            LEAVE allocation_loop;
        END IF;
        
    END LOOP;
    
    CLOSE cur;
    
    -- Rollback / Báo lỗi nếu thiếu hàng (Do bất đồng bộ số lượng)
    IF v_remaining > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Không đủ số lượng hàng hợp lệ trong kho!';
    END IF;
    
END //


-- =========================================================================
-- 4. TỰ ĐỘNG CẢNH BÁO KHO BẰNG STORED PROCEDURE
-- =========================================================================
DROP PROCEDURE IF EXISTS sp_generate_warehouse_alerts //
CREATE PROCEDURE sp_generate_warehouse_alerts()
BEGIN
    -- A. Low stock alerts
    INSERT INTO warehouse_alerts (product_id, alert_type, message, is_resolved)
    SELECT id, 'low_stock', CONCAT('Sản phẩm sắp hết hàng (còn ', stock_quantity, ')'), 0
    FROM products p
    WHERE stock_quantity <= stock_warning AND is_active = 1
      -- Chỉ thông báo nếu chưa có cảnh báo Low Stock chưa resolve của SP này
      AND NOT EXISTS (SELECT 1 FROM warehouse_alerts w WHERE w.product_id = p.id AND w.alert_type='low_stock' AND w.is_resolved=0);
      
    -- B. Expired alerts (Đã hết hạn)
    INSERT INTO warehouse_alerts (product_id, alert_type, message, is_resolved)
    SELECT b.product_id, 'expired', CONCAT('Lô ', b.batch_code, ' đã hết hạn !'), 0
    FROM batches b JOIN products pt ON b.product_id = pt.id
    WHERE b.expiry_date < CURDATE() AND b.remaining_quantity > 0
      AND NOT EXISTS (SELECT 1 FROM warehouse_alerts w WHERE w.product_id = pt.id AND w.alert_type='expired' AND w.message LIKE CONCAT('%', b.batch_code, '%') AND w.is_resolved=0);

    -- C. Expiring Soon (Hết hạn trong 90 ngày tới)
    INSERT INTO warehouse_alerts (product_id, alert_type, message, is_resolved)
    SELECT b.product_id, 'expiring_soon', CONCAT('Lô ', b.batch_code, ' hết hạn vào ', DATE_FORMAT(b.expiry_date, '%d/%m/%Y')), 0
    FROM batches b JOIN products pt ON b.product_id = pt.id
    WHERE b.expiry_date >= CURDATE() AND b.expiry_date <= DATE_ADD(CURDATE(), INTERVAL 90 DAY) AND b.remaining_quantity > 0
      AND NOT EXISTS (SELECT 1 FROM warehouse_alerts w WHERE w.product_id = pt.id AND w.alert_type='expiring_soon' AND w.message LIKE CONCAT('%', b.batch_code, '%') AND w.is_resolved=0);

END //


-- =========================================================================
-- 5. LẬP SCHEDULE CHO WAREHOUSE ALERTS (CHẠY 00:00 MỖI ĐÊM)
-- =========================================================================
DROP EVENT IF EXISTS daily_warehouse_scan //
CREATE EVENT daily_warehouse_scan
ON SCHEDULE EVERY 1 DAY STARTS (TIMESTAMP(CURDATE()) + INTERVAL 1 DAY) -- Chạy vào lúc 0h ngày mai
DO
BEGIN
    CALL sp_generate_warehouse_alerts();
END //

DELIMITER ;
