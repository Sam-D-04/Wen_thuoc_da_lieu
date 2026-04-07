<template>
  <div class="products-page">
    <!-- Page Header -->
    <div class="page-header">
      <div>
        <h1>Quản lý sản phẩm</h1>
        <p class="breadcrumb">Nhà thuốc Da liễu / Sản phẩm</p>
      </div>
      <button class="btn btn-primary" @click="openAddModal">+ Thêm sản phẩm</button>
    </div>

    <!-- Search and Filter -->
    <div class="filters">
      <input
        v-model.trim="searchKeyword"
        type="search"
        class="search-input"
        placeholder="Tìm kiếm sản phẩm..."
        @keyup.enter="applyFilters"
      >
      <select v-model="selectedCategoryId" class="filter-select">
        <option value="">Tất cả danh mục</option>
        <option v-for="category in categories" :key="category.id" :value="String(category.id)">
          {{ category.name }}
        </option>
      </select>
      <button class="filter-btn" @click="applyFilters"><span class="filter-icon" v-html="getFilterIcon()"></span>Lọc</button>
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

    <!-- Products Table -->
    <div class="table-container">
      <table class="products-table">
        <thead>
          <tr>
            <th class="col-id">ID</th>
            <th class="col-name">Sản phẩm</th>
            <th class="col-category">Danh mục</th>
            <th class="col-brand">Thương hiệu</th>
            <th class="col-dosage">Dạng bào chế</th>
            <th class="col-volume">Dung tích</th>
            <th class="col-price">Giá niêm yết</th>
            <th class="col-status">Trạng thái</th>
            <th class="col-actions">Thao tác</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="product in products" :key="product.id">
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
            <td class="col-brand">{{ resolveBrand(product) }}</td>
            <td class="col-dosage">{{ resolveDosage(product) }}</td>
            <td class="col-volume">{{ resolveVolume(product) }}</td>
            <td class="col-price">{{ formatCurrency(product.price) }}</td>
            <td class="col-status">
              <span class="status-badge" :class="`status-${getStatusClass(product.status)}`">
                {{ normalizeStatus(product.status) }}
              </span>
            </td>
            <td class="col-actions">
              <button class="action-btn edit-btn" title="Chỉnh sửa" v-html="getEditIcon()" @click="startEdit(product)"></button>
              <button
                class="action-btn delete-btn"
                title="Xóa"
                v-html="getDeleteIcon()"
                :disabled="deletingProductId === product.id"
                @click="handleDeleteProduct(product)"
              ></button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Pagination -->
    <div class="pagination" v-if="totalPages > 1">
      <button class="page-btn" :disabled="currentPage === 1" @click="goToPage(currentPage - 1)">← Trước</button>
      <button
        v-for="page in visiblePages"
        :key="page"
        class="page-btn"
        :class="{ active: page === currentPage }"
        @click="goToPage(page)"
      >{{ page }}</button>
      <button class="page-btn" :disabled="currentPage === totalPages" @click="goToPage(currentPage + 1)">Tiếp →</button>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useProductStore } from '@/stores/products'
import { warehouseApi } from '@/api/warehouse'
import ProductFormModal from '@/components/ProductFormModal.vue'

const productStore = useProductStore()

const products = computed(() => productStore.products)
const categories = ref([])
const searchKeyword = ref('')
const selectedCategoryId = ref('')
const editingProduct = ref(null)
const showProductForm = ref(false)
const deletingProductId = ref(null)

const currentPage = ref(1)
const totalPages  = ref(1)
const PER_PAGE    = 20

const visiblePages = computed(() => {
  const pages = []
  const start = Math.max(1, currentPage.value - 2)
  const end   = Math.min(totalPages.value, start + 4)
  for (let i = start; i <= end; i++) pages.push(i)
  return pages
})

const fetchProducts = async (page = currentPage.value) => {
  const data = await productStore.fetchProducts({
    per_page:    PER_PAGE,
    page,
    search:      searchKeyword.value || undefined,
    category_id: selectedCategoryId.value || undefined,
  })
  currentPage.value = data?.current_page ?? 1
  totalPages.value  = data?.last_page    ?? 1
}

const applyFilters = async () => {
  currentPage.value = 1
  await fetchProducts(1)
}

const goToPage = async (page) => {
  if (page < 1 || page > totalPages.value) return
  await fetchProducts(page)
}

const formatCurrency = (value) => {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
    minimumFractionDigits: 0
  }).format(value)
}

const normalizeStatus = (status) => (status === 'Hoạt động' ? 'Hoạt động' : 'Ngừng')

