<template>
  <WarehouseSidebar title="Warehouse Dashboard" subtitle="Tổng quan kho nhà thuốc Da Liễu">
    <template #actions>
      <button class="refresh-btn topbar-refresh" type="button" @click="loadDashboard" :disabled="loading">
        <span class="refresh-icon" :class="{ spinning: loading }" v-html="icons.refresh"></span>
        <span>{{ loading ? 'Đang tải...' : 'Refresh' }}</span>
      </button>
    </template>

    <div class="warehouse-dashboard">
      <section v-if="error" class="error-banner">
        <span>{{ error }}</span>
        <button class="refresh-btn small" type="button" @click="loadDashboard">Thử lại</button>
      </section>

      <div v-if="loading && !hasLoadedOnce" class="loading-state">
        <div class="spinner"></div>
        <p>Đang tải dữ liệu kho...</p>
      </div>

      <template v-else>
        <section class="card-grid four-cols">
          <article class="metric-card blue">
            <div class="metric-icon" v-html="icons.box"></div>
            <div class="metric-copy">
              <strong>{{ dashboardStats.products }}</strong>
              <span>Sản phẩm</span>
            </div>
          </article>

          <article class="metric-card purple">
            <div class="metric-icon" v-html="icons.batch"></div>
            <div class="metric-copy">
              <strong>{{ dashboardStats.batches }}</strong>
              <span>Lô hàng</span>
            </div>
          </article>

          <article class="metric-card green">
            <div class="metric-icon" v-html="icons.trend"></div>
            <div class="metric-copy">
              <strong>{{ formatCurrency(dashboardStats.inventoryValue) }}</strong>
              <span>Tồn kho</span>
            </div>
          </article>

          <article class="metric-card orange">
            <div class="metric-icon" v-html="icons.bell"></div>
            <div class="metric-copy">
              <strong>{{ dashboardStats.alerts }}</strong>
              <span>Cảnh báo</span>
            </div>
          </article>
        </section>

        <section class="card-grid three-cols secondary-row">
          <article class="metric-card neutral">
            <div class="metric-icon small" v-html="icons.block"></div>
            <div class="metric-copy">
              <strong>{{ dashboardStats.totalBatches }}</strong>
              <span>Tổng lô hàng</span>
            </div>
          </article>

          <article class="metric-card green">
            <div class="metric-icon small" v-html="icons.box"></div>
            <div class="metric-copy">
              <strong>{{ dashboardStats.products }}</strong>
              <span>Số lượng sản phẩm</span>
            </div>
          </article>

          <article class="metric-card orange">
            <div class="metric-icon small" v-html="icons.clock"></div>
            <div class="metric-copy">
              <strong>{{ dashboardStats.expiringSoon }}</strong>
              <span>Lô sắp hết hạn</span>
            </div>
          </article>
        </section>

        <section class="alert-panel">
          <div class="panel-header">
            <div class="panel-title-wrap">
              <h2>Cảnh báo kho</h2>
              <span class="badge badge-danger">{{ dashboardStats.alerts }}</span>
            </div>
            <button class="view-all-btn" type="button" @click="goTo('/warehouse/alerts')">Xem tất cả</button>
          </div>

          <div class="alert-list">
            <article
              v-for="item in alerts"
              :key="item.id"
              class="alert-item"
              :class="item.theme"
            >
              <div class="alert-left">
                <span class="alert-icon" :class="item.theme" v-html="item.icon"></span>
                <div class="alert-text">
                  <h3>{{ item.title }}</h3>
                  <p>{{ item.message }}</p>
                </div>
              </div>

              <div class="alert-right">
                <span class="status-tag" :class="item.tagClass">{{ item.tag }}</span>
                <button class="handle-btn" type="button" @click="goTo('/warehouse/alerts')">Xử lý</button>
              </div>
            </article>
          </div>
        </section>

        <section class="activity-panel">
          <div class="panel-header">
            <div class="panel-title-wrap">
              <h2>Hoạt động gần đây</h2>
            </div>
            <span class="activity-count">+{{ totalActivities }}</span>
          </div>

          <div class="activity-timeline">
            <article v-for="item in recentActivities" :key="item.id" class="timeline-item">
              <div class="timeline-marker">
                <span class="marker-dot" :class="item.type"></span>
              </div>
              <div class="timeline-content">
                <p class="activity-title">{{ item.title }}</p>
                <p class="activity-desc">{{ item.description }}</p>
                <time class="activity-time">{{ item.time }}</time>
              </div>
            </article>
          </div>
        </section>

        <section class="quick-actions-grid">
          <button class="quick-action-btn" type="button" @click="goTo('/warehouse/products')">
            <span class="quick-icon" v-html="icons.medical"></span>
            <span>Quản lý sản phẩm</span>
          </button>

          <button class="quick-action-btn" type="button" @click="goTo('/warehouse/batches')">
            <span class="quick-icon" v-html="icons.box"></span>
            <span>Nhập kho</span>
          </button>

          <button class="quick-action-btn" type="button" @click="goTo('/warehouse/inventory')">
            <span class="quick-icon" v-html="icons.chart"></span>
            <span>Kiểm kho</span>
          </button>

          <button class="quick-action-btn" type="button" @click="goTo('/warehouse/alerts')">
            <span class="quick-icon" v-html="icons.download"></span>
            <span>Cảnh báo</span>
          </button>
        </section>
      </template>
    </div>
  </WarehouseSidebar>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import WarehouseSidebar from '@/components/warehouse/Sidebar.vue'
