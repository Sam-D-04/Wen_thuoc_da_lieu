<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\Payment;
use App\Services\VNPayService;
use Illuminate\Http\Request;

class VNPayController extends Controller
{
    public function handleReturn(Request $request, VNPayService $vnpay)
    {
        $params = $request->all();
        $frontendUrl = config('app.frontend_url', env('FRONTEND_URL', 'http://localhost:5173'));

        // Xác minh chữ ký
        if (!$vnpay->verifyReturn($params)) {
            return redirect($frontendUrl . '/vnpay-result?status=error&message=invalid_signature');
        }

        $responseCode = $params['vnp_ResponseCode'] ?? '';
        $orderId      = $params['vnp_TxnRef']       ?? null;
        $txnCode      = $params['vnp_TransactionNo'] ?? '';

        $order = $orderId ? Order::find($orderId) : null;

        if (!$order) {
            return redirect($frontendUrl . '/vnpay-result?status=error&message=order_not_found');
        }

        if ($responseCode === '00') {
            // Thanh toán thành công
            $order->update(['payment_status' => 'paid', 'paid_at' => now()]);

            Payment::where('order_id', $order->id)->update([
                'status'           => 'paid',
                'transaction_code' => $txnCode,
                'paid_at'          => now(),
            ]);

            return redirect($frontendUrl . '/vnpay-result?status=success&code=' . urlencode($order->order_code));
        }

        // Thanh toán thất bại / huỷ
        return redirect($frontendUrl . '/vnpay-result?status=failed&code=' . urlencode($order->order_code));
    }
}
