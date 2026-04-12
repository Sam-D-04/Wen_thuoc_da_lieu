<template>
  <div class="min-h-screen bg-gray-50 flex flex-col prevent-overflow">
    <!-- Top bar -->
    <div class="bg-primary text-white text-xs py-1.5">
      <div class="max-w-7xl mx-auto px-2 sm:px-4 flex flex-col sm:flex-row items-center justify-between gap-1 sm:gap-0 text-center sm:text-left">
        <div class="flex flex-wrap items-center justify-center gap-2 sm:gap-4 w-full sm:w-auto">
          <div class="flex items-center gap-1.5 min-w-[110px] justify-center">
            <svg class="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.49 12 19.79 19.79 0 0 1 1.39 3.39 2 2 0 0 1 3.37 1h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 8.37a16 16 0 0 0 5.72 5.72l1.06-1.06a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z"/>
            </svg>
            <span>1800 599 971</span>
          </div>
          <span class="hidden sm:inline text-blue-200">|</span>
          <span class="block sm:inline">Giao hàng toàn quốc · Miễn phí từ 299k</span>
        </div>
        <div class="flex items-center gap-2 justify-center w-full sm:w-auto mt-1 sm:mt-0">
          <template v-if="authStore.isLoggedIn">
            <span class="text-blue-200">Xin chào, <strong class="text-white">{{ authStore.userName }}</strong></span>
            <span class="text-blue-200">|</span>
            <button @click="authStore.logout(); router.push('/shop')" class="hover:text-blue-200 transition-colors">Đăng xuất</button>
          </template>
        </div>
      </div>
    </div>

    <!-- Main header -->
    <header class="bg-white shadow-sm sticky top-0 z-40">
      <div class="max-w-7xl mx-auto px-1.5 sm:px-4 py-1.5 sm:py-3 w-full">
        <div class="flex flex-row items-center justify-between w-full gap-2">
          <!-- Logo -->
          <router-link to="/shop" class="flex flex-col xs:flex-row items-center gap-0.5 xs:gap-2 flex-shrink-0 max-w-[180px] mb-2 sm:mb-0 order-1">
            <div class="w-7 h-7 sm:w-9 sm:h-9 rounded-xl bg-gradient-to-br from-primary to-cyan-500 flex items-center justify-center shadow-md shadow-blue-200 flex-shrink-0 mx-auto xs:mx-0">
              <span class="text-white font-black text-[15px] sm:text-base tracking-tighter leading-none">Dc</span>
            </div>
            <div class="leading-none text-center xs:text-left w-full truncate">
              <div class="text-[15px] sm:text-[17px] font-black tracking-tight leading-tight truncate">
                <span class="text-gray-900">Derma</span><span class="text-primary">city</span>
              </div>
              <div class="text-[8px] sm:text-[10px] text-gray-400 tracking-widest uppercase font-medium truncate">Da Liễu Chuyên Sâu</div>
            </div>
          </router-link>
          <!-- Search Bar desktop -->
          <div class="hidden sm:flex flex-1 justify-center px-4 order-2">
            <div class="w-full max-w-xl relative" ref="searchWrapRef">
              <input
                v-model="searchQuery"
                @keyup.enter="handleSearch"
                @focus="showDropdown = true"
                @input="onSearchInput"
                type="text"
                placeholder="Tìm kiếm sản phẩm, thương hiệu, thành phần..."
                class="w-full pl-4 pr-12 py-2.5 text-sm border-2 border-gray-200 rounded-xl focus:outline-none focus:border-primary transition-colors bg-gray-50 focus:bg-white"
                autocomplete="off"
              />
              <button
                @click="handleSearch"
                class="absolute right-0 top-0 bottom-0 px-4 bg-primary hover:bg-blue-700 text-white rounded-r-xl flex items-center justify-center transition-colors"
              >
                <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                  <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
                </svg>
              </button>
              <!-- Live search dropdown giữ nguyên nếu cần -->
            </div>
          </div>
          <!-- Cart & User -->
          <div class="flex items-center gap-2 flex-shrink-0 order-3">
            <!-- Cart -->
            <button
              @click="cartStore.toggleDrawer()"
              class="flex flex-col items-center gap-0.5 px-3 py-2 rounded-xl hover:bg-gray-50 transition-colors group relative"
            >
              <div class="relative">
                <svg class="w-5 h-5 text-gray-500 group-hover:text-primary transition-colors" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"/><line x1="3" y1="6" x2="21" y2="6"/>
                  <path d="M16 10a4 4 0 0 1-8 0"/>
                </svg>
                <span
                  v-if="cartStore.totalItems > 0"
                  class="absolute -top-2 -right-2 min-w-[18px] h-[18px] bg-warning text-white text-[10px] font-bold rounded-full flex items-center justify-center px-1"
                >{{ cartStore.totalItems }}</span>
              </div>
              <span class="text-[10px] text-gray-500 group-hover:text-primary transition-colors">Giỏ hàng</span>
            </button>
            <!-- User -->
            <router-link
              :to="authStore.isLoggedIn ? '/account/orders' : '/login'"
              class="flex flex-col items-center gap-0.5 px-3 py-2 rounded-xl hover:bg-gray-50 transition-colors group"
            >
              <svg class="w-5 h-5 text-gray-500 group-hover:text-primary transition-colors" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>
              </svg>
              <span class="text-[10px] text-gray-500 group-hover:text-primary transition-colors whitespace-nowrap">
                {{ authStore.isLoggedIn ? 'Tài khoản' : 'Đăng nhập' }}
              </span>
            </router-link>
            <router-link
              v-if="!authStore.isLoggedIn"
              :to="{ path: '/login', query: { tab: 'register' } }"
              class="flex flex-col items-center gap-0.5 px-3 py-2 rounded-xl hover:bg-gray-50 transition-colors group"
            >
              <svg class="w-5 h-5 text-gray-500 group-hover:text-primary transition-colors" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M15 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                <circle cx="10" cy="7" r="4"/>
                <path d="M20 8v6"/>
                <path d="M17 11h6"/>
              </svg>
              <span class="text-[10px] text-gray-500 group-hover:text-primary transition-colors whitespace-nowrap">Đăng ký</span>
            </router-link>
          </div>
        </div>
        <!-- Search Bar dưới logo trên mobile -->
        <div class="block sm:hidden w-full relative mt-2" ref="searchWrapRef">
          <input
            v-model="searchQuery"
            @keyup.enter="handleSearch"
            @focus="showDropdown = true"
            @input="onSearchInput"
            type="text"
            placeholder="Tìm kiếm sản phẩm, thương hiệu, thành phần..."
            class="w-full pl-4 pr-12 py-2.5 text-sm border-2 border-gray-200 rounded-xl focus:outline-none focus:border-primary transition-colors bg-gray-50 focus:bg-white"
            autocomplete="off"
          />
          <button
            @click="handleSearch"
            class="absolute right-0 top-0 bottom-0 px-4 bg-primary hover:bg-blue-700 text-white rounded-r-xl flex items-center justify-center transition-colors"
          >
            <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
            </svg>
          </button>

          <!-- Live search dropdown -->
          <Transition name="search-drop">
            <div
              v-if="showDropdown && searchQuery.trim().length >= 1"
              class="absolute top-full left-0 right-0 mt-1.5 bg-white border border-gray-200 rounded-2xl shadow-xl shadow-blue-100/40 z-50 overflow-hidden"
            >
              <!-- Searching indicator -->
              <div v-if="searchLoading" class="flex items-center gap-2 px-4 py-3 text-sm text-gray-400">
                <svg class="w-4 h-4 animate-spin" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
                </svg>
                Đang tìm...
              </div>

              <!-- Results -->
              <template v-else-if="searchResults.length">
                <div class="px-3 pt-2.5 pb-1 text-[10px] font-semibold text-gray-400 uppercase tracking-widest">
                  Kết quả ({{ searchResults.length }})
                </div>
                <a
                  v-for="product in searchResults"
                  :key="product.id"
                  href="#"
                  @click.prevent="selectProduct(product)"
                  class="flex items-center gap-3 px-3 py-2.5 hover:bg-blue-50 transition-colors group"
                >
                  <!-- Thumbnail -->
                  <div class="w-10 h-10 rounded-xl overflow-hidden flex-shrink-0 bg-blue-50 border border-gray-100 flex items-center justify-center">
                    <img
                      v-if="product.image"
                      :src="product.image"
                      :alt="product.name"
                      class="w-full h-full object-cover"
                      loading="lazy"
                    />
                    <svg v-else class="w-5 h-5 text-blue-200" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                      <rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18M9 21V9"/>
                    </svg>
                  </div>

                  <!-- Info -->
                  <div class="flex-1 min-w-0">
                    <p
                      class="text-sm font-medium text-gray-800 group-hover:text-primary transition-colors truncate"
                      v-html="highlightMatch(product.name, searchQuery)"
                    ></p>
                    <p class="text-xs text-gray-400 truncate">{{ product.brand || product.category_name || '' }}</p>
                  </div>

                  <!-- Price -->
                  <div class="text-right flex-shrink-0">
                    <p class="text-sm font-bold text-primary">{{ productStore.formatPrice(product.price_listed) }}</p>
                    <p v-if="product.stock_quantity === 0" class="text-[10px] text-red-400 font-medium">Hết hàng</p>
                    <p v-else class="text-[10px] text-green-500 font-medium">Còn hàng</p>
                  </div>
                </a>

                <!-- Xem tất cả -->
                <button
                  @click="handleSearch"
                  class="w-full text-center py-2.5 text-sm text-primary font-semibold hover:bg-blue-50 transition-colors border-t border-gray-100"
                >
                  Xem tất cả kết quả cho "{{ searchQuery }}" →
                </button>
              </template>

              <!-- No results -->
              <div v-else class="px-4 py-5 text-center">
                <p class="text-sm text-gray-400">Không tìm thấy sản phẩm phù hợp</p>
                <p class="text-xs text-gray-300 mt-1">Thử từ khoá khác nhé</p>
              </div>
            </div>
          </Transition>
        </div>

        <!-- Right Actions đã chuyển lên trên, phần này xoá bỏ -->
      </div>

    </header>

    <!-- Main Content -->
    <main class="flex-1">
      <router-view />
    </main>

    <!-- Footer -->
    <footer class="bg-gray-800 text-gray-300 mt-12">
      <div class="max-w-7xl mx-auto px-4 py-12">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-8">
          <div>
            <div class="flex items-center gap-2 mb-4">
              <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-primary to-cyan-400 flex items-center justify-center">
                <span class="text-white font-black text-sm">Dc</span>
              </div>
              <span class="text-white font-black text-lg tracking-tight">Derma<span class="text-cyan-400">city</span></span>
            </div>
            <p class="text-sm text-gray-400 leading-relaxed">Chuyên phân phối dược mỹ phẩm da liễu chính hãng. Cam kết chất lượng, nguồn gốc rõ ràng.</p>
          </div>
          <div>
            <h4 class="text-white font-semibold mb-4">Chính sách</h4>
            <ul class="space-y-2 text-sm">
              <li><a href="#" class="hover:text-white transition-colors">Chính sách đổi trả</a></li>
              <li><a href="#" class="hover:text-white transition-colors">Chính sách bảo mật</a></li>
              <li><a href="#" class="hover:text-white transition-colors">Điều khoản sử dụng</a></li>
              <li><a href="#" class="hover:text-white transition-colors">Hướng dẫn mua hàng</a></li>
            </ul>
          </div>
          <div>
            <h4 class="text-white font-semibold mb-4">Liên hệ</h4>
            <ul class="space-y-2 text-sm">
              <li class="flex items-center gap-2"><svg class="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.49 12 19.79 19.79 0 0 1 1.39 3.39 2 2 0 0 1 3.37 1h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 8.37a16 16 0 0 0 5.72 5.72l1.06-1.06a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z"/></svg>1800 599 971</li>
              <li class="flex items-center gap-2"><svg class="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>support@dermacity.vn</li>
            </ul>
          </div>
          <div>
            <h4 class="text-white font-semibold mb-4">Thanh toán</h4>
            <div class="flex flex-wrap gap-2">
              <div class="bg-white rounded px-2 py-1 text-xs font-bold text-gray-700">VNPay</div>
              <div class="bg-[#A50064] rounded px-2 py-1 text-xs font-bold text-white">MoMo</div>
              <div class="bg-blue-600 rounded px-2 py-1 text-xs font-bold text-white">Bank</div>
            </div>
          </div>
        </div>
        <div class="border-t border-gray-700 mt-8 pt-6 text-xs text-center text-gray-500">
          © 2026 Dermacity. All rights reserved.
        </div>
      </div>
    </footer>

    <!-- Cart Drawer -->
    <CartDrawer />
  </div>
