<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-cyan-50 flex items-center justify-center p-4">
    <!-- Background decorative blobs -->
    <div class="absolute inset-0 overflow-hidden pointer-events-none">
      <div class="absolute -top-40 -right-40 w-96 h-96 bg-blue-100 rounded-full opacity-40 blur-3xl"></div>
      <div class="absolute -bottom-40 -left-40 w-96 h-96 bg-cyan-100 rounded-full opacity-40 blur-3xl"></div>
    </div>

    <div class="relative w-full max-w-md">
      <!-- Logo -->
      <div class="text-center mb-8">
        <div class="inline-flex items-center gap-2 mb-3">
          <div class="w-10 h-10 bg-primary rounded-xl flex items-center justify-center shadow-lg shadow-blue-200">
            <svg viewBox="0 0 24 24" class="w-6 h-6 text-white fill-white" xmlns="http://www.w3.org/2000/svg">
              <path d="M11 2a9 9 0 1 0 9 9 9 9 0 0 0-9-9zm1 13.5h-2v-5h2zm0-7h-2V6.5h2z"/>
              <path d="M14 10h-2V8h2v2zm0 4h-2v-2h2v2z" opacity="0.3"/>
              <rect x="10" y="6" width="2" height="2" rx="1"/>
              <rect x="10" y="10" width="2" height="5" rx="1"/>
            </svg>
          </div>
          <span class="text-2xl font-bold text-gray-800">Dược<span class="text-primary">Mỹ</span>Phẩm</span>
        </div>
        <p class="text-sm text-gray-500">Chăm sóc da liễu chuyên sâu</p>
      </div>

      <!-- Card -->
      <div class="bg-white rounded-2xl shadow-xl shadow-blue-100/50 p-8 border border-gray-100">

        <!-- ── OTP VERIFICATION STEP ── -->
        <div v-if="showOtpStep">
          <!-- Header -->
          <div class="text-center mb-6">
            <div class="w-14 h-14 bg-blue-50 rounded-full flex items-center justify-center mx-auto mb-3">
              <svg class="w-7 h-7 text-primary" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="2" y="4" width="20" height="16" rx="2"/>
                <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>
              </svg>
            </div>
            <h2 class="text-lg font-bold text-gray-800">Xác thực email</h2>
            <p class="text-sm text-gray-500 mt-1">
              Mã 6 số đã được gửi đến<br/>
              <span class="font-semibold text-primary">{{ pendingEmailDisplay }}</span>
            </p>
          </div>

          <!-- OTP inputs -->
          <div class="flex gap-2 justify-center mb-2">
            <input
              v-for="(_, i) in otpDigits"
              :key="i"
              :ref="el => otpInputs[i] = el"
              v-model="otpDigits[i]"
              type="text"
              inputmode="numeric"
              maxlength="1"
              @input="onOtpInput(i)"
              @keydown="onOtpKeydown($event, i)"
              @paste.prevent="onOtpPaste($event)"
              class="w-11 h-12 text-center text-xl font-bold border-2 rounded-lg focus:outline-none focus:border-primary transition-colors bg-gray-50 focus:bg-white"
              :class="otpDigits[i] ? 'border-primary' : 'border-gray-200'"
            />
          </div>

          <!-- Countdown / Resend -->
          <div class="text-center text-sm mb-5">
            <span v-if="resendCountdown > 0" class="text-gray-400">
              Gửi lại sau <span class="font-semibold text-gray-600">{{ resendCountdown }}s</span>
            </span>
            <button
              v-else
              type="button"
              @click="handleResend"
              :disabled="isLoading"
              class="text-primary hover:text-blue-700 font-medium disabled:opacity-50"
            >
              Gửi lại mã
            </button>
          </div>

          <!-- Error -->
          <div v-if="otpError" class="flex items-center gap-2 text-sm text-red-600 bg-red-50 border border-red-100 rounded-lg p-3 mb-4">
            <svg class="w-4 h-4 flex-shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
            </svg>
            {{ otpError }}
          </div>

          <!-- Verify button -->
          <button
            type="button"
            @click="handleVerify"
            :disabled="isLoading || otpCode.length < 6"
            class="w-full bg-primary hover:bg-blue-700 text-white font-semibold py-2.5 rounded-lg transition-all duration-200 flex items-center justify-center gap-2 shadow-md shadow-blue-200 hover:shadow-lg hover:shadow-blue-300 disabled:opacity-60 disabled:cursor-not-allowed"
          >
            <svg v-if="isLoading" class="animate-spin w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
            </svg>
            <span>{{ isLoading ? 'Đang xác thực...' : 'Xác nhận' }}</span>
          </button>

          <!-- Back -->
          <button
            type="button"
            @click="showOtpStep = false; activeTab = 'register'"
            class="w-full mt-3 text-sm text-gray-500 hover:text-gray-700 py-1"
          >
            ← Quay lại đăng ký
          </button>
        </div>

        <!-- ── LOGIN / REGISTER TABS ── -->
        <template v-else>
          <!-- Tab Switcher -->
          <div class="flex gap-1 bg-gray-100 rounded-xl p-1 mb-6">
            <button
              @click="activeTab = 'login'"
              :class="[
                'flex-1 py-2 text-sm font-semibold rounded-lg transition-all duration-200',
                activeTab === 'login'
                  ? 'bg-white text-primary shadow-sm'
                  : 'text-gray-500 hover:text-gray-700'
              ]"
            >
              Đăng nhập
            </button>
            <button
              @click="activeTab = 'register'"
              :class="[
                'flex-1 py-2 text-sm font-semibold rounded-lg transition-all duration-200',
                activeTab === 'register'
                  ? 'bg-white text-primary shadow-sm'
                  : 'text-gray-500 hover:text-gray-700'
              ]"
            >
              Đăng ký
            </button>
          </div>

          <!-- LOGIN FORM -->
          <form v-if="activeTab === 'login'" @submit.prevent="handleLogin" class="space-y-4">
            <!-- Email -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Email</label>
              <div class="relative">
                <div class="absolute inset-y-0 left-3 flex items-center pointer-events-none">
                  <svg class="w-4 h-4 text-gray-400" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="2" y="4" width="20" height="16" rx="2"/>
                    <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>
                  </svg>
                </div>
                <input
                  v-model="loginForm.email"
                  type="email"
                  placeholder="your@email.com"
                  class="w-full pl-10 pr-4 py-2.5 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition-colors bg-gray-50 focus:bg-white"
                  required
                />
              </div>
            </div>

            <!-- Password -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Mật khẩu</label>
              <div class="relative">
                <div class="absolute inset-y-0 left-3 flex items-center pointer-events-none">
                  <svg class="w-4 h-4 text-gray-400" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                    <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                  </svg>
                </div>
                <input
                  v-model="loginForm.password"
                  :type="showPassword ? 'text' : 'password'"
                  placeholder="••••••••"
                  class="w-full pl-10 pr-10 py-2.5 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition-colors bg-gray-50 focus:bg-white"
                  required
                />
                <button
                  type="button"
                  @click="showPassword = !showPassword"
                  class="absolute inset-y-0 right-3 flex items-center text-gray-400 hover:text-gray-600"
                >
                  <svg v-if="!showPassword" class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                  </svg>
                  <svg v-else class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/>
                    <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/>
                    <line x1="1" y1="1" x2="23" y2="23"/>
                  </svg>
                </button>
              </div>
            </div>

            <!-- Remember & Forgot -->
            <div class="flex items-center justify-between text-sm">
              <label class="flex items-center gap-2 cursor-pointer">
                <input type="checkbox" v-model="loginForm.remember" class="w-4 h-4 rounded border-gray-300 text-primary focus:ring-primary" />
                <span class="text-gray-600">Ghi nhớ đăng nhập</span>
              </label>
              <button type="button" class="text-primary hover:text-blue-700 font-medium">Quên mật khẩu?</button>
            </div>

            <!-- Error -->
            <div v-if="loginError" class="flex items-center gap-2 text-sm text-red-600 bg-red-50 border border-red-100 rounded-lg p-3">
              <svg class="w-4 h-4 flex-shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
              </svg>
              {{ loginError }}
            </div>

            <!-- Submit Button -->
            <button
              type="submit"
              :disabled="isLoading"
              class="w-full bg-primary hover:bg-blue-700 text-white font-semibold py-2.5 rounded-lg transition-all duration-200 flex items-center justify-center gap-2 shadow-md shadow-blue-200 hover:shadow-lg hover:shadow-blue-300 disabled:opacity-60 disabled:cursor-not-allowed"
            >
              <svg v-if="isLoading" class="animate-spin w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
              </svg>
              <span>{{ isLoading ? 'Đang đăng nhập...' : 'Đăng nhập' }}</span>
            </button>
          </form>

          <!-- REGISTER FORM -->
          <form v-if="activeTab === 'register'" @submit.prevent="handleRegister" class="space-y-4">
            <!-- Name -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Họ và tên</label>
              <div class="relative">
                <div class="absolute inset-y-0 left-3 flex items-center pointer-events-none">
                  <svg class="w-4 h-4 text-gray-400" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>
                  </svg>
                </div>
                <input v-model="registerForm.name" type="text" placeholder="Nguyễn Văn A" class="w-full pl-10 pr-4 py-2.5 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition-colors bg-gray-50 focus:bg-white" required />
              </div>
            </div>

            <!-- Email -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Email</label>
              <div class="relative">
                <div class="absolute inset-y-0 left-3 flex items-center pointer-events-none">
                  <svg class="w-4 h-4 text-gray-400" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="2" y="4" width="20" height="16" rx="2"/>
                    <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>
                  </svg>
                </div>
                <input v-model="registerForm.email" type="email" placeholder="your@email.com" class="w-full pl-10 pr-4 py-2.5 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition-colors bg-gray-50 focus:bg-white" required />
              </div>
            </div>

            <!-- Phone -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Số điện thoại</label>
              <div class="relative">
                <div class="absolute inset-y-0 left-3 flex items-center pointer-events-none">
                  <svg class="w-4 h-4 text-gray-400" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.49 12 19.79 19.79 0 0 1 1.39 3.39 2 2 0 0 1 3.37 1h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 8.37a16 16 0 0 0 5.72 5.72l1.06-1.06a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z"/>
                  </svg>
                </div>
                <input v-model="registerForm.phone" type="tel" placeholder="0909 123 456" class="w-full pl-10 pr-4 py-2.5 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition-colors bg-gray-50 focus:bg-white" required />
              </div>
            </div>

            <!-- Password -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Mật khẩu</label>
              <div class="relative">
                <div class="absolute inset-y-0 left-3 flex items-center pointer-events-none">
                  <svg class="w-4 h-4 text-gray-400" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                    <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                  </svg>
                </div>
                <input v-model="registerForm.password" :type="showPassword ? 'text' : 'password'" placeholder="Tối thiểu 8 ký tự" class="w-full pl-10 pr-10 py-2.5 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition-colors bg-gray-50 focus:bg-white" required />
                <button type="button" @click="showPassword = !showPassword" class="absolute inset-y-0 right-3 flex items-center text-gray-400 hover:text-gray-600">
                  <svg v-if="!showPassword" class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                  <svg v-else class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                </button>
              </div>
            </div>

            <!-- Confirm Password -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Xác nhận mật khẩu</label>
              <div class="relative">
                <div class="absolute inset-y-0 left-3 flex items-center pointer-events-none">
                  <svg class="w-4 h-4 text-gray-400" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                    <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                  </svg>
                </div>
                <input v-model="registerForm.confirmPassword" :type="showPassword ? 'text' : 'password'" placeholder="Nhập lại mật khẩu" class="w-full pl-10 pr-4 py-2.5 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition-colors bg-gray-50 focus:bg-white" required />
              </div>
            </div>

            <!-- Terms -->
            <label class="flex items-start gap-2 cursor-pointer">
              <input type="checkbox" v-model="registerForm.agreeTerms" class="w-4 h-4 mt-0.5 rounded border-gray-300 text-primary focus:ring-primary" required />
              <span class="text-sm text-gray-600">Tôi đồng ý với <button type="button" class="text-primary hover:underline">Điều khoản sử dụng</button> và <button type="button" class="text-primary hover:underline">Chính sách bảo mật</button></span>
            </label>

            <!-- Error -->
            <div v-if="registerError" class="flex items-center gap-2 text-sm text-red-600 bg-red-50 border border-red-100 rounded-lg p-3">
              <svg class="w-4 h-4 flex-shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              {{ registerError }}
            </div>

            <button
              type="submit"
              :disabled="isLoading"
              class="w-full bg-primary hover:bg-blue-700 text-white font-semibold py-2.5 rounded-lg transition-all duration-200 flex items-center justify-center gap-2 shadow-md shadow-blue-200 hover:shadow-lg hover:shadow-blue-300 disabled:opacity-60 disabled:cursor-not-allowed"
            >
              <svg v-if="isLoading" class="animate-spin w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
              <span>{{ isLoading ? 'Đang đăng ký...' : 'Tạo tài khoản' }}</span>
            </button>
          </form>
        </template>
      </div>

      <!-- Back to shop -->
      <div class="text-center mt-6">
        <router-link to="/shop" class="inline-flex items-center gap-1.5 text-sm text-gray-500 hover:text-primary transition-colors">
          <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="m15 18-6-6 6-6"/>
          </svg>
          Quay lại trang mua sắm
        </router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onUnmounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const activeTab = ref(route.query.tab === 'register' ? 'register' : 'login')