import { warehouseApi } from '@/api/warehouse'

const loading = ref(false)
const error = ref('')
const hasLoadedOnce = ref(false)
const router = useRouter()

const todayDisplay = computed(() => {
  const today = new Date()
  return new Intl.DateTimeFormat('vi-VN', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric'
  }).format(today)
})

const dashboardStats = reactive({
  products: 0,
  batches: 0,
  inventoryValue: 0,
  alerts: 0,
  totalBatches: 0,
  expiringSoon: 0
})

const alerts = ref([])
const totalActivities = ref(0)
const recentActivities = ref([])

const icons = {
  warehouse: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M4 10.5 12 5l8 5.5" />
      <path d="M5 10v9h14v-9" />
      <path d="M9 19v-5h6v5" />
    </svg>
  `,
  refresh: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M20 12a8 8 0 0 1-13.7 5.7" />
      <path d="M6 12a8 8 0 0 1 13.7-5.7" />
      <path d="M20 7v5h-5" />
      <path d="M4 17v-5h5" />
    </svg>
  `,
  box: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M4 7.5 12 4l8 3.5-8 3.5-8-3.5Z" />
      <path d="M4 7.5V16l8 3.5 8-3.5V7.5" />
      <path d="M12 11v8" />
    </svg>
  `,
  batch: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M5 8.5 12 5l7 3.5-7 3.5-7-3.5Z" />
      <path d="M5 8.5V16l7 3.5 7-3.5V8.5" />
      <path d="M9 12.2v2.8" />
      <path d="M15 11.2V16" />
    </svg>
  `,
  trend: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M4 18.5h16" />
      <path d="M7 14.5 11 10l3 3 5-6" />
      <path d="M17 7h2v2" />
    </svg>
  `,
  bell: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M6.5 16.5h11l-1-1.4V11a4.5 4.5 0 0 0-9 0v4.1l-1 1.4Z" />
      <path d="M10 18.5a2 2 0 0 0 4 0" />
    </svg>
  `,
  block: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M4 8.5 12 4l8 4.5-8 4.5-8-4.5Z" />
      <path d="M4 8.5V16l8 4.5 8-4.5V8.5" />
    </svg>
  `,
  clock: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <circle cx="12" cy="12" r="8" />
      <path d="M12 8v4l3 2" />
    </svg>
  `,
  medical: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M8.2 15.8 15.8 8.2" />
      <path d="M6.5 6.5a4 4 0 0 1 5.7 0l5.3 5.3a4 4 0 0 1-5.7 5.7l-5.3-5.3a4 4 0 0 1 0-5.7Z" />
    </svg>
  `,
  chart: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M4 19.5h16" />
      <path d="M7 16v-5" />
      <path d="M12 16V8.5" />
      <path d="M17 16V5.5" />
    </svg>
  `,
  download: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M12 4.5v10" />
      <path d="M8.5 11.5 12 15l3.5-3.5" />
      <path d="M5 18h14" />
    </svg>
  `,
  warning: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M12 4.5 4.7 18h14.6L12 4.5Z" />
      <path d="M12 9v4" />
      <circle cx="12" cy="16.4" r="1" fill="currentColor" stroke="none" />
    </svg>
  `
}

