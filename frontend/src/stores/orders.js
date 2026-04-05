import { defineStore } from 'pinia'
import { ref } from 'vue'
import axios from 'axios'
import { useBatchStore } from '@/stores/batches'

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api',
  timeout: 10000,
  headers: {
    Accept: 'application/json'
  }
})

apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('auth_token')
  if (token && !token.startsWith('mock-token-')) {
    config.headers = config.headers || {}
    config.headers.Authorization = `Bearer ${token}`
  } else if (token && token.startsWith('mock-token-')) {
    localStorage.removeItem('auth_token')
    localStorage.removeItem('auth_user')
  }
  return config
})

const normalizeOrderItem = (item) => ({
  ...item,
  product_id: item.product_id ?? item.productId,
  product_name: item.product?.name || item.product_name || item.productName || '',
  batch_id: item.batch_id ?? item.batchId,
  unit_price: Number(item.unit_price ?? item.price ?? 0),
  subtotal: Number(item.subtotal ?? Number(item.unit_price ?? item.price ?? 0) * Number(item.quantity || 0))
})

const normalizeOrder = (order) => {
  const user = order.user || order.customer || {}
  const address = order.address || {}
  const orderStatus = order.order_status || order.status || 'pending'

  return {
    ...order,
    id: order.id,
    customerId: order.user_id ?? order.customer_id ?? user.id,
    customerName: order.customer_name || user.name || '-',
    customerPhone: order.customer_phone || user.phone || '-',
    customerEmail: order.customer_email || user.email || '-',
    orderDate: order.order_date || order.created_at,
    order_status: orderStatus,
    status: order.status || orderStatus,
    payment_method: order.payment_method || 'bank_transfer',
    payment_status: order.payment_status || 'unpaid',
    total_amount: Number(order.total_amount || 0),
    shipping_fee: Number(order.shipping_fee || 0),
    final_amount: Number(order.final_amount || 0),
    note: order.note || '',
    items: Array.isArray(order.items) ? order.items.map(normalizeOrderItem) : [],
    address,
    addressId: order.address_id ?? address.id ?? null
  }
}

export const useOrderStore = defineStore('order', () => {
  const orders = ref([])

  const paymentMethods = [
    { value: 'bank_transfer', label: 'Chuyển khoản' },
    { value: 'vnpay', label: 'VNPay' },
    { value: 'momo', label: 'MoMo' }
  ]

  const orderStatusOptions = ['pending', 'confirmed', 'packing', 'shipping', 'delivered', 'cancelled']

  const orderStatusLabels = {
    pending: 'Chờ xử lý',
    confirmed: 'Đã xác nhận',
    packing: 'Đang đóng gói',
    shipping: 'Đang giao',
    delivered: 'Đã giao',
    cancelled: 'Đã hủy'
  }

  const orderStatusColors = {
    pending: 'warning',
    confirmed: 'processing',
    packing: 'geekblue',
    shipping: 'blue',
    delivered: 'success',
    cancelled: 'error'
  }

  const paymentMethodLabels = {
    bank_transfer: 'Chuyển khoản',
    vnpay: 'VNPay',
    momo: 'MoMo'
  }

  const getOrderById = (id) => {
    return orders.value.find((item) => String(item.id) === String(id)) || null
  }

  const fetchOrders = async () => {
    const response = await apiClient.get('/orders')
    const list = response.data?.data || []
    orders.value = list.map(normalizeOrder)
    return response.data
  }

  const fetchAdminOrders = async (params = {}) => {
    const response = await apiClient.get('/admin/orders', { params })
    const list = response.data?.data || []
    orders.value = list.map(normalizeOrder)
    return response.data
  }

  const updateOrder = (id, updates) => {
    const index = orders.value.findIndex((item) => String(item.id) === String(id))
    if (index === -1) return null

    orders.value[index] = {
      ...orders.value[index],
      ...updates
    }

    return orders.value[index]
  }

  const updateOrderStatus = (id, status) => {
    return updateOrder(id, {
      order_status: status,
      status: orderStatusLabels[status] || status
    })
  }

  const cancelOrder = (id, note = '') => {
    return updateOrder(id, {
      order_status: 'cancelled',
      status: orderStatusLabels.cancelled,
      note
    })
  }

  const deleteOrder = (id) => {
    const index = orders.value.findIndex((item) => String(item.id) === String(id))
    if (index === -1) return false
    orders.value.splice(index, 1)
    return true
  }

  const getAvailableBatchesForProduct = (productId) => {
    const batchStore = useBatchStore()
    return batchStore.batchesSortedByFefo
      .filter((batch) => String(batch.product_id ?? batch.productId) === String(productId))
      .filter((batch) => Number(batch.remaining_quantity ?? batch.quantity ?? 0) > 0)
      .map((batch) => ({
        id: batch.id,
        value: batch.id,
        label: `${batch.batch_code || batch.batchNo || batch.id} - còn ${Number(batch.remaining_quantity ?? batch.quantity ?? 0)}`,
        remaining_quantity: Number(batch.remaining_quantity ?? batch.quantity ?? 0)
      }))
  }

  const createOrderAPI = async (payload) => {
    const response = await apiClient.post('/orders', payload)
    return response.data
  }

  return {
    orders,
    paymentMethods,
    orderStatusOptions,
    orderStatusLabels,
    orderStatusColors,
    paymentMethodLabels,
    getOrderById,
    fetchOrders,
    fetchAdminOrders,
    updateOrder,
    updateOrderStatus,
    cancelOrder,
    deleteOrder,
    getAvailableBatchesForProduct,
    createOrderAPI
  }
})