const showPassword = ref(false)
const isLoading = ref(false)
const loginError = ref('')
const registerError = ref('')

// OTP step
const showOtpStep = ref(false)
const otpDigits = reactive(['', '', '', '', '', ''])
const otpInputs = ref([])
const otpError = ref('')
const resendCountdown = ref(0)
let countdownTimer = null

const pendingEmailDisplay = computed(() => authStore.pendingEmail || '')
const otpCode = computed(() => otpDigits.join(''))

const loginForm = reactive({ email: '', password: '', remember: false })
const registerForm = reactive({ name: '', email: '', phone: '', password: '', confirmPassword: '', agreeTerms: false })

watch(
  () => route.query.tab,
  (tab) => {
    activeTab.value = tab === 'register' ? 'register' : 'login'
  },
  { immediate: true }
)

// ── OTP helpers ──────────────────────────────────────────────────────────────

const startCountdown = () => {
  resendCountdown.value = 60
  clearInterval(countdownTimer)
  countdownTimer = setInterval(() => {
    resendCountdown.value--
    if (resendCountdown.value <= 0) clearInterval(countdownTimer)
  }, 1000)
}

const onOtpInput = (index) => {
  const val = otpDigits[index].replace(/\D/g, '')
  otpDigits[index] = val ? val[0] : ''
  if (otpDigits[index] && index < 5) {
    otpInputs.value[index + 1]?.focus()
  }
}

