<template>
  <div class="max-w-4xl mx-auto px-4 py-8">
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">Tài khoản của tôi</h1>
        <p class="text-sm text-gray-400 mt-1">Xin chào, <strong class="text-primary">{{ authStore.userName }}</strong></p>
      </div>
      <button
        @click="router.push('/shop')"
        class="flex items-center gap-2 text-sm text-white bg-primary hover:bg-blue-700 transition-colors border border-primary px-3 py-2 rounded-lg shadow"
      >
        <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M5 12h14"/>
          <polyline points="13 18 19 12 13 6"/>
        </svg>
        Tiếp tục mua sắm
      </button>
    </div>

    <!-- Tabs -->
    <div class="flex gap-0 border-b border-gray-200 mb-6">
      <button
        v-for="tab in tabs"
        :key="tab.key"
        @click="activeTab = tab.key"
        :class="[
          'flex items-center gap-2 px-4 py-3 text-sm font-medium transition-colors border-b-2 -mb-px',
          activeTab === tab.key ? 'text-primary border-primary' : 'text-gray-500 border-transparent hover:text-gray-700'
        ]"
      >
        <span v-html="tab.icon" class="inline-flex"></span>
        {{ tab.label }}
        <span
          v-if="tab.key === 'orders' && totalOrders > 0"
          class="ml-1 bg-primary/10 text-primary text-xs font-bold px-2 py-0.5 rounded-full"
        >{{ totalOrders }}</span>
      </button>
    </div>

    <!-- Orders Tab -->
    <div v-if="activeTab === 'orders'">

      <!-- Loading skeleton -->
      <div v-if="loadingOrders" class="space-y-4">
        <div v-for="i in 3" :key="i" class="bg-white rounded-2xl border border-gray-100 p-5 animate-pulse">
          <div class="flex justify-between mb-3">
            <div class="h-4 bg-gray-100 rounded w-40"></div>
            <div class="h-5 bg-gray-100 rounded-full w-20"></div>
          </div>
          <div class="space-y-2 mb-3">
            <div class="h-10 bg-gray-50 rounded-lg"></div>
            <div class="h-10 bg-gray-50 rounded-lg"></div>
          </div>
          <div class="h-4 bg-gray-100 rounded w-32 ml-auto"></div>
        </div>
      </div>

      <!-- Error -->
      <div v-else-if="ordersError" class="bg-red-50 border border-red-100 rounded-2xl p-6 text-center">
        <div class="text-3xl mb-3">⚠️</div>
        <p class="text-red-600 font-medium mb-3">{{ ordersError }}</p>
        <button
          @click="fetchOrders"
          class="bg-primary text-white text-sm px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
        >Thử lại</button>
      </div>

      <!-- Empty -->
      <div v-else-if="orders.length === 0" class="text-center py-16">
        <div class="text-5xl mb-4">📦</div>
        <p class="text-gray-500 font-medium">Bạn chưa có đơn hàng nào</p>
        <router-link to="/shop" class="mt-3 inline-block text-primary text-sm hover:underline">Mua sắm ngay</router-link>
      </div>

      <!-- Orders list -->
      <div v-else class="space-y-4">
        <div
          v-for="order in orders"
          :key="order.id"
          class="bg-white rounded-2xl border border-gray-100 p-5 hover:border-primary/20 transition-all hover:shadow-sm"
        >
          <!-- Order header -->
          <div class="flex items-center justify-between mb-3">
            <div class="flex items-center gap-2">
              <span class="text-sm font-bold text-gray-800">{{ order.order_code }}</span>
              <span class="text-xs text-gray-400">·</span>
              <span class="text-xs text-gray-400">{{ formatDate(order.created_at) }}</span>
            </div>
            <div class="flex items-center gap-2">
              <span :class="['text-xs font-semibold px-2 py-0.5 rounded-full', paymentBadge(order.payment_status)]">
                {{ paymentLabels[order.payment_status] || order.payment_status }}
              </span>
              <span :class="['text-xs font-semibold px-2.5 py-1 rounded-full', statusBadge(order.order_status)]">
                {{ statusLabels[order.order_status] || order.order_status }}
              </span>
            </div>
          </div>

          <!-- Items -->
          <div class="space-y-2 mb-3">
            <div
              v-for="item in order.items"
              :key="item.id"
              class="flex items-center gap-3"
            >
              <div class="w-10 h-10 bg-blue-50 rounded-lg flex-shrink-0 flex items-center justify-center border border-blue-100 overflow-hidden">
                <img
                  v-if="item.product?.image_url"
                  :src="item.product.image_url"
                  :alt="item.product?.name"
                  class="w-full h-full object-cover"
                />
                <svg v-else class="w-5 h-5 text-blue-200" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                  <rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18M9 21V9"/>
                </svg>
              </div>
              <div class="flex-1 min-w-0">
                <p class="text-sm text-gray-700 font-medium truncate">{{ item.product?.name || 'Sản phẩm' }}</p>
                <p class="text-xs text-gray-400">x{{ item.quantity }} · {{ formatPrice(item.price) }}/sp</p>
              </div>
              <span class="text-sm font-semibold text-gray-700 whitespace-nowrap">{{ formatPrice(item.total) }}</span>
            </div>
          </div>

          <!-- Order footer -->
          <div class="border-t border-gray-100 pt-3 flex items-center justify-between">
            <div class="text-xs text-gray-400">
              <span v-if="order.payment_method">
                💳 {{ paymentMethodLabels[order.payment_method] || order.payment_method }}
              </span>
              <span v-if="order.shipping_fee === 0" class="ml-2 text-green-600 font-medium">
                🚚 Miễn phí ship
              </span>
            </div>
            <div class="text-right">
              <span class="text-xs text-gray-400 mr-2">Tổng tiền</span>
              <span class="font-bold text-primary text-base">{{ formatPrice(order.final_amount) }}</span>
            </div>
          </div>
        </div>

        <!-- Pagination -->
        <div v-if="lastPage > 1" class="flex items-center justify-center gap-2 pt-4">
          <button
            :disabled="currentPage === 1"
            @click="fetchOrders(currentPage - 1)"
            class="px-3 py-1.5 text-sm border border-gray-200 rounded-lg hover:border-primary hover:text-primary disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
          >← Trước</button>

          <span class="text-sm text-gray-500">Trang {{ currentPage }} / {{ lastPage }}</span>

          <button
            :disabled="currentPage === lastPage"
            @click="fetchOrders(currentPage + 1)"
            class="px-3 py-1.5 text-sm border border-gray-200 rounded-lg hover:border-primary hover:text-primary disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
          >Tiếp →</button>
        </div>
      </div>
    </div>

    <!-- Profile Tab -->
    <div v-if="activeTab === 'profile'" class="bg-white rounded-2xl border border-gray-100 p-6 max-w-md">
      <h2 class="font-bold text-gray-800 mb-4">Thông tin cá nhân</h2>
      <div class="space-y-4">
        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1">Họ và tên</label>
          <input type="text" :value="authStore.user?.name" class="w-full px-3 py-2.5 text-sm border border-gray-200 rounded-lg bg-gray-50" readonly />
        </div>
        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1">Email</label>
          <input type="email" :value="authStore.user?.email" class="w-full px-3 py-2.5 text-sm border border-gray-200 rounded-lg bg-gray-50" readonly />
        </div>
        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1">Số điện thoại</label>
          <input type="tel" :value="authStore.user?.phone" class="w-full px-3 py-2.5 text-sm border border-gray-200 rounded-lg bg-gray-50" readonly />
        </div>
        <p class="text-xs text-gray-400 italic">Chức năng chỉnh sửa thông tin sẽ được tích hợp API backend.</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'
