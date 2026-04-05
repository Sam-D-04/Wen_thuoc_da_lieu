
<template>
  <div class="orders-page">
    <div class="page-header">
      <div>
        <h1>Quản lý đơn hàng</h1>
        <p class="breadcrumb">Nhà thuốc Da liễu / Đơn hàng</p>
      </div>
      <a-space>
        <a-button type="primary" @click="openCreateModal">+ Tạo đơn hàng</a-button>
      </a-space>
    </div>

    <div class="stats-grid">
      <a-card class="stat-card" :bordered="false">
        <p class="stat-label">Tổng đơn hàng</p>
        <p class="stat-value">{{ orderStats.totalOrders }}</p>
      </a-card>
      <a-card class="stat-card" :bordered="false">
        <p class="stat-label">Chờ xử lý</p>
        <p class="stat-value">{{ orderStats.pendingOrders }}</p>
      </a-card>
      <a-card class="stat-card" :bordered="false">
        <p class="stat-label">Đang xử lý</p>
        <p class="stat-value">{{ orderStats.processingOrders }}</p>
      </a-card>
      <a-card class="stat-card" :bordered="false">
        <p class="stat-label">Tổng doanh thu</p>
        <p class="stat-value">{{ formatMoney(orderStats.totalRevenue) }}</p>
      </a-card>
    </div>

    <a-card class="toolbar-card" :bordered="false">
      <a-space wrap>
        <a-input v-model:value="keyword" allow-clear placeholder="Tìm theo mã đơn, khách hàng, SĐT..." class="toolbar-input" />
        <a-select v-model:value="statusFilter" :options="statusFilterOptions" class="toolbar-select" />
      </a-space>
    </a-card>

    <a-card class="table-card" :bordered="false">
      <a-table
        :columns="columns"
        :data-source="filteredOrders"
        :row-key="(record) => record.id"
        :pagination="{ pageSize: 8, showSizeChanger: false }"
        :table-layout="'fixed'"
        size="middle"
      >
        <template #bodyCell="{ column, record }">
          <template v-if="column.key === 'id'">
            <div class="order-id-cell">
              <strong>{{ record.id }}</strong>
              <div class="muted">{{ formatDate(record.orderDate) }}</div>
            </div>
          </template>

          <template v-else-if="column.key === 'customer'">
            <div class="customer-cell">
              <div class="customer-avatar">{{ getInitial(record.customerName) }}</div>
              <div>
                <div class="customer-name cell-ellipsis">{{ record.customerName }}</div>
                <div class="muted cell-ellipsis">{{ record.customerPhone }}</div>
              </div>
            </div>
          </template>

          <template v-else-if="column.key === 'paymentMethod'">
            <span class="cell-ellipsis">{{ record.paymentMethodLabel }}</span>
          </template>

          <template v-else-if="column.key === 'status'">
            <a-tag :color="record.statusColor">{{ record.statusLabel }}</a-tag>
          </template>

          <template v-else-if="column.key === 'total_amount'">
            {{ formatMoney(record.total_amount) }}
          </template>

          <template v-else-if="column.key === 'shipping_fee'">
            {{ formatMoney(record.shipping_fee) }}
          </template>

          <template v-else-if="column.key === 'final_amount'">
            <strong>{{ formatMoney(record.final_amount) }}</strong>
          </template>

          <template v-else-if="column.key === 'actions'">
            <div class="action-group">
              <a-button
                size="small"
                class="action-btn action-detail"
                title="Chi tiết"
                aria-label="Chi tiết"
                @click="openDetailModal(record)"
              >
                <span class="action-icon" v-html="getActionIcon('detail')"></span>
              </a-button>
              <a-button
                v-if="canCancel(record)"
                size="small"
                class="action-btn action-cancel"
                title="Hủy"
                aria-label="Hủy"
                @click="confirmCancel(record)"
              >
                <span class="action-icon" v-html="getActionIcon('cancel')"></span>
              </a-button>
              <a-button
                v-if="canDelete(record)"
                size="small"
                class="action-btn action-delete"
                title="Xóa"
                aria-label="Xóa"
                @click="confirmDelete(record)"
              >
                <span class="action-icon" v-html="getActionIcon('delete')"></span>
              </a-button>
            </div>
          </template>
        </template>
      </a-table>
    </a-card>

    <a-modal
      v-model:open="createVisible"
      :title="createMode === 'create' ? 'Tạo đơn hàng mới' : 'Chỉnh sửa đơn hàng mới'"
      :width="1180"
      :confirm-loading="creating"
      destroy-on-close
      ok-text="Lưu đơn hàng"
      cancel-text="Hủy"
      @ok="submitCreateOrder"
      @cancel="closeCreateModal"
    >
      <a-form ref="createFormRef" :model="createForm" layout="vertical">
        <a-row :gutter="16">
          <a-col :span="8">
            <a-form-item label="Khách hàng" name="customerId" :rules="[{ required: true, message: 'Vui lòng chọn khách hàng' }]">
              <a-select
                v-model:value="createForm.customerId"
                show-search
                :options="customerOptions"
                placeholder="Chọn khách hàng"
                option-filter-prop="label"
              />
            </a-form-item>
          </a-col>
          <a-col :span="8">
            <a-form-item label="Địa chỉ giao hàng" name="addressId" :rules="[{ required: true, message: 'Vui lòng chọn địa chỉ' }]">
              <a-select
                v-model:value="createForm.addressId"
                :options="addressOptions"
                placeholder="Chọn địa chỉ"
                :disabled="!createForm.customerId"
              />
            </a-form-item>
          </a-col>
          <a-col :span="4">
            <a-form-item label="Thanh toán" name="paymentMethod" :rules="[{ required: true, message: 'Vui lòng chọn phương thức thanh toán' }]">
              <a-select v-model:value="createForm.paymentMethod" :options="paymentMethodOptions" />
            </a-form-item>
          </a-col>
          <a-col :span="4">
            <a-form-item label="Phí ship" name="shippingFee">
              <a-input-number v-model:value="createForm.shippingFee" :min="0" class="full-width" />
            </a-form-item>
          </a-col>
        </a-row>

        <a-divider>Danh sách sản phẩm</a-divider>

        <div class="item-actions">
          <a-button @click="addItemLine">+ Thêm dòng sản phẩm</a-button>
          <span class="hint">Mỗi dòng chọn sản phẩm, lô và số lượng. Tồn lô sẽ được kiểm tra trước khi lưu.</span>
        </div>

        <div v-for="(line, index) in createForm.items" :key="line.id" class="order-line-card">
          <div class="line-head">
            <strong>Dòng {{ index + 1 }}</strong>
            <a-button type="link" danger @click="removeItemLine(index)" :disabled="createForm.items.length === 1">Xóa dòng</a-button>
          </div>

          <a-row :gutter="12">
            <a-col :span="8">
              <a-form-item label="Sản phẩm">
                <a-select
                  v-model:value="line.productId"
                  show-search
                  :options="productOptions"
                  placeholder="Chọn sản phẩm"
                  option-filter-prop="label"
                  @change="handleProductChange(index)"
                />
              </a-form-item>
            </a-col>
            <a-col :span="8">
              <a-form-item label="Lô thuốc">
                <a-select
                  v-model:value="line.batchId"
                  :options="getBatchOptions(line.productId)"
                  placeholder="Chọn lô"
                  :disabled="!line.productId"
                  @change="handleBatchChange(index)"
                />
              </a-form-item>
            </a-col>
            <a-col :span="4">
              <a-form-item label="Số lượng">
                <a-input-number v-model:value="line.quantity" :min="1" :precision="0" class="full-width" />
              </a-form-item>
            </a-col>
            <a-col :span="4">
              <a-form-item label="Đơn giá">
                <a-input :value="formatMoney(lineUnitPrice(line.productId))" disabled />
              </a-form-item>
            </a-col>
          </a-row>

          <div class="line-summary">
            <span>Tồn khả dụng: {{ lineAvailableQuantity(line.batchId) }}</span>
            <span>Tạm tính: {{ formatMoney(lineSubtotal(line)) }}</span>
          </div>
        </div>

        <a-divider>Tổng kết đơn hàng</a-divider>
        <div class="totals-grid">
          <div>
            <span>Tổng tiền hàng</span>
            <strong>{{ formatMoney(createTotals.total_amount) }}</strong>
          </div>
          <div>
            <span>Phí vận chuyển</span>
            <strong>{{ formatMoney(createTotals.shipping_fee) }}</strong>
          </div>
          <div>
            <span>Thành tiền</span>
            <strong>{{ formatMoney(createTotals.final_amount) }}</strong>
          </div>
        </div>

        <a-form-item label="Ghi chú">
          <a-textarea v-model:value="createForm.note" :rows="3" placeholder="Ghi chú cho đơn hàng" />
        </a-form-item>

        <a-alert v-if="createError" type="error" :message="createError" show-icon />
      </a-form>
    </a-modal>

    <a-modal
      v-model:open="detailVisible"
      title="Chi tiết đơn hàng"
      :width="1180"
      :confirm-loading="savingDetail"
      ok-text="Lưu thay đổi"
      cancel-text="Đóng"
      destroy-on-close
      @ok="submitDetailOrder"
      @cancel="closeDetailModal"
    >
      <div v-if="selectedOrder" class="detail-layout">
        <a-descriptions bordered :column="2" size="small">
          <a-descriptions-item label="Mã đơn">{{ selectedOrder.id }}</a-descriptions-item>
          <a-descriptions-item label="Ngày tạo">{{ formatDate(selectedOrder.orderDate) }}</a-descriptions-item>
          <a-descriptions-item label="Khách hàng">{{ selectedOrder.customerName }}</a-descriptions-item>
          <a-descriptions-item label="SĐT">{{ selectedOrder.customerPhone }}</a-descriptions-item>
          <a-descriptions-item label="Email">{{ selectedOrder.customerEmail }}</a-descriptions-item>
          <a-descriptions-item label="Phương thức thanh toán">{{ selectedOrder.paymentMethodLabel }}</a-descriptions-item>
          <a-descriptions-item label="Tổng tiền">{{ formatMoney(selectedOrder.total_amount) }}</a-descriptions-item>
          <a-descriptions-item label="Phí ship">{{ formatMoney(selectedOrder.shipping_fee) }}</a-descriptions-item>
          <a-descriptions-item label="Thành tiền">{{ formatMoney(selectedOrder.final_amount) }}</a-descriptions-item>
          <a-descriptions-item label="Trạng thái hiện tại">
            <a-tag :color="selectedOrder.statusColor">{{ selectedOrder.statusLabel }}</a-tag>
          </a-descriptions-item>
        </a-descriptions>

        <a-divider>Địa chỉ giao hàng</a-divider>
        <a-empty v-if="!selectedCustomerAddresses.length" description="Không có địa chỉ" />
        <div v-else class="address-grid">
          <a-card v-for="address in selectedCustomerAddresses" :key="address.id" size="small" class="address-card">
            <div class="address-head">
              <strong>{{ address.recipient_name }}</strong>
              <a-tag v-if="address.is_default" color="blue">Mặc định</a-tag>
            </div>
            <p>{{ address.phone }}</p>
            <p>{{ formatAddress(address) }}</p>
          </a-card>
        </div>

        <a-divider>Sản phẩm đã mua</a-divider>
        <a-table
          :columns="itemColumns"
          :data-source="selectedOrder.items"
          :row-key="(item, index) => item.id || `${selectedOrder.id}-item-${index}`"
          :pagination="false"
          size="small"
          :table-layout="'fixed'"
        >
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'product'">
              <div class="order-product-cell">
                <strong>{{ record.product_name || record.productName }}</strong>
                <div class="muted">Lô: {{ record.batch_id || record.batchId }}</div>
              </div>
            </template>
            <template v-else-if="column.key === 'quantity'">
              {{ record.quantity }}
            </template>
            <template v-else-if="column.key === 'price'">
              {{ formatMoney(record.unit_price || record.price) }}
            </template>
            <template v-else-if="column.key === 'subtotal'">
              <strong>{{ formatMoney(record.subtotal) }}</strong>
            </template>
          </template>
        </a-table>

        <a-divider>Cập nhật trạng thái</a-divider>
        <a-form ref="detailFormRef" :model="detailForm" layout="vertical">
          <a-row :gutter="16">
            <a-col :span="12">
              <a-form-item label="Trạng thái đơn" name="order_status" :rules="[{ required: true, message: 'Vui lòng chọn trạng thái' }]">
                <a-select v-model:value="detailForm.order_status" :options="orderStatusOptions" />
              </a-form-item>
            </a-col>
            <a-col :span="12">
              <a-form-item label="Ghi chú">
                <a-textarea v-model:value="detailForm.note" :rows="4" placeholder="Ghi chú cập nhật" />
              </a-form-item>
            </a-col>
          </a-row>
        </a-form>

        <a-space>
          <a-button danger v-if="canCancel(selectedOrder)" @click="confirmCancel(selectedOrder)">Hủy đơn</a-button>
          <a-button danger v-if="canDelete(selectedOrder)" @click="confirmDelete(selectedOrder)">Xóa đơn</a-button>
        </a-space>

        <a-alert v-if="detailError" type="error" :message="detailError" show-icon class="detail-error" />
      </div>
    </a-modal>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue'
