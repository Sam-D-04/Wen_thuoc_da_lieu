import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

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
