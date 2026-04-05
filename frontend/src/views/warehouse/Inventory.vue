<template>
  <WarehouseSidebar
    title="Quản lý tồn kho"
    subtitle="Theo dõi lịch sử nhập xuất tồn kho"
    :show-page-head="false"
  >
    <div class="inventory-page">
      <header class="inventory-header">
        <div class="title-wrap">
          <span class="title-icon" aria-hidden="true">📦</span>
          <div>
            <h1>Quản lý tồn kho</h1>
            <p>Theo dõi lịch sử nhập xuất tồn kho</p>
          </div>
        </div>
      </header>

      <section class="stats-grid">
        <article class="stat-card">
          <p>Tổng nhập</p>
          <strong class="value positive">+{{ stats.totalImport }}</strong>
        </article>
        <article class="stat-card">
          <p>Tổng xuất</p>
          <strong class="value negative">{{ stats.totalExport }}</strong>
        </article>
        <article class="stat-card">
          <p>Tồn kho hiện tại</p>
          <strong class="value">{{ stats.currentStock }}</strong>
        </article>
        <article class="stat-card">
          <p>Số giao dịch hôm nay</p>
          <strong class="value">{{ stats.todayTransactions }}</strong>
        </article>
      </section>

      <section class="filter-bar">
        <input
          v-model="filters.search"
          type="search"
          class="filter-input search"
          placeholder="Tìm theo sản phẩm, mã lô, reference..."
        >

        <select v-model="filters.type" class="filter-input select">
          <option value="all">Tất cả</option>
          <option value="import">Nhập kho</option>
          <option value="export">Xuất kho</option>
          <option value="adjustment">Kiểm kê</option>
        </select>

        <div class="date-range">
          <input v-model="filters.fromDate" type="date" class="filter-input date">
          <span>đến</span>
          <input v-model="filters.toDate" type="date" class="filter-input date">
        </div>

        <button class="btn btn-primary" @click="applyFilters">Lọc</button>
        <button class="btn btn-secondary" @click="resetFilters">Đặt lại</button>
      </section>

      <section class="table-section">
        <div class="table-head">
          <h2>Lịch sử giao dịch tồn kho</h2>
          <button class="btn btn-export" @click="exportExcel">📄 Xuất Excel</button>
        </div>

        <div class="table-wrap">
          <table class="inventory-table">
            <thead>
              <tr>
                <th>STT</th>
                <th>Thời gian</th>
                <th>Loại</th>
                <th>Sản phẩm</th>
                <th>Mã lô</th>
                <th>Hạn SD</th>
                <th>Số lượng</th>
                <th>Tham chiếu</th>
                <th>Người tạo</th>
                <th>Ghi chú</th>
              </tr>
            </thead>

            <tbody>
              <tr v-if="loading">
                <td colspan="10" class="loading-cell">
                  <span class="spinner"></span>
                  <span>Đang tải dữ liệu...</span>
                </td>
              </tr>

              <tr v-else-if="paginatedTransactions.length === 0">
                <td colspan="10" class="empty-cell">Không có giao dịch phù hợp.</td>
              </tr>

              <tr
                v-for="(item, index) in paginatedTransactions"
                :key="item.id"
              >
                <td>{{ rowStart + index + 1 }}</td>
                <td>{{ formatDateTime(item.created_at) }}</td>
                <td>
                  <span class="badge" :class="`badge-${item.type}`">
                    {{ typeLabel(item.type) }}
                  </span>
                </td>
                <td>{{ item.product_name }}</td>
                <td>{{ item.batch_code }}</td>
                <td>
                  <span :class="expiryClass(item.expiry_date)">
                    {{ formatDate(item.expiry_date) }}
                  </span>
                </td>
                <td>
                  <span :class="quantityClass(item)">
                    {{ formatQuantity(item) }}
                  </span>
                </td>
                <td>{{ item.reference_id }}</td>
                <td>{{ item.created_by_name }}</td>
                <td>{{ item.note || '-' }}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="table-footer">
          <p>
            Hiển thị {{ rowStart + 1 }}-{{ rowEnd }} trên tổng số {{ totalItems }} giao dịch
          </p>

          <div class="footer-actions">
            <label class="page-size">
              Dòng/trang
              <select v-model.number="pagination.pageSize" @change="onPageSizeChange">
                <option v-for="size in pageSizeOptions" :key="size" :value="size">{{ size }}</option>
              </select>
            </label>

            <button class="btn btn-secondary" :disabled="pagination.page <= 1" @click="prevPage">Trước</button>
            <button class="btn btn-secondary" :disabled="pagination.page >= totalPages" @click="nextPage">Sau</button>
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

const filters = reactive({
  search: '',
  type: 'all',
  fromDate: '',
  toDate: ''
})

const pagination = reactive({
  page: 1,
  pageSize: 10
})

const pageSizeOptions = [10, 25, 50]

const stats = reactive({
  totalImport: 0,
  totalExport: 0,
  currentStock: 0,
  todayTransactions: 0
})

const allTransactions = ref([])
const filteredTransactions = ref([])

