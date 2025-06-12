-- 创建操作日志表
CREATE TABLE operation_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    operation_type TEXT NOT NULL,
    table_name TEXT NOT NULL,
    record_id TEXT NOT NULL,
    operation_time DATETIME DEFAULT (datetime('now')) NOT NULL,
    old_data TEXT,  -- SQLite没有JSON类型，使用TEXT存储JSON字符串
    new_data TEXT
);

DELIMITER //
-- 为所有表创建触发器
-- admin表触发器
CREATE TRIGGER IF NOT EXISTS admin_after_insert 
AFTER INSERT ON admin
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, new_data)
    VALUES ('INSERT', 'admin', NEW.id, 
            json_object('id', NEW.id, 'account', NEW.account, 'password', NEW.password, 'token', NEW.token));
END; //
DELIMITER ;

DELIMITER //
CREATE TRIGGER IF NOT EXISTS admin_after_update
AFTER UPDATE ON admin
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, old_data, new_data)
    VALUES ('UPDATE', 'admin', NEW.id, 
            json_object('id', OLD.id, 'account', OLD.account, 'password', OLD.password, 'token', OLD.token),
            json_object('id', NEW.id, 'account', NEW.account, 'password', NEW.password, 'token', NEW.token));
END;//
DELIMITER ;

DELIMITER //
CREATE TRIGGER IF NOT EXISTS admin_after_delete
AFTER DELETE ON admin
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, old_data)
    VALUES ('DELETE', 'admin', OLD.id, 
            json_object('id', OLD.id, 'account', OLD.account, 'password', OLD.password, 'token', OLD.token));
END;//
DELIMITER ;

DELIMITER //
-- blog表触发器
CREATE TRIGGER IF NOT EXISTS blog_after_insert 
AFTER INSERT ON blog
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, new_data)
    VALUES ('INSERT', 'blog', NEW.id, 
            json_object('id', NEW.id, 'category_id', NEW.category_id, 'title', NEW.title, 'content', NEW.content, 'create_time', NEW.create_time));
END;//
DELIMITER ;

DELIMITER //
CREATE TRIGGER IF NOT EXISTS blog_after_update
AFTER UPDATE ON blog
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, old_data, new_data)
    VALUES ('UPDATE', 'blog', NEW.id, 
            json_object('id', OLD.id, 'category_id', OLD.category_id, 'title', OLD.title, 'content', OLD.content, 'create_time', OLD.create_time),
            json_object('id', NEW.id, 'category_id', NEW.category_id, 'title', NEW.title, 'content', NEW.content, 'create_time', NEW.create_time));
END;//
DELIMITER ;

DELIMITER //
CREATE TRIGGER IF NOT EXISTS blog_after_delete
AFTER DELETE ON blog
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, old_data)
    VALUES ('DELETE', 'blog', OLD.id, 
            json_object('id', OLD.id, 'category_id', OLD.category_id, 'title', OLD.title, 'content', OLD.content, 'create_time', OLD.create_time));
END;//
DELIMITER ;

DELIMITER //
-- category表触发器
CREATE TRIGGER IF NOT EXISTS category_after_insert 
AFTER INSERT ON category
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, new_data)
    VALUES ('INSERT', 'category', NEW.id, 
            json_object('id', NEW.id, 'name', NEW.name));
END;//
DELIMITER ;

DELIMITER //
CREATE TRIGGER IF NOT EXISTS category_after_update
AFTER UPDATE ON category
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, old_data, new_data)
    VALUES ('UPDATE', 'category', NEW.id, 
            json_object('id', OLD.id, 'name', OLD.name),
            json_object('id', NEW.id, 'name', NEW.name));
END;//
DELIMITER ;

DELIMITER //
CREATE TRIGGER IF NOT EXISTS category_after_delete
AFTER DELETE ON category
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, old_data)
    VALUES ('DELETE', 'category', OLD.id, 
            json_object('id', OLD.id, 'name', OLD.name));
END;//
DELIMITER ;

DELIMITER //
-- user表触发器
CREATE TRIGGER IF NOT EXISTS "user_after_insert" 
AFTER INSERT ON "user"
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, new_data)
    VALUES ('INSERT', 'user', NEW.id, 
            json_object('id', NEW.id, 'account', NEW.account, 'password', NEW.password, 'email', NEW.email, 'token', NEW.token));
END;//
DELIMITER ;

DELIMITER //
CREATE TRIGGER IF NOT EXISTS "user_after_update"
AFTER UPDATE ON "user"
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, old_data, new_data)
    VALUES ('UPDATE', 'user', NEW.id, 
            json_object('id', OLD.id, 'account', OLD.account, 'password', OLD.password, 'email', OLD.email, 'token', OLD.token),
            json_object('id', NEW.id, 'account', NEW.account, 'password', NEW.password, 'email', NEW.email, 'token', NEW.token));
