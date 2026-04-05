<template>
  <div class="admin-layout">
    <!-- Sidebar -->
    <aside class="sidebar" :class="{ collapsed: sidebarCollapsed }">
      <div class="sidebar-header">
        <router-link to="/admin/dashboard" class="logo">
          <!-- Dermacity Monogram Logo -->
          <div
            class="w-9 h-9 rounded-xl bg-gradient-to-br from-primary to-cyan-500 flex items-center justify-center shadow-md shadow-blue-200 flex-shrink-0"
            style="width: 32px; height: 32px;">
            <span class="text-white font-black text-sm tracking-tighter leading-none"
              style="color: white; font-weight: 900; font-size: 14px;">Dc</span>
          </div>
          <div class="logo-copy">
            <p class="logo-title" style="color: #005B96;">Derma<span style="color: #0ea5e9;">city</span></p>
            <p class="logo-subtitle">Quản trị hệ thống</p>
          </div>
        </router-link>
        <button @click="toggleSidebar" class="toggle-btn">
          <span class="toggle-icon" v-html="getNavIcon('menu')"></span>
        </button>
      </div>

      <nav class="sidebar-nav">
        <router-link v-for="item in navItems" :key="item.path" :to="item.path"
          :title="sidebarCollapsed ? item.label : ''" class="nav-item" :class="{ active: isActiveRoute(item.path) }">
          <span class="nav-icon" v-html="getNavIcon(item.icon)"></span>
          <span v-if="!sidebarCollapsed" class="nav-label">{{ item.label }}</span>
        </router-link>
      </nav>

      <div class="sidebar-footer">
        <button class="logout-btn" :title="sidebarCollapsed ? 'Đăng xuất' : ''" @click="handleLogout"
          :disabled="isLoggingOut">
          <span class="nav-icon" v-html="getNavIcon('logout')"></span>
          <span v-if="!sidebarCollapsed" class="nav-label">{{ isLoggingOut ? 'Đang đăng xuất...' : 'Đăng xuất' }}</span>
        </button>
      </div>
    </aside>

    <!-- Main Content -->
    <div class="main-wrapper">
      <!-- Topbar -->
      <header class="topbar">
        <div class="topbar-left">
          <div class="topbar-brand" style="background: none; border: none; box-shadow: none; padding: 0;">
            <router-link to="/admin/dashboard" class="flex items-center gap-2.5 flex-shrink-0"
              style="text-decoration: none;">
              <!-- Dermacity Monogram Logo -->
              <div
                class="w-9 h-9 rounded-xl bg-gradient-to-br from-primary to-cyan-500 flex items-center justify-center shadow-md shadow-blue-200 flex-shrink-0"
                style="width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; border-radius: 12px; background: linear-gradient(to bottom right, #005B96, #06b6d4);">
                <span class="text-white font-black text-base tracking-tighter leading-none"
                  style="color: white; font-weight: 900; font-size: 16px;">Dc</span>
              </div>
              <div class="leading-none" style="display: flex; flex-direction: column;">
                <div class="text-[17px] font-black tracking-tight"
                  style="font-size: 17px; font-weight: 900; line-height: 1;">
                  <span style="color: #111827;">Derma</span><span style="color: #005B96;">city</span>
                </div>
                <div class="text-[10px] text-gray-400 tracking-widest uppercase font-medium"
                  style="font-size: 10px; color: #9ca3af; letter-spacing: 0.1em; text-transform: uppercase; font-weight: 500; margin-top: 2px;">
                  Quản Trị Viên
                </div>
              </div>
            </router-link>
          </div>
        </div>

        <div class="topbar-right">
          <div class="search-wrap">
            <input type="search" class="search-input" placeholder="Tìm kiếm...">
          </div>

          <!-- Notifications -->
          <button class="topbar-btn notification-btn" title="Thông báo">
            <span class="icon" v-html="getNavIcon('bell')"></span>
            <span v-if="unreadCount > 0" class="badge">{{ unreadCount }}</span>
          </button>

          <!-- Admin Profile Dropdown -->
          <div class="profile-dropdown">
            <button @click="toggleProfileDropdown" class="profile-btn">
              <img src="/avatar-placeholder.svg" alt="Admin" class="avatar">
              <span class="admin-name">Admin</span>
              <span class="dropdown-arrow">▼</span>
            </button>

            <div v-if="profileDropdownOpen" class="dropdown-menu">
              <button @click="goToSecuritySettings" class="dropdown-item"><span class="dropdown-icon"
                  v-html="getNavIcon('lock')"></span>Đổi mật khẩu</button>
            </div>
          </div>
        </div>
      </header>

      <!-- Page Content -->
      <main class="page-content">
        <div v-if="pageRenderError" class="page-error">
          <p>Không thể hiển thị nội dung trang quản trị.</p>
          <small>{{ pageRenderError }}</small>
        </div>
        <router-view v-else />
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onErrorCaptured } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAlertStore } from '@/stores/alerts'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const router = useRouter()
const alertStore = useAlertStore()
const authStore = useAuthStore()

