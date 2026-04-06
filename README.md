# 💊 Dermacity — Dược Mỹ Phẩm Da Liễu

> Kiến trúc: **Frontend (Vue.js SPA)** + **Backend (Laravel API)** tách biệt hoàn toàn.

---

## ⚡ Chạy nhanh (1 lệnh)

Mở **CMD / Terminal** tại thư mục gốc `WEB_THUOC` và chạy:

```bash
npm run dev
```

Lệnh này sẽ **tự động chạy song song** cả Backend lẫn Frontend trong cùng 1 terminal, với màu sắc phân biệt rõ ràng:

```
[BACKEND]  Listening on http://localhost:8000
[FRONTEND] VITE ready at http://localhost:5173
```

> ⚠️ **Lần đầu chạy**: Cần cài dependencies trước — xem hướng dẫn bên dưới.

Hoặc dùng **Double-click** vào file `start-dev.bat` (mỗi server mở 1 cửa sổ riêng).

---

## 🚀 Hướng dẫn chạy thủ công


### Yêu cầu môi trường

| Công cụ | Phiên bản tối thiểu |
|---|---|
| PHP | 8.2+ |
| Composer | 2.x |
| Node.js | 18+ |
| MySQL | 8.0+ (WAMP / XAMPP) |

---

### ⚙️ 1. Chạy Backend (Laravel)

```bash
# Bước 1: Vào thư mục backend
cd backend

# Bước 2: Cài dependencies (chỉ cần làm 1 lần)
composer install

# Bước 3: Sao chép file cấu hình môi trường (chỉ cần làm 1 lần)
cp .env.example .env

# Bước 4: Sinh App Key (chỉ cần làm 1 lần)
php artisan key:generate

# Bước 5: Chạy migration để tạo bảng (chỉ cần làm 1 lần)
php artisan migrate

# Bước 6: Khởi động server API
php artisan serve --port=8000
```

> ✅ Backend chạy tại: **http://localhost:8000**
> ✅ API base URL: **http://localhost:8000/api**

---

### 🎨 2. Chạy Frontend (Vue.js)

```bash
# Bước 1: Vào thư mục frontend
cd frontend

# Bước 2: Cài dependencies (chỉ cần làm 1 lần)
npm install

# Bước 3: Khởi động development server
npm run dev
```

> ✅ Frontend chạy tại: **http://localhost:5173**

---

### 🗄️ 3. Cấu hình Database

1. Mở **phpMyAdmin** (WAMP: http://localhost/phpmyadmin)
2. Tạo database mới tên: `thuoc_da_lieu`
3. Import file SQL (nếu có): `backend/database/thuoc_da_lieu.sql`
4. Kiểm tra file `backend/.env` có đúng thông tin kết nối:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=thuoc_da_lieu
DB_USERNAME=root
DB_PASSWORD=
```

5. Bật **Event Scheduler** trong MySQL (để cảnh báo kho tự động):

```sql
SET GLOBAL event_scheduler = ON;
```

6. Chạy file Triggers & Stored Procedures:

```bash
# Trong phpMyAdmin → chọn database thuoc_da_lieu → tab SQL → paste nội dung file:
backend/database/triggers_sp.sql
```

---

## 🌐 Các đường dẫn quan trọng

| URL | Mô tả |
|---|---|
| `http://localhost:5173/shop` | 🛒 Giao diện cửa hàng (Khách hàng) |
| `http://localhost:5173/admin/dashboard` | 🔑 Bảng điều khiển Admin |
| `http://localhost:5173/warehouse/dashboard` | 📦 Dashboard Nhân viên Kho |
| `http://localhost:5173/warehouse/revenue` | 📊 Thống kê Doanh thu |
| `http://localhost:8000/api` | ⚙️ API Root |

---

## 🔑 Truy cập Admin Dashboard (để Review giao diện)

Mở **Developer Console** (F12) tại `http://localhost:5173` và chạy:

```javascript
// Giả lập đăng nhập Admin (chỉ dùng khi chưa có hệ thống Auth thật)
localStorage.setItem('auth_user', JSON.stringify({ role: 'admin' }));
```

Sau đó truy cập: `http://localhost:5173/admin/dashboard`

---

## 📁 Cấu trúc thư mục

```
WEB_THUOC/
├── backend/          # Laravel API
│   ├── app/
│   │   ├── Http/Controllers/Api/   # Controllers
│   │   ├── Models/                 # Eloquent Models
│   │   └── Services/               # VNPay Service...
│   ├── database/
│   │   ├── migrations/             # Database migrations
│   │   ├── triggers_sp.sql         # MySQL Triggers & Stored Procedures
│   │   └── thuoc_da_lieu.sql       # Database dump
│   └── routes/api.php              # API routes
│
├── frontend/         # Vue.js SPA
│   ├── src/
│   │   ├── views/
│   │   │   ├── storefront/         # Giao diện cửa hàng
│   │   │   ├── warehouse/          # Dashboard kho
│   │   │   └── auth/               # Đăng nhập / Đăng ký
│   │   ├── layouts/                # AdminLayout, StorefrontLayout
│   │   ├── components/             # Shared components
│   │   ├── stores/                 # Pinia stores
│   │   └── router/                 # Vue Router
│   └── tailwind.config.js
│
└── docs/
    └── ThongTin/
        ├── routes_reference.md     # Tài liệu API đầy đủ
        └── github_tasks_to_do.md   # Phân công công việc team
```

---

## 📚 Tài liệu tham khảo

- [API Routes Reference](docs/ThongTin/routes_reference.md)
- [Github Tasks & Phân công](docs/ThongTin/github_tasks_to_do.md)

---

© 2026 Dermacity · Da Liễu Chuyên Sâu
