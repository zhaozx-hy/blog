<template>
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
        <n-button @click="register" type="primary">注册</n-button>
        <n-button @click="goLogin">返回登录</n-button>
      </template>
    </n-card>
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
.register-panel {
  width: 500px;
  margin: 0 auto;
  margin-top: 100px;
  
  .n-button {
    margin-right: 12px;
  }
}
</style>