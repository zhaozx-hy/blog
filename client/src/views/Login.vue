<template>
  <div class="login-container">
    <!-- 回退按钮 -->
    <button class="back-button" @click="onBack">
      <img src="../assets/back3.png" alt="返回" />
    </button>
    <div class="login-panel">
      <n-card title="管理后台登录" >
        <n-form :rules="rules" :model="admin">
          <n-form-item path="account" label="账号">
            <n-input v-model:value="admin.account" placeholder="请输入账号" />
          </n-form-item>
          <n-form-item path="password" label="密码">
            <n-input v-model:value="admin.password" type="password" placeholder="请输入密码" />
          </n-form-item>
        </n-form>
        <template #footer>
          <div class="footer-content">
            <n-checkbox v-model:checked="admin.rember" label="记住我" />
            <n-button class="login-btn" @click="login">登录</n-button>
          </div>
        </template>
      </n-card>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, inject } from 'vue'
import { AdminStore } from '../stores/AdminStore'

import { useRouter, useRoute } from 'vue-router'
const router = useRouter()
const route = useRoute()

const message = inject("message")
const axios = inject("axios")
const adminStore = AdminStore()


function onBack() {
  router.back() // 等同于 window.history.back()
}

/**验证表单规则 */
let rules = {
  account: [
    { required: true, message: "请输入账号", trigger: "blur" },
    { min: 3, max: 12, message: "账号长度在 3 到 12 个字符", trigger: "blur" },
  ],
  password: [
    { required: true, message: "请输入密码", trigger: "blur" },
    { min: 6, max: 18, message: "密码长度在 6 到 18 个字符", trigger: "blur" },
  ],
};

/**管理员登录数据 */
const admin = reactive({
  account: localStorage.getItem("account") || "",
  password: localStorage.getItem("password") || "",
  rember: localStorage.getItem("rember") == 1 || false
})

/**登录 */
const login = async () => {
  let result = await axios.post("/admin/login", {
    account: admin.account,
    password: admin.password
  });
  if (result.data.code == 200) {
    adminStore.token = result.data.data.token
    adminStore.account = result.data.data.account
    adminStore.id = result.data.data.id

    //把数据存储到localStorage
    if (admin.rember) {
      localStorage.setItem("account", admin.account)
      localStorage.setItem("password", admin.password)
      localStorage.setItem("rember", admin.rember ? 1 : 0)
    }
    router.push("/dashboard")
    message.info("登录成功")
  } else {
    message.error("登录失败")
  }
}
</script>

<style lang="scss" scoped>
.login-container {
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

.login-panel {
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

    .n-checkbox {
      align-self: center;
    }
  }

  .login-btn {
    width: 100%;
    background-color: #E10403;
    color: white;
    border: none;
    border-radius: 4px;
    padding: 12px 0;
    font-weight: bold;
    margin-top: 8px;

    &:hover {
      background-color: #ff7875;
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