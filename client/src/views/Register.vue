<template>
  <div class="register-container">
    <!-- 回退按钮 -->
    <button class="back-button" @click="onBack">
      <img src="../assets/back3.png" alt="返回" />
    </button>
    <div class="register-panel">
      <n-card title="用户注册">
        <n-form ref="formRef" :rules="rules" :model="user">
          <n-form-item path="account" label="账号">
            <n-input v-model:value="user.account" placeholder="请输入账号" />
          </n-form-item>
          <n-form-item path="password" label="密码">
            <n-input
                v-model:value="user.password"
                type="password"
                placeholder="6-18位字符，包含字母和数字"
            />
          </n-form-item>
          <n-form-item path="confirmPassword" label="确认密码">
            <n-input
                v-model:value="user.confirmPassword"
                type="password"
                placeholder="请再次输入密码"
            />
          </n-form-item>
          <n-form-item path="email" label="邮箱">
            <n-input v-model:value="user.email" placeholder="请输入有效邮箱" />
          </n-form-item>
        </n-form>
        <template #footer>
          <div class="footer-content">
            <n-button class="register-btn" @click="register" type="primary">注册</n-button>
            <div class="login-link">
              <span @click="goLogin">已有账号？立即登录</span>
            </div>
          </div>
        </template>
      </n-card>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, inject } from 'vue'
import { useRouter } from 'vue-router'
import { NForm } from 'naive-ui'

const router = useRouter()
const message = inject("message")
const axios = inject("axios")
const formRef = ref(null)


function onBack() {
  router.back() // 等同于 window.history.back()
}
// 表单验证规则
const rules = {
  account: [
    { required: true, message: "请输入账号", trigger: "blur" },
    { min: 3, max: 12, message: "账号长度在3-12个字符", trigger: "blur" }
  ],
  password: [
    { required: true, message: "请输入密码", trigger: "blur" },
    { min: 6, max: 18, message: "密码长度6-18个字符", trigger: "blur" },
    { pattern: /^(?=.*[A-Za-z])(?=.*\d).+$/, message: "需包含字母和数字", trigger: "blur" }
  ],
  confirmPassword: [
    { required: true, message: "请确认密码", trigger: "blur" },
    { validator: validatePassword, trigger: ['blur', 'input'] }
  ],
  email: [
    { required: true, message: "请输入邮箱", trigger: "blur" },
    { type: 'email', message: "邮箱格式不正确", trigger: ['blur', 'input'] }
  ]
}

// 用户注册数据
const user = reactive({
  account: '',
  password: '',
  confirmPassword: '',
  email: ''
})

// 密码一致性验证
function validatePassword(rule, value) {
  return value == user.password || new Error('两次输入的密码不一致')
}

// 注册提交
const register = async (e) => {
  e.preventDefault()

  // 表单验证
  try {
    await formRef.value?.validate()
  } catch (errors) {
    message.error('请检查表单信息')
    return
  }

  // 提交注册请求
  const result = await axios.post("/user/register", {
    account: user.account,
    password: user.password,
    email: user.email
  })

  if (result.data.code == 200) {
    message.success('注册成功')
    // 注册成功后自动跳转到登录页
    router.push("/userlogin")
  } else {
    message.error(result.data.message || '注册失败')
  }
}

// 返回登录页面
const goLogin = () => {
  router.push('/userlogin')
}
</script>

<style lang="scss" scoped>
.register-container {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-image: url('../assets/banner3.jpg');
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  background-attachment: fixed;
  display: flex;
  justify-content: center;
  align-items: center;
}

.register-panel {
  width: 400px;
  text-align: center;

  :deep(.n-card__title) {
    font-weight: bold;
    text-align: center;
    font-size: 24px;
    margin-bottom: 24px;
  }

  :deep(.n-form) {
    .n-form-item {
      display: flex;
      flex-direction: column;
      align-items: center;

      .n-form-item-label {
        width: 100%;
        text-align: center;
        padding-bottom: 8px;
        font-weight: 500;
      }

      .n-form-item-blank {
        width: 100%;

        .n-input {
          text-align: left;

          .n-input__input input {
            text-align: left;
            padding-left: 12px;
          }
        }
      }
    }
  }

  .footer-content {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 16px;
    margin-top: 16px;

    .register-btn {
      width: 100%;
      background-color: #E10403;
      color: white;
      border: none;
      border-radius: 4px;
      padding: 12px 0;
      font-weight: bold;

      &:hover {
        background-color: #ff7875;
      }
    }

    .login-link {
      margin-top: 8px;

      span {
        color: #1890ff;
        cursor: pointer;
        font-size: 14px;
        text-decoration: none;

        &:hover {
          text-decoration: underline;
        }
      }
    }
  }
}
.back-button {
  position: absolute;
  top: 48px;
  left: 48px;
  background: transparent;
  border: none;
  cursor: pointer;
  z-index: 5;
  padding: 0;
}

.back-button img {
  width: 44px;
  height: 44px;
}
</style>