<template>
  <div class="batches-page">
    <!-- Page Header -->
    <div class="page-header">
      <div>
        <h1>Quản lý lô thuốc</h1>
        <p class="breadcrumb">Nhà thuốc Da liễu / Lô thuốc</p>
      </div>
      <button class="btn btn-primary" @click="openAddModal">+ Thêm lô mới</button>
    </div>

    <!-- Statistics -->
    <div class="stats-grid">
      <div class="stat-card safe">
        <p class="stat-label">Còn hạn</p>
        <p class="stat-value">{{ safeBatches }}</p>
      </div>
      <div class="stat-card warning">
        <p class="stat-label">Sắp hết hạn (≤30 ngày)</p>
        <p class="stat-value">{{ expiringBatches }}</p>
      </div>
      <div class="stat-card expired">
        <p class="stat-label">Đã hết hạn</p>
        <p class="stat-value">{{ expiredBatches }}</p>
      </div>
    </div>

    <!-- Filters -->
    <div class="filters">
      <a-input-search
        v-model:value="searchKeyword"
        class="search-input"
        placeholder="Tìm kiếm theo tên sản phẩm hoặc số lô..."
        allow-clear
      />

      <a-select
        v-model:value="statusFilter"
        class="filter-select"
        :options="statusOptions"
      />
    </div>

    <!-- Batches Table (FEFO Sorted) -->
    <div class="table-container">
      <table class="batches-table">
        <thead>
          <tr>
            <th class="col-batch">Mã lô</th>
            <th class="col-product">Sản phẩm</th>
            <th class="col-qty">Số lượng hiện tại</th>
            <th class="col-remain">Số lượng nhập</th>
            <th class="col-expiry">Ngày hết hạn</th>
            <th class="col-days">Còn lại</th>
            <th class="col-status">Trạng thái</th>
            <th class="col-actions">Thao tác</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="batch in filteredBatches"
            :key="batch.id"
            :class="getBatchRowClass(batch)"
          >
            <td class="col-batch font-weight-600">{{ batch.batch_code }}</td>
            <td class="col-product">
              <div class="product-cell">
                <div class="product-thumb">{{ resolveProductInitial(batch.product_name) }}</div>
                <div>
                  <p class="product-name">{{ batch.product_name }}</p>
                  <p class="product-sub">ID SP: {{ batch.product_id }}</p>
                </div>
              </div>
            </td>
            <td class="col-qty">
              <span class="qty-badge remaining">{{ batch.remaining_quantity }}</span>
            </td>
            <td class="col-remain">
              <span class="qty-badge">{{ batch.quantity }}</span>
            </td>
            <td class="col-expiry">{{ formatDate(batch.expiry_date) }}</td>
            <td class="col-days">
              <span class="days-badge" :class="getDaysBadgeClass(batch.daysToExpiry)">
                {{ batch.daysToExpiry < 0 ? 'Hết hạn' : batch.daysToExpiry + ' ngày' }}
              </span>
            </td>
            <td class="col-status">
              <span class="status-badge" :class="`status-${getStatusClass(batch.status)}`">
                {{ batch.status }}
              </span>
            </td>
            <td class="col-actions">
              <button
                class="action-btn edit-btn"
                title="Chỉnh sửa"
                v-html="getEditIcon()"
                @click="openEditModal(batch)"
              ></button>
              <button
                class="action-btn delete-btn"
                title="Xóa"
                v-html="getDeleteIcon()"
                @click="handleDelete(batch.id)"
              ></button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Legend -->
    <div class="legend">
      <p><span class="legend-safe"></span> Còn hạn</p>
      <p><span class="legend-warning"></span> Sắp hết hạn (≤30 ngày)</p>
      <p><span class="legend-expired"></span> Đã hết hạn</p>
    </div>

    <!-- Batch Modal -->
    <a-modal
      v-model:open="showModal"
      :title="modalTitle"
      :width="980"
      :confirm-loading="saving"
      :mask-closable="false"
      :destroy-on-close="false"
      @cancel="closeModal"
    >
      <a-form
        ref="formRef"
        :model="formState"
        layout="vertical"
      >
        <div class="batch-form-grid">
          <div class="batch-form-left">
            <a-form-item
              label="Sản phẩm"
              name="product_id"
              :rules="[{ required: true, message: 'Vui lòng chọn sản phẩm' }]"
            >
              <a-select
                v-model:value="formState.product_id"
                :options="productOptions"
                show-search
                option-filter-prop="label"
                placeholder="Chọn sản phẩm"
                :disabled="isEditMode"
                @change="handleProductChange"
              />
            </a-form-item>

            <a-form-item
              label="Mã lô"
              name="batch_code"
              :rules="[
                { required: true, message: 'Mã lô không được để trống' },
                { validator: validateBatchCode }
              ]"
            >
              <a-input
                v-model:value="formState.batch_code"
                placeholder="Nhập mã lô"
                :disabled="isEditMode"
              />
            </a-form-item>

            <div class="form-row-split">
              <a-form-item
                label="Số lượng"
                name="quantity"
                :rules="[
                  { required: true, message: 'Vui lòng nhập số lượng' },
                  { type: 'number', min: 1, message: 'Số lượng phải lớn hơn 0' }
                ]"
              >
                <a-input-number
                  v-model:value="formState.quantity"
                  :min="1"
                  :precision="0"
                  placeholder="Nhập số lượng"
                  class="w-full"
                  :disabled="isEditMode"
                />
              </a-form-item>

              <a-form-item
                label="Tồn còn lại"
                name="remaining_quantity"
                :rules="[
                  { required: true, message: 'Vui lòng nhập tồn còn lại' },
                  { type: 'number', min: 0, message: 'Tồn còn lại không được âm' }
                ]"
              >
                <a-input-number
                  v-model:value="formState.remaining_quantity"
                  :min="0"
                  :precision="0"
                  placeholder="Tồn còn lại"
                  class="w-full"
                  :disabled="modalMode === 'add'"
                />
              </a-form-item>
            </div>

            <a-form-item
              label="Ngày hết hạn"
              name="expiry_date"
              :rules="[
                { required: true, message: 'Vui lòng chọn ngày hết hạn' },
                { validator: validateExpiryDate }
              ]"
            >
              <a-date-picker
                v-model:value="formState.expiry_date"
                class="w-full"
                format="DD/MM/YYYY"
                :disabled-date="disabledPastDate"
                placeholder="Chọn ngày hết hạn"
              />
            </a-form-item>

            <a-form-item label="Ghi chú">
              <a-textarea
                v-model:value="formState.note"
                :rows="3"
                placeholder="Ghi chú thêm nếu cần"
                :disabled="isEditMode"
              />
            </a-form-item>
          </div>

          <div class="batch-form-right">
            <div class="summary-card">
              <h4>Thông tin lô</h4>
              <p><span>Sản phẩm</span><strong>{{ getSelectedProductName() }}</strong></p>
              <p><span>Mã lô</span><strong>{{ formState.batch_code || '---' }}</strong></p>
              <p><span>Số lượng</span><strong>{{ formState.quantity || 0 }}</strong></p>
              <p><span>Tồn còn lại</span><strong>{{ formState.remaining_quantity || 0 }}</strong></p>
              <p><span>Hạn dùng</span><strong>{{ formState.expiry_date ? formatDate(dayjs(formState.expiry_date).format('YYYY-MM-DD')) : '---' }}</strong></p>
            </div>

            <div class="note-box">
              <p>
                <strong>Lưu ý:</strong> Khi nhập số lượng ở modal thêm, tồn còn lại sẽ tự bằng số lượng.
                Khi sửa, chỉ được đổi ngày hết hạn và tồn còn lại để giữ đúng nghiệp vụ.
              </p>
            </div>
          </div>
        </div>
      </a-form>

      <template #footer>
        <a-space>
          <a-button @click="closeModal">Hủy</a-button>
          <a-button type="primary" :loading="saving" @click="submitModal">Lưu</a-button>
        </a-space>
      </template>
    </a-modal>
  </div>
