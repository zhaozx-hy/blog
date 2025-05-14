<template>
    <div>
        Dashboard
        {{ adminStore }}
    </div>
</template>

<script setup>
import { AdminStore} from '../../stores/AdminStore';
const adminStore = AdminStore()
</script>

<style lang="scss"scoped>

</style>