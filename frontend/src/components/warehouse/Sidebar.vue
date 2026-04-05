<template>
  <div class="admin-layout">
    <aside class="sidebar" :class="{ collapsed: sidebarCollapsed, active: mobileMenuOpen }">
      <div class="sidebar-header">
        <div class="logo">
          <div class="logo-icon" v-html="icons.warehouse"></div>
          <div v-if="!sidebarCollapsed" class="logo-copy">
            <p class="logo-title">Warehouse</p>
            <p class="logo-subtitle">Nha thuoc da lieu</p>
          </div>
        </div>
        <button @click="toggleSidebar" class="toggle-btn">
          <span class="toggle-icon" v-html="icons.menu"></span>
        </button>
      </div>

      <nav class="sidebar-nav">
        <RouterLink
          v-for="item in navItems"
          :key="item.to"
          :to="item.to"
          :title="sidebarCollapsed ? item.label : ''"
          class="nav-item"
          :class="{ active: isActiveRoute(item.to) }"
          @click="mobileMenuOpen = false"
        >
          <span class="nav-icon" v-html="icons[item.icon]"></span>
          <span v-if="!sidebarCollapsed" class="nav-label">{{ item.label }}</span>
        </RouterLink>
      </nav>

      <div class="sidebar-footer">
        <button class="logout-btn" type="button" @click="goAdmin" title="Đăng xuất">
          <span class="nav-icon" v-html="icons.logout"></span>
          <span v-if="!sidebarCollapsed" class="nav-label">Đăng xuất</span>
        </button>
      </div>
    </aside>

    <div v-if="mobileMenuOpen" class="overlay" @click="mobileMenuOpen = false"></div>

    <div class="main-wrapper">
      <header class="topbar">
        <div class="topbar-left">
          <button class="mobile-menu-btn" @click="mobileMenuOpen = true">
            <span v-html="icons.menu"></span>
          </button>
          <div class="topbar-brand">
            <div class="brand-mark" aria-hidden="true">
              <span class="brand-mark-icon" v-html="icons.warehouse"></span>
              <span class="brand-mark-dot"></span>
            </div>
            <div class="brand-copy">
              <span class="brand-name">Dermacity</span>
              <span class="brand-tagline">Trao giai phap dung, gui tron niem tin</span>
            </div>
          </div>
        </div>

        <div class="topbar-right">
          <div class="search-wrap">
            <input type="search" class="search-input" placeholder="Tim kiem...">
          </div>

          <button class="topbar-btn notification-btn" title="Thong bao">
            <span class="icon" v-html="icons.alerts"></span>
            <span v-if="unreadCount > 0" class="badge">{{ unreadCount }}</span>
          </button>

          <div class="profile-dropdown">
            <button @click="toggleProfileDropdown" class="profile-btn">
              <img src="/avatar-placeholder.svg" alt="Quản lý kho" class="avatar">
              <span class="admin-name">Quản lý kho</span>
              <span class="dropdown-arrow">▼</span>
            </button>

            <div v-if="profileDropdownOpen" class="dropdown-menu">
              <button @click="goToSecuritySettings" class="dropdown-item">Doi mat khau</button>
            </div>
          </div>
        </div>
      </header>

      <main class="page-content">
        <section v-if="showPageHead" class="page-head">
          <div>
            <h1>{{ title }}</h1>
            <p>{{ subtitle }}</p>
          </div>
          <div class="page-actions">
            <slot name="actions" />
          </div>
        </section>

        <div class="content-card">
          <slot />
        </div>
      </main>
    </div>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

defineProps({
  title: {
    type: String,
    required: true
  },
  subtitle: {
    type: String,
    default: ''
  },
  showPageHead: {
    type: Boolean,
    default: true
  }
})

const route = useRoute()
const router = useRouter()
const unreadCount = computed(() => 0)
const mobileMenuOpen = ref(false)
const sidebarCollapsed = ref(false)
const profileDropdownOpen = ref(false)

