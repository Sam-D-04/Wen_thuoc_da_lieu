# 📋 Dermacity Project - Next Action Items

Dưới đây là danh sách phân rã các tính năng và công việc chưa hoàn thiện của dự án **Dermacity**. Các task này đã được module hóa để bạn dễ dàng tạo Issue/Ticket trên Github và phân công cho các thành viên trong nhóm (Frontend, Backend, Admin).

---

## 🎨 1. Frontend: Tích hợp API thực tế (Storefront)
Hiện tại giao diện e-commerce (Vue.js + Pinia) đang chạy bằng Fake/Mock Data. Cần thay thế bằng việc kết nối `axios` đến Backend Laravel (`localhost:8000/api`). Toàn bộ API Docs đã có tại `docs/ThongTin/routes_reference.md`.

- [ ] **Task 1.1: Quản lý Auth State**
  - Viết interceptors cho Axios gắn Bearer Token (`auth.token`).
  - Gắn API vào method Login / Register ở `stores/auth.js`.
  - Fetch lại User Profile bằng `GET /api/me` khi reload trang.
- [ ] **Task 1.2: Fetch Catalog & Sản phẩm**
  - Chỉnh sửa `stores/shopProducts.js` để gọi API `GET /api/products` và `GET /api/categories`.
  - Đồng bộ logic tìm kiếm, phân trang và Lọc phân loại (category slug).
  - Tích hợp trang ProductDetail gọi API `GET /api/products/{slug}` để lấy mô tả chi tiết, ảnh thật và các Batch đang active.
- [ ] **Task 1.3: Giỏ hàng (Cart) & Checkout Flow**
  - Sửa Pinia Cart sử dụng API thật.
  - Gắn form thanh toán gọi tới `POST /api/orders`.
  - Validate Response từ BE (ví dụ lỗi "Không đủ kho").
- [ ] **Task 1.4: Lịch sử Đơn hàng User**
  - Tại trang tài khoản (Account), gọi `GET /api/orders` để liệt kê lịch sử mua sắm.

---

## ⚙️ 2. Backend: Hoàn thiện Payment & Notification
Backend đã rất vững về quản lý kho lô hàng (FEFO) phân qua DB Triggers/Procedures, lượng công việc tối ưu còn lại không nhiều:

- [ ] **Task 2.1: Tích hợp Cổng thanh toán (VNPay / MoMo)**
  - Viết PHP Service để mã hóa URL thanh toán gửi cho VNPay/MoMo.
  - Cập nhật hàm `OrderController@store`: trả về `payment_url` thay vì Order Object đơn thuần.
  - Viết Controller IPN Webhook để Cổng thanh toán gọi về: kiểm tra chữ ký HMAC và update `payments.status` thành `paid`.
- [ ] **Task 2.2: Gửi hóa đơn qua Email**
  - Config Mailer (`smtp`).
  - Lắng nghe Event `OrderCreated` và gửi giao diện biên lai HTML cho email Khách hàng.

---

## 📊 3. Giao diện Quản trị nội bộ (Admin & Warehouse Dashboard)
Chúng ta mới chỉ dựng giao diện Storefront cho khách mua hàng. Nhưng Backend đã cung cấp đủ Route để xây 1 trang quản trị CMS dành cho Ban quản trị. Có thể xây bằng Vue hoặc Filamen PHP.

- [ ] **Task 3.1: Quản lý Đơn hàng (Admin)**
  - Table hiển thị toàn bộ `GET /api/admin/orders`.
  - Cập nhật trạng thái đơn (Pending -> Confirmed -> Shipping -> Delivered).
- [ ] **Task 3.2: Quản lý Sản phẩm (Admin)**
  - Form tạo/sửa Product (Tạo mới `POST /api/products`), có phần Upload Image.
- [ ] **Task 3.3: Dashboard Nhân viên Kho (Warehouse)**
  - Form riêng biệt dùng để nhập hàng mới từ nhà cung cấp -> Dội API `POST /api/batches`.
  - Fetch và hiển thị chuông cảnh báo Tồn kho từ bảng `warehouse_alerts` (lấy qua API `GET /warehouse/alerts`).
- [ ] **Task 3.4: Báo cáo Thống kê Doanh thu**
  - Bổ sung 1 API `/api/admin/stats/revenue` tính tổng theo ngày/tháng để vẽ chart trên giao diện.

---

## 📦 4. Môi trường & DevOps
- [ ] **Task 4.1: Cấu hình CORS**
  - Đảm bảo file cấu hình `cors` của Backend cho phép Frontend hoạt động ở mọi thiết bị.
- [ ] **Task 4.2: Chuẩn bị Data Thuyết Trình (Seeders)**
  - Viết `DatabaseSeeder.php` tạo sẵn dữ liệu thật cho khoảng 50 Sản phẩm Dược Da Liễu xịn. Sinh sẵn Dummy Orders.
- [ ] **Task 4.3: Viết tài liệu Deploy**
  - Build frontend bằng `npm run build` ném sang thư mục `public` của Laravel để chạy 1 Port duy nhất, hoặc Deploy tách đôi BE (Aapanel/DirectAdmin) và FE (Vercel).