const totalItems = computed(() => filteredTransactions.value.length)
const totalPages = computed(() => Math.max(1, Math.ceil(totalItems.value / pagination.pageSize)))

const rowStart = computed(() => (pagination.page - 1) * pagination.pageSize)
const rowEnd = computed(() => {
  const end = rowStart.value + paginatedTransactions.value.length
  return end || 0
})

const paginatedTransactions = computed(() => {
  const start = rowStart.value
  const end = start + pagination.pageSize
  return filteredTransactions.value.slice(start, end)
})

const parseDate = (value) => new Date(String(value).replace(' ', 'T'))

const formatDateTime = (value) => {
  const d = parseDate(value)
  if (Number.isNaN(d.getTime())) return '-'
  const dd = String(d.getDate()).padStart(2, '0')
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const yyyy = d.getFullYear()
  const hh = String(d.getHours()).padStart(2, '0')
  const min = String(d.getMinutes()).padStart(2, '0')
  return `${dd}/${mm}/${yyyy} ${hh}:${min}`
}

const formatDate = (value) => {
  const d = new Date(value)
  if (Number.isNaN(d.getTime())) return '-'
  const dd = String(d.getDate()).padStart(2, '0')
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const yyyy = d.getFullYear()
  return `${dd}/${mm}/${yyyy}`
}

const daysToExpiry = (value) => {
  const end = new Date(value)
  const now = new Date()
  end.setHours(0, 0, 0, 0)
  now.setHours(0, 0, 0, 0)
  return Math.ceil((end - now) / (1000 * 60 * 60 * 24))
}

const expiryClass = (value) => {
  const days = daysToExpiry(value)
  if (days < 0) return 'expiry-expired'
  if (days <= 30) return 'expiry-warning'
  return 'expiry-safe'
}

const typeLabel = (type) => {
  if (type === 'import') return 'NHẬP KHO'
  if (type === 'export') return 'XUẤT KHO'
  return 'KIỂM KÊ'
}

const formatQuantity = (item) => {
  const q = Number(item.quantity || 0)
  if (item.type === 'import' && q > 0) return `+${q}`
  if (item.type === 'export') return `-${Math.abs(q)}`
  if (q > 0) return `+${q}`
  return `${q}`
}

const quantityClass = (item) => {
  const q = Number(item.quantity || 0)
  if (item.type === 'import' || q > 0) return 'qty-positive'
  if (item.type === 'export' || q < 0) return 'qty-negative'
  return ''
}

const fetchTransactions = async () => {
  loading.value = true

  try {
    const result = await warehouseApi.getInventoryTransactions({
      page: pagination.page,
      pageSize: pagination.pageSize,
      search: filters.search
    })

    allTransactions.value = (result.data || []).map((item) => ({
      id: item.id,
      type: 'inventory',
      quantity: Number(item.stock_quantity || 0),
      reference_id: '-',
      note: item.description || '',
      created_at: item.updated_at || item.created_at || new Date().toISOString(),
      product_name: item.name || 'N/A',
      batch_code: '-',
      expiry_date: null,
      created_by_name: '-'
    }))
      .sort((a, b) => parseDate(b.created_at) - parseDate(a.created_at))

    filteredTransactions.value = [...allTransactions.value]
  } finally {
    loading.value = false
  }
}

const fetchStats = async () => {
  stats.totalImport = 0
  stats.totalExport = 0
  stats.currentStock = allTransactions.value.reduce((sum, item) => sum + Number(item.quantity || 0), 0)
  stats.todayTransactions = allTransactions.value.length
}

const filterTransactions = () => {
  const search = filters.search.trim().toLowerCase()
  const from = filters.fromDate ? new Date(filters.fromDate) : null
  const to = filters.toDate ? new Date(filters.toDate) : null

  if (from) from.setHours(0, 0, 0, 0)
  if (to) to.setHours(23, 59, 59, 999)

  filteredTransactions.value = allTransactions.value.filter((item) => {
    const itemDate = parseDate(item.created_at)

    const matchSearch =
      !search ||
      [item.product_name, item.batch_code, item.reference_id, item.note]
        .join(' ')
        .toLowerCase()
        .includes(search)

    const matchType = filters.type === 'all' || item.type === filters.type
    const matchFrom = !from || itemDate >= from
    const matchTo = !to || itemDate <= to

    return matchSearch && matchType && matchFrom && matchTo
  })

  pagination.page = 1
}

const applyFilters = () => {
  filterTransactions()
}

