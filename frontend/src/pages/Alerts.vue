<template>
  <div class="alerts-page">
    <!-- Page Header -->
    <div class="page-header">
      <div>
        <h1>Quản lý cảnh báo</h1>
        <p class="breadcrumb">Nhà thuốc Da liễu / Cảnh báo</p>
      </div>
      <button class="btn btn-secondary" @click="markAllAsRead">✓ Đánh dấu tất cả đã xem</button>
    </div>

    <!-- Statistics -->
    <div class="stats-grid">
      <div class="stat-card critical">
        <p class="stat-label">Nguy hiểm</p>
        <p class="stat-value">{{ criticalAlerts }}</p>
      </div>
      <div class="stat-card warning">
        <p class="stat-label">Cảnh báo</p>
        <p class="stat-value">{{ warningAlerts }}</p>
      </div>
      <div class="stat-card info">
        <p class="stat-label">Thông tin</p>
        <p class="stat-value">{{ unreadAlerts }}</p>
      </div>
      <div class="stat-card">
        <p class="stat-label">Tất cả cảnh báo</p>
        <p class="stat-value">{{ alerts.length }}</p>
      </div>
    </div>

    <!-- Filter -->
    <div class="filters">
      <button 
        @click="filterType = 'all'" 
        :class="{ active: filterType === 'all' }"
        class="filter-btn"
      >
        Tất cả
      </button>
      <button 
        @click="filterType = 'Hết hạn'" 
        :class="{ active: filterType === 'Hết hạn' }"
        class="filter-btn"
      >
        Hết hạn
      </button>
      <button 
        @click="filterType = 'Hết hàng'" 
        :class="{ active: filterType === 'Hết hàng' }"
        class="filter-btn"
      >
        Hết hàng
      </button>
      <button 
        @click="filterType = 'Tồn kho thấp'" 
        :class="{ active: filterType === 'Tồn kho thấp' }"
        class="filter-btn"
      >
        Tồn kho thấp
      </button>
    </div>

    <!-- Alerts List -->
    <div class="alerts-list">
      <div 
        v-for="alert in filteredAlerts" 
        :key="alert.id"
        class="alert-card"
        :class="[`alert-${alert.severity}`, { unread: !alert.isRead }]"
      >
        <div class="alert-header">
          <div class="alert-title-section">
            <span class="alert-badge" :class="`badge-${alert.severity}`">
              {{ alert.type }}
            </span>
            <h3 class="alert-title">{{ alert.title }}</h3>
          </div>
          <div class="alert-metadata">
            <p class="alert-time">{{ getTimeAgo(alert.createdAt) }}</p>
            <span class="alert-status" :class="`status-${alert.status.toLowerCase()}`">
              {{ alert.status }}
            </span>
          </div>
        </div>

        <p class="alert-message">{{ alert.message }}</p>

        <div class="alert-footer">
          <button 
            v-if="!alert.isRead"
            @click="markAsRead(alert.id)"
            class="btn btn-sm btn-primary"
          >
            ✓ Đánh dấu đã xem
          </button>
          <button 
            @click="updateStatus(alert.id, 'Đã xử lý')"
            v-if="alert.status === 'Chưa xử lý'"
            class="btn btn-sm btn-success"
          >
            ✓ Đánh dấu xử lý
          </button>
          <button 
            @click="deleteAlert(alert.id)"
            class="btn btn-sm btn-danger"
          >
            <span class="btn-icon" v-html="getDeleteIcon()"></span>
            <span>Xóa</span>
          </button>
        </div>
      </div>

      <div v-if="filteredAlerts.length === 0" class="empty-state">
        <p>Không có cảnh báo nào</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAlertStore } from '@/stores/alerts'

const alertStore = useAlertStore()
const filterType = ref('all')

const alerts = computed(() => alertStore.alerts)
const criticalAlerts = computed(() => alertStore.criticalAlerts)
const warningAlerts = computed(() => alertStore.warningAlerts)
const unreadAlerts = computed(() => alertStore.unreadAlerts)

const filteredAlerts = computed(() => {
  if (filterType.value === 'all') {
    return alerts.value
  }
  return alerts.value.filter(a => a.type === filterType.value)
})

const getTimeAgo = (date) => {
  const now = new Date()
  const time = new Date(date)
  const diff = Math.floor((now - time) / 1000)
  
  if (diff < 60) return 'Vừa xong'
  if (diff < 3600) return `${Math.floor(diff / 60)} phút trước`
  if (diff < 86400) return `${Math.floor(diff / 3600)} giờ trước`
  if (diff < 604800) return `${Math.floor(diff / 86400)} ngày trước`
  return date
}

const markAsRead = (id) => {
  alertStore.markAsRead(id)
}

const markAllAsRead = () => {
  alertStore.markAllAsRead()
}

const updateStatus = async (id, status) => {
  if (status !== 'Đã xử lý') {
    return
  }
  await alertStore.resolveAlertAPI(id)
}

const deleteAlert = (id) => {
  alertStore.deleteAlert(id)
}

const getDeleteIcon = () => `
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path d="M5 7h14" />
    <path d="M9 7V5.6c0-.9.7-1.6 1.6-1.6h2.8c.9 0 1.6.7 1.6 1.6V7" />
    <path d="M8 7l.6 11.2c0 .9.7 1.6 1.6 1.6h3.6c.9 0 1.6-.7 1.6-1.6L16 7" />
    <path d="M10 11v4" />
    <path d="M14 11v4" />
  </svg>
`

