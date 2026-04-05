<template>
  <section class="product-form-card">
    <div class="product-form-header">
      <h3>{{ isEditMode ? 'Cập nhật sản phẩm' : 'Thêm sản phẩm mới' }}</h3>
      <span v-if="loadingMeta" class="meta-loading">Đang tải danh mục, thương hiệu...</span>
    </div>

    <form class="product-form-grid" @submit.prevent="handleSubmit">
      <div class="product-form-left">
        <label class="form-row">
          <span>Tên sản phẩm *</span>
          <input
            type="text"
            :value="form.name"
            @input="updateField('name', $event.target.value)"
            placeholder="Nhập tên sản phẩm"
          >
          <small v-if="errors.name" class="error-text">{{ errors.name }}</small>
        </label>

        <label class="form-row">
          <span>Slug</span>
          <input
            type="text"
            :value="form.slug"
            @input="handleSlugChange($event.target.value)"
            placeholder="tu-dong-tao-tu-ten"
          >
        </label>

        <div class="form-row row-split">
          <label>
            <span>Danh mục</span>
            <select :value="form.category_id" @change="updateField('category_id', $event.target.value)">
              <option value="">Chọn danh mục</option>
              <option v-for="item in categories" :key="item.id" :value="item.id">{{ item.name }}</option>
            </select>
          </label>

          <label>
            <span>Thương hiệu</span>
            <select :value="form.brand_id" @change="updateField('brand_id', $event.target.value)">
              <option value="">Không chọn</option>
              <option v-for="item in brands" :key="item.id" :value="item.id">{{ item.name }}</option>
            </select>
          </label>
        </div>

        <label class="form-row">
          <span>Mô tả</span>
          <textarea
            rows="3"
            :value="form.description"
            @input="updateField('description', $event.target.value)"
            placeholder="Mô tả ngắn về sản phẩm"
          ></textarea>
        </label>

        <div class="form-row row-split">
          <label>
            <span>Giá niêm yết *</span>
            <input
              type="number"
              min="0"
              :value="form.price_listed"
              @input="updateField('price_listed', $event.target.value)"
              placeholder="0"
            >
            <small v-if="errors.price_listed" class="error-text">{{ errors.price_listed }}</small>
          </label>

          <label>
            <span>Dạng bào chế</span>
            <input
              type="text"
              :value="form.dosage_form"
              @input="updateField('dosage_form', $event.target.value)"
              placeholder="Gel, kem, serum..."
            >
          </label>
        </div>

        <div class="form-row row-split">
          <label>
            <span>Dung tích</span>
            <input
              type="text"
              :value="form.volume"
              @input="updateField('volume', $event.target.value)"
              placeholder="30ml"
            >
          </label>

          <label class="switch-row">
            <span>Trạng thái</span>
            <button
              type="button"
              class="status-switch"
              :class="form.is_active ? 'active' : 'inactive'"
              @click="updateField('is_active', !form.is_active)"
            >
              {{ form.is_active ? 'Hoạt động' : 'Ngừng' }}
            </button>
          </label>
        </div>

        <p v-if="errors.submit" class="submit-error">{{ errors.submit }}</p>

        <div class="form-actions">
          <button type="submit" class="btn-primary" :disabled="saving">{{ saving ? 'Đang lưu...' : 'Lưu' }}</button>
          <button type="button" class="btn-secondary" @click="emit('cancelled')">Hủy</button>
        </div>
      </div>

      <div class="product-form-right">
        <label class="upload-box">
          <span>Hình ảnh</span>
          <input type="file" accept="image/*" @change="handleImageChange">
        </label>

        <div class="image-preview">
          <img v-if="previewUrl" :src="previewUrl" alt="Xem trước">
          <p v-else>Chưa có ảnh xem trước</p>
        </div>
      </div>
    </form>
  </section>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue'
import axios from 'axios'

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api',
  timeout: 10000
})