const goTo = (path) => {
  router.push(path)
}

const formatCurrency = (value) =>
  new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
    minimumFractionDigits: 0
  }).format(Number(value || 0))

const loadDashboard = async () => {
  loading.value = true
  error.value = ''

  try {
    const [dashboard, alertResult] = await Promise.all([
      warehouseApi.getDashboard(),
      warehouseApi.getAlerts({ page: 1, pageSize: 5 })
    ])

    dashboardStats.products = Number(dashboard.total_products || 0)
    dashboardStats.batches = Number(dashboard.total_batches || 0)
    dashboardStats.inventoryValue = Number(dashboard.inventory_value || 0)
    dashboardStats.alerts = Number(
      (dashboard.alerts_summary?.low_stock || 0) +
      (dashboard.alerts_summary?.expiring_soon || 0) +
      (dashboard.alerts_summary?.expired || 0)
    )
    dashboardStats.totalBatches = Number(dashboard.total_batches || 0)
    dashboardStats.expiringSoon = Number(dashboard.expiring_batches || 0)

    alerts.value = (alertResult.data || []).map((item) => ({
      id: item.id,
      theme: item.alert_type === 'expired' ? 'danger' : item.alert_type === 'low_stock' ? 'orange' : 'warning',
      title: item.product_name || item.product?.name || 'Cảnh báo kho',
      message: item.message || '',
      tag: item.alert_type === 'expired' ? 'HẾT HẠN' : item.alert_type === 'low_stock' ? 'TỒN KHO THẤP' : 'SẮP HẾT HẠN',
      tagClass: item.alert_type === 'expired' ? 'red' : item.alert_type === 'low_stock' ? 'orange' : 'yellow',
      icon: icons.warning
    }))

    recentActivities.value = []
    totalActivities.value = 0
    hasLoadedOnce.value = true
  } catch (err) {
    error.value = err?.message || 'Không tải được dashboard.'
  } finally {
    loading.value = false
  }
}

onMounted(loadDashboard)
</script>

<style scoped>
.warehouse-dashboard {
  min-height: 100%;
  background: transparent;
  border-radius: 0;
  padding: 0;
}

.topbar-refresh {
  white-space: nowrap;
}

.refresh-btn {
  border: none;
  border-radius: 16px;
  background: #3b82f6;
  color: #fff;
  padding: 12px 16px;
  display: inline-flex;
  align-items: center;
  gap: 10px;
  font-weight: 700;
  cursor: pointer;
  box-shadow: 0 12px 24px rgba(59, 130, 246, 0.22);
  transition: transform 0.2s ease, box-shadow 0.2s ease, background 0.2s ease;
}

.refresh-btn:hover {
  transform: translateY(-1px);
  background: #2563eb;
  box-shadow: 0 14px 28px rgba(59, 130, 246, 0.28);
}

.refresh-btn:disabled {
  cursor: progress;
  opacity: 0.92;
}

.refresh-btn.small {
  padding: 10px 14px;
  border-radius: 14px;
}

.refresh-icon {
  width: 18px;
  height: 18px;
  display: inline-flex;
}

.refresh-icon :deep(svg) {
  width: 18px;
  height: 18px;
}

.refresh-icon.spinning {
  animation: spin 0.9s linear infinite;
}