END;//
DELIMITER ;

DELIMITER //
CREATE TRIGGER IF NOT EXISTS "user_after_delete"
AFTER DELETE ON "user"
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, old_data)
    VALUES ('DELETE', 'user', OLD.id, 
            json_object('id', OLD.id, 'account', OLD.account, 'password', OLD.password, 'email', OLD.email, 'token', OLD.token));
END;//
DELIMITER ;

-- 测试1：插入操作
INSERT INTO admin (id,account, password, token) 
VALUES ('9','test_admin', '123456', 'token_123');

-- 测试2：更新操作
UPDATE admin SET password = '654321' WHERE account = 'test_admin';

-- 测试3：删除操作
DELETE FROM admin WHERE account = 'test_admin';

-- 验证日志记录
SELECT * FROM operation_log ORDER BY id DESC;

-- 1. 准备测试数据
INSERT INTO admin (id,account, password, token) 
VALUES ('8','restore_test', 'pass_origin', 'tok_origin');

-- 2. 记录当前时间
SELECT datetime('now') AS current_time;

-- 3. 记录当前最大日志ID
SELECT MAX(id) AS max_log_id_before_restore FROM operation_log;

--  创建事务
BEGIN TRANSACTION;

--  保存要恢复的日志ID范围
CREATE TEMP TABLE IF NOT EXISTS restore_point AS 
SELECT COALESCE(MAX(id), 0) AS max_id 
FROM operation_log 
WHERE operation_time <= '2025-06-11 16:00:00';  --时间可修改

-- 创建临时操作日志表
CREATE TEMP TABLE IF NOT EXISTS restore_operations (
    id INTEGER,
    operation_type TEXT,
    table_name TEXT,
    record_id TEXT,
    old_data TEXT,
    new_data TEXT
);

-- 填充临时表
INSERT INTO restore_operations 
SELECT 
    id,
    operation_type,
    table_name,
    record_id,
    old_data,
    new_data
FROM operation_log 
WHERE id > (SELECT max_id FROM restore_point)
ORDER BY id DESC;  -- 从新到旧恢复

-- 禁用触发器（通过删除临时创建）
DROP TRIGGER IF EXISTS admin_after_insert;
DROP TRIGGER IF EXISTS admin_after_update;
DROP TRIGGER IF EXISTS admin_after_delete;
DROP TRIGGER IF EXISTS blog_after_insert;
DROP TRIGGER IF EXISTS blog_after_update;
DROP TRIGGER IF EXISTS blog_after_delete;
DROP TRIGGER IF EXISTS category_after_insert;
DROP TRIGGER IF EXISTS category_after_update;
DROP TRIGGER IF EXISTS category_after_delete;
DROP TRIGGER IF EXISTS "user_after_insert";
DROP TRIGGER IF EXISTS "user_after_update";
DROP TRIGGER IF EXISTS "user_after_delete";

-- 执行恢复操作
-- admin表恢复
UPDATE admin 
SET account = (
    SELECT json_extract(old_data, '$.account') 
    FROM restore_operations ro 
    WHERE ro.record_id = admin.id 
      AND ro.table_name = 'admin' 
      AND ro.operation_type = 'UPDATE'),
    password = (
    SELECT json_extract(old_data, '$.password') 
    FROM restore_operations ro 
    WHERE ro.record_id = admin.id 
      AND ro.table_name = 'admin' 
      AND ro.operation_type = 'UPDATE'),
    token = (
    SELECT json_extract(old_data, '$.token') 
    FROM restore_operations ro 
    WHERE ro.record_id = admin.id 
      AND ro.table_name = 'admin' 
      AND ro.operation_type = 'UPDATE')
WHERE id IN (
    SELECT record_id 
    FROM restore_operations 
    WHERE table_name = 'admin' 
      AND operation_type = 'UPDATE'
);

DELETE FROM admin 
WHERE id IN (
    SELECT record_id 
    FROM restore_operations 
    WHERE table_name = 'admin' 
      AND operation_type = 'INSERT'
);

INSERT OR IGNORE INTO admin (id, account, password, token)
SELECT 
    json_extract(old_data, '$.id'),
    json_extract(old_data, '$.account'),
    json_extract(old_data, '$.password'),
    json_extract(old_data, '$.token')
FROM restore_operations 
WHERE table_name = 'admin' 
  AND operation_type = 'DELETE';

