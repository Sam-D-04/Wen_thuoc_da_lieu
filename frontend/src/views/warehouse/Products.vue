<template>
  <WarehouseSidebar title="Warehouse Products" subtitle="Quan ly san pham tu bang products" :show-page-head="false">
    <div class="products-page">
      <div class="page-header">
        <div>
          <h1>Quản lý sản phẩm</h1>
          <p class="breadcrumb">Nhà thuốc Da liễu / Sản phẩm</p>
        </div>
        <button class="btn btn-primary" @click="openAddModal">+ Thêm sản phẩm</button>
      </div>

      <div class="filters">
        <input
          v-model="filters.search"
          type="search"
          class="search-input"
          placeholder="Tìm kiếm sản phẩm..."
          @keyup.enter="reload"
        >
        <select v-model="filters.category_id" class="filter-select" @change="reload">
          <option value="">Tất cả danh mục</option>
          <option v-for="item in lookups.categories" :key="item.id" :value="String(item.id)">
            {{ item.name }}
          </option>
        </select>
        <button class="filter-btn" @click="reload"><span class="filter-icon" v-html="getFilterIcon()"></span>Lọc</button>
      </div>

      <div v-if="showProductForm" class="product-form-overlay" @click.self="handleFormCancelled">
        <div class="product-form-modal">
          <button class="overlay-close" @click="handleFormCancelled" title="Đóng">✕</button>
          <ProductFormModal
            :initial-product="editingProduct"
            @saved="handleFormSaved"
            @cancelled="handleFormCancelled"
          />
        </div>
      </div>

      <div v-if="error" class="alert-error">{{ error }}</div>

      <div class="table-container">
        <table class="products-table">
          <thead>
            <tr>
              <th class="col-id">ID</th>
              <th class="col-name">Sản phẩm</th>
              <th class="col-category">Danh mục</th>
              <th class="col-dosage">Dạng bào chế</th>
              <th class="col-volume">Dung tích</th>
              <th class="col-price">Giá niêm yết</th>
              <th class="col-status">Trạng thái</th>
              <th class="col-actions">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="8" class="empty">Đang tải dữ liệu...</td>
            </tr>
            <tr v-else-if="rows.length === 0">
              <td colspan="8" class="empty">Không có sản phẩm.</td>
            </tr>
            <tr v-for="product in rows" :key="product.id">
              <td class="col-id">#{{ product.id }}</td>
              <td class="col-name">
                <div class="product-name">
                  <img :src="resolveImage(product)" alt="Ảnh sản phẩm" class="product-thumb">
                  <div>
                    <p class="name">{{ product.name }}</p>
                    <p class="type">/{{ resolveSlug(product) || 'chua-co-slug' }}</p>
                  </div>
                </div>
              </td>
              <td class="col-category">{{ resolveCategory(product) }}</td>
              <td class="col-dosage">{{ resolveDosage(product) }}</td>
              <td class="col-volume">{{ resolveVolume(product) }}</td>
              <td class="col-price">{{ formatCurrency(product.price) }}</td>
              <td class="col-status">
                <span class="status-badge" :class="`status-${getStatusClass(product.is_active)}`">
                  {{ normalizeStatus(product.is_active) }}
                </span>
              </td>
              <td class="col-actions">
                <button class="action-btn edit-btn" title="Chỉnh sửa" v-html="getEditIcon()" @click="startEdit(product)"></button>
                <button class="action-btn delete-btn" title="Xóa" v-html="getDeleteIcon()" @click="handleDelete(product)"></button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pagination">
        <button class="page-btn" :disabled="pagination.page <= 1 || loading" @click="changePage(pagination.page - 1)">← Trước</button>
        <button class="page-btn active">{{ pagination.page }}</button>
        <button v-if="pagination.page < pagination.totalPages" class="page-btn" @click="changePage(pagination.page + 1)">{{ pagination.page + 1 }}</button>
        <button class="page-btn" :disabled="pagination.page >= pagination.totalPages || loading" @click="changePage(pagination.page + 1)">Tiếp →</button>
      </div>
    </div>
  </WarehouseSidebar>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import WarehouseSidebar from '@/components/warehouse/Sidebar.vue'