const navItems = [
  { to: '/warehouse/dashboard', label: 'Tổng quan', icon: 'dashboard' },
  { to: '/warehouse/products', label: 'Sản phẩm', icon: 'products' },
  { to: '/warehouse/batches', label: 'Lô hàng', icon: 'batches' },
  { to: '/warehouse/inventory', label: 'Tồn kho', icon: 'inventory' },
  { to: '/warehouse/alerts', label: 'Cảnh báo', icon: 'alerts' }
]

const isActiveRoute = (path) => route.path === path || route.path.startsWith(`${path}/`)

const toggleSidebar = () => {
  if (window.innerWidth <= 992) {
    mobileMenuOpen.value = !mobileMenuOpen.value
    return
  }
  sidebarCollapsed.value = !sidebarCollapsed.value
}

const toggleProfileDropdown = () => {
  profileDropdownOpen.value = !profileDropdownOpen.value
}

const goToSecuritySettings = () => {
  profileDropdownOpen.value = false
  router.push({ path: '/settings', query: { tab: 'security' } })
}

const goAdmin = () => {
  router.push('/dashboard')
}

const icons = {
  warehouse: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M4 10.5 12 5l8 5.5" />
      <path d="M5 10v9h14v-9" />
      <path d="M9 19v-5h6v5" />
    </svg>
  `,
  menu: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M4 7h16" />
      <path d="M4 12h16" />
      <path d="M4 17h16" />
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
  batches: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M4 7.5 12 4l8 3.5-8 3.5-8-3.5Z" />
      <path d="M4 7.5V16l8 3.5 8-3.5V7.5" />
      <path d="M8 11v3" />
      <path d="M12 12v4" />
      <path d="M16 10.5v5" />
    </svg>
  `,
  inventory: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M4 19.5h16" />
      <path d="M7 15v-4" />
      <path d="M12 15V8.5" />
      <path d="M17 15V5.5" />
    </svg>
  `,
  alerts: `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M12 4.5 4.7 18h14.6L12 4.5Z" />
      <path d="M12 9v4" />
      <circle cx="12" cy="16.4" r="1" fill="currentColor" stroke="none" />
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
</script>

<style scoped>
.admin-layout {
  display: flex;
  height: 100vh;
  background: linear-gradient(180deg, #f6faff 0%, #eef5ff 100%);
}

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

.logo {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
}

.sidebar.collapsed .logo-copy {
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

.logo-title {
  margin: 0;
  font-size: 14px;
  font-weight: 800;
  color: #29486f;
}

.logo-subtitle {
  margin: 0;
  font-size: 11px;
  color: #6f89ab;
}

.toggle-btn {
  background: rgba(255, 255, 255, 0.45);
  border: 1px solid rgba(82, 121, 184, 0.18);
  color: #426ea8;
  width: 32px;
  height: 32px;
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
}

.toggle-btn:hover {
  background: rgba(255, 255, 255, 0.72);
  border-color: rgba(82, 121, 184, 0.28);
}

.toggle-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.toggle-icon :deep(svg) {
  width: 16px;
  height: 16px;
}

.sidebar-nav {
  display: flex;
  flex-direction: column;
  gap: 10px;
  flex: 1;
  padding: 22px 0;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 12px 20px;
  text-decoration: none;
  color: #4d6687;
  transition: all 0.3s ease;
  border-left: 2px solid transparent;
  cursor: pointer;
}

.nav-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 20px;
  height: 20px;
  min-width: 20px;
  color: #6d9be0;
}

.nav-icon :deep(svg) {
  width: 18px;
  height: 18px;
}

.nav-label {
  font-size: 14px;
  font-weight: 500;
  white-space: nowrap;
}

.sidebar.collapsed .nav-label {
  display: none;
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
}

.logout-btn:hover {
  background: rgba(125, 179, 242, 0.18);
  border-color: rgba(125, 179, 242, 0.4);
}

.main-wrapper {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

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
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
}

.mobile-menu-btn {
  display: none;
  background: rgba(255, 255, 255, 0.45);
  border: 1px solid rgba(82, 121, 184, 0.18);
  color: #426ea8;
  width: 32px;
  height: 32px;
  border-radius: 6px;
  cursor: pointer;
  align-items: center;
  justify-content: center;
}

.mobile-menu-btn :deep(svg) {
  width: 16px;
  height: 16px;
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
}

.brand-mark-icon {
  width: 22px;
  height: 22px;
  color: #426ea8;
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
}

.brand-copy {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.brand-name {
  font-size: 20px;
  font-weight: 900;
  color: #426ea8;
  letter-spacing: -0.8px;
  line-height: 1;
}

.brand-tagline {
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #5f7ea6;
}

.topbar-right {
  display: flex;
  align-items: center;
  gap: 14px;
  margin-left: 16px;
}

.search-wrap {
  width: 360px;
  max-width: 38vw;
}

.search-input {
  width: 100%;
  padding: 7px 14px;
  border: 1px solid #e8edf8;
  border-radius: 10px;
  background: #fbfdff;
  font-size: 12px;
}

.search-input:focus {
  outline: none;
  background: #fff;
  border-color: #6d9be0;
  box-shadow: 0 0 0 3px rgba(109, 155, 224, 0.16);
}

.topbar-btn {
  background: none;
  border: none;
  cursor: pointer;
  width: 36px;
  height: 36px;
  border-radius: 6px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #4f7fc5;
  position: relative;
}

.topbar-btn:hover {
  background: rgba(241, 245, 255, 0.9);
}

.icon :deep(svg) {
  width: 18px;
  height: 18px;
}

.badge {
  position: absolute;
  top: 3px;
  right: 3px;
  min-width: 16px;
  height: 16px;
  border-radius: 999px;
  background: #ef4444;
  color: #fff;
  font-size: 10px;
  font-weight: 700;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0 4px;
}

.profile-dropdown {
  position: relative;
}

.profile-btn {
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 999px;
  padding: 4px 10px 4px 4px;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}

.avatar {
  width: 28px;
  height: 28px;
  border-radius: 999px;
}

.admin-name {
  font-size: 12px;
  font-weight: 700;
  color: #29486f;
}

.dropdown-arrow {
  font-size: 11px;
  color: #64748b;
}

.dropdown-menu {
  position: absolute;
  right: 0;
  top: calc(100% + 8px);
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 24px rgba(15, 23, 42, 0.14);
  padding: 6px;
  min-width: 140px;
  z-index: 40;
}

.dropdown-item {
  width: 100%;
  border: none;
  background: transparent;
  text-align: left;
  padding: 8px;
  border-radius: 6px;
  font-size: 12px;
  cursor: pointer;
}

.dropdown-item:hover {
  background: #f1f5f9;
}

.page-content {
  padding: 18px;
  overflow: auto;
}

.page-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 16px;
}

.page-head h1 {
  margin: 0;
  font-size: 24px;
  color: #0f172a;
}

.page-head p {
  margin: 4px 0 0;
  color: #64748b;
  font-size: 13px;
}

.page-actions {
  display: flex;
  gap: 8px;
  align-items: center;
}

.content-card {
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 18px;
  box-shadow: 0 8px 24px rgba(15, 23, 42, 0.06);
  padding: 16px;
}

.overlay {
  display: none;
}

@media (max-width: 992px) {
  .sidebar {
    position: fixed;
    top: 0;
    left: 0;
    bottom: 0;
    z-index: 30;
    transform: translateX(-100%);
    transition: transform 0.25s ease;
  }

  .sidebar.active {
    transform: translateX(0);
  }

  .sidebar-header {
    justify-content: flex-end;
  }

  .logo {
    display: none !important;
  }

  .logo-icon,
  .logo-copy {
    display: none !important;
  }

  .overlay {
    display: block;
    position: fixed;
    inset: 0;
    background: rgba(15, 23, 42, 0.42);
    z-index: 20;
  }

  .mobile-menu-btn {
    display: inline-flex;
  }

  .topbar-brand {
    display: none !important;
  }

  .search-wrap {
    display: none;
  }

  .page-head {
    flex-direction: column;
    align-items: stretch;
  }
}
</style>
