<template>
  <div class="category-page">
    <div class="page-header">
      <div>
        <h1>Quản lý danh mục</h1>
        <p class="breadcrumb">Nhà thuốc Da liễu / Danh mục</p>
      </div>
    </div>

    <div class="stats-grid">
      <article class="stat-card">
        <p class="stat-label">Tổng danh mục</p>
        <p class="stat-value">{{ categories.length }}</p>
      </article>
      <article class="stat-card">
        <p class="stat-label">Sản phẩm đã gán danh mục</p>
        <p class="stat-value">{{ categorizedProductsCount }}</p>
      </article>
      <article class="stat-card warning">
        <p class="stat-label">Sản phẩm chưa có danh mục</p>
        <p class="stat-value">{{ uncategorizedProductsCount }}</p>
      </article>
    </div>

    <section class="card">
      <h2>Tạo danh mục mới</h2>
      <form class="create-row" @submit.prevent="handleCreateCategory">
        <input
          v-model.trim="newCategoryName"
          type="text"
          class="text-input"
          placeholder="Ví dụ: Dưỡng ẩm"
        >
        <button class="btn btn-primary" type="submit" :disabled="creatingCategory">
          {{ creatingCategory ? 'Đang tạo...' : 'Tạo danh mục' }}
        </button>
      </form>
      <p v-if="createError" class="error-text">{{ createError }}</p>
    </section>

    <section class="card">
      <div class="section-head">
        <h2>Danh sách danh mục</h2>
      </div>

      <table class="table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Tên danh mục</th>
            <th>Slug</th>
            <th>Số sản phẩm</th>
            <th>Thao tác</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="category in categories" :key="category.id">
            <td>#{{ category.id }}</td>
            <td>
              <template v-if="editingCategoryId === category.id">
                <input v-model.trim="editingCategoryName" type="text" class="inline-input">
              </template>
              <template v-else>
                {{ category.name }}
              </template>
            </td>
            <td>{{ category.slug }}</td>
            <td>{{ countProductsByCategory(category.id) }}</td>
            <td>
              <div class="actions">
                <template v-if="editingCategoryId === category.id">
                  <button
                    class="btn btn-primary btn-sm"
                    type="button"
                    :disabled="savingCategory"
                    @click="saveCategoryEdit(category.id)"
                  >
                    {{ savingCategory ? 'Đang lưu...' : 'Lưu' }}
                  </button>
                  <button
                    class="btn btn-ghost btn-sm"
                    type="button"
                    @click="cancelCategoryEdit"
                  >
                    Hủy
                  </button>
                </template>

                <template v-else>
                  <button
                    class="btn btn-ghost btn-sm"
                    type="button"
                    @click="startCategoryEdit(category)"
                  >
                    Sửa
                  </button>
                  <button
                    class="btn btn-danger btn-sm"
                    type="button"
                    @click="handleDeleteCategory(category)"
                  >
                    Xóa
                  </button>
                </template>
              </div>
            </td>
          </tr>

          <tr v-if="!categories.length">
            <td colspan="5" class="empty-cell">Chưa có danh mục.</td>
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

const categories = ref([])
const newCategoryName = ref('')
const createError = ref('')
const creatingCategory = ref(false)

const editingCategoryId = ref(null)
const editingCategoryName = ref('')
const savingCategory = ref(false)

const products = computed(() => productStore.products)

const categorizedProductsCount = computed(() => {
  return products.value.filter((item) => Boolean(item.category_id)).length
})

const uncategorizedProductsCount = computed(() => {
  return products.value.filter((item) => !item.category_id).length
})

const loadData = async () => {
  const [categoryList] = await Promise.all([
    warehouseApi.getCategories(),
    productStore.fetchProducts({ per_page: 200 })
  ])

  categories.value = categoryList
}

const countProductsByCategory = (categoryId) => {
  return products.value.filter((item) => String(item.category_id || '') === String(categoryId)).length
}

const handleCreateCategory = async () => {
  createError.value = ''
  const name = newCategoryName.value

  if (!name) {
    createError.value = 'Vui lòng nhập tên danh mục.'
    return
  }

  creatingCategory.value = true
  try {
    await warehouseApi.createCategory({ name, is_active: true })
    newCategoryName.value = ''
    categories.value = await warehouseApi.getCategories()
  } catch (error) {
    createError.value = error?.response?.data?.message || 'Không thể tạo danh mục.'
  } finally {
    creatingCategory.value = false
  }
}

const startCategoryEdit = (category) => {
  editingCategoryId.value = category.id
  editingCategoryName.value = category.name
}

const cancelCategoryEdit = () => {
  editingCategoryId.value = null
  editingCategoryName.value = ''
}

const saveCategoryEdit = async (id) => {
  const name = editingCategoryName.value
  if (!name) {
    return
  }

  savingCategory.value = true
  try {
    await warehouseApi.updateCategory(id, { name })
    categories.value = await warehouseApi.getCategories()
    cancelCategoryEdit()
  } finally {
    savingCategory.value = false
  }
}

const handleDeleteCategory = async (category) => {
  const hasProducts = countProductsByCategory(category.id) > 0
  if (hasProducts) {
    window.alert('Danh mục đang có sản phẩm. Hãy chuyển sản phẩm sang danh mục khác trước khi xóa.')
    return
  }

  const accepted = window.confirm(`Bạn có chắc muốn xóa danh mục "${category.name}"?`)
  if (!accepted) {
    return
  }

  await warehouseApi.deleteCategory(category.id)
  categories.value = await warehouseApi.getCategories()
}

onMounted(async () => {
  await loadData()
})
</script>

<style scoped>
.category-page {
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
