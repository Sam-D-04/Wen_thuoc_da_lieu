<?php

namespace App\Services;

use App\Models\Order;
use App\Models\Payment;

class VNPayService
{
    protected string $tmnCode;
    protected string $hashSecret;
    protected string $paymentUrl;
    protected string $returnUrl;

    public function __construct()
    {
        $this->tmnCode    = config('vnpay.tmn_code');
        $this->hashSecret = config('vnpay.hash_secret');
        $this->paymentUrl = config('vnpay.url');
        $this->returnUrl  = config('vnpay.return_url');
    }

    public function createPaymentUrl(Order $order): string
    {
        $inputData = [
            'vnp_Version'   => '2.1.0',
            'vnp_TmnCode'   => $this->tmnCode,
            'vnp_Amount'    => (int) ($order->final_amount * 100),
            'vnp_Command'   => 'pay',
            'vnp_CreateDate'=> now()->format('YmdHis'),
            'vnp_CurrCode'  => 'VND',
            'vnp_IpAddr'    => request()->ip(),
            'vnp_Locale'    => 'vn',
            'vnp_OrderInfo' => 'Thanh toan don hang ' . $order->order_code,
            'vnp_OrderType' => 'billpayment',
            'vnp_ReturnUrl' => $this->returnUrl,
            'vnp_TxnRef'    => $order->id,
            'vnp_ExpireDate'=> now()->addMinutes(15)->format('YmdHis'),
        ];

        ksort($inputData);

        $hashData = urldecode(http_build_query($inputData));
        $secureHash = hash_hmac('sha512', $hashData, $this->hashSecret);

        return $this->paymentUrl . '?' . http_build_query($inputData) . '&vnp_SecureHash=' . $secureHash;
    }

    public function verifyReturn(array $params): bool
    {
        $secureHash = $params['vnp_SecureHash'] ?? '';
        $data = $params;
        unset($data['vnp_SecureHash'], $data['vnp_SecureHashType']);
        ksort($data);

        $hashData = urldecode(http_build_query($data));
        $expected = hash_hmac('sha512', $hashData, $this->hashSecret);

        return hash_equals($expected, $secureHash);
    }
}