</template>

<script setup>
import { computed, nextTick, onMounted, reactive, ref, watch } from 'vue'
import dayjs from 'dayjs'
import { message, Modal } from 'ant-design-vue'
import { useBatchStore } from '@/stores/batches'
import { useProductStore } from '@/stores/products'

const batchStore = useBatchStore()
const productStore = useProductStore()

const formRef = ref()
const showModal = ref(false)
const modalMode = ref('add')
const editingBatchId = ref(null)
const saving = ref(false)
const searchKeyword = ref('')
const statusFilter = ref('all')

const formState = reactive({
  product_id: undefined,
  batch_code: '',
  quantity: 1,
  remaining_quantity: 1,
  expiry_date: null,
  note: ''
})

const statusOptions = [
  { label: 'Tất cả trạng thái', value: 'all' },
  { label: 'Còn hạn', value: 'safe' },
  { label: 'Sắp hết hạn', value: 'warning' },
  { label: 'Hết hạn', value: 'expired' }
]

const productOptions = computed(() =>
  productStore.products.map((product) => ({
    label: product.name,
    value: product.id
  }))
)

// Chuẩn hóa dữ liệu lô để table và modal dùng cùng một cấu trúc
const normalizedBatches = computed(() => {
  return batchStore.batchesSortedByFefo.map((batch) => {
    const expiryDate = batch.expiry_date || batch.expiryDate
    const daysToExpiry = batch.daysToExpiry ?? batchStore.getDaysToExpiry(expiryDate)

    return {
      ...batch,
      product_id: batch.product_id ?? batch.productId,
      product_name: batch.product_name || batch.productName || resolveProductName(batch.product_id ?? batch.productId),
      batch_code: batch.batch_code || batch.batchNo,
      quantity: Number(batch.quantity ?? 0),
      remaining_quantity: Number(batch.remaining_quantity ?? batch.quantity ?? 0),
      expiry_date: expiryDate,
      daysToExpiry,
      status: resolveBatchStatus(daysToExpiry)
    }
  })
})