-- blog表恢复
UPDATE blog 
SET category_id = (
    SELECT json_extract(old_data, '$.category_id') 
    FROM restore_operations ro 
    WHERE ro.record_id = blog.id 
      AND ro.table_name = 'blog' 
      AND ro.operation_type = 'UPDATE'),
    title = (
    SELECT json_extract(old_data, '$.title') 
    FROM restore_operations ro 
    WHERE ro.record_id = blog.id 
      AND ro.table_name = 'blog' 
      AND ro.operation_type = 'UPDATE'),
    content = (
    SELECT json_extract(old_data, '$.content') 
    FROM restore_operations ro 
    WHERE ro.record_id = blog.id 
      AND ro.table_name = 'blog' 
      AND ro.operation_type = 'UPDATE'),
    create_time = (
    SELECT json_extract(old_data, '$.create_time') 
    FROM restore_operations ro 
    WHERE ro.record_id = blog.id 
      AND ro.table_name = 'blog' 
      AND ro.operation_type = 'UPDATE')
WHERE id IN (
    SELECT record_id 
    FROM restore_operations 
    WHERE table_name = 'blog' 
      AND operation_type = 'UPDATE'
);

DELETE FROM blog 
WHERE id IN (
    SELECT record_id 
    FROM restore_operations 
    WHERE table_name = 'blog' 
      AND operation_type = 'INSERT'
);

INSERT OR IGNORE INTO blog (id, category_id, title, content, create_time)
SELECT 
    json_extract(old_data, '$.id'),
    json_extract(old_data, '$.category_id'),
    json_extract(old_data, '$.title'),
    json_extract(old_data, '$.content'),
    json_extract(old_data, '$.create_time')
FROM restore_operations 
WHERE table_name = 'blog' 
  AND operation_type = 'DELETE';

-- category表恢复
UPDATE category 
SET name = (
    SELECT json_extract(old_data, '$.name') 
    FROM restore_operations ro 
    WHERE ro.record_id = category.id 
      AND ro.table_name = 'category' 
      AND ro.operation_type = 'UPDATE')
WHERE id IN (
    SELECT record_id 
    FROM restore_operations 
    WHERE table_name = 'category' 
      AND operation_type = 'UPDATE'
);

DELETE FROM category 
WHERE id IN (
    SELECT record_id 
    FROM restore_operations 
    WHERE table_name = 'category' 
      AND operation_type = 'INSERT'
);

INSERT OR IGNORE INTO category (id, name)
SELECT 
    json_extract(old_data, '$.id'),
    json_extract(old_data, '$.name')
FROM restore_operations 
WHERE table_name = 'category' 
  AND operation_type = 'DELETE';

-- user表恢复
UPDATE "user" 
SET account = (
    SELECT json_extract(old_data, '$.account') 
    FROM restore_operations ro 
    WHERE ro.record_id = "user".id 
      AND ro.table_name = 'user' 
      AND ro.operation_type = 'UPDATE'),
    password = (
    SELECT json_extract(old_data, '$.password') 
    FROM restore_operations ro 
    WHERE ro.record_id = "user".id 
      AND ro.table_name = 'user' 
      AND ro.operation_type = 'UPDATE'),
    email = (
    SELECT json_extract(old_data, '$.email') 
    FROM restore_operations ro 
    WHERE ro.record_id = "user".id 
      AND ro.table_name = 'user' 
      AND ro.operation_type = 'UPDATE'),
    token = (
    SELECT json_extract(old_data, '$.token') 
    FROM restore_operations ro 
    WHERE ro.record_id = "user".id 
      AND ro.table_name = 'user' 
      AND ro.operation_type = 'UPDATE')
WHERE id IN (
    SELECT record_id 
    FROM restore_operations 
    WHERE table_name = 'user' 
      AND operation_type = 'UPDATE'
);

DELETE FROM "user" 
WHERE id IN (
    SELECT record_id 
    FROM restore_operations 
    WHERE table_name = 'user' 
      AND operation_type = 'INSERT'
);

INSERT OR IGNORE INTO "user" (id, account, password, email, token)
SELECT 
    json_extract(old_data, '$.id'),
    json_extract(old_data, '$.account'),
    json_extract(old_data, '$.password'),
    json_extract(old_data, '$.email'),
    json_extract(old_data, '$.token')
FROM restore_operations 
WHERE table_name = 'user' 
  AND operation_type = 'DELETE';

-- 删除恢复期间的操作日志
DELETE FROM operation_log 
WHERE id IN (SELECT id FROM restore_operations);

-- 重新创建触发器
DELIMITER //
-- admin表触发器
CREATE TRIGGER IF NOT EXISTS admin_after_insert 
AFTER INSERT ON admin
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, new_data)
    VALUES ('INSERT', 'admin', NEW.id, 
            json_object('id', NEW.id, 'account', NEW.account, 'password', NEW.password, 'token', NEW.token));
END; //
DELIMITER ;