import ProductFormModal from '@/components/ProductFormModal.vue'
import { warehouseApi } from '@/api/warehouse'

const loading = ref(false)
const error = ref('')
const rows = ref([])
const editingProduct = ref(null)
const showProductForm = ref(false)

const filters = reactive({
  search: '',
  category_id: ''
})

const lookups = reactive({
  categories: [],
  brands: []
})

const pagination = reactive({
  page: 1,
  pageSize: 8,
  total: 0,
  totalPages: 1
})

const formatCurrency = (value) =>
  new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', minimumFractionDigits: 0 }).format(Number(value || 0))

const normalizeStatus = (isActive) => (Boolean(isActive) ? 'Hoạt động' : 'Ngừng')

const getStatusClass = (isActive) => (Boolean(isActive) ? 'active' : 'inactive')

const resolveImage = (product) => product.image_url || product.image || '/product-placeholder.svg'

const resolveSlug = (product) => {
  if (product.slug) return product.slug
  return String(product.name || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim()
    .replace(/\s+/g, '-')
    .replace(/[^a-z0-9-]/g, '')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '')
}

const loadLookups = async () => {
  try {
    const data = await warehouseApi.getLookups()
    lookups.categories = data.categories || []
    lookups.brands = data.brands || []
  } catch (err) {
    error.value = err?.message || 'Khong tai duoc danh muc/thuong hieu.'
  }
}

const reload = async () => {
  loading.value = true
  error.value = ''

  try {
    const result = await warehouseApi.getProducts({
      page: pagination.page,
      pageSize: pagination.pageSize,
      search: filters.search,
      category_id: filters.category_id
    })

    rows.value = result.data || []
    pagination.page = result.meta?.page || 1
    pagination.pageSize = result.meta?.pageSize || 8
    pagination.total = result.meta?.total || 0
    pagination.totalPages = result.meta?.totalPages || 1
  } catch (err) {
    error.value = err?.message || 'Khong tai duoc danh sach san pham.'
  } finally {
    loading.value = false
  }
}

const changePage = (page) => {
  pagination.page = page
  reload()
}

const resolveCategory = (product) => product.category?.name || product.category_name || 'N/A'
const resolveDosage = (product) => product.dosage_form || product.unit || 'Chưa cập nhật'
const resolveVolume = (product) => product.volume || 'Chưa cập nhật'

const openAddModal = () => {
  editingProduct.value = null
  showProductForm.value = true
}

const startEdit = (product) => {
  editingProduct.value = {
    id: product.id,
    name: product.name,
    slug: product.slug || '',
    category_id: product.category_id || '',
    brand_id: product.brand_id || '',
    description: product.description || '',
    price_listed: product.price,
    dosage_form: product.dosage_form || product.unit || '',
    volume: product.volume || '',
    is_active: Boolean(product.is_active)
  }
  showProductForm.value = true
}

const handleFormSaved = async (saved) => {
  if (!saved) {
    editingProduct.value = null
    showProductForm.value = false
    return
  }

  error.value = ''

  try {
      // Chuẩn bị payload: nếu có file ảnh (image_file) thì dùng FormData để upload
      let payload = {
        name: saved.name,
        sku: saved.slug || resolveSlug(saved),
        category_id: saved.category_id,
        brand_id: saved.brand_id,
        unit: saved.dosage_form || 'Tuyp',
        price: Number(saved.price_listed || 0),
        stock_quantity: Number(saved.stock_quantity || 0),
        reorder_level: Number(saved.reorder_level || 0),
        is_active: Boolean(saved.is_active),
        description: saved.description || '',
        dosage_form: saved.dosage_form || '',
        volume: saved.volume || '',
        image_url: saved.image_url || ''
      }

      if (saved.image_file) {
        const fd = new FormData()
        Object.keys(payload).forEach((k) => {
          if (payload[k] !== undefined && payload[k] !== null) fd.append(k, payload[k])
        })
        fd.append('image', saved.image_file)
        payload = fd
      }

      if (saved.id && rows.value.some((item) => Number(item.id) === Number(saved.id))) {
        // cập nhật (updateProduct hỗ trợ FormData)
        await warehouseApi.updateProduct(saved.id, payload)
      } else {
        await warehouseApi.createProduct(payload)
      }

    editingProduct.value = null
    showProductForm.value = false
    await reload()
  } catch (err) {
    error.value = err?.message || 'Không lưu được sản phẩm.'
  }
}

