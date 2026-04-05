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

class OrderController extends Controller
{
    // GET /api/orders  (user: own orders)
    public function index(Request $request)
    {
        $orders = Order::with(['items.product', 'address'])
            ->where('user_id', $request->user()->id)
            ->latest()
            ->paginate(10);

        return response()->json($orders);
    }

    // GET /api/orders/{id}
    public function show(Request $request, int $id)
    {
        $order = Order::with(['items.product', 'items.batch', 'address', 'payment'])
            ->where('user_id', $request->user()->id)
            ->findOrFail($id);

        return response()->json($order);
    }

    // POST /api/orders  (Place order — FEFO batch assignment)
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
            // 1. Kiểm tra tồn kho và tính tổng tiền trước
            $totalAmount = 0;
            $itemsSummary = [];

            foreach ($validated['items'] as $item) {
                $product = Product::lockForUpdate()->findOrFail($item['product_id']);
                $needed  = $item['quantity'];

                if ($product->stock_quantity < $needed) {
                    throw new \Exception("Sản phẩm \"{$product->name}\" không đủ hàng (Kho chỉ còn {$product->stock_quantity}).");
                }

                $totalAmount += $product->price_listed * $needed;
                
                $itemsSummary[] = [
                    'product_id' => $product->id,
                    'quantity'   => $needed,
                    'price'      => $product->price_listed,
                ];
            }

            // 2. Tính phí ship và tạo Order (Tạo rỗng để lấy order_id trước)
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

            // 3. Gọi MySQL Procedure để nó tự động chèn record vào `order_items` và trừ kho batches (Triggers sẽ tự lo `products`)
            foreach ($itemsSummary as $sum) {
                DB::statement('CALL sp_allocate_order_fefo(?, ?, ?, ?)', [
                    $order->id,
                    $sum['product_id'],
                    $sum['quantity'],
                    $sum['price']
                ]);
            }

            // 4. Tạo record thanh toán
            Payment::create([
                'order_id'       => $order->id,
                'amount'         => $finalAmount,
                'payment_method' => $validated['payment_method'],
                'status'         => 'pending',
            ]);

            return response()->json($order->load(['items.product', 'address']), 201);
        });
    }

    // PUT /api/orders/{id}/status (admin)
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

    // GET /api/admin/orders (admin)
    public function adminIndex(Request $request)
    {
        $query = Order::with(['user', 'address', 'items.product'])->latest();

        if ($status = $request->get('status')) {
            $query->where('order_status', $status);
        }

        return response()->json($query->paginate(20));
    }
}
