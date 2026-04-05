<template>
  <div class="reports-page">
    <!-- Page Header -->
    <div class="page-header">
      <div>
        <h1>Báo cáo phân tích</h1>
        <p class="breadcrumb">Nhà thuốc Da liễu / Báo cáo</p>
      </div>
      <div class="header-controls">
        <select v-model="selectedPeriod" class="date-select">
          <option value="7days">7 ngày gần đây</option>
          <option value="30days">30 ngày</option>
          <option value="90days">90 ngày</option>
          <option value="year">Năm nay</option>
        </select>
        <button class="btn btn-primary">📥 Xuất báo cáo</button>
      </div>
    </div>

    <!-- Summary Cards -->
    <div class="summary-grid">
      <div class="summary-card">
        <p class="label">Doanh thu toàn kỳ</p>
        <p class="value">{{ formatVnd(totalRevenue) }}</p>
        <p class="change positive">↑ 24% so với {{ previousPeriodLabel }}</p>
      </div>
      <div class="summary-card">
        <p class="label">Tổng đơn hàng</p>
        <p class="value">{{ totalOrders }}</p>
        <p class="change positive">↑ 18% so với {{ previousPeriodLabel }}</p>
      </div>
      <div class="summary-card">
        <p class="label">Giá trị đơn hàng trung bình</p>
        <p class="value">{{ formatVnd(averageOrderValue) }}</p>
        <p class="change positive">↑ 5% so với {{ previousPeriodLabel }}</p>
      </div>
      <div class="summary-card">
        <p class="label">Tỷ lệ chuyển đổi</p>
        <p class="value">3.2%</p>
        <p class="change negative">↓ 0.5% so với {{ previousPeriodLabel }}</p>
      </div>
    </div>

    <!-- Charts Grid -->
    <div class="charts-grid">
      <!-- Revenue Chart -->
      <div class="chart-container big">
        <div class="chart-header">
          <h3>Doanh thu theo kỳ (30 ngày)</h3>
        </div>
        <div class="chart">
          <Bar :data="revenueChartData" :options="revenueChartOptions" />
        </div>
      </div>

      <!-- Product Categories -->
      <div class="chart-container">
        <div class="chart-header">
          <h3>Doanh thu theo danh mục</h3>
        </div>
        <div class="chart">
          <canvas id="categoryChart"></canvas>
        </div>
      </div>

      <!-- Top Products -->
      <div class="table-container">
        <div class="chart-header">
          <h3>10 sản phẩm bán chạy nhất</h3>
        </div>
        <table class="simple-table">
          <tbody>
            <tr v-if="topProducts.length === 0">
              <td colspan="2" class="text-right">Chưa có dữ liệu</td>
            </tr>
            <tr v-for="item in topProducts" :key="item.name">
              <td>{{ item.name }}</td>
              <td class="text-right">{{ formatVnd(item.revenue) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Additional Reports -->
    <div class="reports-section">
      <h3>Báo cáo hàng tồn kho</h3>
      <div class="mini-report">
        <div class="report-item">
          <p class="label">Sản phẩm có tồn kho cao</p>
          <p class="value">0 sản phẩm</p>
        </div>
        <div class="report-item">
          <p class="label">Sản phẩm hạn chế tồn kho</p>
          <p class="value">0 sản phẩm</p>
        </div>
        <div class="report-item">
          <p class="label">Sản phẩm sắp hết hạn</p>
          <p class="value">0 lô</p>
        </div>
        <div class="report-item">
          <p class="label">Giá trị tồn kho</p>
          <p class="value">{{ formatVnd(0) }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import dayjs from 'dayjs'
import Chart from 'chart.js/auto'
import { Bar } from 'vue-chartjs'
import { useOrderStore } from '@/stores/orders'

const selectedPeriod = ref('7days')
const categoryChart = ref(null)
const orderStore = useOrderStore()

const vndFormatter = new Intl.NumberFormat('vi-VN', {
  maximumFractionDigits: 0
})
const formatVnd = (value) => `${vndFormatter.format(Number(value || 0))}₫`

const paidOrders = computed(() =>
  orderStore.orders.filter((order) => String(order.payment_status || '').toLowerCase() === 'paid')
)

const totalOrders = computed(() => orderStore.orders.length)

const totalRevenue = computed(() =>
  paidOrders.value.reduce((sum, order) => sum + Number(order.final_amount || 0), 0)
)

const averageOrderValue = computed(() => {
  if (!totalOrders.value) return 0
  return Math.round(totalRevenue.value / totalOrders.value)
})

const topProducts = computed(() => {
  const revenueMap = new Map()

  orderStore.orders.forEach((order) => {
    ;(order.items || []).forEach((item) => {
      const key = item.product_name || item.productName || `#${item.product_id || item.productId || 'NA'}`
      const current = revenueMap.get(key) || 0
      const amount = Number(item.subtotal || Number(item.unit_price || 0) * Number(item.quantity || 0))
      revenueMap.set(key, current + amount)
    })
  })

  return [...revenueMap.entries()]
    .map(([name, revenue]) => ({ name, revenue }))
    .sort((a, b) => b.revenue - a.revenue)
    .slice(0, 10)
})

// Xử lý dữ liệu cho biểu đồ:
// 1) Tạo trục thời gian 30 ngày liên tục
// 2) Chỉ cộng doanh thu của đơn paid
// 3) Fill 0 cho ngày không có doanh thu
const processChartData = (orders) => {
  const recentDays = Array.from({ length: 30 }, (_, index) => dayjs().subtract(29 - index, 'day'))
  const revenueByDate = new Map(recentDays.map((day) => [day.format('YYYY-MM-DD'), 0]))

  orders
    .filter((order) => order.payment_status === 'paid')
    .forEach((order) => {
      const dateKey = dayjs(order.order_date).format('YYYY-MM-DD')
      if (!revenueByDate.has(dateKey)) return
      revenueByDate.set(dateKey, revenueByDate.get(dateKey) + Number(order.final_amount || 0))
    })

  const fullDates = recentDays.map((day) => day.format('DD/MM/YYYY'))
  const labels = recentDays.map((day) => day.format('DD'))
  const values = recentDays.map((day) => revenueByDate.get(day.format('YYYY-MM-DD')) || 0)

  return { labels, values, fullDates }
}

const revenueChartResult = computed(() => processChartData(orderStore.orders))

const revenueChartData = computed(() => {
  return {
    labels: revenueChartResult.value.labels,
    datasets: [
      {
        label: 'Doanh thu (VND)',
        data: revenueChartResult.value.values,
        backgroundColor: '#1890ff',
        borderRadius: 6,
        maxBarThickness: 20
      }
    ]
  }
})

const revenueChartOptions = computed(() => {
  return {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false },
      tooltip: {
        callbacks: {
          title: (items) => {
            const index = items[0]?.dataIndex ?? 0
            return `Ngày ${revenueChartResult.value.fullDates[index]}`
          },
          label: (context) => {
            return `Doanh thu: ${vndFormatter.format(Number(context.parsed.y || 0))} đ`
          }
        }
      }
    },
    scales: {
      y: {
        grid: {
          color: 'rgba(148, 163, 184, 0.14)'
        },
        ticks: {
          color: '#8094b2',
          callback: (value) => `${(Number(value) / 1000000).toFixed(1)}M`
        }
      },
      x: {
        grid: {
          color: 'rgba(148, 163, 184, 0.08)'
        },
        ticks: {
          color: '#8094b2',
          autoSkip: false,
          callback: (value, index) => {
            const label = revenueChartResult.value.labels[index]
            const keepLabels = ['01', '05', '10', '15', '20', '25', '30']
            return keepLabels.includes(label) ? label : ''
          }
        }
      }
    }
  }
})

const previousPeriodLabel = computed(() => {
  const periodMap = {
    '7days': '7 ngày liền trước',
    '30days': '30 ngày liền trước',
    '90days': '90 ngày liền trước',
    year: 'cùng kỳ năm trước'
  }

  return periodMap[selectedPeriod.value] || 'kỳ trước'
})

onMounted(() => {
  // Category Chart
  const categoryCtx = document.getElementById('categoryChart')
  if (categoryCtx) {
    categoryChart.value = new Chart(categoryCtx, {
      type: 'doughnut',
      data: {
        labels: ['Mụn viêm', 'Phục hồi da', 'Thâm mụn', 'Chống nắng', 'Khác'],
        datasets: [{
          data: [35, 25, 20, 15, 5],
          backgroundColor: [
            '#1e3a8a',
            '#3b82f6',
            '#60a5fa',
            '#bfdbfe',
            '#e0e7ff'
          ]
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              color: '#6b7f9f',
              usePointStyle: true,
              pointStyle: 'circle'
            }
          }
        }
      }
    })
  }
})

