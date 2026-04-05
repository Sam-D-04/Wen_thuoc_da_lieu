import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import axios from 'axios'

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api',
  timeout: 10000,
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

const normalizeCustomer = (customer) => ({
  ...customer,
  status: customer.status === 'active' ? 'active' : 'inactive',
  statusLabel: customer.status === 'active' ? 'Hoạt động' : 'Ngưng hoạt động',
  totalOrders: Number(customer.orders_count ?? customer.totalOrders ?? 0),
  totalSpent: Number(customer.total_spent ?? customer.totalSpent ?? 0),
  type: Number(customer.total_spent ?? customer.totalSpent ?? 0) > 1000000 || Number(customer.orders_count ?? customer.totalOrders ?? 0) > 3 ? 'Thường xuyên' : 'Mới',
  joinDate: customer.created_at || customer.joinDate,
  created_at: customer.created_at || customer.joinDate,
  user_addresses: Array.isArray(customer.addresses) ? customer.addresses : Array.isArray(customer.user_addresses) ? customer.user_addresses : []
})

export const useCustomerStore = defineStore('customer', () => {
  const customers = ref([])

  const totalCustomers = computed(() => customers.value.length)

  const activeCustomers = computed(() =>
    customers.value.filter(c => c.status === 'Đang hoạt động').length
  )

  const loyalCustomers = computed(() =>
    customers.value.filter(c => c.type === 'Thường xuyên').length
  )

  const totalCustomerSpent = computed(() =>
    customers.value.reduce((sum, customer) => sum + customer.totalSpent, 0)
  )

  const topCustomers = computed(() =>
    [...customers.value].sort((a, b) => b.totalSpent - a.totalSpent).slice(0, 5)
  )

  const fetchCustomers = async (params = {}) => {
    const response = await apiClient.get('/admin/users', {
      params: {
        role: 'customer',
        ...params
      }
    })

    const list = response.data?.data || []
    customers.value = list.map(normalizeCustomer)
    return response.data
  }

  const addCustomer = (customer) => {
    const nextId = 'CUST-' + String(customers.value.length + 1).padStart(3, '0')
    const today = new Date().toISOString().split('T')[0]
    const created = normalizeCustomer({
      id: nextId,
      ...customer,
      role: customer.role || 'customer',
      joinDate: today,
      created_at: today,
      totalOrders: 0,
      totalSpent: 0,
      status: 'active',
      type: 'Mới',
      user_addresses: customer.user_addresses || []
    })

    customers.value.push(created)
    return created
  }

  const updateCustomer = (id, updates) => {
    const index = customers.value.findIndex(c => c.id === id)
    if (index > -1) {
      customers.value[index] = { ...customers.value[index], ...updates }
    }
  }

  const updateCustomerType = (id, orderCount) => {
    const index = customers.value.findIndex(c => c.id === id)
    if (index > -1) {
      const type = orderCount >= 5 ? 'Thường xuyên' : 'Mới'
      customers.value[index].type = type
    }
  }

  const deleteCustomer = (id) => {
    const index = customers.value.findIndex(c => c.id === id)
    if (index > -1) {
      customers.value.splice(index, 1)
    }
  }

  const getCustomerOrderHistory = (customerId) => {
    const customer = customers.value.find(c => c.id === customerId)
    return customer ? { id: customerId, name: customer.name, totalOrders: customer.totalOrders } : null
  }

  return {
    customers,
    totalCustomers,
    activeCustomers,
    loyalCustomers,
    totalCustomerSpent,
    topCustomers,
    fetchCustomers,
    addCustomer,
    updateCustomer,
    updateCustomerType,
    deleteCustomer,
    getCustomerOrderHistory
  }
})