import { useAuthStore } from '@/stores/auth'

const router    = useRouter()
const authStore = useAuthStore()

// ── API client ────────────────────────────────────────────────────────────────
const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api',
  headers: { Accept: 'application/json' }
})
api.interceptors.request.use((cfg) => {
  const token = localStorage.getItem('auth_token')
  if (token) cfg.headers.Authorization = `Bearer ${token}`
  return cfg
})

// ── State ─────────────────────────────────────────────────────────────────────
const activeTab     = ref('orders')
const orders        = ref([])
const loadingOrders = ref(false)
const ordersError   = ref('')
const currentPage   = ref(1)
const lastPage      = ref(1)
const totalOrders   = ref(0)

// ── Tabs ──────────────────────────────────────────────────────────────────────
const tabs = [
  { key: 'orders',  label: 'Đơn hàng', icon: '<svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"/><line x1="3" y1="6" x2="21" y2="6"/><path d="M16 10a4 4 0 0 1-8 0"/></svg>' },
  { key: 'profile', label: 'Hồ sơ',    icon: '<svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>' },
]

// ── Label maps ────────────────────────────────────────────────────────────────
const statusLabels = {
  pending:   'Chờ xử lý',
  confirmed: 'Đã xác nhận',
  packing:   'Đang đóng gói',
  shipping:  'Đang giao',
  delivered: 'Đã giao',
  cancelled: 'Đã huỷ',
}

