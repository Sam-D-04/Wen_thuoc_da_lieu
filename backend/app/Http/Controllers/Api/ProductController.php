<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class ProductController extends Controller
{
    // ─── GET /api/products ───────────────────────────────
    public function index(Request $request)
    {
        $query = Product::with(['category', 'brand'])
            ->withSum([
                'batches as batch_remaining_quantity' => function ($q) {
                    $q->where('remaining_quantity', '>', 0)
                      ->whereDate('expiry_date', '>=', now()->toDateString());
                }
            ], 'remaining_quantity')
            ->active()
            ->whereHas('batches', function ($q) {
                $q->where('remaining_quantity', '>', 0)
                  ->whereDate('expiry_date', '>=', now()->toDateString());
            });

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

    // ─── GET /api/admin/products (admin only) ───────────
    public function adminIndex(Request $request)
    {
        $query = Product::with(['category', 'brand'])
            ->withSum('batches as stock_quantity', 'remaining_quantity');

        if ($s = $request->input('search')) {
            $query->where(function ($q) use ($s) {
                $q->where('name', 'like', "%{$s}%")
                  ->orWhereHas('brand', fn($b) => $b->where('name', 'like', "%{$s}%"));
            });
        }

        if ($catId = $request->input('category_id')) {
            $query->where('category_id', $catId);
        }

        if ($brandId = $request->input('brand_id')) {
            $query->where('brand_id', $brandId);
        }

        match ($request->input('sort', 'latest')) {
            'price_asc'  => $query->orderBy('price_listed', 'asc'),
            'price_desc' => $query->orderBy('price_listed', 'desc'),
            default      => $query->latest(),
        };

        $perPage = min((int) $request->input('per_page', 20), 100);

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
            'image'         => 'nullable|image|max:2048',
        ]);

        $validated['slug'] = Str::slug($validated['name']) . '-' . Str::random(6);
        $validated['created_by'] = $request->user()->id;

        if ($request->hasFile('image')) {
            $validated['image'] = $this->toBase64($request->file('image'));
        }

        $product = Product::create($validated);

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
            'image'         => 'nullable|image|max:2048',
        ]);

        if (isset($validated['name'])) {
            $validated['slug'] = Str::slug($validated['name']) . '-' . Str::random(6);
        }
        $validated['updated_by'] = $request->user()->id;

        if ($request->hasFile('image')) {
            $validated['image'] = $this->toBase64($request->file('image'));
        }

        $product->update($validated);

        return response()->json($product->load(['category', 'brand']));
    }

    // ─── DELETE /api/products/{id} (admin) ──────────────
    public function destroy(int $id)
    {
        Product::findOrFail($id)->delete();

        return response()->json(['message' => 'Đã xóa sản phẩm']);
    }

    // ─── Helper ─────────────────────────────────────────
    private function toBase64(\Illuminate\Http\UploadedFile $file): string
    {
        $mime = $file->getMimeType();
        $data = base64_encode(file_get_contents($file->getRealPath()));
        return "data:{$mime};base64,{$data}";
    }
}
