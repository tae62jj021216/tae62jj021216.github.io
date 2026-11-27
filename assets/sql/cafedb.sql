-- =====================================================================
-- Taeyoon.log [DB] 시리즈 예제 DB: cafedb (가상의 카페 체인)
-- https://tae62jj021216.github.io
--
-- MySQL 8.0.31 이상(권장 8.4)에서 실행한다.
--   mysql -u root -p < cafedb.sql
--   또는 MySQL Workbench에서 파일을 열고 전체 실행(Ctrl+Shift+Enter)
--
-- 실행하면 cafedb를 지우고 처음부터 다시 만든다.
-- 모든 이름·지점·데이터는 가상이다.
-- =====================================================================

DROP DATABASE IF EXISTS cafedb;
CREATE DATABASE cafedb DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE cafedb;

-- 메뉴 카테고리 (parent_id로 계층 구성 → 재귀 CTE 예제)
CREATE TABLE category (
    category_id INT PRIMARY KEY,
    name        VARCHAR(20) NOT NULL,
    parent_id   INT NULL,
    FOREIGN KEY (parent_id) REFERENCES category(category_id)
);

-- 회원 (phone NULL 허용 → NULL 처리 예제, referrer_id → 셀프 조인 예제)
CREATE TABLE member (
    member_id   INT PRIMARY KEY,
    name        VARCHAR(10) NOT NULL,
    grade       VARCHAR(10) NOT NULL DEFAULT 'BASIC',
    city        VARCHAR(10),
    phone       VARCHAR(13) NULL,
    joined_on   DATE NOT NULL,
    referrer_id INT NULL,
    FOREIGN KEY (referrer_id) REFERENCES member(member_id)
);

-- 메뉴
CREATE TABLE menu (
    menu_id     INT PRIMARY KEY,
    name        VARCHAR(30) NOT NULL UNIQUE,
    category_id INT NOT NULL,
    price       INT NOT NULL CHECK (price > 0),
    is_seasonal BOOLEAN NOT NULL DEFAULT FALSE,
    released_on DATE NOT NULL,
    FOREIGN KEY (category_id) REFERENCES category(category_id)
);

-- 주문 (member_id NULL = 비회원 주문 → 외부 조인 예제)
CREATE TABLE orders (
    order_id   INT AUTO_INCREMENT PRIMARY KEY,
    member_id  INT NULL,
    store      VARCHAR(10) NOT NULL,
    ordered_at DATETIME NOT NULL,
    FOREIGN KEY (member_id) REFERENCES member(member_id)
);

