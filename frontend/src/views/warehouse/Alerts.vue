<template>
  <WarehouseSidebar
    title="Cảnh báo kho"
    subtitle="Xem và xử lý các cảnh báo từ warehouse_alerts"
    :show-page-head="false"
  >
    <div class="alerts-page">
      <header class="alerts-header">
        <div class="header-left">
          <span class="header-icon" aria-hidden="true">🔔</span>
          <div>
            <h1>Cảnh báo kho</h1>
            <p>Xem và xử lý các cảnh báo từ warehouse_alerts</p>
          </div>
          <span class="header-badge">{{ stats.total_unresolved }} chưa xử lý</span>
        </div>

        <button
          v-if="stats.total_unresolved > 0"
          class="btn btn-primary"
          :disabled="processingAll"
          @click="resolveAllAlerts"
        >
          {{ processingAll ? 'Đang xử lý...' : 'Xử lý tất cả' }}
        </button>
      </header>

      <section class="quick-stats">
        <article class="quick-card low-stock">
          <div class="quick-icon">⚠️</div>
          <div>
            <p>TỒN KHO THẤP</p>
            <strong>{{ stats.low_stock }}</strong>
          </div>
        </article>

        <article class="quick-card expiring-soon">
          <div class="quick-icon">🕐</div>
          <div>
            <p>SẮP HẾT HẠN</p>
            <strong>{{ stats.expiring_soon }}</strong>
          </div>
        </article>

        <article class="quick-card expired">
          <div class="quick-icon">💀</div>
          <div>
            <p>HẾT HẠN</p>
            <strong>{{ stats.expired }}</strong>
          </div>
        </article>
      </section>

      <section class="filter-bar">
        <select v-model="filters.type" class="filter-input">
          <option value="all">Tất cả</option>
          <option value="low_stock">Tồn kho thấp</option>
          <option value="expiring_soon">Sắp hết hạn</option>
          <option value="expired">Hết hạn</option>
        </select>

        <select v-model="filters.status" class="filter-input">
          <option value="all">Tất cả trạng thái</option>
          <option value="unresolved">Chưa xử lý</option>
          <option value="resolved">Đã xử lý</option>
        </select>

        <input
          v-model="filters.search"
          type="search"
          class="filter-input search"
          placeholder="Tìm theo sản phẩm hoặc nội dung..."
        >

        <button class="btn btn-primary" @click="applyFilters">Lọc</button>
        <button class="btn btn-muted" @click="resetFilters">Đặt lại</button>
      </section>

      <div v-if="loading" class="loading-wrap">
        <span class="spinner"></span>
        <p>Đang tải cảnh báo...</p>
      </div>

      <section v-else>
        <div v-if="paginatedAlerts.length === 0" class="empty-state">
          Không có cảnh báo phù hợp.
        </div>

        <div v-else class="alerts-grid">
          <article
            v-for="item in paginatedAlerts"
            :key="item.id"
            class="alert-card"
            :class="themeClass(item.alert_type)"
          >
            <div class="card-top">
              <div class="card-title-wrap">
                <span class="card-icon" :class="themeClass(item.alert_type)">{{ typeIcon(item.alert_type) }}</span>
                <h3>{{ item.product_name }}</h3>
              </div>

              <span class="type-badge" :class="themeClass(item.alert_type)">
                {{ typeLabel(item.alert_type) }}
              </span>
            </div>

            <p class="message">{{ item.message }}</p>

            <div class="meta-block">
              <p>📅 {{ formatDateTime(item.created_at) }}</p>
              <p>👤 Người tạo: {{ item.created_by_name || 'Hệ thống' }}</p>
            </div>

            <div class="card-footer">
              <button
                v-if="!item.is_resolved"
                class="btn btn-resolve"
                :disabled="resolvingIds.has(item.id)"
                @click="resolveAlert(item.id)"
              >
                {{ resolvingIds.has(item.id) ? 'Đang xử lý...' : 'XỬ LÝ' }}
              </button>

              <div v-else class="resolved-box">
                Đã xử lý bởi {{ item.resolved_by_name || 'Hệ thống' }} vào {{ formatDateTime(item.resolved_at) }}
              </div>
            </div>
          </article>
        </div>

        <div class="pagination-wrap">
          <p>Hiển thị {{ paginatedAlerts.length }} trên {{ totalItems }} cảnh báo</p>

          <div class="pagination-actions">
            <label>
              <span>Dòng/trang</span>
              <select v-model.number="pagination.pageSize" @change="onPageSizeChange">
                <option v-for="size in pageSizeOptions" :key="size" :value="size">{{ size }}</option>
              </select>
            </label>

            <button class="btn btn-muted" :disabled="pagination.page <= 1" @click="prevPage">Trước</button>
            <button class="btn btn-muted" :disabled="pagination.page >= totalPages" @click="nextPage">Sau</button>
          </div>
        </div>
      </section>
    </div>
  </WarehouseSidebar>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import WarehouseSidebar from '@/components/warehouse/Sidebar.vue'
import { warehouseApi } from '@/api/warehouse'

const loading = ref(false)
const processingAll = ref(false)
const resolvingIds = ref(new Set())

