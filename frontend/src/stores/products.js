import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api'

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    Accept: 'application/json'
  }
})

const API_ORIGIN = (() => {
  try {
    return new URL(API_BASE_URL).origin
  } catch (error) {
    return 'http://localhost:8000'
  }
})()

const resolveImageUrl = (value) => {
  if (!value) return ''
  const raw = String(value).trim()
  if (!raw) return ''

  if (raw.startsWith('data:')) return raw

  if (/^https?:\/\//i.test(raw)) {
    try {
      const parsed = new URL(raw)
      if (parsed.hostname === 'localhost' && !parsed.port && parsed.pathname.startsWith('/storage/')) {
        return `${API_ORIGIN}${parsed.pathname}${parsed.search || ''}`
      }
    } catch (error) {
      return raw
    }
    return raw
  }

  const normalized = raw.replace(/^\/+/, '')
  if (normalized.startsWith('storage/')) {
    return `${API_ORIGIN}/${normalized}`
  }
  if (normalized.startsWith('products/')) {
    return `${API_ORIGIN}/storage/${normalized}`
  }
  return `${API_ORIGIN}/${normalized}`
}

apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('auth_token')
  if (token) {
    config.headers = config.headers || {}
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

const normalizeProduct = (product) => {
  const isActive = typeof product.is_active === 'boolean'
    ? product.is_active
    : product.is_active === 1 || product.is_active === '1' || product.is_active === 'true' || product.status === 'Hoạt động'

  return {
    ...product,
    price: Number(product.price_listed ?? product.price ?? 0),
    price_listed: Number(product.price_listed ?? product.price ?? 0),
    stock_quantity: Number(product.stock_quantity ?? product.stock ?? 0),
    stock_warning: Number(product.stock_warning ?? 10),
    category_name: product.category?.name || product.category_name || product.category || 'N/A',
    brand_name: product.brand?.name || product.brand_name || product.brand || 'N/A',
    image_url: resolveImageUrl(product.image) || resolveImageUrl(product.image_url),
    is_active: isActive,
    status: isActive ? 'Hoạt động' : 'Ngừng'
  }
}

export const useProductStore = defineStore('product', () => {
  const products = ref([])

  const totalProducts = computed(() => products.value.length)
  const lowStockProducts = computed(() => products.value.filter(p => Number(p.stock_quantity ?? p.stock ?? 0) <= 10).length)

  const fetchProducts = async (params = {}) => {
    const response = await apiClient.get('/admin/products', {
      params: {
        per_page:    params.per_page    || 50,
        page:        params.page        || 1,
        search:      params.search      || undefined,
        category_id: params.category_id || undefined,
        brand_id:    params.brand_id    || undefined,
        sort:        params.sort        || undefined,
      }
    })

    const list = response.data?.data || []
    products.value = list.map(normalizeProduct)
    return response.data
  }

  const addProduct = (product) => {
    const nextId = products.value.length
      ? Math.max(...products.value.map((p) => Number(p.id) || 0)) + 1
      : 1

    const normalized = normalizeProduct({
      ...product,
      id: nextId
    })

    products.value.push(normalized)
    return normalized
  }

  const updateProduct = (id, updates) => {
    const index = products.value.findIndex(p => p.id === id)
    if (index > -1) {
      products.value[index] = {
        ...products.value[index],
        ...updates,
        stock_quantity: updates.stock_quantity ?? updates.stock ?? products.value[index].stock_quantity ?? products.value[index].stock ?? 0,
        stock_warning: updates.stock_warning ?? products.value[index].stock_warning ?? 10
      }
    }
  }

  const deleteProduct = (id) => {
    const index = products.value.findIndex(p => p.id === id)
    if (index > -1) {
      products.value.splice(index, 1)
    }
  }

  return {
    products,
    totalProducts,
    lowStockProducts,
    fetchProducts,
    addProduct,
    updateProduct,
    deleteProduct
  }
})