const filteredBatches = computed(() => {
  const keyword = searchKeyword.value.trim().toLowerCase()

  return normalizedBatches.value.filter((batch) => {
    const matchesKeyword = !keyword || [batch.batch_code, batch.product_name, String(batch.product_id)]
      .join(' ')
      .toLowerCase()
      .includes(keyword)

    const matchesStatus =
      statusFilter.value === 'all' ||
      (statusFilter.value === 'safe' && batch.status === 'Còn hàng') ||
      (statusFilter.value === 'warning' && batch.status === 'Sắp hết hạn') ||
      (statusFilter.value === 'expired' && batch.status === 'Hết hạn')

    return matchesKeyword && matchesStatus
  })
})

const expiredBatches = computed(() => batchStore.expiredBatches)
const expiringBatches = computed(() => batchStore.expiringBatches)
const safeBatches = computed(() => batchStore.totalBatches - expiredBatches.value - expiringBatches.value)

const modalTitle = computed(() => (modalMode.value === 'add' ? 'Thêm lô thuốc mới' : 'Chỉnh sửa lô thuốc'))
const isEditMode = computed(() => modalMode.value === 'edit')

const formatDate = (dateString) => {
  if (!dateString) return '---'
  return dayjs(dateString).format('DD/MM/YYYY')
}

const resolveProductName = (productId) => {
  const product = productStore.products.find((item) => String(item.id) === String(productId))
  return product?.name || 'Không xác định'
}

const getSelectedProductName = () => resolveProductName(formState.product_id)

const resolveBatchStatus = (daysToExpiry) => {
  if (daysToExpiry < 0) return 'Hết hạn'
  if (daysToExpiry <= 30) return 'Sắp hết hạn'
  return 'Còn hàng'
}

const getDaysBadgeClass = (days) => {
  if (days < 0) return 'expired'
  if (days <= 30) return 'warning'
  return 'safe'
}

const getStatusClass = (status) => {
  if (status === 'Còn hàng') return 'safe'
  if (status === 'Sắp hết hạn') return 'warning'
  return 'expired'
}

const getBatchRowClass = (batch) => {
  if (batch.daysToExpiry < 0) return 'row-expired'
  if (batch.daysToExpiry <= 30) return 'row-warning'
  return ''
}

const resolveProductInitial = (productName) => {
  return (productName || '?').slice(0, 1).toUpperCase()
}

// Chặn chọn ngày trong quá khứ
const disabledPastDate = (current) => {
  return current && current < dayjs().startOf('day')
}

// Validator cho mã lô
const validateBatchCode = async (_rule, value) => {
  if (!String(value || '').trim()) {
    return Promise.reject(new Error('Mã lô không được để trống'))
  }
  return Promise.resolve()
}

// Validator cho ngày hết hạn
const validateExpiryDate = async (_rule, value) => {
  if (!value) {
    return Promise.reject(new Error('Vui lòng chọn ngày hết hạn'))
  }
  if (dayjs(value).isBefore(dayjs().startOf('day'))) {
    return Promise.reject(new Error('Không được chọn ngày trong quá khứ'))
  }
  return Promise.resolve()
}

// Khi nhập quantity ở modal thêm thì tự nhảy remaining_quantity
watch(
  () => formState.quantity,
  (value) => {
    if (modalMode.value === 'add') {
      formState.remaining_quantity = Number(value || 0)
    }
  }
)

const resetForm = () => {
  formState.product_id = undefined
  formState.batch_code = ''
  formState.quantity = 1
  formState.remaining_quantity = 1
  formState.expiry_date = null
  formState.note = ''
}

