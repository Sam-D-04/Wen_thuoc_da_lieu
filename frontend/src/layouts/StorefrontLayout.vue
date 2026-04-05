<template>
  <div class="min-h-screen bg-gray-50 flex flex-col">
    <!-- Top bar -->
    <div class="bg-primary text-white text-xs py-1.5">
      <div class="max-w-7xl mx-auto px-4 flex items-center justify-between">
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-1.5">
            <svg class="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.49 12 19.79 19.79 0 0 1 1.39 3.39 2 2 0 0 1 3.37 1h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 8.37a16 16 0 0 0 5.72 5.72l1.06-1.06a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z"/>
            </svg>
            <span>1800 599 971</span>
          </div>
          <span class="text-blue-200">|</span>
          <span>Giao hàng toàn quốc · Miễn phí từ 299k</span>
        </div>
        <div class="flex items-center gap-3">
          <template v-if="authStore.isLoggedIn">
            <span class="text-blue-200">Xin chào, <strong class="text-white">{{ authStore.userName }}</strong></span>
            <span class="text-blue-200">|</span>
            <button @click="authStore.logout(); router.push('/shop')" class="hover:text-blue-200 transition-colors">Đăng xuất</button>
          </template>
          <template v-else>
            <router-link to="/login" class="hover:text-blue-200 transition-colors">Đăng nhập</router-link>
            <span class="text-blue-200">|</span>
            <router-link to="/login" class="hover:text-blue-200 transition-colors">Đăng ký</router-link>
          </template>
        </div>
      </div>
    </div>

    <!-- Main header -->
    <header class="bg-white shadow-sm sticky top-0 z-40">
      <div class="max-w-7xl mx-auto px-4 py-3 flex items-center gap-4">
        <!-- Logo -->
        <router-link to="/shop" class="flex items-center gap-2.5 flex-shrink-0">
          <!-- Dermacity Monogram Logo -->
          <div class="w-9 h-9 rounded-xl bg-gradient-to-br from-primary to-cyan-500 flex items-center justify-center shadow-md shadow-blue-200 flex-shrink-0">
            <span class="text-white font-black text-base tracking-tighter leading-none">Dc</span>
          </div>
          <div class="leading-none">
            <div class="text-[17px] font-black tracking-tight">
              <span class="text-gray-900">Derma</span><span class="text-primary">city</span>
            </div>
            <div class="text-[10px] text-gray-400 tracking-widest uppercase font-medium">Da Liễu Chuyên Sâu</div>
          </div>
        </router-link>

        <!-- Search Bar -->
        <div class="flex-1 relative">
          <input
            v-model="searchQuery"
            @keyup.enter="handleSearch"
            type="text"
            placeholder="Tìm kiếm sản phẩm, thương hiệu, thành phần..."
            class="w-full pl-4 pr-12 py-2.5 text-sm border-2 border-gray-200 rounded-xl focus:outline-none focus:border-primary transition-colors bg-gray-50 focus:bg-white"
          />
          <button
            @click="handleSearch"
            class="absolute right-0 top-0 bottom-0 px-4 bg-primary hover:bg-blue-700 text-white rounded-r-xl flex items-center justify-center transition-colors"
          >
            <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
            </svg>
          </button>
        </div>

        <!-- Right Actions -->
        <div class="flex items-center gap-2 flex-shrink-0">
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
        </div>
      </div>

      <!-- Category Nav - Clinical Color Coding -->
      <div class="border-t border-gray-100 bg-white">
        <div class="max-w-7xl mx-auto px-4">
          <nav class="flex items-center gap-2 overflow-x-auto scrollbar-hide py-2.5">
            <router-link
              v-for="cat in categories"
              :key="cat.id"
              :to="`/shop?category=${cat.slug}`"
              :class="[
                'flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-semibold whitespace-nowrap transition-all duration-200 border',
                cat.color
              ]"
            >
              {{ cat.name }}
            </router-link>
          </nav>
        </div>
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
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useCartStore } from '@/stores/cart'
import { useProductStore } from '@/stores/shopProducts'
import CartDrawer from '@/components/storefront/CartDrawer.vue'

const router = useRouter()
const authStore = useAuthStore()
const cartStore = useCartStore()
const productStore = useProductStore()
const searchQuery = ref('')

const chipThemes = [
  'bg-green-50 text-green-700 border-green-200 hover:bg-green-100',
  'bg-orange-50 text-orange-600 border-orange-200 hover:bg-orange-100',
  'bg-sky-50 text-sky-700 border-sky-200 hover:bg-sky-100',
  'bg-purple-50 text-purple-700 border-purple-200 hover:bg-purple-100',
  'bg-amber-50 text-amber-700 border-amber-200 hover:bg-amber-100',
  'bg-teal-50 text-teal-700 border-teal-200 hover:bg-teal-100',
  'bg-pink-50 text-pink-700 border-pink-200 hover:bg-pink-100'
]

const categories = computed(() => {
  return productStore.categories.map((item, index) => ({
    id: item.id,
    slug: item.slug,
    name: item.name,
    color: chipThemes[index % chipThemes.length]
  }))
})

const handleSearch = () => {
  if (searchQuery.value.trim()) {
    router.push({ path: '/shop', query: { q: searchQuery.value.trim() } })
  }
}

onMounted(async () => {
  if (!productStore.categories.length) {
    await productStore.fetchCategories()
  }
})
</script>
