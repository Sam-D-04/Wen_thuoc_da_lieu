<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\BrandController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\BatchController;
use App\Http\Controllers\Api\WarehouseController;
use App\Http\Controllers\Api\StatsController;
use Illuminate\Support\Facades\Route;

// ─── Public routes ──────────────────────────────────────────────────────────
Route::post('/register',             [AuthController::class, 'register']);
Route::post('/verify-email',         [AuthController::class, 'verifyEmail']);
Route::post('/resend-verification',  [AuthController::class, 'resendVerificationCode']);
Route::post('/login',                [AuthController::class, 'login']);

// Products & Categories (public read)
Route::get('/products',           [ProductController::class, 'index']);
Route::get('/products/{slug}',    [ProductController::class, 'show']);
Route::get('/categories',         [CategoryController::class, 'index']);
Route::get('/categories/{slug}',  [CategoryController::class, 'show']);
Route::get('/brands',             [BrandController::class, 'index']);

// ─── Authenticated routes ────────────────────────────────────────────────────
Route::middleware('auth:sanctum')->group(function () {

    Route::get('/me',               [AuthController::class, 'me']);
    Route::post('/logout',          [AuthController::class, 'logout']);
    Route::put('/change-password',  [AuthController::class, 'changePassword']);

    // Orders — customer
    Route::get('/orders',          [OrderController::class, 'index']);
    Route::get('/orders/{id}',     [OrderController::class, 'show']);
    Route::post('/orders',         [OrderController::class, 'store']);

    // ─── Admin only ──────────────────────────────────────────────────────────
    Route::middleware('admin')->group(function () {

        // Users
        Route::get('/admin/users',    [AuthController::class, 'adminUsers']);

        // All products (no stock/batch filter)
        Route::get('/admin/products', [ProductController::class, 'adminIndex']);

        // Products CRUD
        Route::post('/products',           [ProductController::class, 'store']);
        Route::put('/products/{id}',        [ProductController::class, 'update']);
        Route::post('/products/{id}',       [ProductController::class, 'update']); // hỗ trợ file upload
        Route::delete('/products/{id}',    [ProductController::class, 'destroy']);

        // Categories CRUD
        Route::post('/categories',         [CategoryController::class, 'store']);
        Route::put('/categories/{id}',     [CategoryController::class, 'update']);
        Route::delete('/categories/{id}',  [CategoryController::class, 'destroy']);

        // Brands CRUD
        Route::post('/brands',             [BrandController::class, 'store']);
        Route::put('/brands/{id}',         [BrandController::class, 'update']);
        Route::delete('/brands/{id}',      [BrandController::class, 'destroy']);

        // Orders management
        Route::get('/admin/orders',             [OrderController::class, 'adminIndex']);
        Route::put('/orders/{id}/status',       [OrderController::class, 'updateStatus']);

        // Stats & Revenue
        Route::get('/admin/stats/revenue',      [StatsController::class, 'revenue']);
        Route::get('/admin/stats/overview',     [StatsController::class, 'overview']);
    });

    // ─── Admin + Warehouse ───────────────────────────────────────────────────
    Route::middleware('admin:admin,warehouse')->group(function () {

        // Batches (nhập kho)
        Route::get('/batches',       [BatchController::class, 'index']);
        Route::get('/batches/{id}',  [BatchController::class, 'show']);
        Route::post('/batches',      [BatchController::class, 'store']);
        Route::put('/batches/{id}',  [BatchController::class, 'update']);

        // Warehouse
        Route::get('/warehouse/alerts',              [WarehouseController::class, 'alerts']);
        Route::post('/warehouse/alerts/{id}/resolve',[WarehouseController::class, 'resolveAlert']);
        Route::post('/warehouse/check-alerts',       [WarehouseController::class, 'checkAndGenerateAlerts']);
        Route::get('/warehouse/inventory',           [WarehouseController::class, 'inventory']);
        Route::get('/warehouse/inventory-transactions', [WarehouseController::class, 'inventoryTransactions']);
    });
});
