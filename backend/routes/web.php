<?php

use App\Http\Controllers\VNPayController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// VNPay return URL (browser redirect từ VNPay về)
Route::get('/vnpay/return', [VNPayController::class, 'handleReturn'])->name('vnpay.return');