const getStatusClass = (status) => {
  return normalizeStatus(status) === 'Hoạt động' ? 'active' : 'inactive'
}

const resolveImage = (product) => {
  return product.image_url || product.image || '/product-placeholder.svg'
}

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

const resolveCategory = (product) => product.category_name || product.category || 'N/A'
const resolveBrand = (product) => product.brand_name || product.brand?.name || 'N/A'
const resolveDosage = (product) => product.dosage_form || product.type || 'Chưa cập nhật'
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
    dosage_form: product.dosage_form || product.type || '',
    volume: product.volume || '',
    is_active: normalizeStatus(product.status) === 'Hoạt động'
  }
  showProductForm.value = true
}

const handleDeleteProduct = async (product) => {
  if (!product?.id || deletingProductId.value === product.id) {
    return
  }

  const accepted = window.confirm(`Bạn có chắc muốn xóa sản phẩm "${product.name}"?`)
  if (!accepted) {
    return
  }

  deletingProductId.value = product.id
  try {
    await warehouseApi.deleteProduct(product.id)
    await fetchProducts()
  } catch (error) {
    console.error(error)
    window.alert('Không thể xóa sản phẩm. Vui lòng thử lại.')
  } finally {
    deletingProductId.value = null
  }
}

const handleFormSaved = async (saved) => {
  if (!saved) {
    editingProduct.value = null
    showProductForm.value = false
    return
  }

  const payload = {
    category_id: saved.category_id,
    brand_id: saved.brand_id || null,
    name: saved.name,
    description: saved.description || '',
    price_listed: Number(saved.price_listed || 0),
    dosage_form: saved.dosage_form || '',
    volume: saved.volume || '',
    is_active: Boolean(saved.is_active)
  }

  try {
    if (saved.id) {
      await warehouseApi.updateProduct(saved.id, payload)
    } else {
      const formData = new FormData()
      formData.append('category_id', String(payload.category_id))
      if (payload.brand_id) {
        formData.append('brand_id', String(payload.brand_id))
      }
      formData.append('name', payload.name)
      formData.append('description', payload.description)
      formData.append('price_listed', String(payload.price_listed))
      formData.append('dosage_form', payload.dosage_form)
      formData.append('volume', payload.volume)
      formData.append('is_active', payload.is_active ? '1' : '0')

      if (saved.image_file) {
        formData.append('image', saved.image_file)
      }

      await warehouseApi.createProduct(formData)
    }

    await fetchProducts()
    editingProduct.value = null
    showProductForm.value = false
    window.alert(saved.id ? 'Cập nhật sản phẩm thành công.' : 'Thêm sản phẩm mới thành công.')
  } catch (error) {
    console.error(error)
    window.alert(error?.response?.data?.message || 'Không thể lưu sản phẩm. Vui lòng kiểm tra dữ liệu và thử lại.')
  }
}

const handleFormCancelled = () => {
  editingProduct.value = null
  showProductForm.value = false
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
  const [categoryList] = await Promise.all([
    warehouseApi.getCategories(),
    fetchProducts()
  ])
  categories.value = categoryList
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

/* Filters */
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

/* Table */
.table-container {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow-x: auto;
  overflow-y: hidden;
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
  width: 30%;
}

.col-category {
  width: 12%;
}

.col-brand {
  width: 12%;
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

/* Actions */
.action-btn {
  width: 28px;
  height: 28px;
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  background: white;
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

/* Pagination */
.pagination {
  display: flex;
  justify-content: center;
  gap: 8px;
}

.page-btn {
  padding: 8px 12px;
  border: 1px solid #e2e8f0;
  background: white;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  font-weight: 600;
  color: #475569;
  transition: all 0.3s ease;
}

@media (max-width: 768px) {
  .product-form-overlay {
    padding: 12px;
  }

  .product-form-modal {
    width: 100%;
    margin-top: 8px;
  }
}

.page-btn:hover:not(.active) {
  border-color: #1e3a8a;
  background: #f0f4f8;
  color: #1e3a8a;
}

.page-btn.active {
  background: #1e3a8a;
  color: white;
  border-color: #1e3a8a;
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

/* Responsive */
@media (max-width: 1024px) {
  .filters {
    flex-wrap: wrap;
  }

  .search-input {
    min-width: 200px;
  }
}

@media (max-width: 768px) {
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

  .table-container {
    overflow-x: auto;
  }

  .col-name {
    width: 25%;
  }

  .col-category {
    display: none;
  }

  .col-brand {
    display: none;
  }

  .col-type {
    display: none;
  }
}
</style>