import dayjs from 'dayjs'
import { Modal, message } from 'ant-design-vue'
import { useOrderStore } from '@/stores/orders'
import { useCustomerStore } from '@/stores/customers'
import { useProductStore } from '@/stores/products'
import { useBatchStore } from '@/stores/batches'

const orderStore = useOrderStore()
const customerStore = useCustomerStore()
const productStore = useProductStore()
const batchStore = useBatchStore()

const keyword = ref('')
const statusFilter = ref('all')
const createVisible = ref(false)
const detailVisible = ref(false)
const createMode = ref('create')
const creating = ref(false)
const savingDetail = ref(false)
const createError = ref('')
const detailError = ref('')
const selectedOrderId = ref(null)
const createFormRef = ref()
const detailFormRef = ref()

const paymentMethodOptions = orderStore.paymentMethods.map((item) => ({ label: item.label, value: item.value }))
const orderStatusOptions = orderStore.orderStatusOptions.map((item) => ({ label: orderStore.orderStatusLabels[item], value: item }))
const statusFilterOptions = [
  { label: 'Tất cả trạng thái', value: 'all' },
  ...orderStatusOptions.map((item) => ({ label: item.label, value: item.value }))
]

const columns = [
  { title: 'Mã đơn', key: 'id', dataIndex: 'id', width: 140 },
  { title: 'Khách hàng', key: 'customer', dataIndex: 'customer', width: 220 },
  { title: 'Thanh toán', key: 'paymentMethod', dataIndex: 'paymentMethod', width: 110 },
  { title: 'Tổng tiền', key: 'total_amount', dataIndex: 'total_amount', width: 110 },
  { title: 'Phí ship', key: 'shipping_fee', dataIndex: 'shipping_fee', width: 100 },
  { title: 'Thành tiền', key: 'final_amount', dataIndex: 'final_amount', width: 120 },
  { title: 'Trạng thái', key: 'status', dataIndex: 'status', width: 110 },
  { title: 'Thao tác', key: 'actions', dataIndex: 'actions', width: 160 }
]