.error-banner {
  border: 1px solid #fecaca;
  background: #fef2f2;
  color: #991b1b;
  border-radius: 16px;
  padding: 14px 16px;
  margin-bottom: 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.loading-state {
  min-height: 360px;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 20px;
  display: grid;
  place-items: center;
  gap: 12px;
  box-shadow: 0 10px 24px rgba(15, 23, 42, 0.05);
}

.loading-state p {
  margin: 0;
  color: #64748b;
  font-weight: 600;
}

.spinner {
  width: 46px;
  height: 46px;
  border-radius: 50%;
  border: 4px solid #dbeafe;
  border-top-color: #3b82f6;
  animation: spin 0.9s linear infinite;
}

.card-grid {
  display: grid;
  gap: 14px;
  margin-bottom: 14px;
}

.four-cols {
  grid-template-columns: repeat(4, minmax(0, 1fr));
}

.three-cols {
  grid-template-columns: repeat(3, minmax(0, 1fr));
}

.metric-card {
  background: #fff;
  border-radius: 18px;
  border: 1px solid #edf2f7;
  box-shadow: 0 10px 24px rgba(15, 23, 42, 0.06);
  padding: 16px 18px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 14px;
  text-align: center;
  transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease;
  min-height: 108px;
}

.metric-card:hover,
.alert-item:hover,
.quick-action-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 16px 32px rgba(15, 23, 42, 0.1);
}

.metric-icon {
  width: 54px;
  height: 54px;
  border-radius: 16px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex: 0 0 auto;
}

.metric-icon :deep(svg) {
  width: 26px;
  height: 26px;
}

.metric-icon.small {
  width: 50px;
  height: 50px;
}

.metric-copy {
  display: flex;
  flex-direction: column;
  gap: 4px;
  align-items: center;
}

.metric-copy strong {
  font-size: 30px;
  line-height: 1;
  color: #0f172a;
  letter-spacing: -0.02em;
}

.metric-copy span {
  color: #64748b;
  font-size: 14px;
  font-weight: 600;
}

.blue .metric-icon {
  background: #dbeafe;
  color: #3b82f6;
}

.purple .metric-icon {
  background: #ede9fe;
  color: #8b5cf6;
}

.green .metric-icon {
  background: #dcfce7;
  color: #22c55e;
}

.orange .metric-icon {
  background: #ffedd5;
  color: #f59e0b;
}

.neutral .metric-icon {
  background: #f1f5f9;
  color: #8b5cf6;
}

.alert-panel {
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 20px;
  box-shadow: 0 10px 24px rgba(15, 23, 42, 0.06);
  padding: 18px;
  margin-bottom: 14px;
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 16px;
}

.panel-title-wrap {
  display: flex;
  align-items: center;
  gap: 10px;
}

.panel-title-wrap h2 {
  margin: 0;
  font-size: 20px;
  color: #0f172a;
}

.badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 28px;
  height: 28px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 800;
  padding: 0 8px;
}

.badge-danger {
  background: #fee2e2;
  color: #b91c1c;
}

.view-all-btn {
  border: 1px solid #bfdbfe;
  background: #eff6ff;
  color: #1d4ed8;
  border-radius: 14px;
  padding: 10px 14px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s ease;
}

.view-all-btn:hover {
  background: #dbeafe;
  border-color: #93c5fd;
}

.alert-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.alert-item {
  border-radius: 18px;
  padding: 14px 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  border: 1px solid #e5e7eb;
  border-left-width: 6px;
  background: #fff;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.alert-item.warning {
  background: #fffbeb;
  border-left-color: #facc15;
}

.alert-item.orange {
  background: #fff7ed;
  border-left-color: #fb923c;
}

.alert-item.danger {
  background: #fef2f2;
  border-left-color: #ef4444;
}

.alert-left {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  min-width: 0;
}

.alert-icon {
  width: 40px;
  height: 40px;
  border-radius: 14px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex: 0 0 auto;
}

.alert-icon :deep(svg) {
  width: 20px;
  height: 20px;
}

.alert-icon.warning {
  background: #fef3c7;
  color: #ca8a04;
}

.alert-icon.orange {
  background: #fed7aa;
  color: #ea580c;
}

.alert-icon.danger {
  background: #fecaca;
  color: #dc2626;
}

.alert-text {
  min-width: 0;
}

.alert-text h3 {
  margin: 0;
  color: #0f172a;
  font-size: 16px;
  font-weight: 800;
}

.alert-text p {
  margin: 5px 0 0;
  color: #64748b;
  font-size: 13px;
}

.alert-right {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-shrink: 0;
}

.status-tag {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 999px;
  padding: 7px 12px;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.02em;
}

.status-tag.yellow {
  background: #fef3c7;
  color: #a16207;
}

.status-tag.orange {
  background: #fed7aa;
  color: #c2410c;
}