const pageSizeOptions = [6, 12, 24]

const filters = reactive({
  type: 'all',
  status: 'all',
  search: ''
})

const pagination = reactive({
  page: 1,
  pageSize: 6
})

const allAlerts = ref([])
const filteredAlerts = ref([])

const totalItems = computed(() => filteredAlerts.value.length)
const totalPages = computed(() => Math.max(1, Math.ceil(totalItems.value / pagination.pageSize)))

const paginatedAlerts = computed(() => {
  const start = (pagination.page - 1) * pagination.pageSize
  return filteredAlerts.value.slice(start, start + pagination.pageSize)
})

const stats = computed(() => {
  const unresolved = allAlerts.value.filter((item) => !item.is_resolved)
  return {
    low_stock: unresolved.filter((item) => item.alert_type === 'low_stock').length,
    expiring_soon: unresolved.filter((item) => item.alert_type === 'expiring_soon').length,
    expired: unresolved.filter((item) => item.alert_type === 'expired').length,
    total_unresolved: unresolved.length
  }
})

const parseDate = (value) => new Date(String(value || '').replace(' ', 'T'))

const formatDateTime = (value) => {
  if (!value) return '-'
  const d = parseDate(value)
  if (Number.isNaN(d.getTime())) return '-'

  const dd = String(d.getDate()).padStart(2, '0')
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const yyyy = d.getFullYear()
  const hh = String(d.getHours()).padStart(2, '0')
  const min = String(d.getMinutes()).padStart(2, '0')
  return `${dd}/${mm}/${yyyy} ${hh}:${min}`
}

const typeIcon = (type) => {
  if (type === 'low_stock') return '⚠️'
  if (type === 'expiring_soon') return '🕐'
  return '💀'
}

const typeLabel = (type) => {
  if (type === 'low_stock') return 'TỒN KHO THẤP'
  if (type === 'expiring_soon') return 'SẮP HẾT HẠN'
  return 'HẾT HẠN'
}

const themeClass = (type) => {
  if (type === 'low_stock') return 'low-stock'
  if (type === 'expiring_soon') return 'expiring-soon'
  return 'expired'
}

const fetchAlerts = async () => {
  loading.value = true

  try {
    const result = await warehouseApi.getAlerts({
      page: pagination.page,
      pageSize: pagination.pageSize,
      type: filters.type,
      status: filters.status
    })

    allAlerts.value = (result.data || []).map((item) => ({
      ...item,
      is_resolved: Boolean(item.is_resolved),
      product_name: item.product_name || item.product?.name || 'N/A'
    }))

    filterAlerts()
  } finally {
    loading.value = false
  }
}

const filterAlerts = () => {
  const keyword = filters.search.trim().toLowerCase()

  filteredAlerts.value = allAlerts.value.filter((item) => {
    const byType = filters.type === 'all' || item.alert_type === filters.type

    const byStatus =
      filters.status === 'all' ||
      (filters.status === 'unresolved' && !item.is_resolved) ||
      (filters.status === 'resolved' && item.is_resolved)

    const bySearch =
      !keyword ||
      [item.product_name, item.message]
        .join(' ')
        .toLowerCase()
        .includes(keyword)

    return byType && byStatus && bySearch
  })

  pagination.page = 1
}

const applyFilters = () => {
  filterAlerts()
}

const resetFilters = () => {
  filters.type = 'all'
  filters.status = 'all'
  filters.search = ''
  filterAlerts()
}

const resolveAlert = async (id) => {
  const set = new Set(resolvingIds.value)
  set.add(id)
  resolvingIds.value = set

  try {
    await warehouseApi.resolveAlert(id)
    allAlerts.value = allAlerts.value.map((item) =>
      item.id === id ? { ...item, is_resolved: true, resolved_at: new Date().toISOString() } : item
    )

    filterAlerts()
  } finally {
    const next = new Set(resolvingIds.value)
    next.delete(id)
    resolvingIds.value = next
  }
}

const resolveAllAlerts = async () => {
  if (stats.value.total_unresolved <= 0) return

  const ok = window.confirm('Xác nhận xử lý tất cả cảnh báo?')
  if (!ok) return

  processingAll.value = true
  try {
    const unresolvedIds = allAlerts.value.filter((item) => !item.is_resolved).map((item) => item.id)
    await Promise.all(unresolvedIds.map((id) => warehouseApi.resolveAlert(id)))
    allAlerts.value = allAlerts.value.map((item) =>
      item.is_resolved ? item : { ...item, is_resolved: true, resolved_at: new Date().toISOString() }
    )

    filterAlerts()
  } finally {
    processingAll.value = false
  }
}

const prevPage = () => {
  if (pagination.page > 1) pagination.page -= 1
}

const nextPage = () => {
  if (pagination.page < totalPages.value) pagination.page += 1
}

const onPageSizeChange = () => {
  pagination.page = 1
}

onMounted(fetchAlerts)
</script>

<style scoped>
.alerts-page {
  background: #f0f2f6;
  border-radius: 18px;
  padding: 18px;
}