const itemColumns = [
  { title: 'Sản phẩm', key: 'product', dataIndex: 'product', width: 320 },
  { title: 'Số lượng', key: 'quantity', dataIndex: 'quantity', width: 100 },
  { title: 'Đơn giá', key: 'price', dataIndex: 'price', width: 120 },
  { title: 'Tạm tính', key: 'subtotal', dataIndex: 'subtotal', width: 130 }
]

const createLine = () => ({
  id: `line-${Date.now()}-${Math.random().toString(16).slice(2)}`,
  productId: undefined,
  batchId: undefined,
  quantity: 1
})

const createForm = reactive({
  customerId: undefined,
  addressId: undefined,
  paymentMethod: 'bank_transfer',
  shippingFee: 20000,
  note: '',
  items: [createLine()]
})

const detailForm = reactive({
  order_status: 'pending',
  note: ''
})

const formatMoney = (value) => {
  return `${new Intl.NumberFormat('vi-VN', { maximumFractionDigits: 0 }).format(Number(value || 0))} đ`
}

const formatDate = (dateString) => {
  if (!dateString) return '-'
  return new Intl.DateTimeFormat('vi-VN').format(new Date(dateString))
}

const getInitial = (text) => String(text || '?').trim().charAt(0).toUpperCase()

const getActionIcon = (name) => {
  const iconMap = {
    detail: `
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <path d="M4.5 12s2.7-5.5 7.5-5.5S19.5 12 19.5 12 16.8 17.5 12 17.5 4.5 12 4.5 12Z" />
        <circle cx="12" cy="12" r="2.3" />
      </svg>
    `,
    cancel: `
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <path d="M6 6l12 12" />
        <path d="M18 6 6 18" />
      </svg>
    `,
    delete: `
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <path d="M5 7h14" />
        <path d="M9 7V5.6c0-.9.7-1.6 1.6-1.6h2.8c.9 0 1.6.7 1.6 1.6V7" />
        <path d="M8 7l.6 11.2c0 .9.7 1.6 1.6 1.6h3.6c.9 0 1.6-.7 1.6-1.6L16 7" />
      </svg>
    `
  }

  return iconMap[name] || iconMap.detail
}

