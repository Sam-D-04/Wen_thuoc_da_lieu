<?php

namespace App\Services;

class VNPayService
{
    protected $vnp_TmnCode = "YOUR_TMN_CODE";
    protected $vnp_HashSecret = "YOUR_SECRET";
    protected $vnp_Url = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";

    public function createPaymentUrl($order)
    {
        $vnp_TxnRef = $order->id;
        $vnp_Amount = $order->total_price * 100;
        $vnp_ReturnUrl = route('vnpay.return');

        $inputData = [
            "vnp_Version" => "2.1.0",
            "vnp_TmnCode" => $this->vnp_TmnCode,
            "vnp_Amount" => $vnp_Amount,
            "vnp_Command" => "pay",
            "vnp_CreateDate" => date('YmdHis'),
            "vnp_CurrCode" => "VND",
            "vnp_IpAddr" => request()->ip(),
            "vnp_Locale" => "vn",
            "vnp_OrderInfo" => "Thanh toan don hang #" . $order->id,
            "vnp_OrderType" => "billpayment",
            "vnp_ReturnUrl" => $vnp_ReturnUrl,
            "vnp_TxnRef" => $vnp_TxnRef,
        ];

        ksort($inputData);

        $query = http_build_query($inputData);
        $hashData = urldecode($query);

        $vnp_SecureHash = hash_hmac('sha512', $hashData, $this->vnp_HashSecret);

        return $this->vnp_Url . "?" . $query . '&vnp_SecureHash=' . $vnp_SecureHash;
    }
}
