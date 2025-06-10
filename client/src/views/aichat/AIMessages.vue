<template>
  <div class="chat-container">
    <!-- 左侧侧边栏 -->
    <div class="sidebar" :class="{ collapsed: isCollapsed }">
      <!-- 顶部 Logo 和 名称 -->
      <div class="sidebar-header">
        <div class="logo-wrapper">
          <img src="../../assets/logo.png" alt="Logo" class="logo" />
          <span v-if="!isCollapsed" class="app-name">长征大模型</span>
        </div>
      </div>

      <!-- 分隔线 -->
      <hr class="divider" />

      <!-- 按钮区域：展开/收起 -->
      <div class="button-wrapper">
        <button v-if="!isCollapsed" class="collapse-btn" @click="toggleSidebar">
          <img src="../../assets/side.png" alt="收起" class="toggle-icon" />
        </button>
        <button v-else class="collapse-btn" @click="toggleSidebar">
          <img src="../../assets/side.png" alt="展开" class="toggle-icon" />
        </button>
      </div>

      <!-- 聊天记录区域 -->
      <div v-if="!isCollapsed" class="sidebar-content">
        <div
            v-for="(chat, index) in chatHistory"
            :key="index"
            class="chat-item"
            :class="{ active: currentChatIndex === index }"
            @click="loadChat(index)"
        >
          <div class="chat-item-title">{{ getChatTitle(chat) }}</div>
          <div class="chat-item-preview">{{ getChatPreview(chat) }}</div>
          <button class="delete-chat-btn" @click.stop="deleteChat(index)">
            <img src="../../assets/delete.png" alt="删除" />
          </button>
        </div>
      </div>
    </div>

    <!-- 右侧聊天区域 -->
    <div class="chat-main">
      <!-- 回退按钮 -->
      <button class="back-button" @click="onBack">
        <img src="../../assets/back-red.png" alt="返回" />
      </button>
      <!-- 新对话按钮 -->
      <button class="new-chat-btn" @click="startNewChat">
        <img src="../../assets/logo.png" alt="Logo" class="chat-logo" />
        开启新对话！
      </button>

      <div class="chat-content">
        <!-- 聊天消息气泡结构 -->
        <div
            v-for="(msg, index) in messages"
            :key="index + (msg.from === 'bot' ? msg.text.length : 0)"
            :class="['message', msg.from === 'bot' ? 'bot' : 'user']"
        >
          <!-- 机器人消息：头像在左 -->
          <img
              v-if="msg.from === 'bot'"
              src="../../assets/czlogo.png"
              alt="机器人头像"
              class="avatar"
          />
          <div class="bubble-wrapper">
            <div class="bubble" v-html="formatMessage(msg.text)"></div>
            <!-- 复制按钮（仅机器人消息显示） -->
            <button
                v-if="msg.from === 'bot' && msg.text"
                class="copy-btn"
                @click="copyToClipboard(msg.text, index)"
                :title="copyStatus[index] || '复制'"
            >
              <img src="../../assets/copy.png" alt="复制" />
            </button>
          </div>

          <!-- 用户消息：头像在右 -->
          <img
              v-if="msg.from === 'user'"
              src="../../assets/xs.png"
              alt="用户头像"
              class="avatar"
          />
        </div>
      </div>

      <!-- 底部输入框 -->
      <div class="input-wrapper">
        <input
            v-model="inputValue"
            type="text"
            class="custom-input"
            placeholder="请输入内容"
            @keyup.enter="handleSend"
            :disabled="isLoading"
        />
        <button
            class="arrow-button"
            @click="isLoading ? cancelRequest() : handleSend()"
            :style="{ backgroundColor: isLoading ? '#ff4d4f' : '#e10403' }"
        >
          <img
              src="../../assets/arrow-up.png"
              alt="发送"
              v-if="!isLoading"
          />
          <span v-else style="color: white">×</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, nextTick, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import OpenAI from 'openai'

const router = useRouter()
const inputValue = ref('')
const messages = ref([])
const isCollapsed = ref(false)
const isLoading = ref(false)
const currentBotMessage = ref(null)
const controller = ref(null)
const copyStatus = ref({})
const chatHistory = ref([])
const currentChatIndex = ref(-1)

