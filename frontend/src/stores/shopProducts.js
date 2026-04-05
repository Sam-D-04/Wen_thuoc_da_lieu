import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import axios from 'axios'

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api',
  timeout: 10000
})

export const useProductStore = defineStore('products', () => {
  const products = ref([])
  const hoveredId = ref(null)
  const loading = ref(false)

  const activeProducts = computed(() => products.value.filter(p => p.is_active))

  const getProductBySlug = (slug) => products.value.find(p => p.slug === slug)
  const getProductById = (id) => products.value.find(p => String(p.id) === String(id))

  const filteredProducts = (category = '', query = '') => {
    return activeProducts.value.filter(p => {
      const matchCat = category ? p.category === category : true
      const matchQ = query ? (p.name.toLowerCase().includes(query.toLowerCase()) || p.brand.toLowerCase().includes(query.toLowerCase())) : true
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
        category: item.category?.slug || '',
        brand: item.brand?.name || '',
        price_listed: Number(item.price_listed || 0),
        dosage_form: item.dosage_form || '',
        volume: item.volume || '',
        image: item.image || item.image_url || null,
        description: item.description || '',
        stock_quantity: Number(item.stock_quantity || 0),
        is_active: Boolean(item.is_active),
        sold_count: Number(item.sold_count || 0)
      }))
    } finally {
      loading.value = false
    }
  }

  return {
    products,
    hoveredId,
    loading,
    activeProducts,
    getProductBySlug,
    getProductById,
    filteredProducts,
    formatPrice,
    fetchProducts
  }
})