const openAddModal = async () => {
  modalMode.value = 'add'
  editingBatchId.value = null
  resetForm()
  showModal.value = true
  await nextTick()
  formRef.value?.clearValidate?.()
}

const openEditModal = async (batch) => {
  modalMode.value = 'edit'
  editingBatchId.value = batch.id

  // Đổ dữ liệu dòng đã chọn vào form
  Object.assign(formState, {
    product_id: batch.product_id,
    batch_code: batch.batch_code,
    quantity: batch.quantity,
    remaining_quantity: batch.remaining_quantity,
    expiry_date: dayjs(batch.expiry_date),
    note: batch.note || ''
  })

  showModal.value = true
  await nextTick()
  formRef.value?.clearValidate?.()
}

const closeModal = () => {
  showModal.value = false
  editingBatchId.value = null
  resetForm()
}

const buildPayload = () => {
  const productId = Number(formState.product_id)
  const expiryDate = dayjs(formState.expiry_date).format('YYYY-MM-DD')
  const product = productStore.products.find((item) => Number(item.id) === Number(productId))

  return {
    productId,
    product_id: productId,
    productName: product?.name || '',
    product_name: product?.name || '',
    batch_code: String(formState.batch_code).trim(),
    quantity: Number(formState.quantity),
    remaining_quantity: Number(formState.remaining_quantity),
    expiryDate,
    expiry_date: expiryDate,
    manufactureDate: dayjs().format('YYYY-MM-DD'),
    manufacture_date: dayjs().format('YYYY-MM-DD'),
    note: formState.note,
    status: resolveBatchStatus(batchStore.getDaysToExpiry(expiryDate))
  }
}

const handleAdd = async () => {
  // Tạo lô mới và đồng bộ FEFO sau khi lưu
  const payload = buildPayload()
  const created = await batchStore.createBatchAPI(payload)
  message.success(`Đã thêm lô ${created.batch_code} thành công`)
  closeModal()
}

const handleEdit = async () => {
  // Chỉ cập nhật expiry_date và remaining_quantity theo nghiệp vụ chỉnh sửa
  const existing = batchStore.batches.find((item) => item.id === editingBatchId.value)
  if (!existing) {
    throw new Error('Không tìm thấy lô cần chỉnh sửa')
  }

  const expiryDate = dayjs(formState.expiry_date).format('YYYY-MM-DD')
  const payload = {
    expiry_date: expiryDate,
    remaining_quantity: Number(formState.remaining_quantity)
  }

  const updated = await batchStore.updateBatchAPI(editingBatchId.value, payload)
  message.success(`Đã cập nhật lô ${updated?.batch_code || existing.batch_code} thành công`)
  closeModal()
}

const handleDelete = async (id) => {
  // Xóa lô và tính lại FEFO ngay sau khi hoàn tất
  const target = normalizedBatches.value.find((item) => item.id === id)

  Modal.confirm({
    title: 'Xác nhận xóa lô',
    content: `Bạn có chắc muốn xóa lô ${target?.batch_code || id} không?`,
    okText: 'Xóa',
    okType: 'danger',
    cancelText: 'Hủy',
    async onOk() {
      batchStore.deleteBatch(id)
      message.success(`Đã xóa lô ${target?.batch_code || id} thành công`)
    }
  })
}