const normalizeOrderStatus = (status) => {
  if (orderStore.orderStatusOptions.includes(status)) return status
  if (status === 'Chờ xử lý') return 'pending'
  if (status === 'Đã xác nhận') return 'confirmed'
  if (status === 'Đang đóng gói') return 'packing'
  if (status === 'Đang chuẩn bị hàng') return 'packing'
  if (status === 'Đang giao') return 'shipping'
  if (status === 'Đã giao' || status === 'Đã giao hàng') return 'delivered'
  if (status === 'Đã hủy') return 'cancelled'
  if (status === 'processing') return 'packing'
  return 'pending'
}

const mapOrderView = (order) => {
  const normalizedStatus = normalizeOrderStatus(order.order_status || order.status || 'pending')
  return {
    ...order,
    order_status: normalizedStatus,
    statusLabel: orderStore.orderStatusLabels[normalizedStatus] || order.status || '-',
    statusColor: orderStore.orderStatusColors[normalizedStatus] || 'default',
    paymentMethodLabel: orderStore.paymentMethodLabels[order.payment_method] || order.payment_method || '-'
  }
}

const orderViews = computed(() => orderStore.orders.map(mapOrderView))

const orderStats = computed(() => ({
  totalOrders: orderViews.value.length,
  pendingOrders: orderViews.value.filter((order) => order.order_status === 'pending').length,
  processingOrders: orderViews.value.filter((order) => ['confirmed', 'packing', 'shipping'].includes(order.order_status)).length,
  totalRevenue: orderViews.value.reduce((sum, order) => sum + Number(order.final_amount || 0), 0)
}))

