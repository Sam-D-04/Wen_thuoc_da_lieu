import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api'

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000
})

const API_ORIGIN = (() => {
  try {
    return new URL(API_BASE_URL).origin
  } catch (error) {
    return 'http://localhost:8000'
  }
})()

const resolveImageUrl = (value) => {
  if (!value) return null
  const raw = String(value).trim()
  if (!raw) return null

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
  return `${API_ORIGIN}/storage/${normalized}`
}

export const useProductStore = defineStore('products', () => {
  const products = ref([])
  const categories = ref([])
  const hoveredId = ref(null)
  const loading = ref(false)

  const activeProducts = computed(() => products.value.filter(p => p.is_active))

  const getProductBySlug = (slug) => products.value.find(p => p.slug === slug)
  const getProductById = (id) => products.value.find(p => String(p.id) === String(id))

  const filteredProducts = (category = '', query = '') => {
    return activeProducts.value.filter(p => {
      const matchCat = category ? p.category_slug === category : true
      const matchQ = query
        ? (p.name.toLowerCase().includes(query.toLowerCase()) || String(p.brand || '').toLowerCase().includes(query.toLowerCase()))
        : true
      return matchCat && matchQ
    })
  }

  const formatPrice = (price) => new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price)

  const fetchProducts = async () => {
    loading.value = true
    try {
      const response = await apiClient.get('/products', { params: { per_page: 100 } })
      const rows = Array.isArray(response.data?.data) ? response.data.data : []

      products.value = rows.map((item) => ({
        id: item.id,
        name: item.name,
        slug: item.slug,
        category_slug: item.category?.slug || '',
        category_name: item.category?.name || '',
        brand: item.brand?.name || '',
        price_listed: Number(item.price_listed || 0),
        dosage_form: item.dosage_form || '',
        volume: item.volume || '',
        image: resolveImageUrl(item.image) || resolveImageUrl(item.image_url),
        description: item.description || '',
        stock_quantity: Number(item.batch_remaining_quantity ?? item.stock_quantity ?? 0),
        is_active: Boolean(item.is_active),
        sold_count: Number(item.sold_count || 0)
      }))
    } finally {
      loading.value = false
    }
  }

  const fetchCategories = async () => {
    const response = await apiClient.get('/categories')
    const rows = Array.isArray(response.data) ? response.data : (Array.isArray(response.data?.data) ? response.data.data : [])
    categories.value = rows.map((item) => ({
      id: item.id,
      name: item.name,
      slug: item.slug
    }))
    return categories.value
  }

  return {
    products,
    categories,
    hoveredId,
    loading,
    activeProducts,
    getProductBySlug,
    getProductById,
    filteredProducts,
    formatPrice,
    fetchProducts,
    fetchCategories
  }
})
