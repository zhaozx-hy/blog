<template>
  <div class="container">
    <!-- 回退按钮 -->
    <button class="back-button" @click="onBack">
      <img src="../../assets/back3.png" alt="返回" />
    </button>

    <div class="bg-overlay"></div>
    <div class="inner">
      <p class="welcome-text">欢迎使用长征大模型</p>

      <div class="input-wrapper">
        <input
            v-model="inputValue"
            type="text"
            placeholder="请输入内容"
            class="custom-input"
            @keyup.enter="onClick"
        />
        <button class="arrow-button" @click="onClick">
          <img src="../../assets/arrow-up.png" alt="箭头" />
        </button>
      </div>
    </div>

    <div class="footer-intro">
      <div class="footer-content">
        <h2>长征精神</h2>
        <p>长征精神是中国共产党和红军在二万五千里长征征途中铸就的伟大革命精神。</p>
        <p>
          它体现了坚定的理想信念，不怕艰难险阻的英雄气概，实事求是的科学态度，
          以及紧密团结协作、同舟共济的优良传统。
        </p>
      </div>
    </div>
  </div>
</template>


<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'

const inputValue = ref('')
const router = useRouter()

function onClick() {
  const trimmed = inputValue.value.trim()
  if (!trimmed) {
    alert('请输入内容')
    return
  }
  router.push({ path: '/aimessages', query: { input: trimmed } })
}

// 回退逻辑
function onBack() {
  router.back() // 等同于 window.history.back()
}
</script>


<style scoped>
html, body {
  margin: 0;
  padding: 0;
  height: 100vh;
  overflow: hidden;
}

.container {
  position: relative;
  width: 100%;
  height: 100vh;
  background-image: url('../../assets/index_img.png');
  background-size: cover;
  background-repeat: no-repeat;
  background-position: center;
  background-attachment: fixed;
  display: flex;
  justify-content: center;
  align-items: center;
  overflow: hidden;
}


.bg-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.6); /* 调整这里的透明度实现变暗 */
  z-index: 1;
  pointer-events: none; /* 不影响下方内容交互 */
}

.inner, .your-content {
  position: relative;
  z-index: 2; /* 确保内容显示在遮罩上面 */
}




.inner {
  text-align: center;
  margin-top: -160px;  /* 从原来的 0 改为负值以向上移动 */
  max-height: calc(100vh - 120px);
  overflow: hidden;
  position: relative;
  z-index: 2;
}



/* 输入框和按钮等保持之前样式 */


.welcome-text {
  font-size: 32px;
  font-weight: 600;
  margin-bottom: 48px;
  color: #ffffff;
}

.input-wrapper {
  position: relative;
  width: 600px;
}

.custom-input {
  width: 100%;
  height: 58px;
  padding: 0 60px 0 16px; /* 右侧留出按钮空间 */
  font-size: 16px;
  border-radius: 15px;
  border: 1.5px solid #ccc;
  outline: none;
  box-sizing: border-box;
  transition: border-color 0.3s;
}

.custom-input:focus {
  border-color: #E10403;
}

.arrow-button {
  position: absolute;
  bottom: 6px;
  right: 6px;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: none;
  background-color: #E10403;
  cursor: pointer;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 0;
  transition: background-color 0.3s;
}

.arrow-button:hover {
  background-color: #B12431;
}

.arrow-button img {
  width: 20px;  /* 你可以调整图片大小 */
  height: 20px;
}
.bottom-image {
  position: absolute;
  bottom: 0px; /* 距离底部距离，可调 */
  left: 50%;
  transform: translateX(-50%);
  width: 100%;        /* 自行调整大小 */
  height: 200px;
  border-radius: 0px; /* 圆角 */
  object-fit: cover;
}
.footer-intro {
  position: absolute;
  bottom: 0;
  width: 100%;
  height: 100px;
  background-color: rgba(177, 36, 49, 0.8); /* 深色背景 */
  color: #dddddd; /* 更暗的字体颜色 */
  padding: 12px 40px;
  box-sizing: border-box;
  z-index: 3;
  text-align: left;
}

.footer-content {
  border-left: 4px solid #ffffff; /* 左侧竖杠 */
  padding-left: 16px; /* 竖杠和文字之间留空 */
}

.footer-content h2 {
  margin: 0 0 4px;
  font-size: 20px;
}

.footer-content p {
  margin: 0 0 0px;
  font-size: 14px;
  line-height: 1.2;
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
