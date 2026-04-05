import { createRouter, createWebHistory } from 'vue-router'
import warehouseRoutes from './warehouse'
import AdminLayout from '@/layouts/AdminLayout.vue'
import StorefrontLayout from '@/layouts/StorefrontLayout.vue'
import Dashboard from '@/pages/Dashboard.vue'
import Products from '@/pages/Products.vue'
import Category from '@/pages/Category.vue'
import Brand from '@/pages/Brand.vue'
import Batches from '@/pages/Batches.vue'
import Orders from '@/pages/Orders.vue'
import Customers from '@/pages/Customers.vue'
import Alerts from '@/pages/Alerts.vue'
import Reports from '@/pages/Reports.vue'
import Settings from '@/pages/Settings.vue'
import LoginRegister from '@/views/auth/LoginRegister.vue'
import Home from '@/views/storefront/Home.vue'
import ProductDetail from '@/views/storefront/ProductDetail.vue'
import Checkout from '@/views/storefront/Checkout.vue'
import Account from '@/views/storefront/Account.vue'

const routes = [
  // ─── Auth ─────────────────────────────────────────────
  {
    path: '/login',
    name: 'Login',
    component: LoginRegister,
    meta: { title: 'Đăng nhập / Đăng ký' }
  },

  // ─── Storefront ───────────────────────────────────────
  {
    path: '/shop',
    component: StorefrontLayout,
    children: [
      {
        path: '',
        name: 'Home',
        component: Home,
        meta: { title: 'Dược Mỹ Phẩm Da Liễu - Mua sắm online' }
      },
      {
        path: 'product/:slug',
        name: 'ProductDetail',
        component: ProductDetail,
        meta: { title: 'Chi tiết sản phẩm' }
      },
      {
        path: '/checkout',
        name: 'Checkout',
        component: Checkout,
        meta: { title: 'Thanh toán', requiresAuth: true }
      },
      {
        path: '/account/orders',
        name: 'Account',
        component: Account,
        meta: { title: 'Tài khoản của tôi', requiresAuth: true }
      }
    ]
  },

  // ─── Admin ────────────────────────────────────────────
  {
    path: '/admin',
    component: AdminLayout,
    meta: { requiresAdmin: true },
    children: [
      { path: '', redirect: '/admin/dashboard' },
      { path: 'dashboard', name: 'Dashboard', component: Dashboard, meta: { title: 'Tổng quan' } },
      { path: 'products', name: 'Products', component: Products, meta: { title: 'Sản phẩm' } },
      { path: 'categories', name: 'Categories', component: Category, meta: { title: 'Danh mục' } },
      { path: 'brands', name: 'Brands', component: Brand, meta: { title: 'Thương hiệu' } },
      { path: 'batches', name: 'Batches', component: Batches, meta: { title: 'Lô thuốc' } },
      { path: 'orders', name: 'Orders', component: Orders, meta: { title: 'Đơn hàng' } },
      { path: 'customers', name: 'Customers', component: Customers, meta: { title: 'Khách hàng' } },
      { path: 'alerts', name: 'Alerts', component: Alerts, meta: { title: 'Cảnh báo' } },
      { path: 'reports', name: 'Reports', component: Reports, meta: { title: 'Báo cáo' } },
      { path: 'settings', name: 'Settings', component: Settings, meta: { title: 'Cài đặt' } },
    ]
  },

  // ─── Warehouse ────────────────────────────────────────
  ...warehouseRoutes,

  // ─── Legacy Admin Paths ───────────────────────────────
  { path: '/dashboard', redirect: '/admin/dashboard' },
  { path: '/products', redirect: '/admin/products' },
  { path: '/categories', redirect: '/admin/categories' },
  { path: '/brands', redirect: '/admin/brands' },
  { path: '/batches', redirect: '/admin/batches' },
  { path: '/orders', redirect: '/admin/orders' },
  { path: '/customers', redirect: '/admin/customers' },
  { path: '/alerts', redirect: '/admin/alerts' },
  { path: '/reports', redirect: '/admin/reports' },
  { path: '/settings', redirect: '/admin/settings' },

  // ─── Redirect root ────────────────────────────────────
  { path: '/', redirect: '/shop' },

  // ─── 404 ──────────────────────────────────────────────
  { path: '/:pathMatch(.*)*', redirect: '/shop' }
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) return savedPosition
    return { top: 0 }
  }
})

// ─── Navigation Guard ─────────────────────────────────
router.beforeEach((to, from, next) => {
  let user = null

  try {
    user = JSON.parse(localStorage.getItem('auth_user') || 'null')
  } catch (error) {
    localStorage.removeItem('auth_user')
    user = null
  }

  // Update document title
  if (to.meta.title) document.title = to.meta.title + ' | DượcMỹPhẩm'

  // Auth protection
  if (to.meta.requiresAuth && !user) {
    return next('/login')
  }

  // Admin protection
  if (to.meta.requiresAdmin && (!user || user.role !== 'admin')) {
    return next('/shop')
  }

  next()
})

export default router
