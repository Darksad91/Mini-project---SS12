-- 1. Tạo Database
CREATE DATABASE IF NOT EXISTS SocialNetworkDB;
USE SocialNetworkDB;

-- 2. Bảng users
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Bảng posts
CREATE TABLE posts (
    post_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_posts_users
    FOREIGN KEY (user_id)
    REFERENCES users(user_id)
    ON DELETE CASCADE
);

-- 4. Bảng likes
CREATE TABLE likes (
    like_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    post_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_likes_users
    FOREIGN KEY (user_id)
    REFERENCES users(user_id)
    ON DELETE CASCADE,

    CONSTRAINT fk_likes_posts
    FOREIGN KEY (post_id)
    REFERENCES posts(post_id)
    ON DELETE CASCADE,

    CONSTRAINT uq_user_post_like
    UNIQUE(user_id, post_id)
);

-- 5. Bảng comments
CREATE TABLE comments (
    comment_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    post_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_comments_users
    FOREIGN KEY (user_id)
    REFERENCES users(user_id)
    ON DELETE CASCADE,

    CONSTRAINT fk_comments_posts
    FOREIGN KEY (post_id)
    REFERENCES posts(post_id)
    ON DELETE CASCADE
);

-- 6. Bảng friends
CREATE TABLE friends (
    friend_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    friend_user_id INT NOT NULL,

    status ENUM('pending', 'accepted', 'blocked')
    DEFAULT 'pending',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_friends_user1
    FOREIGN KEY (user_id)
    REFERENCES users(user_id)
    ON DELETE CASCADE,

    CONSTRAINT fk_friends_user2
    FOREIGN KEY (friend_user_id)
    REFERENCES users(user_id)
    ON DELETE CASCADE,

    CONSTRAINT chk_not_self_friend
    CHECK (user_id <> friend_user_id)
);

-- 7. Tạo Index
CREATE INDEX idx_posts_created_at
ON posts(created_at);

-- 8. View user info
CREATE VIEW view_user_info AS
SELECT
    user_id,
    username,
    email,
    created_at
FROM users;

-- 9. View thống kê bài viết
CREATE VIEW view_post_statistics AS
SELECT
    p.post_id,
    u.username,
    p.content,

    COUNT(DISTINCT l.like_id) AS total_likes,
    COUNT(DISTINCT c.comment_id) AS total_comments,

    p.created_at

FROM posts p

LEFT JOIN users u
ON p.user_id = u.user_id

LEFT JOIN likes l
ON p.post_id = l.post_id

LEFT JOIN comments c
ON p.post_id = c.post_id

WHERE p.is_deleted = FALSE

GROUP BY
    p.post_id,
    u.username,
    p.content,
    p.created_at;

-- 10. Procedure thêm user
DELIMITER $$

CREATE PROCEDURE sp_add_user(
    IN p_username VARCHAR(100),
    IN p_password VARCHAR(255),
    IN p_email VARCHAR(255)
)
BEGIN

    DECLARE email_count INT;

    SELECT COUNT(*) INTO email_count
    FROM users
    WHERE email = p_email;

    IF email_count > 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email already exists';

    ELSE

        INSERT INTO users(username, password, email)
        VALUES(p_username, p_password, p_email);

    END IF;

END $$

DELIMITER ;

-- 11. Procedure tạo post
DELIMITER $$

CREATE PROCEDURE sp_create_post(
    IN p_user_id INT,
    IN p_content TEXT,
    OUT p_new_post_id INT
)
BEGIN

    INSERT INTO posts(user_id, content)
    VALUES(p_user_id, p_content);

    SET p_new_post_id = LAST_INSERT_ID();

END $$

DELIMITER ;

-- 12. Procedure lấy danh sách bạn bè
DELIMITER $$

CREATE PROCEDURE sp_get_friends(
    IN p_user_id INT,
    IN p_limit INT,
    IN p_offset INT
)
BEGIN

    SELECT
        u.user_id,
        u.username,
        u.email,
        f.created_at

    FROM friends f

    JOIN users u
    ON f.friend_user_id = u.user_id

    WHERE
        f.user_id = p_user_id
        AND f.status = 'accepted'

    LIMIT p_limit OFFSET p_offset;

END $$

DELIMITER ;