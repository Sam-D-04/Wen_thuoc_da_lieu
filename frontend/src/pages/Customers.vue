<template>
  <div class="customers-page">
    <div class="page-header">
      <div>
        <h1>Quản lý khách hàng</h1>
        <p class="breadcrumb">Nhà thuốc Da liễu / Khách hàng</p>
      </div>
      <a-space>
        <a-button type="primary" @click="openCreateModal">+ Thêm khách hàng</a-button>
      </a-space>
    </div>

    <div class="stats-grid">
      <a-card class="stat-card" :bordered="false">
        <p class="stat-label">Tổng khách hàng</p>
        <p class="stat-value">{{ customerMetrics.length }}</p>
      </a-card>
      <a-card class="stat-card" :bordered="false">
        <p class="stat-label">Đang hoạt động</p>
        <p class="stat-value">{{ activeCustomerCount }}</p>
      </a-card>
      <a-card class="stat-card" :bordered="false">
        <p class="stat-label">VIP</p>
        <p class="stat-value">{{ vipCustomerCount }}</p>
      </a-card>
      <a-card class="stat-card" :bordered="false">
        <p class="stat-label">Tổng chi tiêu</p>
        <p class="stat-value">{{ formatCurrency(totalPaidSpent) }}</p>
      </a-card>
    </div>

    <a-card class="toolbar-card" :bordered="false">
      <a-space wrap>
        <a-input
          v-model:value="keyword"
          allow-clear
          placeholder="Tìm theo tên, email, SĐT..."
          class="toolbar-input"
        />
        <a-select
          v-model:value="statusFilter"
          class="toolbar-select"
          :options="statusFilterOptions"
        />
      </a-space>
    </a-card>

    <a-card class="table-card" :bordered="false">
      <a-table
        :columns="columns"
        :data-source="filteredCustomers"
        :row-key="(record) => record.id"
        :pagination="{ pageSize: 8, showSizeChanger: false }"
        :table-layout="'fixed'"
        size="middle"
      >
        <template #bodyCell="{ column, record }">
          <template v-if="column.key === 'name'">
            <div class="customer-name-cell">
              <div class="customer-avatar">{{ getInitial(record.name) }}</div>
              <div>
                <div class="customer-name">{{ record.name }}</div>
                <div class="customer-sub">{{ record.email }}</div>
              </div>
            </div>
          </template>

          <template v-else-if="column.key === 'phone'">
            <span class="cell-ellipsis">{{ record.phone }}</span>
          </template>

          <template v-else-if="column.key === 'email'">
            <span class="cell-ellipsis">{{ record.email }}</span>
          </template>

          <template v-else-if="column.key === 'status'">
            <a-tag :color="record.status === 'active' ? 'green' : 'default'">
              {{ record.statusLabel }}
            </a-tag>
          </template>

          <template v-else-if="column.key === 'orders'">
            {{ record.orderCount }} đơn
          </template>

          <template v-else-if="column.key === 'spent'">
            {{ formatCurrency(record.totalSpent) }}
          </template>

          <template v-else-if="column.key === 'joined_at'">
            {{ formatDate(record.joinedAt) }}
          </template>

          <template v-else-if="column.key === 'vip'">
            <a-tag :color="record.isVip ? 'gold' : 'blue'">
              {{ record.isVip ? 'VIP' : 'Mới' }}
            </a-tag>
          </template>

          <template v-else-if="column.key === 'actions'">
            <div class="action-group">
              <a-button size="small" @click="openDetailModal(record)">Xem</a-button>
              <a-button size="small" type="primary" ghost @click="openEditModal(record)">Sửa</a-button>
            </div>
          </template>
        </template>
      </a-table>
    </a-card>

    <a-card class="top-card" :bordered="false">
      <div class="section-head">
        <h3>Khách hàng hàng đầu</h3>
        <span>Top theo tổng chi tiêu</span>
      </div>
      <div class="top-list">
        <div v-for="(customer, index) in topCustomers" :key="customer.id" class="top-item">
          <span class="rank">{{ index + 1 }}</span>
          <div class="top-info">
            <p class="top-name">{{ customer.name }}</p>
            <p class="top-meta">{{ customer.orderCount }} đơn hàng</p>
          </div>
          <strong>{{ formatCurrency(customer.totalSpent) }}</strong>
        </div>
      </div>
    </a-card>

    <a-modal
      v-model:open="createVisible"
      :title="createMode === 'create' ? 'Thêm khách hàng' : 'Chỉnh sửa khách hàng'"
      :confirm-loading="savingCustomer"
      ok-text="Lưu"
      cancel-text="Hủy"
      :width="720"
      destroy-on-close
      @ok="submitCustomerForm"
      @cancel="closeCustomerModal"
    >
      <a-form ref="customerFormRef" :model="customerForm" layout="vertical">
        <a-row :gutter="16">
          <a-col :span="12">
            <a-form-item label="Tên khách hàng" name="name" :rules="[{ required: true, message: 'Vui lòng nhập tên khách hàng' }]">
              <a-input v-model:value="customerForm.name" placeholder="Nhập tên khách hàng" />
            </a-form-item>
          </a-col>
          <a-col :span="12">
            <a-form-item label="Email" name="email" :rules="emailRules">
              <a-input v-model:value="customerForm.email" placeholder="name@example.com" />
            </a-form-item>
          </a-col>
        </a-row>

        <a-row :gutter="16">
          <a-col :span="12">
            <a-form-item label="Số điện thoại" name="phone" :rules="phoneRules">
              <a-input v-model:value="customerForm.phone" placeholder="Ví dụ: 0901234567" />
            </a-form-item>
          </a-col>
          <a-col :span="12">
            <a-form-item label="Trạng thái" name="status" :rules="[{ required: true, message: 'Vui lòng chọn trạng thái' }]">
              <a-select v-model:value="customerForm.status" :options="customerStatusOptions" />
            </a-form-item>
          </a-col>
        </a-row>
      </a-form>
    </a-modal>

    <a-modal
      v-model:open="detailVisible"
      title="Chi tiết khách hàng"
      :width="980"
      :footer="null"
      destroy-on-close
      @cancel="closeDetailModal"
    >
      <div v-if="selectedCustomer" class="detail-grid">
        <a-descriptions bordered :column="2" size="small">
          <a-descriptions-item label="Tên khách hàng">{{ selectedCustomer.name }}</a-descriptions-item>
          <a-descriptions-item label="Email">{{ selectedCustomer.email }}</a-descriptions-item>
          <a-descriptions-item label="Số điện thoại">{{ selectedCustomer.phone }}</a-descriptions-item>
          <a-descriptions-item label="Trạng thái">
            <a-tag :color="selectedCustomer.status === 'active' ? 'green' : 'default'">
              {{ selectedCustomer.statusLabel }}
            </a-tag>
          </a-descriptions-item>
          <a-descriptions-item label="Số đơn hàng">{{ selectedCustomer.orderCount }}</a-descriptions-item>
          <a-descriptions-item label="Tổng chi tiêu">{{ formatCurrency(selectedCustomer.totalSpent) }}</a-descriptions-item>
          <a-descriptions-item label="Ngày tham gia">{{ formatDate(selectedCustomer.joinedAt) }}</a-descriptions-item>
          <a-descriptions-item label="Phân loại">
            <a-tag :color="selectedCustomer.isVip ? 'gold' : 'blue'">{{ selectedCustomer.isVip ? 'VIP' : 'Mới' }}</a-tag>
          </a-descriptions-item>
        </a-descriptions>

        <a-divider>Danh sách địa chỉ của khách hàng</a-divider>

        <a-empty v-if="!selectedCustomer.addresses.length" description="Khách hàng chưa có địa chỉ" />
        <a-space direction="vertical" class="address-list" v-else>
          <a-card v-for="address in selectedCustomer.addresses" :key="address.id" size="small" class="address-card">
            <div class="address-head">
              <strong>{{ address.recipient_name || selectedCustomer.name }}</strong>
              <a-tag v-if="address.is_default" color="blue">Mặc định</a-tag>
            </div>
            <p>{{ address.phone || selectedCustomer.phone }}</p>
            <p>{{ formatAddress(address) }}</p>
          </a-card>
        </a-space>
      </div>
    </a-modal>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { message } from 'ant-design-vue'