const sidebarCollapsed = ref(false)
const profileDropdownOpen = ref(false)
const pageRenderError = ref('')
const isLoggingOut = ref(false)

onErrorCaptured((error) => {
  pageRenderError.value = error instanceof Error ? error.message : String(error)
  return false
})

const navItems = [
  { path: '/admin/dashboard', label: 'Tổng quan', icon: 'dashboard' },
  { path: '/admin/categories', label: 'Danh mục', icon: 'categories' },
  { path: '/admin/brands', label: 'Thương hiệu', icon: 'brands' },
  { path: '/admin/products', label: 'Sản phẩm', icon: 'products' },
  { path: '/admin/batches', label: 'Lô thuốc', icon: 'batches' },
  { path: '/admin/orders', label: 'Đơn hàng', icon: 'orders' },
  { path: '/admin/customers', label: 'Khách hàng', icon: 'customers' },
  { path: '/admin/alerts', label: 'Cảnh báo', icon: 'alerts' },
  { path: '/admin/reports', label: 'Báo cáo', icon: 'reports' },
  { path: '/admin/settings', label: 'Cài đặt', icon: 'settings' }
]

const unreadCount = computed(() => alertStore.unreadAlerts)

const toggleSidebar = () => {
  sidebarCollapsed.value = !sidebarCollapsed.value
}

const toggleProfileDropdown = () => {
  profileDropdownOpen.value = !profileDropdownOpen.value
}

const goToSecuritySettings = () => {
  profileDropdownOpen.value = false
  router.push({ path: '/admin/settings', query: { tab: 'security' } })
}

const handleLogout = async () => {
  if (isLoggingOut.value) {
    return
  }

  isLoggingOut.value = true
  profileDropdownOpen.value = false

  try {
    await authStore.logout()
  } finally {
    isLoggingOut.value = false
    router.push('/login')
  }
}

const isActiveRoute = (path) => {
  return route.path.startsWith(path)
}

