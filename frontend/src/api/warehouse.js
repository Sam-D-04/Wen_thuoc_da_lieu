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

const toList = (payload) => {
  if (Array.isArray(payload)) return payload
  if (Array.isArray(payload?.data)) return payload.data
  return []
}

const toPaginated = (payload, fallbackPage = 1, fallbackPageSize = 10) => {
  if (payload && Array.isArray(payload.data)) {
    return {
      data: payload.data,
      meta: {
        page: Number(payload.current_page || fallbackPage),
        pageSize: Number(payload.per_page || fallbackPageSize),
        total: Number(payload.total || payload.data.length),
        totalPages: Number(payload.last_page || 1)
      }
    }
  }

  const list = toList(payload)
  return {
    data: list,
    meta: {
      page: fallbackPage,
      pageSize: fallbackPageSize,
      total: list.length,
      totalPages: 1
    }
  }
}

export const warehouseApi = {
  async getDashboard() {
    const [inventoryRes, alertsRes, batchesRes] = await Promise.all([
      apiClient.get('/warehouse/inventory'),
      apiClient.get('/warehouse/alerts'),
      apiClient.get('/batches')
    ])

    const inventory = toList(inventoryRes.data)
    const alerts = toList(alertsRes.data)
    const batches = toList(batchesRes.data)
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    const expiringBatches = batches.filter((item) => {
      const expiryDate = new Date(String(item.expiry_date || item.expiryDate || '').replace(' ', 'T'))
      if (Number.isNaN(expiryDate.getTime())) return false
      expiryDate.setHours(0, 0, 0, 0)
      const days = Math.ceil((expiryDate - today) / (1000 * 60 * 60 * 24))
      return days >= 0 && days <= 30
    })

    const inventoryValue = inventory.reduce(
      (sum, item) => sum + Number(item.stock_quantity || 0) * Number(item.price_listed || 0),
      0
    )

    return {
      total_products: inventory.length,
      total_batches: batches.length,
      inventory_value: inventoryValue,
      expiring_batches: expiringBatches.length,
      low_stock_items: inventory.filter(
        (item) => Number(item.stock_quantity || 0) <= Number(item.stock_warning || 0)
      ).length,
      alerts_summary: {
        low_stock: alerts.filter((item) => item.alert_type === 'low_stock').length,
        expiring_soon: alerts.filter((item) => item.alert_type === 'expiring_soon').length,
        expired: alerts.filter((item) => item.alert_type === 'expired').length
      }
    }
  },

  async getLookups() {
    const [categoriesRes, brandsRes] = await Promise.all([
      apiClient.get('/categories'),
      apiClient.get('/brands')
    ])

    return {
      categories: toList(categoriesRes.data),
      brands: toList(brandsRes.data)
    }
  },

  async getCategories() {
    const response = await apiClient.get('/categories')
    return toList(response.data)
  },

  async createCategory(payload) {
    const response = await apiClient.post('/categories', payload)
    return response.data
  },

  async updateCategory(id, payload) {
    const response = await apiClient.put(`/categories/${id}`, payload)
    return response.data
  },

  async deleteCategory(id) {
    const response = await apiClient.delete(`/categories/${id}`)
    return response.data
  },

  async getBrands() {
    const response = await apiClient.get('/brands')
    return toList(response.data)
  },

  async createBrand(payload) {
    const response = await apiClient.post('/brands', payload)
    return response.data
  },

  async updateBrand(id, payload) {
    const response = await apiClient.put(`/brands/${id}`, payload)
    return response.data
  },

  async deleteBrand(id) {
    const response = await apiClient.delete(`/brands/${id}`)
    return response.data
  },

  async getProducts(params) {
    const response = await apiClient.get('/products', { params })
    return toPaginated(response.data, Number(params?.page || 1), Number(params?.pageSize || 10))
  },

  async createProduct(payload) {
    const response = await apiClient.post('/products', payload)
    return response.data
  },

  async updateProduct(id, payload) {
    const response = await apiClient.put(`/products/${id}`, payload)
    return response.data
  },

  async deleteProduct(id) {
    const response = await apiClient.delete(`/products/${id}`)
    return response.data
  },

  async getBatches(params) {
    const response = await apiClient.get('/batches', { params })
    return toPaginated(response.data, Number(params?.page || 1), Number(params?.pageSize || 10))
  },

  async createBatch(payload) {
    const mappedPayload = {
      product_id: payload.product_id,
      batch_code: payload.batch_no || payload.batch_code,
      expiry_date: payload.expiry_date,
      quantity: payload.quantity
    }

    const response = await apiClient.post('/batches', mappedPayload)
    return response.data
  },

  async updateBatch(id, payload) {
    const mappedPayload = {
      expiry_date: payload.expiry_date || payload.expiryDate,
      remaining_quantity: payload.remaining_quantity
    }

    const response = await apiClient.put(`/batches/${id}`, mappedPayload)
    return response.data
  },

  async deleteBatch() {
    throw new Error('API hiện chưa hỗ trợ xóa lô hàng.')
  },

  async getInventoryTransactions(params) {
    const mappedParams = {
      page: Number(params?.page || 1),
      per_page: Number(params?.pageSize || 10),
      search: params?.search || undefined,
      type: params?.type && params.type !== 'all' ? params.type : undefined,
      from_date: params?.fromDate || undefined,
      to_date: params?.toDate || undefined
    }

    const response = await apiClient.get('/warehouse/inventory-transactions', { params: mappedParams })
    return toPaginated(response.data, Number(mappedParams.page), Number(mappedParams.per_page))
  },

  async getInventory(params) {
    const response = await apiClient.get('/warehouse/inventory', { params })
    return toPaginated(response.data, Number(params?.page || 1), Number(params?.pageSize || 20))
  },

  async getAlerts(params) {
    const response = await apiClient.get('/warehouse/alerts', { params })
    return toPaginated(response.data, Number(params?.page || 1), Number(params?.pageSize || 10))
  },

  async resolveAlert(id) {
    const response = await apiClient.post(`/warehouse/alerts/${id}/resolve`)
    return response.data
  }
}
