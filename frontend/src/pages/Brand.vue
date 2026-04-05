<template>
  <div class="brand-page">
    <div class="page-header">
      <div>
        <h1>Quản lý thương hiệu</h1>
        <p class="breadcrumb">Nhà thuốc Da liễu / Thương hiệu</p>
      </div>
    </div>

    <div class="stats-grid">
      <article class="stat-card">
        <p class="stat-label">Tổng thương hiệu</p>
        <p class="stat-value">{{ brands.length }}</p>
      </article>
      <article class="stat-card">
        <p class="stat-label">Sản phẩm đã gắn thương hiệu</p>
        <p class="stat-value">{{ brandedProductsCount }}</p>
      </article>
      <article class="stat-card warning">
        <p class="stat-label">Sản phẩm chưa có thương hiệu</p>
        <p class="stat-value">{{ unbrandedProductsCount }}</p>
      </article>
    </div>

    <section class="card">
      <h2>Tạo thương hiệu mới</h2>
      <form class="create-row" @submit.prevent="handleCreateBrand">
        <input
          v-model.trim="newBrandName"
          type="text"
          class="text-input"
          placeholder="Ví dụ: La Roche-Posay"
        >
        <button class="btn btn-primary" type="submit" :disabled="creatingBrand">
          {{ creatingBrand ? 'Đang tạo...' : 'Tạo thương hiệu' }}
        </button>
      </form>
      <p v-if="createError" class="error-text">{{ createError }}</p>
    </section>

    <section class="card">
      <div class="section-head">
        <h2>Danh sách thương hiệu</h2>
      </div>

      <table class="table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Tên thương hiệu</th>
            <th>Slug</th>
            <th>Số sản phẩm</th>
            <th>Thao tác</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="brand in brands" :key="brand.id">
            <td>#{{ brand.id }}</td>
            <td>
              <template v-if="editingBrandId === brand.id">
                <input v-model.trim="editingBrandName" type="text" class="inline-input">
              </template>
              <template v-else>
                {{ brand.name }}
              </template>
            </td>
            <td>{{ brand.slug }}</td>
            <td>{{ countProductsByBrand(brand.id) }}</td>
            <td>
              <div class="actions">
                <template v-if="editingBrandId === brand.id">
                  <button
                    class="btn btn-primary btn-sm"
                    type="button"
                    :disabled="savingBrand"
                    @click="saveBrandEdit(brand.id)"
                  >
                    {{ savingBrand ? 'Đang lưu...' : 'Lưu' }}
                  </button>
                  <button class="btn btn-ghost btn-sm" type="button" @click="cancelBrandEdit">
                    Hủy
                  </button>
                </template>

                <template v-else>
                  <button class="btn btn-ghost btn-sm" type="button" @click="startBrandEdit(brand)">
                    Sửa
                  </button>
                  <button class="btn btn-danger btn-sm" type="button" @click="handleDeleteBrand(brand)">
                    Xóa
                  </button>
                </template>
              </div>
            </td>
          </tr>

          <tr v-if="!brands.length">
            <td colspan="5" class="empty-cell">Chưa có thương hiệu.</td>
          </tr>
        </tbody>
      </table>
    </section>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { warehouseApi } from '@/api/warehouse'
import { useProductStore } from '@/stores/products'

const productStore = useProductStore()

const brands = ref([])
const newBrandName = ref('')
const createError = ref('')
const creatingBrand = ref(false)

const editingBrandId = ref(null)
const editingBrandName = ref('')
const savingBrand = ref(false)

const products = computed(() => productStore.products)

const brandedProductsCount = computed(() => {
  return products.value.filter((item) => Boolean(item.brand_id)).length
})

const unbrandedProductsCount = computed(() => {
  return products.value.filter((item) => !item.brand_id).length
})

const loadData = async () => {
  const [brandList] = await Promise.all([
    warehouseApi.getBrands(),
    productStore.fetchProducts({ per_page: 200 })
  ])

  brands.value = brandList
}

const countProductsByBrand = (brandId) => {
  return products.value.filter((item) => String(item.brand_id || '') === String(brandId)).length
}