const onOtpKeydown = (e, index) => {
  if (e.key === 'Backspace' && !otpDigits[index] && index > 0) {
    otpInputs.value[index - 1]?.focus()
  }
}

const onOtpPaste = (e) => {
  const text = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, 6)
  text.split('').forEach((ch, i) => { otpDigits[i] = ch })
  otpInputs.value[Math.min(text.length, 5)]?.focus()
}

onUnmounted(() => clearInterval(countdownTimer))

// ── Handlers ──────────────────────────────────────────────────────────────────

const handleLogin = async () => {
  loginError.value = ''
  isLoading.value = true
  try {
    const result = await authStore.login(loginForm.email, loginForm.password)
    if (result.success) {
      const role = result.user?.role
      if (role === 'admin') router.push('/admin/dashboard')
      else if (role === 'warehouse') router.push('/warehouse')
      else router.push('/shop')
    } else {
      loginError.value = result.message || 'Email hoặc mật khẩu không đúng'
    }
  } catch {
    loginError.value = 'Đã có lỗi xảy ra. Vui lòng thử lại.'
  } finally {
    isLoading.value = false
  }
}

const handleRegister = async () => {
  registerError.value = ''
  if (registerForm.password !== registerForm.confirmPassword) {
    registerError.value = 'Mật khẩu xác nhận không khớp'
    return
  }
  if (registerForm.password.length < 8) {
    registerError.value = 'Mật khẩu phải có ít nhất 8 ký tự'
    return
  }
  isLoading.value = true
  try {
    const result = await authStore.register(registerForm)
    if (result.success && result.requiresVerification) {
      showOtpStep.value = true
      otpDigits.fill('')
      otpError.value = ''
      startCountdown()
    } else {
      registerError.value = result.message || 'Đăng ký thất bại'
    }
  } catch {
    registerError.value = 'Đã có lỗi xảy ra. Vui lòng thử lại.'
  } finally {
    isLoading.value = false
  }
}

const handleVerify = async () => {
  otpError.value = ''
  if (otpCode.value.length < 6) return
  isLoading.value = true
  try {
    const result = await authStore.verifyEmail(authStore.pendingEmail, otpCode.value)
    if (result.success) {
      router.push('/shop')
    } else {
      otpError.value = result.message || 'Mã không đúng'
    }
  } catch {
    otpError.value = 'Đã có lỗi xảy ra. Vui lòng thử lại.'
  } finally {
    isLoading.value = false
  }
}

const handleResend = async () => {
  isLoading.value = true
  try {
    const result = await authStore.resendCode(authStore.pendingEmail)
    if (result.success) {
      otpError.value = ''
      otpDigits.fill('')
      startCountdown()
    } else {
      otpError.value = result.message || 'Gửi lại thất bại'
    }
  } catch {
    otpError.value = 'Đã có lỗi xảy ra. Vui lòng thử lại.'
  } finally {
    isLoading.value = false
  }
}
</script>