onBeforeUnmount(() => {
  if (categoryChart.value) {
    categoryChart.value.destroy()
    categoryChart.value = null
  }
})
</script>

<style scoped>
.reports-page {
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

.header-controls {
  display: flex;
  gap: 12px;
}

.date-select {
  padding: 8px 12px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 13px;
  cursor: pointer;
}

/* Summary Grid */
.summary-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

.summary-card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 20px;
  text-align: center;
  transition: all 0.3s ease;
}

.summary-card:hover {
  border-color: #1e3a8a;
  box-shadow: 0 4px 12px rgba(30, 58, 138, 0.1);
}

.summary-card .label {
  font-size: 12px;
  color: #64748b;
  text-transform: uppercase;
  font-weight: 600;
  margin: 0 0 8px 0;
  letter-spacing: 0.5px;
}

.summary-card .value {
  font-size: 24px;
  font-weight: 700;
  color: #1e3a8a;
  margin: 0 0 8px 0;
}

.summary-card .change {
  font-size: 12px;
  margin: 0;
  font-weight: 500;
}

.change.positive {
  color: #059669;
}

.change.negative {
  color: #ef4444;
}

/* Charts Grid */
.charts-grid {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 20px;
  margin-bottom: 24px;
}

.chart-container {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.chart-container.big {
  grid-column: 1;
}

.chart-header {
  margin-bottom: 16px;
}

.chart-header h3 {
  font-size: 15px;
  font-weight: 600;
  color: #1e3a8a;
  margin: 0;
}

.chart {
  position: relative;
  height: 300px;
}

.chart canvas {
  width: 100% !important;
  height: 100% !important;
  display: block;
}

.table-container {
  grid-column: 2;
}

.simple-table {
  width: 100%;
  font-size: 12px;
  border-collapse: collapse;
}

.simple-table td {
  padding: 10px 0;
  border-bottom: 1px solid #f1f5f9;
  color: #475569;
}

.simple-table td:first-child {
  color: #1e3a8a;
  font-weight: 500;
}

.text-right {
  text-align: right;
  font-weight: 600;
  color: #1e3a8a;
}

/* Reports Section */
.reports-section {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 24px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.reports-section h3 {
  font-size: 16px;
  font-weight: 600;
  color: #1e3a8a;
  margin: 0 0 16px 0;
}

.mini-report {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

.report-item {
  padding: 16px;
  background: #f8fafc;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.report-item .label {
  font-size: 12px;
  color: #64748b;
  text-transform: uppercase;
  font-weight: 600;
  margin: 0 0 8px 0;
  letter-spacing: 0.5px;
}

.report-item .value {
  font-size: 22px;
  font-weight: 700;
  color: #1e3a8a;
  margin: 0;
}

/* Buttons */
.btn {
  padding: 8px 16px;
  border-radius: 6px;
  border: none;
  cursor: pointer;
  font-size: 12px;
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
  box-shadow: 0 2px 8px rgba(30, 58, 138, 0.3);
}

/* Responsive */
@media (max-width: 1024px) {
  .summary-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .charts-grid {
    grid-template-columns: 1fr;
  }

  .chart-container.big {
    grid-column: auto;
  }

  .table-container {
    grid-column: auto;
  }

  .mini-report {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
    gap: 16px;
  }

  .summary-grid {
    grid-template-columns: 1fr;
  }

  .header-controls {
    flex-wrap: wrap;
  }

  .mini-report {
    grid-template-columns: 1fr;
  }
}
</style>
