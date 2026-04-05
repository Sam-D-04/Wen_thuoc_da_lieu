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

const ALERT_TYPE_LABELS = {
  low_stock: 'Tồn kho thấp',
  expired: 'Hết hạn',
  expiring_soon: 'Sắp hết hạn'
}

const ALERT_SEVERITY_MAP = {
  low_stock: 'warning',
  expired: 'danger',
  expiring_soon: 'warning'
}

const normalizeAlert = (alert) => {
  const typeKey = alert.alert_type || alert.type || 'low_stock'
  return {
    ...alert,
    id: alert.id,
    type: ALERT_TYPE_LABELS[typeKey] || typeKey,
    severity: ALERT_SEVERITY_MAP[typeKey] || alert.severity || 'info',
    title: alert.title || ALERT_TYPE_LABELS[typeKey] || 'Cảnh báo kho',
    message: alert.message || '',
    productId: alert.product_id ?? alert.productId,
    batchId: alert.batch_id ?? alert.batchId,
    createdAt: alert.created_at || alert.createdAt || new Date().toISOString(),
    isResolved: Number(alert.is_resolved ?? alert.isResolved ?? 0),
    isRead: Number(alert.is_resolved ?? alert.isResolved ?? 0) === 1,
    status: Number(alert.is_resolved ?? alert.isResolved ?? 0) === 1 ? 'Đã xử lý' : 'Chưa xử lý'
  }
}

export const useAlertStore = defineStore('alert', () => {
  const alerts = ref([])

  const unreadAlerts = computed(() =>
    alerts.value.filter(a => !a.isRead).length
  )

  const criticalAlerts = computed(() =>
    alerts.value.filter(a => a.severity === 'danger').length
  )

  const warningAlerts = computed(() =>
    alerts.value.filter(a => a.severity === 'warning').length
  )

  const expirySoonAlerts = computed(() =>
    alerts.value.filter(a => a.type === 'Hết hạn' && a.status === 'Chưa xử lý')
  )

  const outOfStockAlerts = computed(() =>
    alerts.value.filter(a => a.type === 'Hết hàng')
  )

  const lowStockAlerts = computed(() =>
    alerts.value.filter(a => a.type === 'Tồn kho thấp')
  )

  // Lấy 5 cảnh báo gần đây nhất chưa đọc
  const recentUnreadAlerts = computed(() =>
    alerts.value
      .filter(a => !a.isRead || Number(a.isResolved) === 0)
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .slice(0, 5)
  )

  const unresolvedRecentAlerts = computed(() =>
    alerts.value
      .filter(a => Number(a.isResolved) === 0)
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .slice(0, 5)
  )

  const addAlert = (alert) => {
    const nextId = 'ALERT-' + String(alerts.value.length + 1).padStart(3, '0')
    const today = new Date().toISOString().split('T')[0]
    alerts.value.unshift({
      id: nextId,
      ...alert,
      createdAt: today,
      status: 'Chưa xử lý',
      isRead: false
    })
    return nextId
  }

  const fetchAlerts = async (params = {}) => {
    const response = await apiClient.get('/warehouse/alerts', { params })
    const list = Array.isArray(response.data?.data)
      ? response.data.data
      : Array.isArray(response.data)
        ? response.data
        : []

    alerts.value = list.map(normalizeAlert)
    return response.data
  }

  const resolveAlertAPI = async (id) => {
    await apiClient.post(`/warehouse/alerts/${id}/resolve`)
    const alert = alerts.value.find((item) => String(item.id) === String(id))
    if (alert) {
      alert.isRead = true
      alert.isResolved = 1
      alert.status = 'Đã xử lý'
    }
    return alert
  }

  const markAsRead = (id) => {
    const alert = alerts.value.find(a => a.id === id)
    if (alert) {
      alert.isRead = true
    }
  }

  const markAsUnread = (id) => {
    const alert = alerts.value.find(a => a.id === id)
    if (alert) {
      alert.isRead = false
    }
  }

  const markAllAsRead = () => {
    alerts.value.forEach(a => a.isRead = true)
  }

  const updateAlertStatus = (id, status) => {
    const alert = alerts.value.find(a => a.id === id)
    if (alert) {
      alert.status = status
      alert.isResolved = status === 'Đã xử lý' ? 1 : alert.isResolved
    }
  }

  const deleteAlert = (id) => {
    const index = alerts.value.findIndex(a => a.id === id)
    if (index > -1) {
      alerts.value.splice(index, 1)
    }
  }

  const deleteAllReadAlerts = () => {
    const index = alerts.value.findIndex(a => a.isRead)
    while (index > -1) {
      alerts.value.splice(index, 1)
    }
  }

  // Tư động tạo cảnh báo hết hạn dựa trên lô hàng
  const createExpiryAlert = (batch) => {
    const existingAlert = alerts.value.find(
      a => a.batchId === batch.id && a.type === 'Hết hạn'
    )
    if (!existingAlert) {
      const days = Math.floor(
        (new Date(batch.expiryDate) - new Date()) / (1000 * 60 * 60 * 24)
      )
      const severity = days < 0 ? 'danger' : days <= 30 ? 'warning' : 'info'
      addAlert({
        type: 'Hết hạn',
        severity,
        title: `${batch.productName} sắp hết hạn`,
        message: `Lô ${batch.batchNo} sẽ hết hạn vào ngày ${batch.expiryDate}`,
        productId: batch.productId,
        batchId: batch.id,
        daysLeft: days
      })
    }
  }

  return {
    alerts,
    unreadAlerts,
    criticalAlerts,
    warningAlerts,
    expirySoonAlerts,
    outOfStockAlerts,
    lowStockAlerts,
    recentUnreadAlerts,
    unresolvedRecentAlerts,
    fetchAlerts,
    resolveAlertAPI,
    addAlert,
    markAsRead,
    markAsUnread,
    markAllAsRead,
    updateAlertStatus,
    deleteAlert,
    deleteAllReadAlerts,
    createExpiryAlert
  }
})