const navIconMap = {
  medical: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M8.2 15.8 15.8 8.2" />
      <path d="M6.5 6.5a4 4 0 0 1 5.7 0l5.3 5.3a4 4 0 0 1-5.7 5.7l-5.3-5.3a4 4 0 0 1 0-5.7Z" />
      <path d="M8.7 8.7a2.2 2.2 0 0 0 0 3.1l3.5 3.5a2.2 2.2 0 0 0 3.1 0" opacity="0.35" />
    </svg>
  `,
  menu: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M4 7h16" />
      <path d="M4 12h16" />
      <path d="M4 17h16" />
    </svg>
  `,
  bell: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M6.5 16.5h11l-1-1.4V11a4.5 4.5 0 0 0-9 0v4.1l-1 1.4Z" />
      <path d="M10 18.5a2 2 0 0 0 4 0" />
    </svg>
  `,
  lock: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <rect x="5.5" y="10.5" width="13" height="9" rx="2" />
      <path d="M8.5 10.5V8.2a3.5 3.5 0 0 1 7 0v2.3" />
    </svg>
  `,
  dashboard: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <rect x="3.5" y="3.5" width="7" height="7" rx="1.5" />
      <rect x="13.5" y="3.5" width="7" height="4" rx="1.5" />
      <rect x="13.5" y="9.5" width="7" height="11" rx="1.5" />
      <rect x="3.5" y="13.5" width="7" height="7" rx="1.5" />
    </svg>
  `,
  products: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M4 8.5 12 4l8 4.5-8 4.5-8-4.5Z" />
      <path d="M4 8.5v7l8 4.5 8-4.5v-7" />
      <path d="M12 13v7" />
    </svg>
  `,
  categories: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M4 5.5h6v6H4z" />
      <path d="M14 5.5h6v6h-6z" />
      <path d="M4 14.5h6v6H4z" />
      <path d="M14 14.5h6v6h-6z" />
    </svg>
  `,
  brands: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M5 12.5 12 5l7 7.5-7 6.5-7-6.5Z" />
      <path d="M12 5v14" opacity="0.55" />
    </svg>
  `,
  batches: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M4 7.5 12 4l8 3.5-8 3.5-8-3.5Z" />
      <path d="M4 7.5V16l8 3.5 8-3.5V7.5" />
      <path d="M8 11v3" />
      <path d="M12 12v4" />
      <path d="M16 10.5v5" />
    </svg>
  `,
  orders: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M3.5 5h2l2 10h10.5l2-7.5H7" />
      <circle cx="10.5" cy="19" r="1.4" />
      <circle cx="18" cy="19" r="1.4" />
    </svg>
  `,
  customers: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <circle cx="12" cy="8" r="3.2" />
      <path d="M5.5 19c1.4-3.2 4.1-5 6.5-5s5.1 1.8 6.5 5" />
      <path d="M18.5 9.5a2.4 2.4 0 0 1 0 4.8" opacity="0.7" />
    </svg>
  `,
  alerts: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M12 4.5 4.7 18h14.6L12 4.5Z" />
      <path d="M12 9v4" />
      <circle cx="12" cy="16.4" r="1" fill="currentColor" stroke="none" />
    </svg>
  `,
  reports: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M4 19.5h16" />
      <path d="M6.5 17V12" />
      <path d="M11 17V8.5" />
      <path d="M15.5 17V5.5" />
      <path d="M20 17V10" />
    </svg>
  `,
  settings: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <circle cx="12" cy="12" r="3.2" />
      <path d="M19 12a7 7 0 0 0-.1-1l1.8-1.3-1.8-3.1-2.1.7a7 7 0 0 0-1.8-1L14.6 3h-5.2l-.4 2.3a7 7 0 0 0-1.8 1l-2.1-.7-1.8 3.1L5.1 11a7 7 0 0 0 0 2l-1.8 1.3 1.8 3.1 2.1-.7a7 7 0 0 0 1.8 1l.4 2.3h5.2l.4-2.3a7 7 0 0 0 1.8-1l2.1.7 1.8-3.1L18.9 13a7 7 0 0 0 .1-1Z" opacity="0.55" />
    </svg>
  `,
  logout: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M10 4.5H5.8A1.8 1.8 0 0 0 4 6.3v11.4a1.8 1.8 0 0 0 1.8 1.8H10" />
      <path d="M13 8.5 17 12l-4 3.5" />
      <path d="M17 12H8.5" />
    </svg>
  `
}

const getNavIcon = (key) => navIconMap[key] || navIconMap.dashboard
</script>

<style scoped>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

.admin-layout {
  display: flex;
  height: 100vh;
  background: linear-gradient(180deg, #f6faff 0%, #eef5ff 100%);
}

/* Sidebar */
.sidebar {
  width: 280px;
  background: linear-gradient(180deg, #d7e9ff 0%, #e7f1ff 100%);
  border-right: 1px solid rgba(90, 137, 207, 0.14);
  display: flex;
  flex-direction: column;
  transition: width 0.3s ease;
  color: #29486f;
  overflow-y: auto;
  box-shadow: 8px 0 20px rgba(108, 140, 190, 0.1);
}

.sidebar.collapsed {
  width: 80px;
}

.sidebar-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 22px 20px;
  border-bottom: 1px solid rgba(78, 118, 178, 0.1);
}

.sidebar.collapsed .sidebar-header {
  justify-content: center;
}

.logo {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
}

.logo-copy {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.logo-title {
  margin: 0;
  font-size: 20px;
  line-height: 1;
  font-weight: 900;
  color: #005B96;
  letter-spacing: -0.6px;
}

.logo-subtitle {
  margin: 0;
  font-size: 11px;
  line-height: 1.1;
  font-weight: 700;
  color: #6a84a6;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.sidebar.collapsed .logo {
  display: none;
}

.logo-icon {
  width: 28px;
  height: 28px;
  color: #6d9be0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.38);
  border: 1px solid rgba(109, 155, 224, 0.18);
  border-radius: 12px;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.65);
}

.logo-icon :deep(svg) {
  width: 28px;
  height: 28px;
}

.toggle-btn {
  background: rgba(255, 255, 255, 0.45);
  border: 1px solid rgba(82, 121, 184, 0.18);
  color: #005B96;
  width: 32px;
  height: 32px;
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
  font-size: 14px;
}

.toggle-btn:hover {
  background: rgba(255, 255, 255, 0.72);
  border-color: rgba(82, 121, 184, 0.28);
}

.toggle-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #005B96;
}

.toggle-icon :deep(svg) {
  width: 16px;
  height: 16px;
}

.sidebar-nav {
  flex: 1;
  padding: 22px 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 12px 20px;
  color: #4d6687;
  text-decoration: none;
  transition: all 0.3s ease;
  border-left: 2px solid transparent;
  cursor: pointer;
}

.nav-item:hover {
  background: rgba(255, 255, 255, 0.58);
  color: #29486f;
}

.nav-item.active {
  background: rgba(255, 255, 255, 0.82);
  color: #29486f;
  border-left-color: #7db3f2;
}

.nav-icon {
  width: 20px;
  height: 20px;
  min-width: 20px;
  text-align: center;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  color: #6d9be0;
}

.nav-icon :deep(svg) {
  width: 18px;
  height: 18px;
}

.nav-label {
  font-size: 14px;
  font-weight: 500;
  letter-spacing: 0.1px;
  white-space: nowrap;
  transition: opacity 0.3s ease;
}

.sidebar.collapsed .nav-label {
  opacity: 0;
  width: 0;
  display: none;
}

.sidebar-footer {
  padding: 20px;
  border-top: 1px solid rgba(78, 118, 178, 0.1);
}

.logout-btn {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 11px 14px;
  background: rgba(255, 255, 255, 0.55);
  border: 1px solid rgba(78, 118, 178, 0.18);
  color: #29486f;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 16px;
}

.logout-btn:hover {
  background: rgba(125, 179, 242, 0.18);
  border-color: rgba(125, 179, 242, 0.4);
}

/* Main Wrapper */
.main-wrapper {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* Topbar */
.topbar {
  background: rgba(255, 255, 255, 0.86);
  border-bottom: 1px solid #e8edf8;
  padding: 0 30px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 66px;
  box-shadow: 0 4px 16px rgba(108, 140, 190, 0.06);
}

.topbar-left {
  flex: 1;
  min-width: 0;
  max-width: 400px;
  display: flex;
  align-items: center;
}

.topbar-brand {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px 8px 8px;
  border-radius: 18px;
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.86), rgba(220, 235, 255, 0.74));
  border: 1px solid rgba(109, 155, 224, 0.12);
  box-shadow: 0 10px 24px rgba(108, 140, 190, 0.08);
}

.brand-mark {
  width: 40px;
  height: 40px;
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 14px;
  background: linear-gradient(135deg, rgba(109, 155, 224, 0.22), rgba(164, 206, 255, 0.34));
  border: 1px solid rgba(109, 155, 224, 0.18);
  box-shadow: 0 8px 18px rgba(109, 155, 224, 0.12);
  overflow: hidden;
}

.brand-mark-icon {
  width: 22px;
  height: 22px;
  color: #005B96;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.brand-mark-icon :deep(svg) {
  width: 22px;
  height: 22px;
}

.brand-mark-dot {
  position: absolute;
  top: 7px;
  right: 7px;
  width: 8px;
  height: 8px;
  border-radius: 999px;
  background: rgba(125, 179, 242, 0.95);
  box-shadow: 0 0 0 3px rgba(255, 255, 255, 0.35);
}

.brand-name {
  font-size: 20px;
  font-weight: 900;
  color: #005B96;
  letter-spacing: -0.8px;
  line-height: 1;
  text-shadow: 0 1px 0 rgba(255, 255, 255, 0.85);
}

.brand-copy {
  display: flex;
  flex-direction: column;
  gap: 3px;
  min-width: 0;
}

.brand-tagline {
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #5f7ea6;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.search-input {
  width: 100%;
  padding: 7px 14px;
  border: 1px solid #e8edf8;
  border-radius: 10px;
  background: #fbfdff;
  font-size: 12px;
  transition: all 0.3s ease;
}

.search-input:focus {
  outline: none;
  background: white;
  border-color: #6d9be0;
  box-shadow: 0 0 0 3px rgba(109, 155, 224, 0.16);
}

.topbar-right {
  display: flex;
  align-items: center;
  gap: 14px;
  margin-left: 16px;
  flex-shrink: 0;
}

.search-wrap {
  width: 360px;
  max-width: 38vw;
}

.topbar-btn {
  background: none;
  border: none;
  cursor: pointer;
  width: 36px;
  height: 36px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  transition: all 0.3s ease;
  color: #6e84a3;
  font-size: 16px;
}

.topbar-btn .icon :deep(svg) {
  width: 18px;
  height: 18px;
}

.topbar-btn:hover {
  background: #eef6ff;
  color: #5a89cf;
}

.badge {
  position: absolute;
  top: -5px;
  right: -5px;
  background: #ef4444;
  color: white;
  width: 22px;
  height: 22px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 700;
  border: 2px solid white;
}

/* Profile Dropdown */
.profile-dropdown {
  position: relative;
}

.profile-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  background: none;
  border: none;
  padding: 5px 10px;
  cursor: pointer;
  border-radius: 10px;
  transition: all 0.3s ease;
  color: #005B96;
}

.profile-btn:hover {
  background: #eef6ff;
}

.avatar {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  border: 2px solid #e7eef8;
}

.admin-name {
  font-size: 12px;
  font-weight: 600;
  color: #005B96;
}

.dropdown-arrow {
  font-size: 9px;
  color: #64748b;
  transition: transform 0.3s ease;
}

.profile-btn:hover .dropdown-arrow {
  transform: rotate(180deg);
}

.dropdown-menu {
  position: absolute;
  top: 100%;
  right: 0;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
  margin-top: 10px;
  min-width: 190px;
  z-index: 100;
}

.dropdown-item {
  width: 100%;
  padding: 10px 14px;
  border: none;
  background: none;
  text-align: left;
  cursor: pointer;
  font-size: 12px;
  color: #475569;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 8px;
}

.dropdown-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #005B96;
}

.dropdown-icon :deep(svg) {
  width: 14px;
  height: 14px;
}

.dropdown-item:first-child {
  border-radius: 7px 7px 0 0;
}

.dropdown-item:hover:not(.danger) {
  background: #f4f8ff;
  color: #005B96;
}

.dropdown-item.danger {
  color: #ef4444;
}

.dropdown-item.danger:hover {
  background: rgba(125, 179, 242, 0.14);
}

.dropdown-divider {
  margin: 8px 0;
  border: none;
  border-top: 1px solid #e2e8f0;
}

/* Page Content */
.page-content {
  flex: 1;
  overflow-y: auto;
  overflow-x: auto;
  min-width: 0;
  padding: 24px;
}

.page-error {
  min-height: 160px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-direction: column;
  gap: 8px;
  border: 1px dashed #c5d6ef;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.75);
  color: #355984;
}

.page-error {
  border-color: #f2c6c6;
  color: #8a2f2f;
}

.page-error p {
  margin: 0;
  font-weight: 700;
}

.page-error small {
  margin: 0;
  max-width: 720px;
  text-align: center;
  word-break: break-word;
}

/* Scrollbar Styling */
.sidebar::-webkit-scrollbar,
.page-content::-webkit-scrollbar {
  width: 8px;
}

.sidebar::-webkit-scrollbar-track,
.page-content::-webkit-scrollbar-track {
  background: transparent;
}

.sidebar::-webkit-scrollbar-thumb,
.page-content::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.2);
  border-radius: 4px;
}

.sidebar::-webkit-scrollbar-thumb:hover,
.page-content::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.3);
}

.page-content::-webkit-scrollbar-thumb {
  background: #cfd9eb;
}

.page-content::-webkit-scrollbar-thumb:hover {
  background: #aebdd7;
}

/* Responsive */
@media (max-width: 1024px) {
  .sidebar {
    width: 240px;
  }

  .sidebar.collapsed {
    width: 60px;
  }

  .topbar {
    padding: 0 16px;
  }

  .topbar-right {
    margin-left: 12px;
    gap: 12px;
  }

  .profile-btn {
    padding: 6px 8px;
  }

  .admin-name {
    display: none;
  }

  .dropdown-arrow {
    display: none;
  }

  .search-wrap {
    width: 260px;
    max-width: 32vw;
  }

  .page-content {
    padding: 16px;
  }
}

@media (max-width: 768px) {
  .sidebar {
    position: fixed;
    left: 0;
    top: 0;
    height: 100vh;
    z-index: 1000;
    width: 260px;
    transform: translateX(-100%);
    transition: transform 0.3s ease;
  }

  .sidebar.active {
    transform: translateX(0);
  }

  .sidebar .logo {
    display: none;
  }

  .topbar-left {
    max-width: none;
  }

  .topbar-brand {
    display: none;
  }

  .search-wrap {
    width: 180px;
    max-width: 40vw;
  }
}
</style>
