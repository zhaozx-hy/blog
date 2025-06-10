<template>
  <div>
    <!-- 顶部导航栏 -->
    <div class="navbar">
      <div class="navbar-left" @click="homePage">
        <img src="../assets/logo.png" class="logo" />
        <span class="title">博客系统</span>
      </div>
      <div class="navbar-right-container">
        <div class="navbar-right">
          <div class="nav-item" @click="homePage">首页</div>
          <n-popselect
              @update:value="searchByCategory"
              v-model:value="selectedCategory"
              :options="categortyOptions"
              trigger="click"
          >
            <div class="nav-item">分类 <span>{{ categoryName }}</span></div>
          </n-popselect>
          <div class="nav-item" @click="userboard">用户</div>
          <div class="nav-item" @click="dashboard">后台</div>
          <div class="nav-item" @click="aichat">长征大模型</div>
          <div class="search-container">
            <n-input
                v-model:value="pageInfo.keyword"
                placeholder="关键词"
                size="small"
                style="width: 180px; border-radius: 20px; margin-right: 8px;font-size: 12px"
            />
            <img src="../assets/serche.png" class="search-icon" @click="loadBlogs(0)" />
          </div>
        </div>
      </div>
    </div>

    <!-- 主内容区域 -->
    <div class="container">
      <!-- 轮播图 -->
      <n-carousel autoplay show-arrow :show-dots="false" style="height: 400px; margin: 30px 0;">
        <img src="../assets/banner.png" style="width: 100%; height: 100%; object-fit: cover;" />
        <img src="../assets/banner2.jpg" style="width: 100%; height: 100%; object-fit: cover;" />
        <img src="../assets/banner3.jpg" style="width: 100%; height: 100%; object-fit: cover;" />
        <img src="../assets/banner4.jpg" style="width: 100%; height: 100%; object-fit: cover;" />
        <img src="../assets/banner5.jpg" style="width: 100%; height: 100%; object-fit: cover;" />
      </n-carousel>

      <!-- 博客列表 -->
      <div v-for="(blog, index) in blogListInfo" :key="index"
           style="margin-bottom: 15px; cursor: pointer; display: flex; align-items: center; border-bottom: 1px solid #f0f0f0; padding-bottom: 15px;">

        <!-- 红色边框日期方框 -->
        <div style="margin-right: 15px; flex-shrink: 0;">
          <div style="width: 70px; height: 70px; border: 2px solid #E10403;
                display: flex; flex-direction: column; justify-content: center;
                align-items: center; text-align: center; border-radius: 4px;">
            <div style="font-size: 12px; color: #333;">{{ formatDate(blog.create_time, 'Y年M月') }}</div>
            <div style="font-size: 20px; font-weight: bold; color: #333;">{{ formatDate(blog.create_time, 'D日') }}</div>
          </div>
        </div>

        <!-- 博客内容卡片 -->
        <n-card
            :title="blog.title"
            style="flex-grow: 1; box-shadow: none; border: none; background-color: transparent;"
            :header-style="{ fontSize: '20px', fontWeight: 'bold' }"
        >
          <div style="color: #666; line-height: 1.6;">{{ blog.content }}</div>
          <template #footer>
            <n-space align="center" justify="start">
              <n-button type="error" size="small" @click.stop="toDetail(blog)" style="margin-top: 10px;background-color: #E10403;height: 36px;width: 90px">
                显示详情
              </n-button>
            </n-space>
          </template>
        </n-card>
      </div>

      <n-pagination
          @update:page="loadBlogs"
          v-model:page="pageInfo.page"
          :page-count="pageInfo.pageCount"
      />

      <n-divider />

      <div class="footer">
        <div>Power by XXXX</div>
        <div>XICP备XXXXX号-1</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, inject, onMounted, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'

const router = useRouter()
const route = useRoute()

const message = inject("message")
const dialog = inject("dialog")
const axios = inject("axios")

const selectedCategory = ref(0)
const categortyOptions = ref([])
const blogListInfo = ref([])