</template>

<script setup>
import { onMounted, onBeforeUnmount, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useCartStore } from '@/stores/cart'
import { useProductStore } from '@/stores/shopProducts'
import CartDrawer from '@/components/storefront/CartDrawer.vue'

const router       = useRouter()
const authStore    = useAuthStore()
const cartStore    = useCartStore()
const productStore = useProductStore()

// ── Search State ──────────────────────────────────────────────────────────────
const searchQuery   = ref('')
const searchResults = ref([])
const searchLoading = ref(false)
const showDropdown  = ref(false)
const searchWrapRef = ref(null)
let   debounceTimer = null

// ── Debounced live search ─────────────────────────────────────────────────────
const onSearchInput = () => {
  clearTimeout(debounceTimer)
  const q = searchQuery.value.trim()

  if (q.length < 1) {
    searchResults.value = []
    return
  }

  searchLoading.value = true
  debounceTimer = setTimeout(() => {
    // Tìm trong dữ liệu đã load sẵn (không cần thêm request)
    const lower = q.toLowerCase()
    searchResults.value = productStore.activeProducts
      .filter(p =>
        p.name.toLowerCase().includes(lower) ||
        String(p.brand  || '').toLowerCase().includes(lower) ||
        String(p.dosage_form || '').toLowerCase().includes(lower)
      )
      .slice(0, 6)   // Giới hạn 6 kết quả
    searchLoading.value = false
  }, 250)
}

