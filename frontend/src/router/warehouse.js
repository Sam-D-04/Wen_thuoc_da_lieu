import WarehouseDashboard from '@/views/warehouse/Dashboard.vue'
import WarehouseProducts from '@/views/warehouse/Products.vue'
import WarehouseBatches from '@/views/warehouse/Batches.vue'
import WarehouseInventory from '@/views/warehouse/Inventory.vue'
import WarehouseAlerts from '@/views/warehouse/Alerts.vue'

const warehouseRoutes = [
  {
    path: '/warehouse',
    redirect: '/warehouse/dashboard'
  },
  {
    path: '/warehouse/dashboard',
    name: 'WarehouseDashboard',
    component: WarehouseDashboard,
    meta: { title: 'Kho - Tong quan' }
  },
  {
    path: '/warehouse/products',
    name: 'WarehouseProducts',
    component: WarehouseProducts,
    meta: { title: 'Kho - San pham' }
  },
  {
    path: '/warehouse/batches',
    name: 'WarehouseBatches',
    component: WarehouseBatches,
    meta: { title: 'Kho - Lo hang' }
  },
  {
    path: '/warehouse/inventory',
    name: 'WarehouseInventory',
    component: WarehouseInventory,
    meta: { title: 'Kho - Ton kho' }
  },
  {
    path: '/warehouse/alerts',
    name: 'WarehouseAlerts',
    component: WarehouseAlerts,
    meta: { title: 'Kho - Canh bao' }
  }
]

export default warehouseRoutes