const resetFilters = () => {
  filters.search = ''
  filters.type = 'all'
  filters.fromDate = ''
  filters.toDate = ''
  filterTransactions()
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

const exportExcel = () => {
  const headers = ['STT', 'Thời gian', 'Loại', 'Sản phẩm', 'Mã lô', 'Hạn SD', 'Số lượng', 'Tham chiếu', 'Người tạo', 'Ghi chú']

  const rows = filteredTransactions.value.map((item, idx) => [
    idx + 1,
    formatDateTime(item.created_at),
    typeLabel(item.type),
    item.product_name,
    item.batch_code,
    formatDate(item.expiry_date),
    formatQuantity(item),
    item.reference_id,
    item.created_by_name,
    item.note || ''
  ])

  const csv = [headers, ...rows]
    .map((line) => line.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(','))
    .join('\n')

  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = 'inventory_transactions_report.csv'
  a.click()
  URL.revokeObjectURL(url)
}

onMounted(async () => {
  await Promise.all([fetchTransactions(), fetchStats()])
})
</script>

<style scoped>
.inventory-page {
  background: #f0f2f6;
  border-radius: 18px;
  padding: 18px;
  width: 100%;
  margin: 0;
}

.inventory-header {
  margin-bottom: 16px;
}

.title-wrap {
  display: flex;
  align-items: center;
  gap: 10px;
}

.title-icon {
  width: 42px;
  height: 42px;
  border-radius: 12px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: #eaf2ff;
  font-size: 20px;
}

.title-wrap h1 {
  margin: 0;
  font-size: 30px;
  color: #1e3a8a;
}

.title-wrap p {
  margin: 4px 0 0;
  color: #64748b;
  font-size: 14px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 12px;
  margin-bottom: 14px;
}

.stat-card {
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 8px 20px rgba(15, 23, 42, 0.06);
  border: 1px solid #e2e8f0;
  padding: 14px;
  text-align: center;
}

.stat-card p {
  margin: 0;
  font-size: 13px;
  color: #64748b;
}

.stat-card .value {
  display: block;
  margin-top: 8px;
  font-size: 28px;
  color: #0f172a;
}

.stat-card .value.positive {
  color: #10b981;
}

.stat-card .value.negative {
  color: #ef4444;
}

.filter-bar {
  display: grid;
  grid-template-columns: 1.4fr 0.8fr 1.1fr auto auto;
  gap: 10px;
  margin-bottom: 14px;
  width: 100%;
}

.filter-input {
  border: 1px solid #d6dee9;
  background: #fff;
  border-radius: 10px;
  padding: 10px 12px;
  font-size: 13px;
}

.date-range {
  display: flex;
  align-items: center;
  gap: 8px;
}

.date-range span {
  color: #64748b;
  font-size: 12px;
}

.btn {
  border: none;
  border-radius: 10px;
  padding: 10px 14px;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
}

.btn-primary {
  background: #3b82f6;
  color: #fff;
}

.btn-secondary {
  background: #e5e7eb;
  color: #334155;
}

.btn-export {
  background: #3b82f6;
  color: #fff;
}

.table-section {
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 8px 20px rgba(15, 23, 42, 0.06);
  border: 1px solid #e2e8f0;
  padding: 14px;
  width: 100%;
}

.table-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  margin-bottom: 10px;
}

.table-head h2 {
  margin: 0;
  font-size: 18px;
  color: #0f172a;
}

.table-wrap {
  overflow-x: auto;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
}

.inventory-table {
  width: 100%;
  min-width: 1180px;
  border-collapse: collapse;
}

.inventory-table th {
  text-align: left;
  padding: 12px;
  background: #f8fafc;
  color: #475569;
  font-size: 12px;
  white-space: nowrap;
}

.inventory-table td {
  padding: 12px;
  border-top: 1px solid #eef2f7;
  font-size: 13px;
  color: #334155;
}

.inventory-table tbody tr:hover {
  background: #f8fbff;
}

.badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 999px;
  padding: 4px 10px;
  font-size: 11px;
  font-weight: 800;
}

.badge-import {
  background: #dcfce7;
  color: #15803d;
}

.badge-export {
  background: #fee2e2;
  color: #b91c1c;
}

.badge-adjustment {
  background: #ffedd5;
  color: #c2410c;
}

.expiry-safe {
  color: #16a34a;
  font-weight: 700;
}

.expiry-warning {
  color: #d97706;
  font-weight: 700;
}

.expiry-expired {
  color: #dc2626;
  font-weight: 700;
}

.qty-positive {
  color: #10b981;
  font-weight: 800;
}

.qty-negative {
  color: #ef4444;
  font-weight: 800;
}

.loading-cell,
.empty-cell {
  text-align: center;
  color: #64748b;
}

.loading-cell {
  display: table-cell;
}

.spinner {
  display: inline-block;
  width: 16px;
  height: 16px;
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

.table-footer {
  margin-top: 10px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  flex-wrap: wrap;
}

.table-footer p {
  margin: 0;
  color: #64748b;
  font-size: 13px;
}

.footer-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.page-size {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  color: #64748b;
  font-size: 12px;
}

.page-size select {
  border: 1px solid #d6dee9;
  border-radius: 8px;
  padding: 6px 8px;
  font-size: 12px;
}

@media (max-width: 1100px) {
  .stats-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .filter-bar {
    grid-template-columns: 1fr;
  }

  .date-range {
    justify-content: space-between;
  }
}

@media (max-width: 640px) {
  .stats-grid {
    grid-template-columns: 1fr;
  }

  .inventory-page {
    padding: 12px;
  }

  .title-wrap h1 {
    font-size: 24px;
  }
}
</style>