.alerts-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 14px;
  flex-wrap: wrap;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.header-icon {
  width: 42px;
  height: 42px;
  border-radius: 12px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: #eaf2ff;
  font-size: 20px;
}

.header-left h1 {
  margin: 0;
  font-size: 28px;
  color: #1e3a8a;
}

.header-left p {
  margin: 4px 0 0;
  color: #64748b;
  font-size: 14px;
}

.header-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 999px;
  padding: 6px 10px;
  font-size: 12px;
  font-weight: 800;
  background: #fee2e2;
  color: #b91c1c;
}

.quick-stats {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
  margin-bottom: 14px;
}

.quick-card {
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 8px 20px rgba(15, 23, 42, 0.06);
  border: 1px solid #e2e8f0;
  padding: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  text-align: center;
}

.quick-card .quick-icon {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  background: #fff;
}

.quick-card > div {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.quick-card p {
  margin: 0;
  font-size: 12px;
  color: #64748b;
  font-weight: 700;
}

.quick-card strong {
  display: block;
  margin-top: 4px;
  font-size: 28px;
  color: #0f172a;
}

.quick-card.low-stock .quick-icon {
  color: #f59e0b;
}

.quick-card.expiring-soon .quick-icon {
  color: #eab308;
}

.quick-card.expired .quick-icon {
  color: #ef4444;
}

.filter-bar {
  display: grid;
  grid-template-columns: 0.9fr 0.9fr 1.3fr auto auto;
  gap: 10px;
  margin-bottom: 14px;
}

.filter-input {
  border: 1px solid #d6dee9;
  background: #fff;
  border-radius: 10px;
  padding: 10px 12px;
  font-size: 13px;
}

.btn {
  border: none;
  border-radius: 10px;
  padding: 10px 14px;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
}

.btn:disabled {
  opacity: 0.65;
  cursor: not-allowed;
}

.btn-primary {
  background: #3b82f6;
  color: #fff;
}

.btn-muted {
  background: #e5e7eb;
  color: #334155;
}

.btn-resolve {
  width: 100%;
  background: #10b981;
  color: #fff;
}

.loading-wrap {
  min-height: 220px;
  border-radius: 16px;
  background: #fff;
  border: 1px solid #e2e8f0;
  display: grid;
  place-items: center;
  color: #64748b;
}

.spinner {
  display: inline-block;
  width: 18px;
  height: 18px;
  border: 2px solid #bfdbfe;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  margin-right: 8px;
  vertical-align: -3px;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.empty-state {
  background: #fff;
  border: 1px dashed #cbd5e1;
  border-radius: 14px;
  padding: 18px;
  text-align: center;
  color: #64748b;
}

.alerts-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
}

.alert-card {
  border-radius: 16px;
  border-left: 6px solid transparent;
  padding: 14px;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.alert-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 12px 24px rgba(15, 23, 42, 0.12);
}

.alert-card.low-stock {
  background: #fffbeb;
  border-left-color: #f59e0b;
}

.alert-card.expiring-soon {
  background: #fef3c7;
  border-left-color: #eab308;
}

.alert-card.expired {
  background: #fef2f2;
  border-left-color: #ef4444;
}

.card-top {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 8px;
}

.card-title-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
}

.card-icon {
  font-size: 18px;
}

.card-top h3 {
  margin: 0;
  font-size: 16px;
  color: #0f172a;
}

.type-badge {
  border-radius: 999px;
  padding: 4px 8px;
  font-size: 10px;
  font-weight: 800;
  white-space: nowrap;
}

.type-badge.low-stock {
  background: #fed7aa;
  color: #c2410c;
}

.type-badge.expiring-soon {
  background: #fde68a;
  color: #a16207;
}

.type-badge.expired {
  background: #fecaca;
  color: #b91c1c;
}

.message {
  margin: 10px 0;
  color: #475569;
  font-size: 14px;
  line-height: 1.5;
}

.meta-block {
  border-top: 1px solid rgba(148, 163, 184, 0.25);
  padding-top: 8px;
  margin-top: 8px;
}

.meta-block p {
  margin: 4px 0;
  font-size: 12px;
  color: #64748b;
}

.card-footer {
  margin-top: 10px;
}

.resolved-box {
  border-radius: 10px;
  background: #dcfce7;
  color: #166534;
  font-size: 12px;
  font-weight: 700;
  padding: 10px;
}

.pagination-wrap {
  margin-top: 14px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  flex-wrap: wrap;
}

.pagination-wrap p {
  margin: 0;
  color: #64748b;
  font-size: 13px;
}

.pagination-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.pagination-actions label {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #64748b;
}

.pagination-actions select {
  border: 1px solid #d6dee9;
  border-radius: 8px;
  padding: 6px 8px;
  font-size: 12px;
}

@media (max-width: 1200px) {
  .alerts-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .filter-bar {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 760px) {
  .quick-stats {
    grid-template-columns: 1fr;
  }

  .alerts-grid {
    grid-template-columns: 1fr;
  }

  .filter-bar {
    grid-template-columns: 1fr;
  }

  .alerts-page {
    padding: 12px;
  }

  .header-left h1 {
    font-size: 24px;
  }
}
</style>