import { useCustomerStore } from '@/stores/customers'
import { useOrderStore } from '@/stores/orders'

const customerStore = useCustomerStore()
const orderStore = useOrderStore()

const keyword = ref('')
const statusFilter = ref('all')
const createVisible = ref(false)
const detailVisible = ref(false)
const createMode = ref('create')
const selectedCustomerId = ref(null)
const savingCustomer = ref(false)
const customerFormRef = ref()

const customerStatusOptions = [
  { label: 'Hoạt động', value: 'active' },
  { label: 'Ngưng hoạt động', value: 'inactive' }
]

const statusFilterOptions = [
  { label: 'Tất cả trạng thái', value: 'all' },
  { label: 'Hoạt động', value: 'active' },
  { label: 'Ngưng hoạt động', value: 'inactive' },
  { label: 'VIP', value: 'vip' },
  { label: 'Mới', value: 'new' }
]

const customerForm = reactive({
  id: null,
  name: '',
  email: '',
  phone: '',
  status: 'active'
})

const columns = [
  { title: 'Tên khách hàng', key: 'name', dataIndex: 'name', width: 240 },
  { title: 'Điện thoại', key: 'phone', dataIndex: 'phone', width: 120 },
  { title: 'Email', key: 'email', dataIndex: 'email', width: 220 },
  { title: 'Loại khách', key: 'vip', dataIndex: 'vip', width: 100 },
  { title: 'Số đơn', key: 'orders', dataIndex: 'orders', width: 90 },
  { title: 'Tổng chi tiêu', key: 'spent', dataIndex: 'spent', width: 140 },
  { title: 'Ngày tham gia', key: 'joined_at', dataIndex: 'joined_at', width: 120 },
  { title: 'Trạng thái', key: 'status', dataIndex: 'status', width: 110 },
  { title: 'Thao tác', key: 'actions', dataIndex: 'actions', width: 132 }
]

