-- Users (Password is 'password' hashed with a dummy Argon2-like string)
-- Note: You may need to update these with real hashes if you want to login with 'password'
INSERT INTO "user" (username, email, password, bio, image) VALUES 
('jake', 'jake@jake.jake', '$argon2id$v=19$m=65536,t=2,p=1$c29tZXNhbHQ$Rdesc85idS9tV3Y3S3JKZXNCZ3NidVE', 'I work at statefarm', 'https://api.realworld.io/images/smiley-cyrus.jpeg'),
('anna', 'anna@example.com', '$argon2id$v=19$m=65536,t=2,p=1$c29tZXNhbHQ$Rdesc85idS9tV3Y3S3JKZXNCZ3NidVE', 'I love Haskell', 'https://api.realworld.io/images/demo-avatar.png'),
('gerard', 'gerard@example.com', '$argon2id$v=19$m=65536,t=2,p=1$c29tZXNhbHQ$Rdesc85idS9tV3Y3S3JKZXNCZ3NidVE', 'Coffee enthusiast and coder', 'https://api.realworld.io/images/smiley-cyrus.jpeg'),
('john_doe', 'john@doe.com', '$argon2id$v=19$m=65536,t=2,p=1$c29tZXNhbHQ$Rdesc85idS9tV3Y3S3JKZXNCZ3NidVE', 'Just another developer', NULL);

-- Tags
INSERT INTO "tag" (name) VALUES ('haskell'), ('servant'), ('webdev'), ('functional-programming'), ('tutorial'), ('react'), ('nodejs'), ('postgres');

-- Articles
INSERT INTO "article" (slug, title, description, body, author_id, created_at, updated_at) VALUES 
('how-to-train-your-dragon', 'How to train your dragon', 'Ever wonder how?', 'It takes a lot of patience and some fish.', 1, NOW(), NOW()),
('how-to-train-your-dragon-2', 'How to train your dragon 2', 'So stuck?', 'It takes even more patience and a bigger dragon.', 1, NOW(), NOW()),
('servant-is-awesome', 'Servant is awesome', 'Type-safe APIs in Haskell', 'Servant is a library for declaring web APIs at the type-level.', 2, NOW(), NOW()),
('intro-to-fp', 'Introduction to Functional Programming', 'Learn the basics of FP', 'Functional programming is a programming paradigm where programs are constructed by applying and composing functions.', 2, NOW(), NOW()),
('building-realworld-haskell', 'Building a RealWorld App with Haskell', 'A step-by-step guide', 'In this article, we explore the implementation of the Conduit API using Servant and Persistent.', 3, NOW(), NOW()),
('postgres-performance-tips', 'Postgres Performance Tips', 'Make your queries faster', 'Indexing, vacuuming, and analyzing are key to a healthy database.', 4, NOW(), NOW()),
('react-vs-vue-2026', 'React vs Vue in 2026', 'Which one to choose?', 'Both frameworks have evolved significantly, but React remains dominant in the enterprise.', 3, NOW(), NOW());

-- Article Tags
INSERT INTO "article_tag" (article_id, tag_id) VALUES 
(1, 1), (1, 3), 
(3, 1), (3, 2), (3, 4),
(4, 4), (4, 5),
(5, 1), (5, 2), (5, 3),
(6, 8), (6, 3),
(7, 6), (7, 3);

-- Comments
INSERT INTO "comment" (body, author_id, article_id, created_at, updated_at) VALUES 
('Great article! Really helped me understand Servant.', 3, 3, NOW(), NOW()),
('I prefer Vue actually, but good read.', 4, 7, NOW(), NOW()),
('Nice tips on Postgres, thanks!', 2, 6, NOW(), NOW()),
('When is the next part coming out?', 1, 5, NOW(), NOW());

-- Favorites
INSERT INTO "favorite" (user_id, article_id) VALUES 
(1, 3), (1, 4), (1, 5),
(2, 5), (2, 7),
(3, 1), (3, 6);

-- Follows
INSERT INTO "follow" (follower_id, followed_id) VALUES 
(1, 2), (1, 3),
(2, 1), (2, 3),
(3, 1), (3, 2), (3, 4);