const filteredOrders = computed(() => {
  const text = keyword.value.trim().toLowerCase()

  return orderViews.value.filter((order) => {
    const matchesText =
      !text ||
      [order.id, order.customerName, order.customerPhone, order.customerEmail, order.statusLabel]
        .join(' ')
        .toLowerCase()
        .includes(text)

    const matchesStatus =
      statusFilter.value === 'all' ||
      order.order_status === statusFilter.value

    return matchesText && matchesStatus
  })
})

const customerOptions = computed(() =>
  customerStore.customers
    .filter((customer) => customer.role === 'customer')
    .map((customer) => ({ label: `${customer.name} - ${customer.phone}`, value: customer.id }))
)

const selectedCustomer = computed(() =>
  customerStore.customers.find((customer) => customer.id === createForm.customerId)
)

const selectedCustomerAddresses = computed(() => {
  if (!selectedOrderId.value) {
    return selectedCustomer.value?.user_addresses || []
  }

  const order = orderStore.getOrderById(selectedOrderId.value)
  const customer = customerStore.customers.find((item) => item.id === order?.customerId)
  return customer?.user_addresses || []
})

const addressOptions = computed(() => {
  const addresses = selectedCustomer.value?.user_addresses || []
  return addresses.map((address) => ({
    label: formatAddress(address),
    value: address.id
  }))
})

const selectedOrder = computed(() => {
  if (!selectedOrderId.value) return null
  const order = orderStore.getOrderById(selectedOrderId.value)
  return order ? mapOrderView(order) : null
})

const createTotals = computed(() => {
  const total_amount = createForm.items.reduce((sum, line) => sum + lineSubtotal(line), 0)
  const shipping_fee = Number(createForm.shippingFee || 0)
  return {
    total_amount,
    shipping_fee,
    final_amount: total_amount + shipping_fee
  }
})

const productOptions = computed(() =>
  productStore.products.map((product) => ({ label: product.name, value: product.id }))
)