onMounted(async () => {
  await alertStore.fetchAlerts()
})
</script>

<style scoped>
.alerts-page {
  animation: fadeIn 0.3s ease;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

/* Page Header */
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 24px;
}

.page-header h1 {
  font-size: 28px;
  font-weight: 700;
  color: #1e3a8a;
  margin: 0 0 8px 0;
}

.breadcrumb {
  color: #64748b;
  font-size: 13px;
  margin: 0;
}

/* Statistics */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

.stat-card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 16px;
  text-align: center;
  transition: all 0.3s ease;
}

.stat-card.critical {
  border-color: #fecaca;
  background: #fef2f2;
}

.stat-card.warning {
  border-color: #fcd34d;
  background: #fffbeb;
}

.stat-card.info {
  border-color: #bfdbfe;
  background: #eff6ff;
}

.stat-card:hover {
  border-color: #1e3a8a;
  box-shadow: 0 4px 12px rgba(30, 58, 138, 0.1);
}

.stat-label {
  font-size: 12px;
  font-weight: 600;
  color: #64748b;
  text-transform: uppercase;
  margin: 0 0 8px 0;
  letter-spacing: 0.5px;
}

.stat-value {
  font-size: 26px;
  font-weight: 700;
  color: #1e3a8a;
  margin: 0;
}

/* Filters */
.filters {
  display: flex;
  gap: 12px;
  margin-bottom: 24px;
}

.filter-btn {
  padding: 8px 16px;
  border: 1px solid #e2e8f0;
  background: white;
  border-radius: 6px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
  color: #475569;
  transition: all 0.3s ease;
}

.filter-btn:hover {
  border-color: #1e3a8a;
  background: #f0f4f8;
  color: #1e3a8a;
}

.filter-btn.active {
  background: #1e3a8a;
  color: white;
  border-color: #1e3a8a;
}

/* Alerts List */
.alerts-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.btn-danger {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.btn-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.btn-icon :deep(svg) {
  width: 14px;
  height: 14px;
}

.alert-card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 20px;
  transition: all 0.3s ease;
  border-left: 4px solid #1e3a8a;
}

.alert-card.alert-danger {
  border-left-color: #ef4444;
}

.alert-card.alert-warning {
  border-left-color: #f59e0b;
}

.alert-card.alert-info {
  border-left-color: #3b82f6;
}

.alert-card.unread {
  background: #f8fafc;
  box-shadow: 0 2px 8px rgba(30, 58, 138, 0.1);
}

.alert-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.alert-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 12px;
}

.alert-title-section {
  display: flex;
  align-items: center;
  gap: 12px;
}

.alert-badge {
  padding: 4px 10px;
  border-radius: 4px;
  font-weight: 600;
  font-size: 11px;
  text-transform: uppercase;
  white-space: nowrap;
}

.badge-danger {
  background: #fee2e2;
  color: #991b1b;
}

.badge-warning {
  background: #fef3c7;
  color: #92400e;
}

.badge-info {
  background: #dbeafe;
  color: #0c4a6e;
}

.alert-title {
  font-size: 16px;
  font-weight: 600;
  color: #1e3a8a;
  margin: 0;
}

.alert-metadata {
  display: flex;
  gap: 12px;
  align-items: center;
}

.alert-time {
  font-size: 12px;
  color: #64748b;
  margin: 0;
}

.alert-status {
  padding: 4px 10px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
}

.status-chưa-xử-lý {
  background: #fef3c7;
  color: #92400e;
}

.status-đã-xử-lý {
  background: #d1fae5;
  color: #065f46;
}

.status-không-cần-xử-lý {
  background: #e0e7ff;
  color: #3730a3;
}

.alert-message {
  color: #475569;
  line-height: 1.6;
  margin: 0 0 16px 0;
  font-size: 13px;
}

.alert-footer {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

/* Buttons */
.btn {
  padding: 8px 16px;
  border-radius: 6px;
  border: none;
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.3s ease;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.btn-sm {
  padding: 6px 12px;
  font-size: 12px;
}

.btn-primary {
  background: #1e3a8a;
  color: white;
}

.btn-primary:hover {
  background: #1e40af;
  box-shadow: 0 2px 8px rgba(30, 58, 138, 0.3);
}

.btn-success {
  background: #059669;
  color: white;
}

.btn-success:hover {
  background: #047857;
}

.btn-danger {
  background: #ef4444;
  color: white;
}

.btn-danger:hover {
  background: #dc2626;
}

.btn-secondary {
  background: #f1f5f9;
  color: #475569;
  border: 1px solid #e2e8f0;
}

.btn-secondary:hover {
  background: #e2e8f0;
  border-color: #cbd5e1;
}

/* Empty State */
.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #64748b;
  font-size: 14px;
}

/* Responsive */
@media (max-width: 1024px) {
  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .alert-header {
    flex-direction: column;
    gap: 12px;
  }
}

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
    gap: 16px;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }

  .filters {
    flex-wrap: wrap;
  }

  .filter-btn {
    flex: 1;
    min-width: 100px;
  }
}
</style>
