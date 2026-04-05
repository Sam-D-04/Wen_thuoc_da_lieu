<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\WarehouseAlert;
use App\Models\Product;
use App\Models\Batch;
use App\Models\InventoryTransaction;
use Illuminate\Http\Request;
use Carbon\Carbon;

class WarehouseController extends Controller
{
    // GET /api/warehouse/alerts
    public function alerts(Request $request)
    {
        $query = WarehouseAlert::with('product')->unresolved()->latest();

        if ($type = $request->get('type')) {
            $query->where('alert_type', $type);
        }

        return response()->json($query->paginate(20));
    }

    // POST /api/warehouse/alerts/{id}/resolve
    public function resolveAlert(Request $request, int $id)
    {
        $alert = WarehouseAlert::findOrFail($id);
        $alert->update([
            'is_resolved' => true,
            'resolved_by' => $request->user()->id,
            'resolved_at' => now(),
        ]);
        return response()->json($alert);
    }

    // POST /api/warehouse/check-alerts — auto-generate alerts
    public function checkAndGenerateAlerts()
    {
        $generated = 0;

        // Low stock alerts
        $lowStockProducts = Product::active()->lowStock()->get();
        foreach ($lowStockProducts as $product) {
            WarehouseAlert::firstOrCreate(
                ['product_id' => $product->id, 'alert_type' => 'low_stock', 'is_resolved' => false],
                ['message' => "Sản phẩm \"{$product->name}\" sắp hết hàng (còn {$product->stock_quantity})"]
            );
            $generated++;
        }

        // Expiring soon alerts (within 90 days)
        $expiringBatches = Batch::with('product')
            ->expiringSoon(90)
            ->available()
            ->get();
        foreach ($expiringBatches as $batch) {
            WarehouseAlert::firstOrCreate(
                ['product_id' => $batch->product_id, 'alert_type' => 'expiring_soon', 'is_resolved' => false],
                ['message' => "Lô {$batch->batch_code} sản phẩm \"{$batch->product->name}\" hết hạn vào {$batch->expiry_date->format('d/m/Y')}"]
            );
            $generated++;
        }

        // Expired alerts
        $expiredBatches = Batch::with('product')->expired()->available()->get();
        foreach ($expiredBatches as $batch) {
            WarehouseAlert::firstOrCreate(
                ['product_id' => $batch->product_id, 'alert_type' => 'expired', 'is_resolved' => false],
                ['message' => "Lô {$batch->batch_code} sản phẩm \"{$batch->product->name}\" đã HẾT HẠN"]
            );
            $generated++;
        }

        return response()->json(['message' => "Đã tạo {$generated} cảnh báo"]);
    }

    // GET /api/warehouse/inventory — tồn kho tổng hợp
    public function inventory(Request $request)
    {
        $query = Product::with(['category', 'brand', 'batches' => fn($q) => $q->available()])
            ->active();

        if ($s = $request->get('search')) {
            $query->where('name', 'like', "%{$s}%");
        }

        return response()->json($query->paginate(20));
    }

    // GET /api/warehouse/inventory-transactions — lịch sử nhập/xuất kho
    public function inventoryTransactions(Request $request)
    {
        $validated = $request->validate([
            'search' => 'nullable|string|max:255',
            'type' => 'nullable|in:import,export,adjustment',
            'from_date' => 'nullable|date',
            'to_date' => 'nullable|date',
            'per_page' => 'nullable|integer|min:1|max:100',
        ]);

        $query = InventoryTransaction::with([
            'product:id,name',
            'batch:id,batch_code,expiry_date',
            'createdBy:id,name',
        ])->latest('created_at');

        if (!empty($validated['type'])) {
            $query->where('type', $validated['type']);
        }

        if (!empty($validated['from_date'])) {
            $query->whereDate('created_at', '>=', Carbon::parse($validated['from_date'])->toDateString());
        }

        if (!empty($validated['to_date'])) {
            $query->whereDate('created_at', '<=', Carbon::parse($validated['to_date'])->toDateString());
        }

        if (!empty($validated['search'])) {
            $search = trim((string) $validated['search']);
            $query->where(function ($q) use ($search) {
                $q->where('note', 'like', "%{$search}%")
                    ->orWhere('reference_id', 'like', "%{$search}%")
                    ->orWhereHas('product', function ($p) use ($search) {
                        $p->where('name', 'like', "%{$search}%");
                    })
                    ->orWhereHas('batch', function ($b) use ($search) {
                        $b->where('batch_code', 'like', "%{$search}%");
                    });
            });
        }

        $perPage = (int) ($validated['per_page'] ?? 20);

        return response()->json($query->paginate($perPage));
    }
}
