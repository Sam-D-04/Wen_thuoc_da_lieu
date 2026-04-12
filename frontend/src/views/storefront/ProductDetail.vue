<template>
  <div class="max-w-7xl mx-auto px-2 sm:px-4 py-4 sm:py-8">
    <!-- Loading state -->
    <div v-if="!product" class="flex items-center justify-center py-20">
      <div class="text-center">
        <svg class="animate-spin w-10 h-10 text-primary mx-auto mb-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
        </svg>
        <p class="text-gray-500">Đang tải sản phẩm...</p>
      </div>
    </div>

    <!-- Not found -->
    <div v-else-if="notFound" class="flex flex-col items-center justify-center py-20 text-center">
      <div class="text-6xl mb-4">🔍</div>
      <h2 class="text-xl font-bold text-gray-700 mb-2">Không tìm thấy sản phẩm</h2>
      <p class="text-gray-400 mb-6">Sản phẩm bạn tìm kiếm không tồn tại hoặc đã bị xoá.</p>
      <router-link to="/shop" class="bg-primary text-white px-5 py-2.5 rounded-xl text-sm font-medium hover:bg-blue-700 transition-colors">
        Quay lại mua sắm
      </router-link>
    </div>

    <!-- Product Detail -->
    <div v-else>
      <!-- Breadcrumb -->
      <nav class="flex items-center gap-2 text-sm text-gray-400 mb-6">
        <router-link to="/shop" class="hover:text-primary transition-colors">Trang chủ</router-link>
        <svg class="w-3 h-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m9 18 6-6-6-6"/></svg>
        <span>{{ product.name }}</span>
      </nav>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 md:gap-10">
        <!-- Image -->
        <div>
          <div class="aspect-square bg-gradient-to-br from-blue-50 to-cyan-50 rounded-2xl border border-gray-100 flex items-center justify-center overflow-hidden max-w-xs mx-auto md:max-w-full">
            <img v-if="product.image" :src="product.image" :alt="product.name" class="w-full h-full object-contain p-4 sm:p-8" />
            <div v-else class="flex flex-col items-center justify-center gap-3 p-4 sm:p-8">
              <div class="w-20 h-20 sm:w-24 sm:h-24 bg-white rounded-2xl flex items-center justify-center shadow-sm">
                <svg class="w-12 h-12 text-blue-300" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                  <rect x="3" y="3" width="18" height="18" rx="2"/>
                  <path d="M3 9h18M9 21V9"/>
                </svg>
              </div>
              <p class="text-sm text-blue-300 font-medium">{{ product.dosage_form }}</p>
            </div>
          </div>
        </div>

        <!-- Info -->
        <div class="flex flex-col gap-4 sm:gap-5">
          <div>
            <p class="text-sm text-primary font-semibold mb-1">{{ product.brand }}</p>
            <h1 class="text-2xl font-bold text-gray-800 leading-snug">{{ product.name }}</h1>
            <div class="flex flex-wrap items-center gap-2 mt-2 text-sm text-gray-500">
              <span class="bg-gray-100 px-2 py-0.5 rounded text-xs">{{ product.dosage_form }}</span>
              <span class="bg-gray-100 px-2 py-0.5 rounded text-xs">{{ product.volume }}</span>
              <span v-if="product.stock_quantity > 0" class="text-green-600 font-medium flex items-center gap-1">
                <svg class="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                Còn hàng ({{ product.stock_quantity }})
              </span>
              <span v-else class="text-red-500 font-medium">Hết hàng</span>
            </div>
          </div>

          <!-- Price -->
          <div class="flex items-baseline gap-3">
            <span class="text-3xl font-bold text-primary">{{ formatPrice(product.price_listed) }}</span>
            <span class="text-sm text-gray-400">/ {{ product.dosage_form }}</span>
          </div>

          <!-- Highlights -->
          <div class="bg-blue-50 rounded-xl p-4 space-y-2">
            <div class="flex items-center gap-2 text-sm text-gray-700">
              <svg class="w-4 h-4 text-green-500 flex-shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
              <span>Sản phẩm chính hãng, có hóa đơn</span>
            </div>
            <div class="flex items-center gap-2 text-sm text-gray-700">
              <svg class="w-4 h-4 text-green-500 flex-shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
              <span>Miễn phí vận chuyển đơn từ 299.000đ</span>
            </div>
            <div class="flex items-center gap-2 text-sm text-gray-700">
              <svg class="w-4 h-4 text-green-500 flex-shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
              <span>Đổi trả trong vòng 7 ngày</span>
            </div>
          </div>

          <!-- Quantity -->
          <div class="flex flex-wrap items-center gap-2 sm:gap-4">
            <span class="text-sm font-medium text-gray-700">Số lượng:</span>
            <div class="flex items-center gap-0 border border-gray-200 rounded-xl overflow-hidden">
              <button
                @click="quantity = Math.max(1, quantity - 1)"
                class="w-10 h-10 flex items-center justify-center hover:bg-gray-50 transition-colors text-gray-600"
              >
                <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="5" y1="12" x2="19" y2="12"/></svg>
              </button>
              <span class="w-12 text-center text-sm font-bold text-gray-800">{{ quantity }}</span>
              <button
                @click="quantity = Math.min(product.stock_quantity, quantity + 1)"
                class="w-10 h-10 flex items-center justify-center hover:bg-gray-50 transition-colors text-gray-600"
              >
                <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
              </button>
            </div>
          </div>

          <!-- Actions -->
          <div class="flex flex-col sm:flex-row gap-2 sm:gap-3">
            <button
              @click="handleAddToCart"
              :disabled="product.stock_quantity === 0"
              class="flex-1 border-2 border-primary text-primary font-semibold py-3 rounded-xl hover:bg-primary hover:text-white transition-all duration-200 disabled:opacity-40 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"/>
                <line x1="3" y1="6" x2="21" y2="6"/>
                <path d="M16 10a4 4 0 0 1-8 0"/>
              </svg>
              Thêm vào giỏ
            </button>
            <button
              @click="handleBuyNow"
              :disabled="product.stock_quantity === 0"
              class="flex-1 bg-primary text-white font-semibold py-3 rounded-xl hover:bg-blue-700 transition-all duration-200 shadow-md shadow-blue-200 hover:shadow-lg disabled:opacity-40 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M5 12h14M12 5l7 7-7 7"/>
              </svg>
              Mua ngay
            </button>
          </div>
        </div>
      </div>

      <!-- Description tabs -->
      <div class="mt-8 sm:mt-12">
        <div class="flex flex-wrap gap-0 border-b border-gray-200 mb-4 sm:mb-6">
          <button
            v-for="tab in tabs"
            :key="tab.key"
            @click="activeTab = tab.key"
            :class="[
              'px-5 py-3 text-sm font-medium transition-colors border-b-2 -mb-px',
              activeTab === tab.key
                ? 'text-primary border-primary'
                : 'text-gray-500 border-transparent hover:text-gray-700'
            ]"
          >
            {{ tab.label }}
          </button>
        </div>
        <div class="prose prose-sm max-w-none text-gray-600 leading-relaxed break-words">
          <div v-if="activeTab === 'description'">
            <p>{{ product.description }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useProductStore } from '@/stores/shopProducts'
import { useCartStore } from '@/stores/cart'

const route = useRoute()
const router = useRouter()
const productStore = useProductStore()
const cartStore = useCartStore()

const quantity = ref(1)
const activeTab = ref('description')
const notFound = ref(false)

const tabs = [
  { key: 'description', label: 'Mô tả sản phẩm' },
]

const product = computed(() => {
  const p = productStore.getProductBySlug(route.params.slug)
  if (!p) {
    notFound.value = true
    return null
  }
  return p
})

watch(() => route.params.slug, () => { quantity.value = 1; notFound.value = false })

const formatPrice = (price) => new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price)

const handleAddToCart = () => {
  cartStore.addItem(product.value, quantity.value)
  cartStore.openDrawer()
}

const handleBuyNow = () => {
  cartStore.addItem(product.value, quantity.value)
  router.push('/checkout')
}

onMounted(async () => {
  if (!productStore.products.length) {
    await productStore.fetchProducts()
  }
})
</script>
