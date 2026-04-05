<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
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
            ->active();

        // Search by name or brand name
        if ($s = $request->get('search')) {
            $query->where(function ($q) use ($s) {
                $q->where('name', 'like', "%{$s}%")
                  ->orWhereHas('brand', fn($b) => $b->where('name', 'like', "%{$s}%"));
            });
        }

        // Filter by category slug
        if ($slug = $request->get('category')) {
            $query->whereHas('category', fn($q) => $q->where('slug', $slug));
        }

        // Filter by category_id
        if ($catId = $request->get('category_id')) {
            $query->where('category_id', $catId);
        }

        // Filter by brand_id
        if ($brandId = $request->get('brand_id')) {
            $query->where('brand_id', $brandId);
        }

        // Price range
        if ($min = $request->get('min_price')) {
            $query->where('price_listed', '>=', $min);
        }
        if ($max = $request->get('max_price')) {
            $query->where('price_listed', '<=', $max);
        }

        // Sort
        match ($request->get('sort', 'latest')) {
            'price_asc'  => $query->orderBy('price_listed', 'asc'),
            'price_desc' => $query->orderBy('price_listed', 'desc'),
            'popular'    => $query->orderBy('sold_count', 'desc'),
            default      => $query->latest(),
        };

        $perPage = min((int) $request->get('per_page', 12), 50);

        return response()->json($query->paginate($perPage));
    }

    // ─── GET /api/products/{slug} ────────────────────────
    public function show(Request $request, string $slug)
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
            $validated['image'] = $request->file('image')->store('products', 'public');
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
            if ($product->image && Storage::disk('public')->exists($product->image)) {
                Storage::disk('public')->delete($product->image);
            }
            $validated['image'] = $request->file('image')->store('products', 'public');
        }

        $product->update($validated);

        return response()->json($product->load(['category', 'brand']));
    }

    // ─── DELETE /api/products/{id} (admin) ──────────────
    public function destroy(int $id)
    {
        $product = Product::findOrFail($id);

        if ($product->image && Storage::disk('public')->exists($product->image)) {
            Storage::disk('public')->delete($product->image);
        }

        $product->delete();

        return response()->json(['message' => 'Đã xóa sản phẩm']);
    }
}