const handleFormCancelled = () => {
  editingProduct.value = null
  showProductForm.value = false
}

const handleDelete = async (item) => {
  if (!window.confirm(`Xoa san pham ${item.name}?`)) return

  loading.value = true
  error.value = ''

  try {
    await warehouseApi.deleteProduct(item.id)
    await reload()
  } catch (err) {
    error.value = err?.message || 'Khong xoa duoc san pham.'
  } finally {
    loading.value = false
  }
}

const getEditIcon = () => `
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path d="M4.5 19.5h4l10.8-10.8a1.8 1.8 0 0 0 0-2.6l-1.4-1.4a1.8 1.8 0 0 0-2.6 0L4.5 15.5v4Z" />
    <path d="M13.8 5.2 18.8 10.2" />
  </svg>
`

const getDeleteIcon = () => `
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path d="M5 7h14" />
    <path d="M9 7V5.6c0-.9.7-1.6 1.6-1.6h2.8c.9 0 1.6.7 1.6 1.6V7" />
    <path d="M8 7l.6 11.2c0 .9.7 1.6 1.6 1.6h3.6c.9 0 1.6-.7 1.6-1.6L16 7" />
    <path d="M10 11v4" />
    <path d="M14 11v4" />
  </svg>
`

const getFilterIcon = () => `
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <circle cx="11" cy="11" r="5.5" />
    <path d="M16 16l4 4" />
  </svg>
`

onMounted(async () => {
  await loadLookups()
  await reload()
})
</script>

