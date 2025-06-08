import { createRouter, createWebHashHistory } from "vue-router";

let routes = [
    { path: "/test", component: () => import("../views/Test.vue") },
    { path: "/", component: () => import("../views/HomePage.vue") },
    { path: "/detail", component: () => import("../views/Detail.vue") },
    { path: "/login", component: () => import("../views/Login.vue") },
    { path: "/userlogin", component: () => import("../views/Userlogin.vue") },
    { path: "/register", component: () => import("../views/Register.vue") },
    {
        path: "/dashboard", component: () => import("../views/dashboard/Dashboard.vue"), children: [
            { path: "/dashboard/category", component: () => import("../views/dashboard/Category.vue") },
            { path: "/dashboard/article", component: () => import("../views/dashboard/Article.vue") },
        ]
    },
    {
        path: "/userboard", component: () => import("../views/userboard/Userboard.vue"), children: [
            // { path: "/userboard/category", component: () => import("../views/userboard/Category.vue") },
            { path: "/userboard/article", component: () => import("../views/userboard/Article.vue") },
        ]
    },
]

const router = createRouter({
    history: createWebHashHistory(),
    routes,
});

export { router, routes };