<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-cyan-50 flex items-center justify-center p-4">
    <div class="bg-white rounded-2xl shadow-xl shadow-blue-100/50 p-10 max-w-md w-full text-center border border-gray-100">

      <!-- Success -->
      <template v-if="status === 'success'">
        <div class="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-5">
          <svg class="w-10 h-10 text-green-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <polyline points="20 6 9 17 4 12"/>
          </svg>
        </div>
        <h1 class="text-2xl font-bold text-gray-800 mb-2">Thanh toán thành công!</h1>
        <p class="text-gray-500 text-sm mb-1">Đơn hàng của bạn đã được xác nhận</p>
        <p v-if="orderCode" class="text-primary font-bold text-lg mb-6">{{ orderCode }}</p>
      </template>

      <!-- Failed -->
      <template v-else-if="status === 'failed'">
        <div class="w-20 h-20 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-5">
          <svg class="w-10 h-10 text-red-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
          </svg>
        </div>
        <h1 class="text-2xl font-bold text-gray-800 mb-2">Thanh toán thất bại</h1>
        <p class="text-gray-500 text-sm mb-6">Giao dịch bị huỷ hoặc có lỗi xảy ra. Đơn hàng vẫn được lưu, bạn có thể thử lại.</p>
      </template>

      <!-- Error -->
      <template v-else>
        <div class="w-20 h-20 bg-yellow-100 rounded-full flex items-center justify-center mx-auto mb-5">
          <svg class="w-10 h-10 text-yellow-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
          </svg>
        </div>
        <h1 class="text-2xl font-bold text-gray-800 mb-2">Có lỗi xảy ra</h1>
        <p class="text-gray-500 text-sm mb-6">Không thể xác minh giao dịch. Vui lòng liên hệ hỗ trợ.</p>
      </template>

      <!-- Buttons -->
      <div class="space-y-3">
        <router-link
          to="/account/orders"
          class="w-full bg-primary hover:bg-blue-700 text-white font-semibold py-3 rounded-xl transition-all flex items-center justify-center gap-2 text-sm shadow-md shadow-blue-200"
        >
          Xem đơn hàng của tôi
        </router-link>
        <router-link
          to="/shop"
          class="w-full bg-gray-50 hover:bg-gray-100 text-gray-600 font-medium py-3 rounded-xl transition-all flex items-center justify-center text-sm border border-gray-200"
        >
          Tiếp tục mua sắm
        </router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()
const status    = computed(() => route.query.status || 'error')
const orderCode = computed(() => route.query.code   || '')
</script>