const lineProduct = (productId) => productStore.products.find((product) => String(product.id) === String(productId))
const lineBatch = (batchId) => batchStore.batches.find((batch) => String(batch.id) === String(batchId))

const lineUnitPrice = (productId) => Number(lineProduct(productId)?.price || 0)
const lineAvailableQuantity = (batchId) => Number(lineBatch(batchId)?.remaining_quantity ?? lineBatch(batchId)?.quantity ?? 0)
const lineSubtotal = (line) => lineUnitPrice(line.productId) * Number(line.quantity || 0)

const formatAddress = (address) => {
  const parts = [address.address_line, address.ward, address.district, address.province].filter(Boolean)
  return parts.join(', ')
}

const getBatchOptions = (productId) => {
  if (!productId) return []
  return orderStore.getAvailableBatchesForProduct(productId).map((batch) => ({
    label: `${batch.label} | HSD: ${formatDate(batch.expiry_date)}`,
    value: batch.value
  }))
}

const resetCreateForm = () => {
  createForm.customerId = undefined
  createForm.addressId = undefined
  createForm.paymentMethod = 'bank_transfer'
  createForm.shippingFee = 20000
  createForm.note = ''
  createForm.items.splice(0, createForm.items.length, createLine())
  createError.value = ''
}

const openCreateModal = () => {
  createMode.value = 'create'
  resetCreateForm()
  createVisible.value = true
}

const closeCreateModal = () => {
  createVisible.value = false
  resetCreateForm()
}

const openDetailModal = (order) => {
  selectedOrderId.value = order.id
  detailForm.order_status = order.order_status
  detailForm.note = order.note || ''
  detailError.value = ''
  detailVisible.value = true
}

const closeDetailModal = () => {
  detailVisible.value = false
  selectedOrderId.value = null
  detailError.value = ''
}

const addItemLine = () => {
  createForm.items.push(createLine())
}

const removeItemLine = (index) => {
  if (createForm.items.length === 1) return
  createForm.items.splice(index, 1)
}

const handleProductChange = (index) => {
  createForm.items[index].batchId = undefined
}

const handleBatchChange = (index) => {
  const batch = lineBatch(createForm.items[index].batchId)
  if (batch && Number(createForm.items[index].quantity || 0) > Number(batch.remaining_quantity ?? batch.quantity ?? 0)) {
    createForm.items[index].quantity = Number(batch.remaining_quantity ?? batch.quantity ?? 0)
  }
}

const canCancel = (order) => ['pending', 'confirmed', 'packing', 'shipping'].includes(order.order_status)
const canDelete = (order) => ['pending', 'cancelled'].includes(order.order_status)

const validateCreateOrder = () => {
  if (!createForm.customerId) return 'Vui lòng chọn khách hàng.'
  if (!createForm.addressId) return 'Vui lòng chọn địa chỉ giao hàng.'
  if (!createForm.paymentMethod) return 'Vui lòng chọn phương thức thanh toán.'
  if (!createForm.items.length) return 'Đơn hàng phải có ít nhất một dòng sản phẩm.'

  const usedBatchIds = new Set()

  for (let index = 0; index < createForm.items.length; index += 1) {
    const line = createForm.items[index]
    const product = lineProduct(line.productId)
    const batch = lineBatch(line.batchId)

    if (!product) return `Dòng ${index + 1}: vui lòng chọn sản phẩm.`
    if (!batch) return `Dòng ${index + 1}: vui lòng chọn lô thuốc.`
    if (String(batch.product_id ?? batch.productId) !== String(product.id)) {
      return `Dòng ${index + 1}: lô thuốc không khớp với sản phẩm.`
    }
    if (usedBatchIds.has(batch.id)) {
      return `Dòng ${index + 1}: không được chọn trùng lô thuốc.`
    }

    const quantity = Number(line.quantity || 0)
    const available = Number(batch.remaining_quantity ?? batch.quantity ?? 0)
    if (!Number.isInteger(quantity) || quantity <= 0) {
      return `Dòng ${index + 1}: số lượng phải là số nguyên dương.`
    }
    if (quantity > available) {
      return `Dòng ${index + 1}: số lượng vượt quá tồn khả dụng của lô.`
    }

    usedBatchIds.add(batch.id)
  }

  return ''
}



