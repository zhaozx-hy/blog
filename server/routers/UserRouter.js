const express = require("express")
const router = express.Router()
const { v4: uuidv4 } = require("uuid")
const { db, genid } = require("../db/DbUtils")

router.post("/login", async (req, res) => {

    let { account, password } = req.body;
    let { err, rows } = await db.async.all("select * from `user` where `account` = ? AND `password` = ?", [account, password])

    if (err == null && rows.length > 0) {

        let login_token = uuidv4();
        let update_token_sql = "UPDATE `user` SET `token` = ? where `id` = ?"

        await db.async.run(update_token_sql,[login_token,rows[0].id])

        let user_info = rows[0]
        user_info.token = login_token
        user_info.password = ""

        res.send({
            code: 200,
            msg: "登录成功",
            data:user_info
        })
    } else {
        res.send({
            code: 500,
            msg: "登录失败"
        })
    }
})

router.post("/register", async (req, res) => {
    const { account, password, email } = req.body;

    // 1. 参数校验
    if (!account || !password || !email) {
        return res.status(400).send({
            code: 400,
            msg: "账号、密码和邮箱不能为空"
        });
    }

    try {
        // 2. 检查账号/邮箱唯一性
        const checkSql = "SELECT * FROM `user` WHERE `account` = ? OR `email` = ?";
        const { err: checkErr, rows } = await db.async.all(checkSql, [account, email]);
        
        if (checkErr) throw new Error("数据库查询失败");
        if (rows.length > 0) {
            return res.send({
                code: 409,
                msg: "账号或邮箱已被注册"
            });
        }

        // 3. 生成唯一ID和初始token
        const userId = uuidv4(); 
        const initToken = uuidv4();
        
        // 4. 插入新用户
        const insertSql = "INSERT INTO `user` (`id`,`account`,`password`,`email`,`token`) VALUES (?, ?, ?, ?, ?)"
        const { err: insertErr } = await db.async.run(
            insertSql, 
            [userId, account, password, email, initToken]
        );
        
        if (insertErr) throw new Error("用户注册失败");

        // 5. 返回成功响应
        res.status(200).send({
            code: 200,
            msg: "注册成功",
            data: { 
                id: userId,
                account,
                email,
                token: initToken 
            }
        });
        
    } catch (error) {
        // 6. 错误处理
        console.error("注册异常:", error.message);
        res.status(500).send({
            code: 500,
            msg: "服务器内部错误"
        });
    }
});


module.exports = router