const handleCreateBrand = async () => {
  createError.value = ''
  const name = newBrandName.value

  if (!name) {
    createError.value = 'Vui lòng nhập tên thương hiệu.'
    return
  }

  creatingBrand.value = true
  try {
    await warehouseApi.createBrand({ name, is_active: true })
    newBrandName.value = ''
    brands.value = await warehouseApi.getBrands()
  } catch (error) {
    createError.value = error?.response?.data?.message || 'Không thể tạo thương hiệu.'
  } finally {
    creatingBrand.value = false
  }
}

const startBrandEdit = (brand) => {
  editingBrandId.value = brand.id
  editingBrandName.value = brand.name
}

const cancelBrandEdit = () => {
  editingBrandId.value = null
  editingBrandName.value = ''
}

const saveBrandEdit = async (id) => {
  const name = editingBrandName.value
  if (!name) {
    return
  }

  savingBrand.value = true
  try {
    await warehouseApi.updateBrand(id, { name })
    brands.value = await warehouseApi.getBrands()
    cancelBrandEdit()
  } finally {
    savingBrand.value = false
  }
}

const handleDeleteBrand = async (brand) => {
  const hasProducts = countProductsByBrand(brand.id) > 0
  if (hasProducts) {
    window.alert('Thương hiệu đang có sản phẩm. Hãy chuyển thương hiệu sản phẩm trước khi xóa.')
    return
  }

  const accepted = window.confirm(`Bạn có chắc muốn xóa thương hiệu "${brand.name}"?`)
  if (!accepted) {
    return
  }

  await warehouseApi.deleteBrand(brand.id)
  brands.value = await warehouseApi.getBrands()
}

onMounted(async () => {
  await loadData()
})
</script>

<style scoped>
.brand-page {
  display: grid;
  gap: 20px;
}

.page-header h1 {
  margin: 0;
  color: #1e3a8a;
  font-size: 28px;
}

.breadcrumb {
  margin: 6px 0 0;
  color: #64748b;
  font-size: 13px;
}

.stats-grid {
  display: grid;
  gap: 12px;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
}

.stat-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 14px;
}

.stat-card.warning {
  border-color: #f59e0b;
  background: #fffbeb;
}

.stat-label {
  margin: 0;
  color: #64748b;
  font-size: 13px;
}

.stat-value {
  margin: 8px 0 0;
  color: #0f172a;
  font-size: 28px;
  font-weight: 700;
}

.card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  padding: 16px;
}

.card h2 {
  margin: 0 0 12px;
  color: #1e293b;
  font-size: 18px;
}

.create-row {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 10px;
}

.text-input,
.inline-input {
  width: 100%;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  padding: 8px 10px;
  font-size: 14px;
}

.section-head {
  margin-bottom: 10px;
}

.table {
  width: 100%;
  border-collapse: collapse;
}

.table th,
.table td {
  border-bottom: 1px solid #e2e8f0;
  padding: 10px 8px;
  text-align: left;
  vertical-align: middle;
  font-size: 14px;
}

.table th {
  color: #475569;
  font-weight: 600;
}

.empty-cell {
  text-align: center;
  color: #64748b;
  padding: 18px;
}

.actions {
  display: flex;
  gap: 8px;
}

.btn {
  border: 1px solid transparent;
  border-radius: 8px;
  padding: 8px 12px;
  font-size: 14px;
  cursor: pointer;
}

.btn:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.btn-sm {
  font-size: 13px;
  padding: 6px 10px;
}

.btn-primary {
  color: #ffffff;
  background: #1d4ed8;
}

.btn-primary:hover:enabled {
  background: #1e40af;
}

.btn-ghost {
  color: #334155;
  background: #f8fafc;
  border-color: #cbd5e1;
}

.btn-ghost:hover {
  background: #f1f5f9;
}

.btn-danger {
  color: #ffffff;
  background: #dc2626;
}

.btn-danger:hover {
  background: #b91c1c;
}

.error-text {
  margin: 8px 0 0;
  color: #dc2626;
  font-size: 13px;
}

@media (max-width: 900px) {
  .create-row {
    grid-template-columns: 1fr;
  }

  .table {
    display: block;
    overflow-x: auto;
  }
}
</style>
