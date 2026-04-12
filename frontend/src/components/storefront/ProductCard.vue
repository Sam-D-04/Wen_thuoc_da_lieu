<template>
  <div
    @mouseenter="$emit('hover', product.id)"
    @mouseleave="$emit('hover', null)"
    class="group bg-white rounded-2xl border border-gray-100 overflow-hidden hover:shadow-lg hover:shadow-blue-100/60 hover:-translate-y-0.5 transition-all duration-300 cursor-pointer w-full max-w-xs sm:max-w-sm md:max-w-full"
  >
    <!-- Image -->
    <div class="relative aspect-square bg-gradient-to-br from-blue-50 to-cyan-50 overflow-hidden max-w-full mx-auto" @click="$emit('view', product)">
      <img v-if="product.image" :src="product.image" :alt="product.name" class="w-full h-full object-contain p-2 sm:p-3" />
      <div v-else class="w-full h-full flex flex-col items-center justify-center gap-2 p-2 sm:p-4">
        <div class="w-12 h-12 sm:w-16 sm:h-16 bg-white/70 rounded-xl flex items-center justify-center shadow-sm">
          <svg class="w-8 h-8 text-blue-300" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <rect x="3" y="3" width="18" height="18" rx="2"/>
            <path d="M3 9h18M9 21V9"/>
          </svg>
        </div>
        <span class="text-xs text-blue-300 font-medium text-center">{{ product.dosage_form }}</span>
      </div>

      <!-- Stock warning -->
      <div v-if="product.stock_quantity > 0 && product.stock_quantity <= 10"
        class="absolute top-2 left-2 bg-warning text-white text-[10px] font-bold px-2 py-0.5 rounded-full">
        Sắp hết
      </div>
      <div v-if="product.stock_quantity === 0"
        class="absolute inset-0 bg-black/40 flex items-center justify-center">
        <span class="bg-white text-gray-700 text-xs font-bold px-3 py-1 rounded-full">Hết hàng</span>
      </div>

      <!-- Quick add button (appears on hover) -->
      <button
        v-if="product.stock_quantity > 0"
        @click.stop="$emit('add-to-cart', product)"
        class="absolute bottom-2 right-2 w-8 h-8 bg-primary text-white rounded-xl flex items-center justify-center shadow-md opacity-0 group-hover:opacity-100 translate-y-2 group-hover:translate-y-0 transition-all duration-200 hover:bg-blue-700"
      >
        <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
          <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
        </svg>
      </button>
    </div>

    <!-- Info -->
    <div class="p-2 sm:p-3" @click="$emit('view', product)">
      <p class="text-xs text-gray-400 font-medium mb-0.5">{{ product.brand }}</p>
      <h3 class="text-sm font-semibold text-gray-800 line-clamp-2 leading-snug mb-1 min-h-[2.5rem]">{{ product.name }}</h3>
      <p class="text-xs text-gray-400 mb-2">{{ product.dosage_form }} · {{ product.volume }}</p>

      <div class="flex items-center justify-between">
        <span class="text-base font-bold text-primary">{{ formatPrice(product.price_listed) }}</span>
        <span v-if="product.stock_quantity <= 0" class="text-xs text-gray-400">Hết hàng</span>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({ product: { type: Object, required: true } })
defineEmits(['add-to-cart', 'view', 'hover'])

const formatPrice = (price) => new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price)
</script>