const paymentLabels = {
  paid:     'Đã thanh toán',
  unpaid:   'Chưa thanh toán',
  refunded: 'Đã hoàn tiền',
}

const paymentMethodLabels = {
  bank_transfer: 'Chuyển khoản',
  vnpay:         'VNPay',
  momo:          'MoMo',
  cod:           'COD',
}

// ── Badge helpers ─────────────────────────────────────────────────────────────
const statusBadge = (s) => ({
  delivered: 'bg-green-100 text-green-700',
  cancelled: 'bg-red-100 text-red-600',
  shipping:  'bg-blue-100 text-blue-700',
  confirmed: 'bg-indigo-100 text-indigo-700',
  packing:   'bg-purple-100 text-purple-700',
}[s] ?? 'bg-yellow-100 text-yellow-700')

const paymentBadge = (s) => ({
  paid:     'bg-emerald-100 text-emerald-700',
  refunded: 'bg-gray-100 text-gray-500',
}[s] ?? 'bg-orange-100 text-orange-700')

// ── Helpers ───────────────────────────────────────────────────────────────────
const formatPrice = (v) =>
  new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 })
    .format(Number(v || 0))

const formatDate = (dateStr) => {
  if (!dateStr) return ''
  return new Intl.DateTimeFormat('vi-VN', {
    day: '2-digit', month: '2-digit', year: 'numeric',
    hour: '2-digit', minute: '2-digit'
  }).format(new Date(dateStr))
}

// ── Fetch orders from real API ────────────────────────────────────────────────
const fetchOrders = async (page = 1) => {
  if (!authStore.isLoggedIn) return

  loadingOrders.value = true
  ordersError.value   = ''

  try {
    const { data } = await api.get('/orders', { params: { page } })

    // Laravel paginator: { data: [...], current_page, last_page, total }
    if (data?.data) {
      orders.value      = data.data
      currentPage.value = data.current_page
      lastPage.value    = data.last_page
      totalOrders.value = data.total
    } else if (Array.isArray(data)) {
      orders.value      = data
      totalOrders.value = data.length
    }
  } catch (err) {
    if (err?.response?.status === 401) {
      authStore.logout()
      router.push('/login')
    } else {
      ordersError.value =
        err?.response?.data?.message || 'Không thể tải lịch sử đơn hàng. Vui lòng thử lại.'
    }
  } finally {
    loadingOrders.value = false
  }
}

// ── Actions ───────────────────────────────────────────────────────────────────
const handleLogout = () => {
  authStore.logout()
  router.push('/login')
}

// ── Init ──────────────────────────────────────────────────────────────────────
onMounted(() => {
  if (!authStore.isLoggedIn) {
    router.push('/login')
    return
  }
  fetchOrders()
})
</script>