const props = defineProps({
  initialProduct: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['saved', 'cancelled'])

const EMPTY_FORM = {
  id: null,
  name: '',
  slug: '',
  category_id: '',
  brand_id: '',
  description: '',
  price_listed: '',
  dosage_form: '',
  volume: '',
  is_active: true
}

const form = reactive({ ...EMPTY_FORM })
const errors = reactive({})
const categories = ref([])
const brands = ref([])
const loadingMeta = ref(false)
const saving = ref(false)
const slugLocked = ref(false)
const previewUrl = ref('')

const isEditMode = computed(() => Boolean(form.id))

const slugify = (value) => {
  return String(value || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim()
    .replace(/\s+/g, '-')
    .replace(/[^a-z0-9-]/g, '')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '')
}

const resolveCategoryName = (categoryId) => {
  const found = categories.value.find((item) => String(item.id) === String(categoryId))
  return found?.name || ''
}

const resetForm = (product = null) => {
  const next = product
    ? {
        ...EMPTY_FORM,
        id: product.id || null,
        name: product.name || '',
        slug: product.slug || slugify(product.name || ''),
        category_id: product.category_id || '',
        brand_id: product.brand_id || '',
        description: product.description || '',
        price_listed: product.price_listed || product.price || '',
        dosage_form: product.dosage_form || product.type || '',
        volume: product.volume || '',
        is_active: typeof product.is_active === 'boolean' ? product.is_active : true
      }
    : { ...EMPTY_FORM }

  Object.assign(form, next)
  Object.keys(errors).forEach((key) => delete errors[key])
  slugLocked.value = Boolean(product?.slug)
  previewUrl.value = product?.image_url || product?.image || ''
}

const updateField = (field, value) => {
  form[field] = value
  if (field === 'name' && !slugLocked.value) {
    form.slug = slugify(value)
  }
}

const handleSlugChange = (value) => {
  slugLocked.value = true
  form.slug = slugify(value)
}

const handleImageChange = (event) => {
  const file = event.target.files?.[0]
  if (!file) return

  const reader = new FileReader()
  reader.onload = () => {
    previewUrl.value = String(reader.result || '')
  }
  reader.readAsDataURL(file)
}

const validateForm = () => {
  Object.keys(errors).forEach((key) => delete errors[key])

  if (!String(form.name).trim()) {
    errors.name = 'Tên sản phẩm là bắt buộc.'
  }

  const price = Number(form.price_listed)
  if (!Number.isFinite(price) || price <= 0) {
    errors.price_listed = 'Giá niêm yết phải lớn hơn 0.'
  }

  return Object.keys(errors).length === 0
}

const loadMeta = async () => {
  loadingMeta.value = true
  try {
    const [categoryRes, brandRes] = await Promise.all([apiClient.get('/categories'), apiClient.get('/brands')])
    const categoryData = categoryRes.data || []
    const brandData = brandRes.data || []

    categories.value = Array.isArray(categoryData) ? categoryData : categoryData.data || []
    brands.value = Array.isArray(brandData) ? brandData : brandData.data || []
  } catch (error) {
    categories.value = []
    brands.value = []
  } finally {
    loadingMeta.value = false
  }
}

const handleSubmit = async () => {
  if (!validateForm()) return

  saving.value = true

  const payload = {
    id: form.id,
    name: form.name.trim(),
    slug: form.slug || slugify(form.name),
    category_id: form.category_id || null,
    category_name: resolveCategoryName(form.category_id),
    brand_id: form.brand_id || null,
    description: form.description,
    price_listed: Number(form.price_listed),
    dosage_form: form.dosage_form,
    volume: form.volume,
    is_active: Boolean(form.is_active),
    image_url: previewUrl.value
  }

  try {
    emit('saved', payload)
  } catch (error) {
    errors.submit = 'Không thể lưu dữ liệu. Vui lòng thử lại.'
  } finally {
    saving.value = false
  }
}

watch(
  () => props.initialProduct,
  (value) => {
    resetForm(value)
  },
  { immediate: true }
)

onMounted(() => {
  loadMeta()
})

onBeforeUnmount(() => {
  if (previewUrl.value && previewUrl.value.startsWith('blob:')) {
    URL.revokeObjectURL(previewUrl.value)
  }
})
</script>

<style scoped>
.product-form-card {
  background: #ffffff;
  border: 1px solid #e5edf9;
  border-radius: 16px;
  padding: 18px;
  margin-bottom: 22px;
  box-shadow: 0 8px 20px rgba(16, 55, 102, 0.07);
}

.product-form-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 14px;
}

.product-form-header h3 {
  margin: 0;
  font-size: 17px;
  color: #1f4f96;
}

.meta-loading {
  font-size: 12px;
  color: #7a8fac;
}

.product-form-grid {
  display: grid;
  grid-template-columns: 1.8fr 1fr;
  gap: 18px;
}

.product-form-left {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.form-row {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-row > span,
.form-row label > span {
  font-size: 12px;
  font-weight: 600;
  color: #5d7699;
}

.form-row input,
.form-row select,
.form-row textarea {
  border: 1px solid #d8e4f6;
  border-radius: 10px;
  padding: 9px 11px;
  font-size: 13px;
  color: #2f4f75;
  background: #fcfeff;
}

.form-row input:focus,
.form-row select:focus,
.form-row textarea:focus {
  outline: none;
  border-color: #7daef0;
  box-shadow: 0 0 0 3px rgba(125, 174, 240, 0.16);
}

.row-split {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.row-split label {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.switch-row {
  justify-content: flex-end;
}

.status-switch {
  border: 1px solid #cbd9ef;
  border-radius: 999px;
  padding: 8px 12px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  background: #f1f6ff;
  color: #3564a0;
}

.status-switch.active {
  background: #dcfce7;
  border-color: #86efac;
  color: #166534;
}

.status-switch.inactive {
  background: #fef2f2;
  border-color: #fecaca;
  color: #b91c1c;
}

.form-actions {
  display: flex;
  gap: 10px;
  margin-top: 4px;
}

.btn-primary,
.btn-secondary {
  border: none;
  border-radius: 10px;
  padding: 10px 14px;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
}

.btn-primary {
  background: #3f7bd4;
  color: #ffffff;
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-secondary {
  background: #f1f5f9;
  color: #4b5f7c;
  border: 1px solid #d4dce8;
}

.product-form-right {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.upload-box {
  border: 1px dashed #acc5eb;
  border-radius: 12px;
  padding: 10px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  color: #5b7397;
  font-size: 12px;
  font-weight: 600;
  background: #f6faff;
}

.upload-box input {
  font-size: 12px;
}

.image-preview {
  border: 1px solid #dbe7f8;
  border-radius: 12px;
  min-height: 220px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f8fbff;
  overflow: hidden;
}

.image-preview p {
  margin: 0;
  font-size: 12px;
  color: #8599b7;
}

.image-preview img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.error-text,
.submit-error {
  font-size: 12px;
  color: #dc2626;
  margin: 0;
}

@media (max-width: 960px) {
  .product-form-grid {
    grid-template-columns: 1fr;
  }

  .image-preview {
    min-height: 180px;
  }
}
</style>