<style scoped>
.products-page {
  animation: fadeIn 0.3s ease;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

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

.filters {
  display: flex;
  gap: 12px;
  margin-bottom: 24px;
}

.search-input {
  flex: 1;
  padding: 10px 16px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 13px;
  transition: all 0.3s ease;
}

.search-input:focus {
  outline: none;
  border-color: #1e3a8a;
  box-shadow: 0 0 0 3px rgba(30, 58, 138, 0.1);
}

.filter-select {
  padding: 10px 12px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.filter-select:focus {
  outline: none;
  border-color: #1e3a8a;
}

.filter-btn {
  padding: 10px 16px;
  background: #f1f5f9;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
  color: #475569;
  transition: all 0.3s ease;
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.filter-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #64748b;
}

.filter-icon :deep(svg) {
  width: 15px;
  height: 15px;
}

.filter-btn:hover {
  background: #e2e8f0;
  border-color: #cbd5e1;
}

.product-form-overlay {
  position: fixed;
  inset: 0;
  z-index: 1400;
  background: rgba(15, 23, 42, 0.32);
  backdrop-filter: blur(2px);
  padding: 24px;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  overflow-y: auto;
}

.product-form-modal {
  width: min(1120px, 96vw);
  margin-top: 20px;
  position: relative;
}

.overlay-close {
  position: absolute;
  top: 12px;
  right: 12px;
  width: 32px;
  height: 32px;
  border: 1px solid #d6e1f2;
  border-radius: 10px;
  background: #ffffff;
  color: #4a6a94;
  font-size: 14px;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  z-index: 2;
}

.overlay-close:hover {
  background: #f2f7ff;
  color: #1f4f96;
}

.product-form-modal :deep(.product-form-card) {
  margin-bottom: 0;
  box-shadow: 0 24px 48px rgba(15, 23, 42, 0.22);
}

.alert-error {
  margin-bottom: 12px;
  border: 1px solid #fecaca;
  background: #fef2f2;
  color: #991b1b;
  border-radius: 8px;
  padding: 8px 10px;
}

.table-container {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: auto;
  background: #fff;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  margin-bottom: 20px;
}

.products-table {
  width: 100%;
  min-width: 1020px;
  border-collapse: collapse;
  font-size: 13px;
}

.products-table thead {
  background: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
}

.products-table th {
  padding: 12px 16px;
  text-align: left;
  font-weight: 600;
  color: #475569;
  white-space: nowrap;
}

.products-table td {
  padding: 12px 16px;
  border-bottom: 1px solid #f1f5f9;
}

.products-table tbody tr:hover {
  background: #f8fafc;
}

.col-id {
  width: 60px;
}

.col-name {
  width: 34%;
}

.col-category {
  width: 14%;
}

.col-dosage {
  width: 12%;
}

.col-volume {
  width: 10%;
}

.col-price {
  width: 12%;
}

.col-status {
  width: 10%;
}

.col-actions {
  width: 8%;
  text-align: center;
}

.product-name {
  display: flex;
  align-items: center;
  gap: 10px;
}

.product-thumb {
  width: 42px;
  height: 42px;
  border-radius: 10px;
  object-fit: cover;
  border: 1px solid #dbe7f8;
  background: #f1f5f9;
}

.product-name .name {
  font-weight: 600;
  color: #1e3a8a;
  margin: 0 0 2px 0;
}

.product-name .type {
  font-size: 11px;
  color: #94a3b8;
  margin: 0;
}

.status-badge {
  padding: 4px 10px;
  border-radius: 4px;
  font-weight: 600;
  font-size: 12px;
}

.status-active {
  background: #d1fae5;
  color: #065f46;
}

.status-warning {
  background: #fef3c7;
  color: #92400e;
}

.status-inactive {
  background: #f3f4f6;
  color: #6b7280;
}

.action-btn {
  width: 28px;
  height: 28px;
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  background: #fff;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
  margin: 0 4px;
  color: #4f7fc5;
}

.action-btn :deep(svg) {
  width: 15px;
  height: 15px;
}

.action-btn:hover {
  border-color: #1e3a8a;
  background: #f0f4f8;
  color: #1e3a8a;
}

.delete-btn:hover {
  border-color: #ef4444;
  background: #fee2e2;
  color: #ef4444;
}

.pagination {
  display: flex;
  justify-content: center;
  gap: 8px;
}

.page-btn {
  padding: 8px 12px;
  border: 1px solid #e2e8f0;
  background: #fff;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  font-weight: 600;
  color: #475569;
  transition: all 0.3s ease;
}

.page-btn:hover:not(.active) {
  border-color: #1e3a8a;
  background: #f0f4f8;
  color: #1e3a8a;
}

.page-btn.active {
  background: #1e3a8a;
  color: #fff;
  border-color: #1e3a8a;
}

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
  gap: 8px;
}

.btn-primary {
  background: #1e3a8a;
  color: white;
}

.btn-primary:hover {
  background: #1e40af;
  box-shadow: 0 4px 12px rgba(30, 58, 138, 0.3);
}

.alert-error {
  margin-bottom: 12px;
  border: 1px solid #fecaca;
  background: #fef2f2;
  color: #991b1b;
  border-radius: 10px;
  padding: 8px 10px;
}

@media (max-width: 1024px) {
  .filters {
    flex-wrap: wrap;
  }
}

@media (max-width: 860px) {
  .page-header {
    flex-direction: column;
    gap: 16px;
  }

  .filters {
    flex-direction: column;
  }

  .search-input,
  .filter-select {
    width: 100%;
  }

  .product-form-overlay {
    padding: 12px;
  }

  .product-form-modal {
    width: 100%;
    margin-top: 8px;
  }
}
</style>
