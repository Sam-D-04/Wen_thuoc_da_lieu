<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class Product extends Model
{
    protected $fillable = [
        'category_id', 'brand_id', 'name', 'slug', 'image',
        'description', 'price_listed', 'dosage_form', 'volume',
        'stock_quantity', 'stock_warning', 'is_active', 'sold_count',
        'created_by', 'updated_by',
    ];

    protected $casts = [
        'price_listed'   => 'float',
        'stock_quantity' => 'integer',
        'stock_warning'  => 'integer',
        'sold_count'     => 'integer',
        'is_active'      => 'boolean',
    ];

    protected $appends = ['image_url', 'is_low_stock'];

    // ─── Relations ─────────────────────────────────────
    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function brand()
    {
        return $this->belongsTo(Brand::class);
    }

    public function batches()
    {
        return $this->hasMany(Batch::class)->orderBy('expiry_date');
    }

    public function activeBatches()
    {
        return $this->hasMany(Batch::class)
            ->where('remaining_quantity', '>', 0)
            ->orderBy('expiry_date'); // FEFO
    }

    public function orderItems()
    {
        return $this->hasMany(OrderItem::class);
    }

    public function tags()
    {
        return $this->belongsToMany(Tag::class, 'product_tag');
    }

    public function warehouseAlerts()
    {
        return $this->hasMany(WarehouseAlert::class);
    }

    // ─── Accessors ──────────────────────────────────────
    public function getImageUrlAttribute(): ?string
    {
        if (!$this->image) return null;
        if (str_starts_with($this->image, 'http')) return $this->image;

        // Legacy: relative path stored before R2 migration
        $url = Storage::disk('public')->url($this->image);
        if (str_starts_with($url, 'http')) {
            return $url;
        }
        $origin = request()?->getSchemeAndHttpHost() ?: rtrim(config('app.url'), '/');
        return rtrim($origin, '/') . '/' . ltrim($url, '/');
    }

    public function getIsLowStockAttribute(): bool
    {
        return $this->stock_quantity <= $this->stock_warning;
    }

    // ─── Scopes ─────────────────────────────────────────
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeLowStock($query)
    {
        return $query->whereColumn('stock_quantity', '<=', 'stock_warning');
    }
}