const emailRules = [
  { required: true, message: 'Vui lòng nhập email' },
  { type: 'email', message: 'Email không đúng định dạng' }
]

const phoneRules = [
  { required: true, message: 'Vui lòng nhập số điện thoại' },
  {
    validator: (_, value) => {
      const text = String(value || '').trim()
      const valid = /^\d{10,11}$/.test(text)
      return valid ? Promise.resolve() : Promise.reject(new Error('Số điện thoại phải là số và có 10-11 ký tự'))
    }
  }
]

const formatCurrency = (value) => {
  return `${new Intl.NumberFormat('vi-VN', { maximumFractionDigits: 0 }).format(Number(value || 0))} đ`
}

const formatDate = (dateString) => {
  if (!dateString) return '-'
  return new Intl.DateTimeFormat('vi-VN').format(new Date(dateString))
}

const formatAddress = (address) => {
  const parts = [address.address_line, address.ward, address.district, address.city || address.province].filter(Boolean)
  return parts.join(', ')
}

const getInitial = (name) => String(name || '?').trim().charAt(0).toUpperCase()

const normalizeStatus = (status) => {
  if (status === 'active' || status === 'Đang hoạt động') return 'active'
  return 'inactive'
}

const mapCustomerRecord = (customer) => {
  // Mapping SQL:
  // users.role = 'customer' -> customerStore.customers
  // orders.user_id -> orderStore.orders.customerId
  // user_addresses.user_id -> customer.user_addresses
  const customerOrders = orderStore.orders.filter((order) => String(order.customerId) === String(customer.id))
  const orderCount = customerOrders.length
  const totalSpent = customerOrders
    .filter((order) => String(order.payment_status) === 'paid')
    .reduce((sum, order) => sum + Number(order.final_amount || 0), 0)

  const isVip = totalSpent > 1000000 || orderCount > 3
  const status = normalizeStatus(customer.status)

  return {
    id: customer.id,
    name: customer.name,
    email: customer.email,
    phone: customer.phone,
    status,
    statusLabel: status === 'active' ? 'Hoạt động' : 'Ngưng hoạt động',
    joinedAt: customer.created_at || customer.joinDate,
    orderCount,
    totalSpent,
    isVip,
    vipLabel: isVip ? 'VIP' : 'Mới',
    addresses: Array.isArray(customer.user_addresses) ? customer.user_addresses : []
  }
}

const customerMetrics = computed(() => {
  return customerStore.customers
    .filter((customer) => customer.role === 'customer')
    .map(mapCustomerRecord)
})

const filteredCustomers = computed(() => {
  const text = keyword.value.trim().toLowerCase()

  return customerMetrics.value.filter((customer) => {
    const matchesKeyword =
      !text ||
      [customer.name, customer.email, customer.phone, customer.statusLabel]
        .join(' ')
        .toLowerCase()
        .includes(text)

    const matchesStatus =
      statusFilter.value === 'all' ||
      (statusFilter.value === 'active' && customer.status === 'active') ||
      (statusFilter.value === 'inactive' && customer.status === 'inactive') ||
      (statusFilter.value === 'vip' && customer.isVip) ||
      (statusFilter.value === 'new' && !customer.isVip)

    return matchesKeyword && matchesStatus
  })
})

