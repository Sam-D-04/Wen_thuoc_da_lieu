<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;
use App\Models\Batch;

class ProductController extends Controller
{
    // ─── GET /api/products ───────────────────────────────
    public function index(Request $request)
    {
        // Mặc định chỉ hiển thị sản phẩm còn hàng (có lô tồn) cho client công khai.
        // Nếu request được thực hiện bởi admin/warehouse (đã xác thực), hiển thị tất cả sản
        // phẩm (để admin có thể thêm/sửa sản phẩm ngay cả khi chưa có lô).
        $query = Product::with(['category', 'brand'])
            ->withSum([
                'batches as batch_remaining_quantity' => function ($q) {
                    $q->where('remaining_quantity', '>', 0)
                      ->whereDate('expiry_date', '>=', now()->toDateString());
                }
            ], 'remaining_quantity')
            ->active();

        $onlyAvailable = true;
        if ($request->user()) {
            // User model có các helper isAdmin/isWarehouse
            if (method_exists($request->user(), 'isAdmin') && $request->user()->isAdmin()) {
                $onlyAvailable = false;
            }
            if (method_exists($request->user(), 'isWarehouse') && $request->user()->isWarehouse()) {
                $onlyAvailable = false;
            }
        }

        if ($onlyAvailable) {
            $query->whereHas('batches', function ($q) {
                $q->where('remaining_quantity', '>', 0)
                  ->whereDate('expiry_date', '>=', now()->toDateString());
            });
        }

        if ($s = $request->input('search')) {
            $query->where(function ($q) use ($s) {
                $q->where('name', 'like', "%{$s}%")
                  ->orWhereHas('brand', fn($b) => $b->where('name', 'like', "%{$s}%"));
            });
        }

        if ($slug = $request->input('category')) {
            $query->whereHas('category', fn($q) => $q->where('slug', $slug));
        }

        if ($catId = $request->input('category_id')) {
            $query->where('category_id', $catId);
        }

        if ($brandId = $request->input('brand_id')) {
            $query->where('brand_id', $brandId);
        }

        if ($min = $request->input('min_price')) {
            $query->where('price_listed', '>=', $min);
        }
        if ($max = $request->input('max_price')) {
            $query->where('price_listed', '<=', $max);
        }

        match ($request->input('sort', 'latest')) {
            'price_asc'  => $query->orderBy('price_listed', 'asc'),
            'price_desc' => $query->orderBy('price_listed', 'desc'),
            'popular'    => $query->orderBy('sold_count', 'desc'),
            default      => $query->latest(),
        };

        $perPage = min((int) $request->input('per_page', 12), 50);

        return response()->json($query->paginate($perPage));
    }

    // ─── GET /api/products/{slug} ────────────────────────
    public function show(string $slug)
    {
        $product = Product::with(['category', 'brand', 'batches' => fn($q) => $q->available()])
            ->where('slug', $slug)
            ->active()
            ->firstOrFail();

        return response()->json($product);
    }

    // ─── POST /api/products (admin) ──────────────────────
    public function store(Request $request)
    {
        $validated = $request->validate([
            'category_id'   => 'required|exists:categories,id',
            'brand_id'      => 'nullable|exists:brands,id',
            'name'          => 'required|string|max:200',
            'description'   => 'nullable|string',
            'price_listed'  => 'required|numeric|min:0',
            'dosage_form'   => 'required|string|max:50',
            'volume'        => 'required|string|max:20',
            'stock_warning' => 'nullable|integer|min:0',
            'is_active'     => 'boolean',
            'stock_quantity' => 'nullable|integer|min:0',
            'image'         => 'nullable|image|max:2048',
        ]);

        $validated['slug'] = Str::slug($validated['name']) . '-' . Str::random(6);
        $validated['created_by'] = $request->user()->id;

        if ($request->hasFile('image')) {
            $validated['image'] = $request->file('image')->store('products', 'public');
        }

        $product = Product::create($validated);

        // Nếu client cung cấp stock_quantity > 0 khi tạo sản phẩm, tạo một lô hàng tương ứng
        if (!empty($validated['stock_quantity']) && intval($validated['stock_quantity']) > 0) {
            $quantity = intval($validated['stock_quantity']);
            Batch::create([
                'product_id' => $product->id,
                'batch_code' => Str::upper(Str::random(8)),
                'expiry_date' => now()->addYear()->toDateString(),
                'quantity' => $quantity,
                'remaining_quantity' => $quantity,
                'created_by' => $request->user()->id,
            ]);
        }

        return response()->json($product->load(['category', 'brand']), 201);
    }

    // ─── PUT /api/products/{id} (admin) ─────────────────
    public function update(Request $request, int $id)
    {
        $product = Product::findOrFail($id);

        $validated = $request->validate([
            'category_id'   => 'sometimes|exists:categories,id',
            'brand_id'      => 'nullable|exists:brands,id',
            'name'          => 'sometimes|string|max:200',
            'description'   => 'nullable|string',
            'price_listed'  => 'sometimes|numeric|min:0',
            'dosage_form'   => 'sometimes|string|max:50',
            'volume'        => 'sometimes|string|max:20',
            'stock_warning' => 'nullable|integer|min:0',
            'is_active'     => 'boolean',
            'stock_quantity' => 'nullable|integer|min:0',
            'image'         => 'nullable|image|max:2048',
        ]);

        if (isset($validated['name'])) {
            $validated['slug'] = Str::slug($validated['name']) . '-' . Str::random(6);
        }
        $validated['updated_by'] = $request->user()->id;

        if ($request->hasFile('image')) {
            if ($product->image && !str_starts_with($product->image, 'data:') && Storage::disk('public')->exists($product->image)) {
                Storage::disk('public')->delete($product->image);
            }
            $validated['image'] = $request->file('image')->store('products', 'public');
        }

        $prevQty = $product->stock_quantity ?? 0;
        $product->update($validated);

        // Nếu client cập nhật stock_quantity tăng lên, tạo một lô mới tương ứng với phần tăng
        if (isset($validated['stock_quantity'])) {
            $newQty = intval($validated['stock_quantity']);
            if ($newQty > $prevQty) {
                $added = $newQty - $prevQty;
                Batch::create([
                    'product_id' => $product->id,
                    'batch_code' => Str::upper(Str::random(8)),
                    'expiry_date' => now()->addYear()->toDateString(),
                    'quantity' => $added,
                    'remaining_quantity' => $added,
                    'created_by' => $request->user()->id,
                ]);
            }
        }

        return response()->json($product->load(['category', 'brand']));
    }

    // ─── DELETE /api/products/{id} (admin) ──────────────
    public function destroy(int $id)
    {
        Product::findOrFail($id)->delete();

        return response()->json(['message' => 'Đã xóa sản phẩm']);
    }

}