-- 주문 상세 (복합 기본키)
CREATE TABLE order_item (
    order_id INT,
    menu_id  INT,
    qty      INT NOT NULL DEFAULT 1 CHECK (qty > 0),
    PRIMARY KEY (order_id, menu_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (menu_id) REFERENCES menu(menu_id)
);

-- 직원 (manager_id → 셀프 조인·재귀 CTE 조직도 예제)
CREATE TABLE staff (
    staff_id   INT PRIMARY KEY,
    name       VARCHAR(10) NOT NULL,
    role       VARCHAR(10) NOT NULL,
    store      VARCHAR(10) NULL,
    manager_id INT NULL,
    salary     INT NOT NULL,
    FOREIGN KEY (manager_id) REFERENCES staff(staff_id)
);

-- 연도별 이벤트 참가자 (구조가 같은 두 테이블 → UNION 예제)
CREATE TABLE event_2025 (
    member_id INT,
    name      VARCHAR(10),
    prize     VARCHAR(20)
);
CREATE TABLE event_2026 LIKE event_2025;

INSERT INTO category VALUES
 (1, '음료', NULL),
 (2, '커피', 1),
 (3, '논커피', 1),
 (4, '에스프레소', 2),
 (5, '콜드브루', 2),
 (6, '디저트', NULL),
 (7, '케이크', 6),
 (8, '구움과자', 6);

INSERT INTO member VALUES
 (101, '홍길동', 'VIP',   '서울', '010-1111-2222', '2024-03-02', NULL),
 (102, '성춘향', 'BASIC', '서울', NULL,            '2024-07-15', 101),
 (103, '이몽룡', 'GOLD',  '부산', '010-3333-4444', '2024-11-20', NULL),
 (104, '심청', 'BASIC', '대전', '010-5555-6666', '2025-01-08', 103),
 (105, '흥부', 'GOLD',  '서울', NULL,            '2025-04-30', 101),
 (106, '놀부', 'BASIC', '부산', '010-7777-8888', '2025-09-12', NULL),
 (107, '콩쥐', 'VIP',   '대전', '010-9999-0000', '2026-02-14', 104),
 (108, '팥쥐', 'BASIC', NULL,   NULL,            '2026-06-01', NULL);

INSERT INTO menu VALUES
 (1,  '아메리카노',       4, 4500, FALSE, '2024-01-01'),
 (2,  '카페라떼',         4, 5000, FALSE, '2024-01-01'),
 (3,  '바닐라라떼',       4, 5500, FALSE, '2024-01-01'),
 (4,  '콜드브루',         5, 5000, FALSE, '2024-06-01'),
 (5,  '콜드브루 라떼',    5, 5500, FALSE, '2024-06-01'),
 (6,  '말차라떼',         3, 5500, FALSE, '2024-03-15'),
 (7,  '딸기 에이드',      3, 6000, TRUE,  '2026-03-01'),
 (8,  '치즈케이크',       7, 6500, FALSE, '2024-01-01'),
 (9,  '초코케이크',       7, 6500, FALSE, '2024-09-01'),
 (10, '버터쿠키',         8, 3000, FALSE, '2025-02-01'),
 (11, '밤 마들렌',        8, 3500, TRUE,  '2025-10-01');

INSERT INTO orders (order_id, member_id, store, ordered_at) VALUES
 (1,  101,  '본점',   '2026-08-01 08:12:00'),
 (2,  102,  '본점',   '2026-08-01 12:40:00'),
 (3,  NULL, '강변점', '2026-08-02 09:05:00'),
 (4,  103,  '강변점', '2026-08-03 15:30:00'),
 (5,  101,  '공원점', '2026-08-05 10:00:00'),
 (6,  104,  '본점',   '2026-08-07 19:20:00'),
 (7,  NULL, '공원점', '2026-08-08 11:11:00'),
 (8,  105,  '본점',   '2026-08-10 08:45:00'),
 (9,  103,  '강변점', '2026-08-12 13:00:00'),
 (10, 107,  '공원점', '2026-08-15 16:25:00'),
 (11, 101,  '본점',   '2026-08-20 09:30:00'),
 (12, 106,  '강변점', '2026-08-22 14:10:00');

INSERT INTO order_item VALUES
 (1, 1, 2), (1, 8, 1),
 (2, 2, 1),
 (3, 1, 1), (3, 10, 2),
 (4, 4, 2), (4, 9, 1),
 (5, 3, 1),
 (6, 6, 1), (6, 11, 3),
 (7, 7, 2),
 (8, 1, 1), (8, 5, 1),
 (9, 2, 3),
 (10, 7, 1), (10, 8, 2),
 (11, 1, 1), (11, 10, 1),
 (12, 5, 2);

INSERT INTO staff VALUES
 (1, '월매', '대표',   NULL,     NULL, 6000),
 (2, '방자', '점장',   '본점',   1,    4200),
 (3, '향단', '점장',   '강변점', 1,    4200),
 (4, '변학도', '점장',   '공원점', 1,    4000),
 (5, '장화', '바리스타', '본점',   2,    3100),
 (6, '홍련', '바리스타', '본점',   2,    3000),
 (7, '전우치', '바리스타', '강변점', 3,    3100),
 (8, '옹고집', '파트타임', '본점',   5,    2100);

INSERT INTO event_2025 VALUES
 (101, '홍길동', '쿠폰'),
 (103, '이몽룡', '텀블러'),
 (104, '심청', '쿠폰');
INSERT INTO event_2026 VALUES
 (101, '홍길동', '텀블러'),
 (105, '흥부', '쿠폰'),
 (107, '콩쥐', '쿠폰');