DELIMITER //
CREATE TRIGGER IF NOT EXISTS admin_after_update
AFTER UPDATE ON admin
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, old_data, new_data)
    VALUES ('UPDATE', 'admin', NEW.id, 
            json_object('id', OLD.id, 'account', OLD.account, 'password', OLD.password, 'token', OLD.token),
            json_object('id', NEW.id, 'account', NEW.account, 'password', NEW.password, 'token', NEW.token));
END;//
DELIMITER ;

DELIMITER //
CREATE TRIGGER IF NOT EXISTS admin_after_delete
AFTER DELETE ON admin
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, old_data)
    VALUES ('DELETE', 'admin', OLD.id, 
            json_object('id', OLD.id, 'account', OLD.account, 'password', OLD.password, 'token', OLD.token));
END;//
DELIMITER ;

DELIMITER //
-- blog表触发器
CREATE TRIGGER IF NOT EXISTS blog_after_insert 
AFTER INSERT ON blog
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, new_data)
    VALUES ('INSERT', 'blog', NEW.id, 
            json_object('id', NEW.id, 'category_id', NEW.category_id, 'title', NEW.title, 'content', NEW.content, 'create_time', NEW.create_time));
END;//
DELIMITER ;

DELIMITER //
CREATE TRIGGER IF NOT EXISTS blog_after_update
AFTER UPDATE ON blog
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, old_data, new_data)
    VALUES ('UPDATE', 'blog', NEW.id, 
            json_object('id', OLD.id, 'category_id', OLD.category_id, 'title', OLD.title, 'content', OLD.content, 'create_time', OLD.create_time),
            json_object('id', NEW.id, 'category_id', NEW.category_id, 'title', NEW.title, 'content', NEW.content, 'create_time', NEW.create_time));
END;//
DELIMITER ;

DELIMITER //
CREATE TRIGGER IF NOT EXISTS blog_after_delete
AFTER DELETE ON blog
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, old_data)
    VALUES ('DELETE', 'blog', OLD.id, 
            json_object('id', OLD.id, 'category_id', OLD.category_id, 'title', OLD.title, 'content', OLD.content, 'create_time', OLD.create_time));
END;//
DELIMITER ;

DELIMITER //
-- category表触发器
CREATE TRIGGER IF NOT EXISTS category_after_insert 
AFTER INSERT ON category
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, new_data)
    VALUES ('INSERT', 'category', NEW.id, 
            json_object('id', NEW.id, 'name', NEW.name));
END;//
DELIMITER ;

DELIMITER //
CREATE TRIGGER IF NOT EXISTS category_after_update
AFTER UPDATE ON category
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, old_data, new_data)
    VALUES ('UPDATE', 'category', NEW.id, 
            json_object('id', OLD.id, 'name', OLD.name),
            json_object('id', NEW.id, 'name', NEW.name));
END;//
DELIMITER ;

DELIMITER //
CREATE TRIGGER IF NOT EXISTS category_after_delete
AFTER DELETE ON category
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, old_data)
    VALUES ('DELETE', 'category', OLD.id, 
            json_object('id', OLD.id, 'name', OLD.name));
END;//
DELIMITER ;

DELIMITER //
-- user表触发器
CREATE TRIGGER IF NOT EXISTS "user_after_insert" 
AFTER INSERT ON "user"
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, new_data)
    VALUES ('INSERT', 'user', NEW.id, 
            json_object('id', NEW.id, 'account', NEW.account, 'password', NEW.password, 'email', NEW.email, 'token', NEW.token));
END;//
DELIMITER ;

DELIMITER //
CREATE TRIGGER IF NOT EXISTS "user_after_update"
AFTER UPDATE ON "user"
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, old_data, new_data)
    VALUES ('UPDATE', 'user', NEW.id, 
            json_object('id', OLD.id, 'account', OLD.account, 'password', OLD.password, 'email', OLD.email, 'token', OLD.token),
            json_object('id', NEW.id, 'account', NEW.account, 'password', NEW.password, 'email', NEW.email, 'token', NEW.token));
END;//
DELIMITER ;

DELIMITER //
CREATE TRIGGER IF NOT EXISTS "user_after_delete"
AFTER DELETE ON "user"
BEGIN
    INSERT INTO operation_log (operation_type, table_name, record_id, old_data)
    VALUES ('DELETE', 'user', OLD.id, 
            json_object('id', OLD.id, 'account', OLD.account, 'password', OLD.password, 'email', OLD.email, 'token', OLD.token));
END;//
DELIMITER ;

-- 清理临时表(执行该操作则会试验证2无法执行）
--DROP TABLE IF EXISTS restore_point;
--DROP TABLE IF EXISTS restore_operations;

COMMIT;

-- 验证1：检查数据是否回滚
SELECT * FROM admin WHERE account = 'restore_test';

-- 验证2：检查日志是否清理
SELECT * FROM operation_log 
WHERE id > (SELECT max_id FROM restore_point);