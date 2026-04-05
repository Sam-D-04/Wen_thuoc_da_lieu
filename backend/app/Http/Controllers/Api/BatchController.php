<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Batch;
use App\Models\Product;
use App\Models\InventoryTransaction;
use App\Models\WarehouseAlert;
use Illuminate\Http\Request;

class BatchController extends Controller
{
    // GET /api/batches?product_id=x
    public function index(Request $request)
    {
        $query = Batch::with('product')->latest();

        if ($productId = $request->get('product_id')) {
            $query->where('product_id', $productId);
        }
        if ($request->get('expiring_soon')) {
            $query->expiringSoon(90);
        }
        if ($request->get('expired')) {
            $query->expired();
        }

        return response()->json($query->paginate(20));
    }

    // POST /api/batches (admin/warehouse — nhập kho)
    public function store(Request $request)
    {
        $validated = $request->validate([
            'product_id'  => 'required|exists:products,id',
            'batch_code'  => 'required|string|max:50|unique:batches,batch_code',
            'expiry_date' => 'required|date|after:today',
            'quantity'    => 'required|integer|min:1',
        ]);

        $validated['remaining_quantity'] = $validated['quantity'];
        $validated['created_by']         = $request->user()->id;

        $batch = Batch::create($validated);

        // Update product stock (Đã được xử lý ngầm trong MySQL bằng AFTER_BATCH_INSERT Trigger)

        // Log inventory transaction
        InventoryTransaction::create([
            'product_id'  => $validated['product_id'],
            'batch_id'    => $batch->id,
            'type'        => 'import',
            'quantity'    => $validated['quantity'],
            'created_by'  => $request->user()->id,
            'note'        => 'Nhập kho — lô ' . $validated['batch_code'],
        ]);

        return response()->json($batch->load('product'), 201);
    }

    // GET /api/batches/{id}
    public function show(int $id)
    {
        return response()->json(Batch::with('product')->findOrFail($id));
    }

    // PUT /api/batches/{id}
    public function update(Request $request, int $id)
    {
        $batch = Batch::findOrFail($id);

        $validated = $request->validate([
            'expiry_date'       => 'sometimes|date|after:today',
            'remaining_quantity'=> "sometimes|integer|min:0|max:{$batch->quantity}",
        ]);

        $batch->update($validated);

        return response()->json($batch->load('product'));
    }
}