const formatDate = (dateString, format) => {
  try {
    // 处理中文日期格式（如"2024年09月15日"）
    if (dateString.includes('年') && dateString.includes('月') && dateString.includes('日')) {
      const parts = dateString.match(/(\d+)年(\d+)月(\d+)日/);
      if (parts && parts.length === 4) {
        const year = parts[1];
        const month = parseInt(parts[2]); // 转换为数字去掉前导零
        const day = parseInt(parts[3]);   // 转换为数字去掉前导零

        if (format === 'Y年M月') return `${year}年${month}月`;
        if (format === 'D日') return `${day}日`;
        return dateString;
      }
    }

    // 处理标准日期格式
    const date = new Date(dateString);
    if (isNaN(date.getTime())) return '';

    const year = date.getFullYear();
    const month = date.getMonth() + 1; // 不加前导零
    const day = date.getDate();       // 不加前导零

    if (format === 'Y年M月') return `${year}年${month}月`;
    if (format === 'D日') return `${day}日`;
    return dateString;
  } catch (e) {
    console.error('日期格式化错误:', e);
    return '';
  }
}

const pageInfo = reactive({
  page: 1,
  pageSize: 3,
  pageCount: 0,
  count: 0,
  keyword: "",
  categoryId: 0,
})

onMounted(() => {
  loadCategorys()
  loadBlogs()
})

const loadBlogs = async (page = 0) => {
  if (page != 0) pageInfo.page = page
  let res = await axios.get(`/blog/search?keyword=${pageInfo.keyword}&page=${pageInfo.page}&pageSize=${pageInfo.pageSize}&categoryId=${pageInfo.categoryId}`)
  let temp_rows = res.data.data.rows
  for (let row of temp_rows) {
    row.content += "..."
    let d = new Date(row.create_time)
    row.create_time = `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日`
  }
  blogListInfo.value = temp_rows
  pageInfo.count = res.data.data.count
  pageInfo.pageCount = Math.ceil(pageInfo.count / pageInfo.pageSize)
}

const categoryName = computed(() => {
  let selectedOption = categortyOptions.value.find((option) => option.value === selectedCategory.value)
  return selectedOption ? selectedOption.label : ""
})

const loadCategorys = async () => {
  let res = await axios.get("/category/list")
  categortyOptions.value = res.data.rows.map((item) => ({ label: item.name, value: item.id }))
}

const searchByCategory = (categoryId) => {
  pageInfo.categoryId = categoryId
  loadBlogs()
}

const toDetail = (blog) => {
  router.push({ path: "/detail", query: { id: blog.id } })
}

const homePage = () => router.push("/")
const dashboard = () => router.push("/login")
const userboard = () => router.push("/userlogin")
const aichat = () => router.push("/aimessages")
</script>

<style lang="scss" scoped>
/* 顶部导航栏 */
.navbar {
  width: 100%;
  background-color: #E10403;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 40px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  position: sticky;
  top: 0;
  z-index: 10;
}

.navbar-left {
  display: flex;
  align-items: center;
  cursor: pointer;
  transition: all 0.3s ease;

  &:hover {
    opacity: 0.8;
  }
}

.logo {
  height: 40px;
  margin-right: 10px;
  transition: transform 0.3s ease;

  &:hover {
    transform: scale(1.05);
  }
}

.title {
  font-size: 20px;
  font-weight: bold;
  color: white;
  transition: all 0.3s ease;
}

/* 右侧导航项容器，和主体居中对齐 */
.navbar-right-container {
  max-width: 1200px;
  width: 100%;
  display: flex;
  justify-content: flex-end;
  margin-right: 400px;
}

.navbar-right {
  display: flex;
  gap: 32px;
  font-size: 16px;
  align-items: center;
  color: white;
}

/* 导航项样式 */
.nav-item {
  position: relative;
  padding: 8px 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  border-radius: 4px;

  &::before {
    content: '';
    position: absolute;
    bottom: 0;
    left: 50%;
    width: 0;
    height: 2px;
    background-color: white;
    transition: all 0.3s ease;
    transform: translateX(-50%);
  }

  &:hover {
    background-color: rgba(255, 255, 255, 0.2);

    &::before {
      width: calc(100% - 24px);
    }
  }

  &:active {
    transform: translateY(1px);
    background-color: rgba(255, 255, 255, 0.3);
  }
}

/* 搜索容器 */
.search-container {
  display: flex;
  align-items: center;
  gap: 0;
  margin-left: 32px;
}

/* 搜索图标 */
.search-icon {
  height: 20px;
  cursor: pointer;
  margin-left: 8px;
  transition: all 0.3s ease;

  &:hover {
    transform: scale(1.1);
    opacity: 0.8;
  }

  &:active {
    transform: scale(0.95);
  }
}

/* 主体容器内容居中 */
.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

/* 页脚 */
.footer {
  text-align: center;
  color: #999;
  font-size: 14px;
  margin: 40px 0 20px;
}
</style>