const submitCreateOrder = async () => {
  try {
    await createFormRef.value?.validate()

    const customer = selectedCustomer.value
    const address = (customer?.user_addresses || []).find(
      (item) => item.id === createForm.addressId
    )

    const payload = {
      items: createForm.items.map((line) => ({
        product_id: line.productId,
        quantity: Number(line.quantity)
      })),
      address: {
        full_name: customer.name,
        phone: customer.phone,
        address_line: address.address_line,
        ward: address.ward,
        district: address.district,
        city: address.city
      },
      payment_method: createForm.paymentMethod,
      note: createForm.note
    }

    creating.value = true
    createError.value = ''

    // 🔥 GỌI STORE (KHÔNG GỌI AXIOS TRỰC TIẾP)
    const res = await orderStore.createOrderAPI(payload)

    // 🔥 REDIRECT THANH TOÁN
    if (res.payment_url) {
      window.location.href = res.payment_url
    } else {
      message.success('Đặt hàng thành công')
      closeCreateModal()
    }

  } catch (error) {
    createError.value = error?.message || 'Lỗi tạo đơn'
  } finally {
    creating.value = false
  }
}

const submitDetailOrder = async () => {
  try {
    await detailFormRef.value?.validate()
    if (!selectedOrderId.value) return

    const currentOrder = orderStore.getOrderById(selectedOrderId.value)
    if (!currentOrder) return

    savingDetail.value = true
    detailError.value = ''

    if (detailForm.order_status === 'cancelled') {
      orderStore.cancelOrder(currentOrder.id, detailForm.note)
    } else {
      orderStore.updateOrderStatus(currentOrder.id, detailForm.order_status)
      orderStore.updateOrder(currentOrder.id, {
        note: detailForm.note,
        order_status: detailForm.order_status
      })
    }

    message.success('Đã cập nhật đơn hàng')
    closeDetailModal()
  } catch (error) {
    if (error?.errorFields) return
    detailError.value = error?.message || 'Không thể cập nhật đơn hàng'
  } finally {
    savingDetail.value = false
  }
}

const confirmCancel = (order) => {
  Modal.confirm({
    title: 'Xác nhận hủy đơn',
    content: `Bạn có chắc muốn hủy đơn ${order.id} không? Hệ thống sẽ cộng lại tồn cho các lô liên quan.`,
    okText: 'Hủy đơn',
    okType: 'danger',
    cancelText: 'Không',
    onOk() {
      orderStore.cancelOrder(order.id, 'Hủy từ giao diện quản lý.')
      message.success(`Đã hủy đơn ${order.id}`)
      if (selectedOrderId.value === order.id) {
        detailVisible.value = false
      }
    }
  })
}

const confirmDelete = (order) => {
  Modal.confirm({
    title: 'Xác nhận xóa đơn',
    content: `Bạn có chắc muốn xóa đơn ${order.id} không?`,
    okText: 'Xóa',
    okType: 'danger',
    cancelText: 'Không',
    onOk() {
      orderStore.deleteOrder(order.id)
      message.success(`Đã xóa đơn ${order.id}`)
      if (selectedOrderId.value === order.id) {
        detailVisible.value = false
      }
    }
  })
}

watch(createVisible, (visible) => {
  if (visible && !createForm.customerId && customerOptions.value.length > 0) {
    createForm.customerId = customerOptions.value[0].value
  }
})

watch(
  () => createForm.customerId,
  (customerId) => {
    const addresses = customerStore.customers.find((customer) => customer.id === customerId)?.user_addresses || []
    createForm.addressId = addresses[0]?.id
  }
)

watch(
  () => createForm.items.map((line) => line.productId),
  () => {
    createForm.items.forEach((line) => {
      const batch = lineBatch(line.batchId)
      const product = lineProduct(line.productId)
      if (batch && product && String(batch.product_id ?? batch.productId) !== String(product.id)) {
        line.batchId = undefined
      }
    })
  },
  { deep: true }
)

onMounted(async () => {
  await Promise.all([
    customerStore.fetchCustomers(),
    productStore.fetchProducts({ per_page: 50 }),
    batchStore.fetchBatches(),
    orderStore.fetchAdminOrders()
  ])
})
</script>

<style scoped>
.orders-page {
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
  color: #1f4f96;
  margin: 0 0 6px 0;
}

