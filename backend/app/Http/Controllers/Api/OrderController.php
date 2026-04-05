<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\UserAddress;
use App\Models\Product;
use App\Models\Batch;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use App\Services\VNPayService;

class OrderController extends Controller
{
    public function index(Request $request)
    {
        $orders = Order::with(['items.product', 'address'])
            ->where('user_id', $request->user()->id)
            ->latest()
            ->paginate(10);

        return response()->json($orders);
    }

    public function show(Request $request, int $id)
    {
        $order = Order::with(['items.product', 'items.batch', 'address', 'payment'])
            ->where('user_id', $request->user()->id)
            ->findOrFail($id);

        return response()->json($order);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'items'                     => 'required|array|min:1',
            'items.*.product_id'        => 'required|exists:products,id',
            'items.*.quantity'          => 'required|integer|min:1',
            'address.full_name'         => 'required|string',
            'address.phone'             => 'required|string',
            'address.address_line'      => 'required|string',
            'address.ward'              => 'required|string',
            'address.district'          => 'required|string',
            'address.city'              => 'required|string',
            'payment_method'            => 'required|in:bank_transfer,vnpay,momo',
            'note'                      => 'nullable|string',
        ]);

        $user = $request->user();

        return DB::transaction(function () use ($validated, $user) {

            $vnpay = app(VNPayService::class);

            // 1. Kiểm tra tồn kho
            $totalAmount = 0;
            $itemsSummary = [];

            foreach ($validated['items'] as $item) {
                $product = Product::lockForUpdate()->findOrFail($item['product_id']);
                $needed  = $item['quantity'];

                if ($product->stock_quantity < $needed) {
                    throw new \Exception("Sản phẩm \"{$product->name}\" không đủ hàng");
                }

                $totalAmount += $product->price_listed * $needed;

                $itemsSummary[] = [
                    'product_id' => $product->id,
                    'quantity'   => $needed,
                    'price'      => $product->price_listed,
                ];
            }

            // 2. Tính tiền + tạo order
            $shippingFee  = $totalAmount >= 299000 ? 0 : 25000;
            $finalAmount  = $totalAmount + $shippingFee;

            $address = UserAddress::create([
                'user_id'      => $user->id,
                'full_name'    => $validated['address']['full_name'],
                'phone'        => $validated['address']['phone'],
                'address_line' => $validated['address']['address_line'],
                'ward'         => $validated['address']['ward'],
                'district'     => $validated['address']['district'],
                'city'         => $validated['address']['city'],
            ]);

            $order = Order::create([
                'user_id'        => $user->id,
                'address_id'     => $address->id,
                'order_code'     => 'ORD-' . strtoupper(Str::random(10)),
                'total_amount'   => $totalAmount,
                'shipping_fee'   => $shippingFee,
                'final_amount'   => $finalAmount,
                'order_status'   => 'pending',
                'payment_status' => 'unpaid',
                'payment_method' => $validated['payment_method'],
                'note'           => $validated['note'] ?? null,
            ]);

            // 3. FEFO
            foreach ($itemsSummary as $sum) {
                DB::statement('CALL sp_allocate_order_fefo(?, ?, ?, ?)', [
                    $order->id,
                    $sum['product_id'],
                    $sum['quantity'],
                    $sum['price']
                ]);
            }

            // 4. Payment (chỉ 1 lần)
            Payment::create([
                'order_id'       => $order->id,
                'amount'         => $finalAmount,
                'payment_method' => $validated['payment_method'],
                'status'         => 'pending',
            ]);

            // 5. Payment URL
            $paymentUrl = null;

            if ($validated['payment_method'] === 'vnpay') {
                $paymentUrl = $vnpay->createPaymentUrl($order);
            }

            // 6. Response
            return response()->json([
                'order_id'     => $order->id,
                'order_code'   => $order->order_code,
                'final_amount' => $order->final_amount,
                'payment_method' => $order->payment_method,
                'payment_url'  => $paymentUrl,
                'message'      => $paymentUrl
                    ? 'Tạo đơn thành công, chuyển hướng thanh toán'
                    : 'Đặt hàng thành công'
            ], 201);
        });
    }

    public function updateStatus(Request $request, int $id)
    {
        $validated = $request->validate([
            'order_status'   => 'required|in:pending,confirmed,packing,shipping,delivered,cancelled',
            'payment_status' => 'nullable|in:unpaid,paid',
        ]);

        $order = Order::findOrFail($id);
        $order->update($validated);

        return response()->json($order);
    }

    public function adminIndex(Request $request)
    {
        $query = Order::with(['user', 'address', 'items.product'])->latest();

        if ($status = $request->get('status')) {
            $query->where('order_status', $status);
        }

        return response()->json($query->paginate(20));
    }
}