const submitModal = async () => {
  try {
    await formRef.value?.validate()
    saving.value = true

    if (modalMode.value === 'add') {
      await handleAdd()
    } else {
      await handleEdit()
    }
  } catch (error) {
    if (error?.errorFields) return
    message.error(error?.message || 'Có lỗi xảy ra, vui lòng thử lại')
  } finally {
    saving.value = false
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

onMounted(async () => {
  await Promise.all([
    batchStore.fetchBatches(),
    productStore.fetchProducts({ per_page: 50 })
  ])
})
</script>

<style scoped>
.batches-page {
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

/* Statistics Grid */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

.stat-card {
  padding: 16px;
  border-radius: 8px;
  border: 2px solid #e2e8f0;
  text-align: center;
}

.stat-card.safe {
  background: #f0fdf4;
  border-color: #86efac;
  color: #166534;
}

.stat-card.warning {
  background: #fffbeb;
  border-color: #fcd34d;
  color: #92400e;
}

.stat-card.expired {
  background: #fef2f2;
  border-color: #fecaca;
  color: #991b1b;
}

.stat-label {
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  margin: 0 0 8px 0;
  letter-spacing: 0.5px;
  opacity: 0.8;
}

.stat-value {
  font-size: 28px;
  font-weight: 700;
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
}

.filter-select {
  min-width: 200px;
}

.search-input :deep(.ant-input-search),
.filter-select :deep(.ant-select-selector) {
  border-radius: 8px !important;
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

.batches-table {
  width: 100%;
  min-width: 1080px;
  border-collapse: collapse;
  font-size: 13px;
}

.batches-table thead {
  background: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
}

.batches-table th {
  padding: 12px 14px;
  text-align: left;
  font-weight: 600;
  color: #475569;
  white-space: nowrap;
}

.batches-table td {
  padding: 12px 14px;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: top;
}

.batches-table tbody tr {
  transition: all 0.2s ease;
}

.batches-table tbody tr:hover {
  background: #f8fafc;
}

.batches-table tbody tr.row-expired {
  background: #fef2f2;
  border-left: 3px solid #ef4444;
}

.batches-table tbody tr.row-warning {
  background: #fffbeb;
  border-left: 3px solid #f59e0b;
}

.col-batch { width: 120px; }
.col-product { width: 28%; }
.col-qty { width: 110px; }
.col-remain { width: 120px; }
.col-expiry { width: 140px; }
.col-days { width: 120px; }
.col-status { width: 120px; }
.col-actions { width: 100px; text-align: center; }

.font-weight-600 {
  font-weight: 600;
  color: #1e3a8a;
}

.product-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}

.product-thumb {
  width: 38px;
  height: 38px;
  border-radius: 10px;
  background: #dbeafe;
  color: #1e3a8a;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  flex-shrink: 0;
}

.product-name {
  margin: 0 0 2px 0;
  font-weight: 600;
  color: #1e3a8a;
}

.product-sub {
  margin: 0;
  font-size: 11px;
  color: #64748b;
}

/* Badges */
.qty-badge {
  background: #e0e7ff;
  color: #1e3a8a;
  padding: 4px 8px;
  border-radius: 4px;
  font-weight: 600;
  display: inline-block;
}

.qty-badge.remaining {
  background: #d1fae5;
  color: #065f46;
}

.days-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-weight: 600;
  font-size: 12px;
}

.days-badge.safe {
  background: #d1fae5;
  color: #065f46;
}

.days-badge.warning {
  background: #fef3c7;
  color: #92400e;
}

.days-badge.expired {
  background: #fee2e2;
  color: #991b1b;
}

.status-badge {
  padding: 4px 10px;
  border-radius: 4px;
  font-weight: 600;
  font-size: 12px;
}

.status-safe {
  background: #d1fae5;
  color: #065f46;
}

.status-warning {
  background: #fef3c7;
  color: #92400e;
}

.status-expired {
  background: #fee2e2;
  color: #991b1b;
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

/* Legend */
.legend {
  display: flex;
  gap: 24px;
  padding: 16px;
  background: #f8fafc;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  font-size: 12px;
}

.legend p {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0;
  color: #475569;
}

.legend-safe,
.legend-warning,
.legend-expired {
  width: 12px;
  height: 12px;
  border-radius: 2px;
}

.legend-safe {
  background: #86efac;
}

.legend-warning {
  background: #fcd34d;
}

.legend-expired {
  background: #fecaca;
}

/* Modal layout */
.batch-form-grid {
  display: grid;
  grid-template-columns: minmax(0, 1.5fr) minmax(280px, 0.85fr);
  gap: 18px;
}

.batch-form-left {
  min-width: 0;
}

.batch-form-right {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.form-row-split {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.w-full {
  width: 100%;
}

.summary-card,
.note-box {
  border: 1px solid #dbe7f8;
  border-radius: 14px;
  background: #f8fbff;
  padding: 14px;
}

.summary-card h4 {
  margin: 0 0 12px 0;
  font-size: 14px;
  color: #1e3a8a;
}

.summary-card p {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  margin: 0 0 8px 0;
  font-size: 12px;
  color: #475569;
}

.summary-card p:last-child {
  margin-bottom: 0;
}

.summary-card span {
  color: #64748b;
}

.summary-card strong {
  color: #1e3a8a;
  text-align: right;
}

.note-box p {
  margin: 0;
  font-size: 12px;
  line-height: 1.6;
  color: #475569;
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
  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .filters {
    flex-wrap: wrap;
  }

  .batch-form-grid {
    grid-template-columns: 1fr;
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
    flex-direction: column;
  }

  .table-container {
    overflow-x: auto;
  }

  .form-row-split {
    grid-template-columns: 1fr;
  }
}
</style>
