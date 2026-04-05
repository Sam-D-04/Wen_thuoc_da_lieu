import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { warehouseApi } from '@/api/warehouse'

const normalizeBatch = (batch) => ({
  ...batch,
  productId: batch.product_id ?? batch.productId,
  product_id: batch.product_id ?? batch.productId,
  productName: batch.product?.name || batch.product_name || batch.productName,
  product_name: batch.product?.name || batch.product_name || batch.productName,
  batchNo: batch.batch_code ?? batch.batchNo,
  batch_code: batch.batch_code ?? batch.batchNo,
  quantity: Number(batch.quantity ?? 0),
  remaining_quantity: Number(batch.remaining_quantity ?? batch.quantity ?? 0),
  expiryDate: batch.expiry_date || batch.expiryDate,
  expiry_date: batch.expiry_date || batch.expiryDate,
  manufactureDate: batch.manufacture_date || batch.manufactureDate,
  manufacture_date: batch.manufacture_date || batch.manufactureDate,
  status: batch.status || 'Còn hàng'
})

export const useBatchStore = defineStore('batch', () => {
  const batches = ref([])

  // Tính số ngày còn lại đến ngày hết hạn
  const getDaysToExpiry = (expiryDate) => {
    const today = new Date()
    const expiry = new Date(expiryDate)
    const diff = expiry - today
    return Math.floor(diff / (1000 * 60 * 60 * 24))
  }

  // Xác định trạng thái dựa trên ngày hết hạn
  const getExpiryStatus = (expiryDate) => {
    const days = getDaysToExpiry(expiryDate)
    if (days < 0) return 'Hết hạn'
    if (days <= 30) return 'Sắp hết hạn'
    return 'Còn hàng'
  }

  // FEFO: Lô hàng có ngày hết hạn gần nhất được ưu tiên sử dụng
  const batchesSortedByFefo = computed(() => {
    return batches.value
      .map(batch => ({
        ...batch,
        daysToExpiry: getDaysToExpiry(batch.expiry_date || batch.expiryDate),
        status: getExpiryStatus(batch.expiry_date || batch.expiryDate)
      }))
      .sort((a, b) => a.daysToExpiry - b.daysToExpiry)
  })

  const expiredBatches = computed(() => {
    return batches.value.filter(b => getDaysToExpiry(b.expiry_date || b.expiryDate) < 0).length
  })

  const expiringBatches = computed(() => {
    return batches.value.filter(b => {
      const days = getDaysToExpiry(b.expiry_date || b.expiryDate)
      return days >= 0 && days <= 30
    }).length
  })

  const totalBatches = computed(() => batches.value.length)

  const fetchBatches = async (params = {}) => {
    const response = await warehouseApi.getBatches(params)
    const list = response.data || []
    batches.value = list.map(normalizeBatch)
    return response
  }

  const createBatchAPI = async (payload) => {
    const created = await warehouseApi.createBatch(payload)
    batches.value.unshift(normalizeBatch(created))
    return created
  }

  const addBatch = (batch) => {
    const newId = 'B' + String(parseInt(batches.value[batches.value.length - 1]?.id.substring(1) || '0') + 1).padStart(3, '0')
    const created = normalizeBatch({
      id: newId,
      ...batch,
      productId: batch.product_id ?? batch.productId,
      product_id: batch.product_id ?? batch.productId,
      productName: batch.product_name ?? batch.productName,
      product_name: batch.product_name ?? batch.productName,
      batchNo: batch.batch_code ?? batch.batchNo,
      batch_code: batch.batch_code ?? batch.batchNo,
      quantity: Number(batch.quantity || 0),
      remaining_quantity: Number(batch.remaining_quantity ?? batch.quantity ?? 0),
      expiryDate: batch.expiry_date || batch.expiryDate,
      expiry_date: batch.expiry_date || batch.expiryDate,
      manufactureDate: batch.manufacture_date || batch.manufactureDate,
      manufacture_date: batch.manufacture_date || batch.manufactureDate,
      status: getExpiryStatus(batch.expiry_date || batch.expiryDate)
    })
    batches.value.push(created)
    return created
  }

  const updateBatch = (id, updates) => {
    const index = batches.value.findIndex(b => b.id === id)
    if (index > -1) {
      batches.value[index] = {
        ...batches.value[index],
        ...updates,
        productId: updates.product_id ?? updates.productId ?? batches.value[index].productId,
        product_id: updates.product_id ?? updates.productId ?? batches.value[index].product_id,
        productName: updates.product_name ?? updates.productName ?? batches.value[index].productName,
        product_name: updates.product_name ?? updates.productName ?? batches.value[index].product_name,
        batchNo: updates.batch_code ?? updates.batchNo ?? batches.value[index].batchNo,
        batch_code: updates.batch_code ?? updates.batchNo ?? batches.value[index].batch_code,
        quantity: Number(updates.quantity ?? batches.value[index].quantity ?? 0),
        remaining_quantity: Number(updates.remaining_quantity ?? updates.quantity ?? batches.value[index].remaining_quantity ?? batches.value[index].quantity ?? 0),
        expiryDate: updates.expiry_date || updates.expiryDate || batches.value[index].expiry_date || batches.value[index].expiryDate,
        expiry_date: updates.expiry_date || updates.expiryDate || batches.value[index].expiry_date || batches.value[index].expiryDate,
        manufactureDate: updates.manufacture_date || updates.manufactureDate || batches.value[index].manufactureDate,
        manufacture_date: updates.manufacture_date || updates.manufactureDate || batches.value[index].manufacture_date || batches.value[index].manufactureDate,
        status: getExpiryStatus(updates.expiry_date || updates.expiryDate || batches.value[index].expiry_date || batches.value[index].expiryDate)
      }
      return batches.value[index]
    }
    return null
  }

  const restoreBatchQuantity = (batchId, quantity) => {
    const index = batches.value.findIndex((batch) => batch.id === batchId)
    if (index === -1) return null

    const currentRemaining = Number(batches.value[index].remaining_quantity ?? batches.value[index].quantity ?? 0)
    batches.value[index] = {
      ...batches.value[index],
      remaining_quantity: currentRemaining + Number(quantity || 0)
    }
    return batches.value[index]
  }

  const deleteBatch = (id) => {
    const index = batches.value.findIndex(b => b.id === id)
    if (index > -1) {
      batches.value.splice(index, 1)
      return true
    }
    return false
  }

  // Lấy lô hàng ưu tiên (FEFO) cho một sản phẩm
  const getPriorityBatchForProduct = (productId) => {
    return batchesSortedByFefo.value.find(b => (b.product_id ?? b.productId) === productId && Number(b.remaining_quantity ?? b.quantity ?? 0) > 0)
  }

  return {
    batches,
    batchesSortedByFefo,
    expiredBatches,
    expiringBatches,
    totalBatches,
    fetchBatches,
    createBatchAPI,
    addBatch,
    updateBatch,
    restoreBatchQuantity,
    deleteBatch,
    getDaysToExpiry,
    getExpiryStatus,
    getPriorityBatchForProduct
  }
})