// 初始化OpenAI客户端
const openai = new OpenAI({
  baseURL: 'https://api.deepseek.com',
  apiKey: 'sk-2a3b0bc9be4740469605c617abdb4d75',
  dangerouslyAllowBrowser: true
})

// 加载本地存储的聊天记录
onMounted(() => {
  const savedChats = localStorage.getItem('chatHistory')
  if (savedChats) {
    chatHistory.value = JSON.parse(savedChats)
  }
})

function onBack() {
  router.go(-1)
}

function startNewChat() {
  messages.value = []
  inputValue.value = ''
  currentChatIndex.value = -1
}

function deleteChat(index) {
  if (confirm('确定要删除此聊天记录吗？')) {
    chatHistory.value.splice(index, 1)
    localStorage.setItem('chatHistory', JSON.stringify(chatHistory.value))
    if (currentChatIndex.value === index) {
      currentChatIndex.value = -1
      messages.value = []
    } else if (currentChatIndex.value > index) {
      currentChatIndex.value--
    }
  }
}

function toggleSidebar() {
  isCollapsed.value = !isCollapsed.value
}

function formatMessage(text) {
  if (!text) return ''
  let formatted = text
      .replace(/^#+\s*/gm, '')
      .replace(/\*\*/g, '')
      .replace(/\*/g, '')
      .replace(/\n{3,}/g, '\n\n')
      .replace(/^- /gm, '• ')
      .trim()
  formatted = formatted
      .replace(/```([\s\S]*?)```/g, '<pre><code>$1</code></pre>')
      .replace(/`([^`]+)`/g, '<code>$1</code>')
  formatted = formatted.replace(/(?<!<\/code>|<\/pre>)\n(?!<code>|<pre>)/g, '<br>')
  return formatted
}

function copyToClipboard(text, index) {
  navigator.clipboard.writeText(text).then(() => {
    copyStatus.value[index] = '已复制'
    setTimeout(() => {
      delete copyStatus.value[index]
    }, 2000)
  }).catch(err => {
    console.error('复制失败:', err)
    copyStatus.value[index] = '复制失败'
  })
}

function getChatTitle(chat) {
  if (chat.length === 0) return '新对话'
  const firstMessage = chat[0].text
  return firstMessage.length > 20
      ? firstMessage.substring(0, 20) + '...'
      : firstMessage
}

function getChatPreview(chat) {
  if (chat.length === 0) return '无内容'
  const lastMessage = chat[chat.length - 1].text
  return lastMessage.length > 30
      ? lastMessage.substring(0, 30) + '...'
      : lastMessage
}

function loadChat(index) {
  currentChatIndex.value = index
  messages.value = [...chatHistory.value[index]]
  nextTick(() => scrollToBottom())
}

function saveChat() {
  if (messages.value.length === 0) return
  if (currentChatIndex.value >= 0) {
    chatHistory.value[currentChatIndex.value] = [...messages.value]
  } else {
    chatHistory.value.push([...messages.value])
    currentChatIndex.value = chatHistory.value.length - 1
  }
  localStorage.setItem('chatHistory', JSON.stringify(chatHistory.value))
}

async function handleSend() {
  const text = inputValue.value.trim()
  if (!text || isLoading.value) return
  if (currentChatIndex.value === -1 && messages.value.length === 0) {
    saveChat()
  }
  messages.value = [...messages.value, { from: 'user', text }]
  inputValue.value = ''
  await nextTick()
  scrollToBottom()
  const botMsg = ref({ from: 'bot', text: '' })
  messages.value = [...messages.value, botMsg.value]
  currentBotMessage.value = botMsg
  isLoading.value = true
  await nextTick()
  scrollToBottom()
  controller.value = new AbortController()
  try {
    const response = await fetch('https://api.deepseek.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${openai.apiKey}`
      },
      body: JSON.stringify({
        model: "deepseek-chat",
        messages: [
          { role: "system", content: "你是一个精通长征相关历史事件的知识助手，你的回答要注意格式和长度。回复适量。" },
          { role: "user", content: text }
        ],
        stream: true,
        temperature: 0.7
      }),
      signal: controller.value.signal
    })
    if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`)
    const reader = response.body.getReader()
    const decoder = new TextDecoder()
    let buffer = ''
    while (true) {
      const { value, done } = await reader.read()
      if (done) break
      buffer += decoder.decode(value, { stream: true })
      const lines = buffer.split('\n')
      buffer = lines.pop() || ''
      for (const line of lines) {
        if (!line.trim() || line === 'data: [DONE]') continue
        try {
          const data = JSON.parse(line.replace(/^data: /, ''))
          const content = data.choices[0]?.delta?.content || ''
          if (content) {
            botMsg.value.text += content
            debouncedScroll()
          }
        } catch (e) {
          console.error('解析错误:', e, '原始数据:', line)
        }
      }
    }
  } catch (err) {
    if (err.name !== 'AbortError') {
      console.error('API错误:', err)
      botMsg.value.text += '\n\n(请求出错: ' + (err.message || '未知错误') + ')'
    }
  } finally {
    isLoading.value = false
    currentBotMessage.value = null
    controller.value = null
    scrollToBottom()
    saveChat()
  }
}

let scrollTimeout = null
function debouncedScroll() {
  clearTimeout(scrollTimeout)
  scrollTimeout = setTimeout(scrollToBottom, 100)
}

function scrollToBottom() {
  nextTick(() => {
    const container = document.querySelector('.chat-content')
    if (container) {
      container.scrollTop = container.scrollHeight
    }
  })
}

function cancelRequest() {
  if (controller.value) {
    controller.value.abort()
    isLoading.value = false
    if (currentBotMessage.value) {
      currentBotMessage.value.text += ' (请求已取消)'
      scrollToBottom()
    }
    currentBotMessage.value = null
  }
}
</script>

<style scoped>
.chat-container {
  display: flex;
  height: 100vh;
  overflow: hidden;
  background-color: #f5f5f5;
}
/* 省略现有样式保持不变 */

.new-chat-btn {
  position: absolute;
  top: 20px;
  left: 70px;
  background: #e10403;        /* 红色背景 */
  border: none;
  border-radius: 12px;         /* 圆角矩形 */
  cursor: pointer;
  font-size: 16px;
  color: white;                /* 白色文字 */
  padding: 8px 12px;           /* 内边距适当增加 */
  display: flex;
  align-items: center;         /* 垂直居中对齐图标和文字 */
  gap: 6px;                    /* 图标和文字之间的间距 */
}

.chat-logo {
  width: 20px;
  height: 20px;
}

.new-chat-btn:hover {
  color: #B12431;
}
.chat-container {
  display: flex;
  height: 100vh;
  overflow: hidden;
  background-color: #f5f5f5;
}

.sidebar {
  width: 240px;
  background-color: #B12431;
  color: white;
  height: 100vh;
  transition: width 0.3s ease;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.sidebar.collapsed {
  width: 60px;
}

.sidebar-header {
  display: flex;
  align-items: center;
  padding: 16px;
}

.logo-wrapper {
  display: flex;
  align-items: center;
}

.logo {
  width: 32px;
  height: 32px;
}

.app-name {
  margin-left: 12px;
  font-size: 18px;
  font-weight: bold;
  white-space: nowrap;
}

.divider {
  margin: 0 16px;
  border: none;
  border-top: 1px solid rgba(255, 255, 255, 0.2);
}

.button-wrapper {
  padding: 8px 16px;
  display: flex;
  justify-content: flex-end;
}

.collapse-btn {
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 0;
  opacity: 0.7;
  transition: opacity 0.2s;
}

.collapse-btn:hover {
  opacity: 1;
}

.toggle-icon {
  width: 20px;
  height: 20px;
  filter: brightness(0) invert(1);
}

.sidebar-content {
  padding: 16px;
  flex-grow: 1;
  overflow-y: auto;
  font-size: 14px;
  line-height: 1.5;
}

.chat-item {
  position: relative;
  padding: 10px;
  margin-bottom: 8px;
  border-radius: 8px;
  cursor: pointer;
  background-color: rgba(255, 255, 255, 0.1);
  transition: background-color 0.2s;
}

.chat-item:hover {
  background-color: rgba(255, 255, 255, 0.2);
}

.chat-item.active {
  background-color: rgba(255, 255, 255, 0.3);
}

.delete-chat-btn {
  position: absolute;
  top: 8px;
  right: 8px;
  background: transparent;
  border: none;
  width: 26px;
  height: 18px;
  opacity: 0.5;
  transition: opacity 0.2s;
}

.delete-chat-btn:hover {
  opacity: 1;
}

.delete-chat-btn img {
  width: 100%;
  height: 100%;
}

.chat-item-title {
  font-weight: bold;
  margin-bottom: 4px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  padding-right: 20px;
}

.chat-item-preview {
  font-size: 12px;
  opacity: 0.8;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  padding-right: 20px;
}

.chat-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 20px 40px;
  background-color: #fdf8d5;
  box-sizing: border-box;
  position: relative;
}

.back-button {
  position: absolute;
  top: 20px;
  left: 20px;
  background: transparent;
  border: none;
  cursor: pointer;
  z-index: 10;
  padding: 0;
  transition: transform 0.2s;
}

.back-button:hover {
  transform: scale(1.1);
}

.back-button img {
  width: 32px;
  height: 32px;
}

.chat-content {
  flex: 1;
  width: 60%;
  overflow-y: scroll;
  padding: 60px 0 20px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  margin: 0 auto;
  scrollbar-width: none;
  -ms-overflow-style: none;
}

.chat-content::-webkit-scrollbar {
  display: none;
}

.message {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.message.bot {
  justify-content: flex-start;
}

.message.user {
  justify-content: flex-end;
}

.avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
}

.bubble-wrapper {
  position: relative;
  max-width: 80%;

}

.bubble {
  padding: 12px 16px;
  border-radius: 16px;
  font-size: 15px;
  line-height: 1.6;
  word-break: break-word;
}

.message.bot .bubble {
  background-color: #fdf8d5;
  color: #333;

}

.message.user .bubble {
  background-color: #d62c1a;
  color: #fff;
}

.message.user .avatar {
  order: 2;
}

.copy-btn {
  position: absolute;
  bottom: 8px;
  right: 8px;
  background: rgba(0, 0, 0, 0.05);
  border: none;
  border-radius: 4px;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  opacity: 0;
  transition: opacity 0.2s;
}

.bubble-wrapper:hover .copy-btn {
  opacity: 1;
}

.copy-btn:hover {
  background: rgba(0, 0, 0, 0.1);
}

.copy-btn img {
  width: 14px;
  height: 14px;
}

pre {
  background-color: #f5f2e9;
  border-left: 3px solid #d62c1a;
  border-radius: 6px;
  padding: 12px;
  overflow-x: auto;
  margin: 8px 0;
  font-family: 'Courier New', monospace;
  font-size: 14px;
}

code {
  background-color: #f5f2e9;
  padding: 2px 4px;
  border-radius: 4px;
  font-family: 'Courier New', monospace;
  font-size: 14px;
  color: #c7254e;
}

.input-wrapper {
  position: relative;
  width: 60%;
  margin: 20px auto 0;
}

.custom-input {
  width: 100%;
  height: 60px;
  padding: 0 60px 0 16px;
  font-size: 16px;
  border-radius: 12px;
  border: 1.5px solid #ccc;
  box-sizing: border-box;
  outline: none;
  transition: border-color 0.2s;
}

.custom-input:focus {
  border-color: #e10403;
}

.custom-input:disabled {
  background-color: #f5f5f5;
  opacity: 0.7;
}

.arrow-button {
  position: absolute;
  top: 10px;
  right: 10px;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: none;
  background-color: #e10403;
  cursor: pointer;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 0;
  transition: background-color 0.2s;
}

.arrow-button:hover {
  background-color: #B12431;
}

.arrow-button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

.arrow-button img {
  width: 20px;
  height: 20px;
}

.message.bot .bubble {
  position: relative;
  overflow: hidden;
}

.message.bot .bubble:empty::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 0;
  width: 100%;
  height: 2px;
  background: linear-gradient(90deg, transparent, #e10403, transparent);
  animation: loading 1.5s infinite;
  opacity: 0.3;
}

@keyframes loading {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}
</style>