const activeCustomerCount = computed(() => customerMetrics.value.filter((customer) => customer.status === 'active').length)
const vipCustomerCount = computed(() => customerMetrics.value.filter((customer) => customer.isVip).length)
const totalPaidSpent = computed(() => customerMetrics.value.reduce((sum, customer) => sum + customer.totalSpent, 0))
const topCustomers = computed(() => [...customerMetrics.value].sort((a, b) => b.totalSpent - a.totalSpent).slice(0, 5))

const selectedCustomer = computed(() => {
  const customer = customerStore.customers.find((item) => item.id === selectedCustomerId.value)
  return customer ? mapCustomerRecord(customer) : null
})

const resetCustomerForm = () => {
  customerForm.id = null
  customerForm.name = ''
  customerForm.email = ''
  customerForm.phone = ''
  customerForm.status = 'active'
}

const openCreateModal = () => {
  createMode.value = 'create'
  resetCustomerForm()
  createVisible.value = true
}

const openEditModal = (customer) => {
  createMode.value = 'edit'
  customerForm.id = customer.id
  customerForm.name = customer.name
  customerForm.email = customer.email
  customerForm.phone = customer.phone
  customerForm.status = customer.status
  createVisible.value = true
}

const openDetailModal = (customer) => {
  selectedCustomerId.value = customer.id
  detailVisible.value = true
}

const closeCustomerModal = () => {
  createVisible.value = false
  resetCustomerForm()
}

const closeDetailModal = () => {
  detailVisible.value = false
  selectedCustomerId.value = null
}

const submitCustomerForm = async () => {
  try {
    await customerFormRef.value?.validate()
    savingCustomer.value = true

    const payload = {
      name: customerForm.name.trim(),
      email: customerForm.email.trim(),
      phone: customerForm.phone.trim(),
      status: customerForm.status === 'active' ? 'Đang hoạt động' : 'Ngưng hoạt động'
    }

    if (createMode.value === 'create') {
      customerStore.addCustomer(payload)
      message.success('Đã thêm khách hàng')
    } else {
      customerStore.updateCustomer(customerForm.id, payload)
      message.success('Đã cập nhật khách hàng')
    }

    closeCustomerModal()
  } catch (error) {
    if (error?.errorFields) return
    message.error(error?.message || 'Không thể lưu khách hàng')
  } finally {
    savingCustomer.value = false
  }
}

watch(createVisible, (visible) => {
  if (!visible && createMode.value === 'create') {
    resetCustomerForm()
  }
})

onMounted(async () => {
  await Promise.all([
    customerStore.fetchCustomers(),
    orderStore.fetchAdminOrders()
  ])
})
</script>

<style scoped>
.customers-page {
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
.table-card,
.top-card {
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

.customer-name-cell {
  display: flex;
  align-items: center;
  gap: 12px;
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
}

.customer-name {
  margin: 0;
  font-weight: 700;
  color: #1f4f96;
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
  gap: 8px;
  flex-wrap: wrap;
}

.action-group :deep(.ant-btn) {
  border-radius: 10px;
  min-width: 52px;
  padding-inline: 12px;
}

.table-card :deep(.ant-table-thead > tr > th) {
  white-space: nowrap;
}

.table-card :deep(.ant-table-cell) {
  vertical-align: middle;
  overflow: hidden;
}

.table-card :deep(.ant-table-tbody > tr > td) {
  padding-top: 14px;
  padding-bottom: 14px;
}

.table-card :deep(.ant-table-cell .customer-name-cell) {
  min-width: 0;
}

.customer-sub {
  margin: 2px 0 0 0;
  font-size: 12px;
  color: #6b7f9f;
}

.section-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 16px;
}

.section-head h3 {
  margin: 0;
  color: #1f4f96;
  font-size: 18px;
}

.section-head span {
  color: #8094b2;
  font-size: 12px;
}

.top-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.top-item {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 12px 14px;
  border-radius: 14px;
  background: #f8fbff;
}

.rank {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: #1f4f96;
  color: #fff;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-weight: 800;
}

.top-info {
  flex: 1;
}

.top-name {
  margin: 0 0 2px 0;
  font-weight: 700;
  color: #1f4f96;
}

.top-meta {
  margin: 0;
  font-size: 12px;
  color: #8094b2;
}

.detail-grid {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.address-list {
  width: 100%;
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

@media (max-width: 1024px) {
  .stats-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .toolbar-input {
    width: 260px;
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
    flex-direction: column;
    align-items: stretch;
  }

  .action-group :deep(.ant-btn) {
    width: 100%;
  }
}
</style>
