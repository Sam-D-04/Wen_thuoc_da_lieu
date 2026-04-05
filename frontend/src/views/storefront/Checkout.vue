<template>
  <div class="max-w-4xl mx-auto px-4 py-8">
    <!-- Page title -->
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-800">Thanh toán</h1>
      <p class="text-sm text-gray-400 mt-1">Hoàn tất thông tin để đặt hàng</p>
    </div>

    <!-- Empty cart redirect -->
    <div v-if="cartStore.items.length === 0" class="text-center py-20">
      <div class="text-5xl mb-4">🛒</div>
      <p class="text-gray-500 font-medium mb-4">Giỏ hàng của bạn đang trống</p>
      <router-link to="/shop" class="bg-primary text-white px-5 py-2.5 rounded-xl text-sm font-medium hover:bg-blue-700 transition-colors">
        Tiếp tục mua sắm
      </router-link>
    </div>

    <div v-else class="grid md:grid-cols-5 gap-8">
      <!-- Left: Form -->
      <div class="md:col-span-3 space-y-5">
        <!-- Shipping Info -->
        <div class="bg-white rounded-2xl border border-gray-100 p-5">
          <h2 class="font-bold text-gray-800 mb-4 flex items-center gap-2">
            <svg class="w-4 h-4 text-primary" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/>
            </svg>
            Thông tin giao hàng
          </h2>
          <div class="space-y-3">
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Họ và tên *</label>
                <input v-model="form.name" type="text" placeholder="Nguyễn Văn A" class="w-full px-3 py-2.5 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary bg-gray-50 focus:bg-white" required />
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Số điện thoại *</label>
                <input v-model="form.phone" type="tel" placeholder="0909 123 456" class="w-full px-3 py-2.5 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary bg-gray-50 focus:bg-white" required />
              </div>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Địa chỉ *</label>
              <input v-model="form.address_line" type="text" placeholder="Số nhà, tên đường..." class="w-full px-3 py-2.5 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary bg-gray-50 focus:bg-white" required />
            </div>
            <div class="grid grid-cols-3 gap-3">
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Phường / Xã</label>
                <input v-model="form.ward" type="text" placeholder="Phường 1" class="w-full px-3 py-2.5 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary bg-gray-50 focus:bg-white" />
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Quận / Huyện</label>
                <input v-model="form.district" type="text" placeholder="Quận 1" class="w-full px-3 py-2.5 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary bg-gray-50 focus:bg-white" />
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Tỉnh / Thành phố</label>
                <input v-model="form.city" type="text" placeholder="TP. HCM" class="w-full px-3 py-2.5 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary bg-gray-50 focus:bg-white" />
              </div>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Ghi chú cho shop (tùy chọn)</label>
              <textarea v-model="form.note" rows="2" placeholder="VD: Gọi trước khi giao, tránh giao buổi sáng..." class="w-full px-3 py-2.5 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary bg-gray-50 focus:bg-white resize-none"></textarea>
            </div>
          </div>
        </div>

        <!-- Payment Method -->
        <div class="bg-white rounded-2xl border border-gray-100 p-5">
          <h2 class="font-bold text-gray-800 mb-4 flex items-center gap-2">
            <svg class="w-4 h-4 text-primary" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/>
            </svg>
            Phương thức thanh toán
          </h2>
          <div class="space-y-2">
            <label
              v-for="pm in paymentMethods"
              :key="pm.value"
              :class="[
                'flex items-center gap-3 p-3 rounded-xl border-2 cursor-pointer transition-all',
                form.payment_method === pm.value ? 'border-primary bg-primary/5' : 'border-gray-100 hover:border-gray-200'
              ]"
            >
              <input type="radio" :value="pm.value" v-model="form.payment_method" class="sr-only" />
              <div :class="['w-5 h-5 rounded-full border-2 flex items-center justify-center flex-shrink-0', form.payment_method === pm.value ? 'border-primary' : 'border-gray-300']">
                <div v-if="form.payment_method === pm.value" class="w-2.5 h-2.5 bg-primary rounded-full"></div>
              </div>
              <span class="text-2xl">{{ pm.icon }}</span>
              <div>
                <div class="text-sm font-semibold text-gray-800">{{ pm.label }}</div>
                <div class="text-xs text-gray-400">{{ pm.desc }}</div>
              </div>
            </label>
          </div>
        </div>
      </div>

      <!-- Right: Order Summary -->
      <div class="md:col-span-2">
        <div class="bg-white rounded-2xl border border-gray-100 p-5 sticky top-28">
          <h2 class="font-bold text-gray-800 mb-4">Đơn hàng của bạn</h2>

          <!-- Items list -->
          <div class="space-y-3 mb-4">
            <div v-for="item in cartStore.items" :key="item.productId" class="flex gap-3">
              <div class="w-12 h-12 bg-blue-50 rounded-lg flex-shrink-0 flex items-center justify-center border border-gray-100 overflow-hidden">
                <img v-if="item.image" :src="item.image" :alt="item.name" class="w-full h-full object-cover" />
                <svg v-else class="w-6 h-6 text-blue-200" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18M9 21V9"/></svg>
              </div>
              <div class="flex-1 min-w-0">
                <p class="text-xs font-medium text-gray-700 line-clamp-2">{{ item.name }}</p>
                <p class="text-xs text-gray-400 mt-0.5">x{{ item.quantity }}</p>
              </div>
              <span class="text-xs font-semibold text-gray-700 whitespace-nowrap">{{ cartStore.formatPrice(item.price * item.quantity) }}</span>
            </div>
          </div>

          <div class="border-t border-gray-100 pt-4 space-y-2">
            <div class="flex justify-between text-sm text-gray-600">
              <span>Tạm tính</span>
              <span>{{ cartStore.formatPrice(cartStore.totalAmount) }}</span>
            </div>
            <div class="flex justify-between text-sm text-gray-600">
              <span>Phí vận chuyển</span>
              <span class="text-green-600">{{ cartStore.totalAmount >= 299000 ? 'Miễn phí' : cartStore.formatPrice(25000) }}</span>
            </div>
            <div class="border-t border-gray-100 pt-2 flex justify-between font-bold text-gray-800">
              <span>Tổng cộng</span>
              <span class="text-primary text-lg">{{ cartStore.formatPrice(finalAmount) }}</span>
            </div>
          </div>

          <!-- Error -->
          <div v-if="error" class="mt-3 p-3 bg-red-50 border border-red-100 rounded-lg text-sm text-red-600">{{ error }}</div>

          <!-- Success -->
          <div v-if="orderSuccess" class="mt-3 p-3 bg-green-50 border border-green-100 rounded-xl text-sm text-green-700 flex items-center gap-2">
            <svg class="w-4 h-4 flex-shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
            Đặt hàng thành công! Mã đơn: <strong>{{ orderId }}</strong>
          </div>

          <button
            @click="handleSubmit"
            :disabled="isSubmitting || orderSuccess"
            class="w-full mt-4 bg-primary hover:bg-blue-700 text-white font-bold py-3 rounded-xl transition-all duration-200 shadow-md shadow-blue-200 hover:shadow-lg disabled:opacity-60 disabled:cursor-not-allowed flex items-center justify-center gap-2"
          >
            <svg v-if="isSubmitting" class="animate-spin w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
            <svg v-else class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
            {{ isSubmitting ? 'Đang đặt hàng...' : orderSuccess ? 'Đã đặt hàng!' : 'Xác nhận đặt hàng' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'
import { useCartStore } from '@/stores/cart'
import { useAuthStore } from '@/stores/auth'
import { useProductStore } from '@/stores/shopProducts'

const router = useRouter()
const cartStore = useCartStore()
const authStore = useAuthStore()
const productStore = useProductStore()

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api',
  timeout: 15000,
  headers: {
    Accept: 'application/json'
  }
})

apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('auth_token')
  if (token) {
    config.headers = config.headers || {}
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

const isSubmitting = ref(false)
const orderSuccess = ref(false)
const orderId = ref('')
const error = ref('')

const form = ref({
  name: authStore.user?.name || '',
  phone: authStore.user?.phone || '',
  address_line: '',
  ward: '',
  district: '',
  city: '',
  note: '',
  payment_method: 'bank_transfer'
})

const paymentMethods = [
  { value: 'bank_transfer', label: 'Chuyển khoản ngân hàng', icon: '🏦', desc: 'Chuyển khoản trực tiếp qua ngân hàng' },
  { value: 'vnpay', label: 'VNPay', icon: '💳', desc: 'Thanh toán qua cổng VNPay' },
  { value: 'momo', label: 'MoMo', icon: '💜', desc: 'Ví điện tử MoMo' },
]

const shippingFee = computed(() => cartStore.totalAmount >= 299000 ? 0 : 25000)
const finalAmount = computed(() => cartStore.totalAmount + shippingFee.value)

const handleSubmit = async () => {
  error.value = ''
  if (!authStore.isLoggedIn) {
    error.value = 'Vui lòng đăng nhập để đặt hàng.'
    router.push('/login')
    return
  }

  if (!cartStore.items.length) {
    error.value = 'Giỏ hàng trống, không thể đặt hàng.'
    return
  }

  if (!form.value.name || !form.value.phone || !form.value.address_line) {
    error.value = 'Vui lòng điền đầy đủ thông tin giao hàng.'
    return
  }

  isSubmitting.value = true
  try {
    const payload = {
      items: cartStore.items.map((item) => ({
        product_id: item.productId,
        quantity: Number(item.quantity || 0)
      })),
      address: {
        full_name: form.value.name,
        phone: form.value.phone,
        address_line: form.value.address_line,
        ward: form.value.ward || '',
        district: form.value.district || '',
        city: form.value.city || ''
      },
      payment_method: form.value.payment_method,
      note: form.value.note || ''
    }

    const response = await apiClient.post('/orders', payload)
    const data = response.data || {}

    orderId.value = data.order_code || String(data.order_id || '')
    orderSuccess.value = true

    cartStore.clearCart()
    await productStore.fetchProducts()

    if (data.payment_url) {
      window.location.href = data.payment_url
      return
    }

    setTimeout(() => router.push('/account/orders'), 1800)
  } catch (err) {
    error.value = err?.response?.data?.message || err?.message || 'Đặt hàng thất bại. Vui lòng thử lại.'
  } finally {
    isSubmitting.value = false
  }
}
</script>