.breadcrumb {
  color: #8094b2;
  font-size: 12px;
  margin: 0;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
  margin-bottom: 18px;
}

.stat-card {
  border-radius: 16px;
  box-shadow: 0 8px 22px rgba(16, 55, 102, 0.08);
  text-align: center;
}

.stat-card :deep(.ant-card-body) {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.stat-label {
  margin: 0 0 8px 0;
  font-size: 12px;
  color: #6b7f9f;
  font-weight: 700;
  text-transform: uppercase;
}

.stat-value {
  margin: 0;
  font-size: 28px;
  font-weight: 800;
  color: #1f4f96;
}

.toolbar-card,
.table-card {
  border-radius: 16px;
  box-shadow: 0 8px 22px rgba(16, 55, 102, 0.08);
  margin-bottom: 18px;
}

.toolbar-input {
  width: 320px;
}

.toolbar-select {
  width: 220px;
}

.order-id-cell strong,
.customer-name {
  color: #1f4f96;
}

.muted {
  font-size: 12px;
  color: #8094b2;
}

.customer-cell {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
}

.customer-avatar {
  width: 38px;
  height: 38px;
  border-radius: 12px;
  background: linear-gradient(135deg, #5a89cf, #7fb3ff);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 800;
  flex-shrink: 0;
}

.cell-ellipsis {
  display: inline-block;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  vertical-align: middle;
}

.action-group {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.action-btn {
  border-radius: 999px;
  width: 30px;
  min-width: 30px;
  height: 30px;
  padding: 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  box-shadow: none;
}

.action-btn :deep(svg) {
  width: 14px;
  height: 14px;
}

.action-detail {
  border-color: #cfe0ff;
  color: #1f4f96;
  background: #f7fbff;
}

.action-detail:hover {
  border-color: #9ec0ff;
  background: #eef5ff;
  color: #18407c;
}

.action-cancel {
  border-color: #ffd6d6;
  color: #e11d48;
  background: #fff7f8;
}

.action-cancel:hover {
  border-color: #ffb3b3;
  background: #fff0f2;
  color: #be123c;
}

.action-delete {
  border-color: #ffd0d0;
  color: #ef4444;
  background: #fff7f7;
}

.action-delete:hover {
  border-color: #ffaaaa;
  background: #ffecec;
  color: #dc2626;
}

.table-card :deep(.ant-table-thead > tr > th) {
  white-space: nowrap;
}

.table-card :deep(.ant-table-cell) {
  vertical-align: middle;
  overflow: hidden;
}

.table-card :deep(.ant-table-cell) .muted,
.table-card :deep(.ant-table-cell) .customer-name {
  min-width: 0;
}

.table-card :deep(.ant-table-tbody > tr > td) {
  padding-top: 14px;
  padding-bottom: 14px;
}

.item-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  margin-bottom: 16px;
}

.hint {
  font-size: 12px;
  color: #8094b2;
}

.order-line-card {
  border: 1px solid #e5edf9;
  border-radius: 16px;
  padding: 16px;
  margin-bottom: 12px;
  background: #fbfdff;
}

.line-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.line-summary {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  font-size: 12px;
  color: #607896;
}

.totals-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
  margin-bottom: 16px;
}

.totals-grid > div {
  background: #f8fbff;
  border: 1px solid #e5edf9;
  border-radius: 14px;
  padding: 14px;
}

.totals-grid span {
  display: block;
  font-size: 12px;
  color: #8094b2;
  margin-bottom: 6px;
}

.totals-grid strong {
  color: #1f4f96;
  font-size: 18px;
}

.address-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.address-card {
  border-radius: 14px;
}

.address-head {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: center;
}

.address-card p {
  margin: 6px 0 0 0;
  color: #4f6482;
}

.order-product-cell strong {
  color: #1f4f96;
}

.detail-error {
  margin-top: 14px;
}

.full-width {
  width: 100%;
}

@media (max-width: 1024px) {
  .stats-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .toolbar-input {
    width: 260px;
  }

  .action-group {
    justify-content: center;
  }

  .address-grid {
    grid-template-columns: 1fr;
  }

  .totals-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
    gap: 12px;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }

  .toolbar-input,
  .toolbar-select {
    width: 100%;
  }

  .action-group {
    justify-content: center;
  }
}
</style>
