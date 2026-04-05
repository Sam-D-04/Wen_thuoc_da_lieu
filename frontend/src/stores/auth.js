import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import axios from 'axios'

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api',
  timeout: 10000,
  headers: {
    Accept: 'application/json'
  }
})

export const useAuthStore = defineStore('auth', () => {
  let persistedUser = null
  try {
    persistedUser = JSON.parse(localStorage.getItem('auth_user') || 'null')
  } catch (error) {
    persistedUser = null
    localStorage.removeItem('auth_user')
  }

  const user = ref(persistedUser)
  const token = ref(localStorage.getItem('auth_token') || null)

  const isLoggedIn = computed(() => !!user.value && !!token.value)
  const isAdmin = computed(() => user.value?.role === 'admin')
  const isWarehouse = computed(() => user.value?.role === 'warehouse')
  const isCustomer = computed(() => user.value?.role === 'customer')
  const userName = computed(() => user.value?.name || '')

  const clearAuthState = () => {
    user.value = null
    token.value = null
    localStorage.removeItem('auth_user')
    localStorage.removeItem('auth_token')
  }

  const login = async (email, password) => {
    try {
      const response = await apiClient.post('/login', { email, password })
      const nextUser = response.data?.user || null
      const nextToken = response.data?.token || null

      if (!nextUser || !nextToken) {
        return { success: false, message: 'Dữ liệu đăng nhập không hợp lệ.' }
      }

      user.value = nextUser
      token.value = nextToken

      localStorage.setItem('auth_user', JSON.stringify(nextUser))
      localStorage.setItem('auth_token', nextToken)

      return { success: true, user: nextUser }
    } catch (error) {
      return { success: false, message: error?.response?.data?.message || 'Đăng nhập thất bại' }
    }
  }

  const register = async (formData) => {
    try {
      const response = await apiClient.post('/register', {
        name: formData.name,
        email: formData.email,
        phone: formData.phone,
        password: formData.password,
        password_confirmation: formData.confirmPassword
      })

      const nextUser = response.data?.user || null
      const nextToken = response.data?.token || null

      if (!nextUser || !nextToken) {
        return { success: false, message: 'Dữ liệu đăng ký không hợp lệ.' }
      }

      user.value = nextUser
      token.value = nextToken

      localStorage.setItem('auth_user', JSON.stringify(nextUser))
      localStorage.setItem('auth_token', nextToken)

      return { success: true, user: nextUser }
    } catch (error) {
      return { success: false, message: error?.response?.data?.message || 'Đăng ký thất bại' }
    }
  }

  const logout = async () => {
    const currentToken = token.value

    // Clear local session first so the UI logs out immediately.
    clearAuthState()

    if (!currentToken) {
      return { success: true }
    }

    try {
      await apiClient.post('/logout', {}, {
        headers: {
          Authorization: `Bearer ${currentToken}`
        }
      })
      return { success: true }
    } catch (error) {
      return {
        success: false,
        message: error?.response?.data?.message || 'Đăng xuất cục bộ thành công nhưng không đồng bộ được phiên máy chủ.'
      }
    }
  }

  return { user, token, isLoggedIn, isAdmin, isWarehouse, isCustomer, userName, login, register, logout }
})
