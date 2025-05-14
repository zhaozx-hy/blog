import { createApp } from 'vue'
import naive from 'naive-ui'
import {createDiscreteApi} from 'naive-ui'
import {createPinia} from "pinia"
import {router} from './common/router'
import axios from 'axios'

import './style.css'
import App from './App.vue'

axios.defaults.baseURL = "http://localhost:8080"
const { message, notification, dialog } = createDiscreteApi(["message", "dialog", "notification"])

const app = createApp(App)

app.provide("message", message)
app.provide("notification", notification)
app.provide("dialog", dialog)

app.provide("axios",axios)
app.use(naive)
app.use(createPinia())
app.use(router)
app.mount('#app')