.status-tag.red {
  background: #fecaca;
  color: #b91c1c;
}

.handle-btn {
  border: none;
  background: #3b82f6;
  color: #fff;
  border-radius: 14px;
  padding: 10px 14px;
  font-weight: 800;
  cursor: pointer;
  transition: transform 0.2s ease, background 0.2s ease;
}

.handle-btn:hover {
  background: #2563eb;
}

.activity-panel {
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 20px;
  box-shadow: 0 10px 24px rgba(15, 23, 42, 0.06);
  padding: 18px;
  margin-bottom: 14px;
}

.activity-panel .panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 16px;
}

.activity-count {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 50px;
  height: 32px;
  border-radius: 999px;
  background: #f0f9ff;
  color: #0369a1;
  font-size: 14px;
  font-weight: 800;
  border: 1px solid #bae6fd;
}

.activity-timeline {
  display: flex;
  flex-direction: column;
  gap: 12px;
  position: relative;
}

.timeline-item {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 10px;
  border-radius: 14px;
  background: #fafbff;
  border: 1px solid #f0f4f8;
  transition: all 0.2s ease;
}

.timeline-item:hover {
  background: #f5f8ff;
  border-color: #dbeafe;
}

.timeline-marker {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: #f1f5f9;
  flex: 0 0 auto;
  position: relative;
}

.marker-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  display: block;
}

.marker-dot.export {
  background: #22c55e;
  box-shadow: 0 0 8px rgba(34, 197, 94, 0.4);
}

.marker-dot.import {
  background: #3b82f6;
  box-shadow: 0 0 8px rgba(59, 130, 246, 0.4);
}

.marker-dot.adjust {
  background: #f59e0b;
  box-shadow: 0 0 8px rgba(245, 158, 11, 0.4);
}

.marker-dot.alert {
  background: #ef4444;
  box-shadow: 0 0 8px rgba(239, 68, 68, 0.4);
}

.timeline-content {
  flex: 1;
  min-width: 0;
}

.activity-title {
  margin: 0;
  color: #0f172a;
  font-size: 14px;
  font-weight: 800;
}

.activity-desc {
  margin: 4px 0;
  color: #64748b;
  font-size: 13px;
}

.activity-time {
  display: block;
  color: #94a3b8;
  font-size: 12px;
  font-weight: 600;
}

.quick-actions-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 14px;
}

.quick-action-btn {
  border: 1px solid #e2e8f0;
  background: #fff;
  border-radius: 18px;
  padding: 16px;
  min-height: 96px;
  display: flex;
  align-items: center;
  gap: 12px;
  font-weight: 800;
  color: #1e293b;
  cursor: pointer;
  box-shadow: 0 10px 24px rgba(15, 23, 42, 0.06);
  transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease;
}

.quick-action-btn:hover {
  border-color: #bfdbfe;
}

.quick-icon {
  width: 46px;
  height: 46px;
  border-radius: 16px;
  background: #eff6ff;
  color: #3b82f6;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex: 0 0 auto;
}

.quick-icon :deep(svg) {
  width: 22px;
  height: 22px;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }

  to {
    transform: rotate(360deg);
  }
}

@media (max-width: 1200px) {
  .four-cols,
  .three-cols,
  .quick-actions-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 768px) {
  .warehouse-dashboard {
    padding: 14px;
    border-radius: 16px;
  }

  .dashboard-header {
    flex-direction: column;
    align-items: stretch;
  }

  .header-actions,
  .panel-header,
  .alert-item,
  .alert-right {
    flex-direction: column;
    align-items: stretch;
  }

  .title-row,
  .alert-left,
  .alert-right,
  .panel-title-wrap {
    align-items: flex-start;
  }

  .four-cols,
  .three-cols,
  .quick-actions-grid {
    grid-template-columns: 1fr;
  }

  .metric-card {
    min-height: auto;
  }

  .alert-right {
    width: 100%;
  }

  .status-tag,
  .handle-btn,
  .view-all-btn,
  .refresh-btn {
    width: 100%;
    justify-content: center;
  }

  .error-banner {
    flex-direction: column;
    align-items: stretch;
  }

  .metric-copy strong {
    font-size: 26px;
  }
}
</style>
