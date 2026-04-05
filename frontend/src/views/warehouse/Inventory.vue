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
            <h1>Lịch sử nhập/xuất kho</h1>
            <p>Dữ liệu thực từ giao dịch tồn kho và đơn hàng</p>
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
          <strong class="value negative">-{{ stats.totalExport }}</strong>
        </article>
        <article class="stat-card">
          <p>Giao dịch hôm nay</p>
          <strong class="value">{{ stats.todayTransactions }}</strong>
        </article>
        <article class="stat-card">
          <p>Tồn kho hiện tại</p>
          <strong class="value">{{ stats.currentStock }}</strong>
        </article>
      </section>

      <section class="filter-bar">
        <input
          v-model="filters.search"
          type="search"
          class="filter-input search"
          placeholder="Tìm theo sản phẩm, mã lô, mã đơn..."
        >

        <select v-model="filters.type" class="filter-input select">
          <option value="all">Tất cả loại</option>
          <option value="import">Nhập kho</option>
          <option value="export">Xuất kho</option>
          <option value="adjustment">Điều chỉnh</option>
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
          <h2>Giao dịch tồn kho</h2>
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
                <td>{{ item.batch_code || '-' }}</td>
                <td>{{ formatDate(item.expiry_date) }}</td>
                <td>
                  <span :class="quantityClass(item.type)">
                    {{ formatQuantity(item) }}
                  </span>
                </td>
                <td>{{ item.reference_display }}</td>
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
  todayTransactions: 0,
  currentStock: 0
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

const parseDate = (value) => new Date(String(value || '').replace(' ', 'T'))

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
  if (!value) return '-'
  const d = new Date(value)
  if (Number.isNaN(d.getTime())) return '-'
  const dd = String(d.getDate()).padStart(2, '0')
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const yyyy = d.getFullYear()
  return `${dd}/${mm}/${yyyy}`
}

const typeLabel = (type) => {
  if (type === 'import') return 'NHẬP KHO'
  if (type === 'export') return 'XUẤT KHO'
  return 'ĐIỀU CHỈNH'
}

const quantityClass = (type) => {
  if (type === 'export') return 'qty-negative'
  return 'qty-positive'
}

const formatQuantity = (item) => {
  const quantity = Number(item.quantity || 0)
  if (item.type === 'export') return `-${Math.abs(quantity)}`
  return `+${quantity}`
}

const fetchTransactions = async () => {
  loading.value = true

  try {
    const result = await warehouseApi.getInventoryTransactions({
      page: 1,
      pageSize: 500,
      search: filters.search,
      type: filters.type,
      fromDate: filters.fromDate,
      toDate: filters.toDate
    })

    allTransactions.value = (result.data || []).map((item) => ({
      id: item.id,
      type: item.type,
      quantity: Number(item.quantity || 0),
      created_at: item.created_at,
      product_name: item.product?.name || '-',
      batch_code: item.batch?.batch_code || '-',
      expiry_date: item.batch?.expiry_date || null,
      reference_id: item.reference_id,
      reference_display: item.reference_id ? `#${item.reference_id}` : '-',
      created_by_name: item.created_by?.name || '-',
      note: item.note || ''
    }))

    filteredTransactions.value = [...allTransactions.value]
    calculateStats()
    await loadCurrentStock()
    pagination.page = 1
  } finally {
    loading.value = false
  }
}

const loadCurrentStock = async () => {
  let page = 1
  let totalPages = 1
  let totalStock = 0

  while (page <= totalPages) {
    const result = await warehouseApi.getInventory({ page, pageSize: 100 })
    const items = Array.isArray(result?.data) ? result.data : []

    totalStock += items.reduce((sum, item) => sum + Number(item.stock_quantity || 0), 0)
    totalPages = Number(result?.meta?.totalPages || 1)
    page += 1
  }

  stats.currentStock = totalStock
}

const calculateStats = () => {
  stats.totalImport = filteredTransactions.value
    .filter((item) => item.type === 'import')
    .reduce((sum, item) => sum + Number(item.quantity || 0), 0)

  stats.totalExport = filteredTransactions.value
    .filter((item) => item.type === 'export')
    .reduce((sum, item) => sum + Number(item.quantity || 0), 0)

  const today = new Date()
  today.setHours(0, 0, 0, 0)

  stats.todayTransactions = filteredTransactions.value.filter((item) => {
    const d = parseDate(item.created_at)
    if (Number.isNaN(d.getTime())) return false
    d.setHours(0, 0, 0, 0)
    return d.getTime() === today.getTime()
  }).length

}

const applyFilters = async () => {
  await fetchTransactions()
}

const resetFilters = async () => {
  filters.search = ''
  filters.type = 'all'
  filters.fromDate = ''
  filters.toDate = ''
  await fetchTransactions()
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
    item.reference_display,
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
  await fetchTransactions()
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