// ── Highlight từ trùng khớp ───────────────────────────────────────────────────
const highlightMatch = (text, query) => {
  if (!query) return text
  const escaped = query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  return text.replace(
    new RegExp(`(${escaped})`, 'gi'),
    '<mark class="bg-yellow-100 text-yellow-800 rounded px-0.5">$1</mark>'
  )
}

// ── Điều hướng khi chọn sản phẩm ─────────────────────────────────────────────
const selectProduct = (product) => {
  showDropdown.value = false
  searchQuery.value  = ''
  searchResults.value = []
  router.push(`/shop/product/${product.slug}`)
}

// ── Enter / tìm tất cả ───────────────────────────────────────────────────────
const handleSearch = () => {
  if (searchQuery.value.trim()) {
    showDropdown.value = false
    router.push({ path: '/shop', query: { q: searchQuery.value.trim() } })
  }
}

// ── Đóng dropdown khi click ngoài ────────────────────────────────────────────
const handleOutsideClick = (e) => {
  if (searchWrapRef.value && !searchWrapRef.value.contains(e.target)) {
    showDropdown.value = false
  }
}

// ── Lifecycle ─────────────────────────────────────────────────────────────────
onMounted(async () => {
  document.addEventListener('click', handleOutsideClick)
  if (!productStore.categories.length) {
    await productStore.fetchCategories()
  }
  // Load products trước để live search dùng được
  if (!productStore.products.length) {
    productStore.fetchProducts()
  }
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleOutsideClick)
  clearTimeout(debounceTimer)
})
</script>

<style scoped>
/* Ngăn tràn ngang trên mobile */
.prevent-overflow {
  max-width: 100vw;
  overflow-x: hidden;
}

html, body {
  max-width: 100vw;
  overflow-x: hidden;
}
/* Search dropdown slide + fade animation */
.search-drop-enter-active,
.search-drop-leave-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
}
.search-drop-enter-from,
.search-drop-leave-to {
  opacity: 0;
  transform: translateY(-6px) scale(0.98);
}

@media (max-width: 639px) {
  header > div {
    flex-direction: row !important;
  }
  header > div > .order-1 {
    order: 1;
  }
  header > div > .order-2 {
    order: 2;
  }
  header > div > .order-3 {
    order: 3;
    margin-left: auto;
  }
  body, html, .prevent-overflow {
    max-width: 100vw;
    overflow-x: hidden !important;
  }
}
</style>
