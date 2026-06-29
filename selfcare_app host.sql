-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jun 29, 2026 at 05:01 PM
-- Server version: 12.1.2-MariaDB-log
-- PHP Version: 8.3.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `selfcare_app`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `BersihkanDatabaseUser` (IN `target_user_id` INT)   BEGIN
    -- Matikan foreign key checking agar tidak terkena constrain error saat delete
    SET foreign_key_checks = 0;

    -- 1. Hapus seluruh riwayat mood logs
    DELETE FROM ema_mood_logs WHERE id_user = target_user_id;

    -- 2. Hapus seluruh riwayat asupan kalori makanan
    DELETE FROM calorie_logs WHERE id_user = target_user_id;

    -- 3. Hapus anak baris detail gerakan latihan
    DELETE FROM workout_session_exercises 
    WHERE id_session IN (SELECT id_session FROM workout_sessions WHERE id_user = target_user_id);

    -- 4. Hapus kepala sesi latihan harian
    DELETE FROM workout_sessions WHERE id_user = target_user_id;

    -- Nyalakan kembali foreign key checking
    SET foreign_key_checks = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `IsiDataDummySejarah` (IN `target_user_id` INT)   BEGIN
    -- 🔥 PERUBAHAN: Dimulai dari angka 1 (kemarin) agar hari ini bebas kuota untuk testing live
    DECLARE counter INT DEFAULT 1; 
    DECLARE current_dt DATE;
    DECLARE random_mood INT;
    DECLARE random_cal INT;
    DECLARE session_type VARCHAR(50);
    DECLARE sess_id INT;

    SET foreign_key_checks = 0;

    -- Loop mundur dari H-1 hingga H-49 (7 minggu penuh)
    WHILE counter <= 49 DO
        SET current_dt = DATE_SUB(CURDATE(), INTERVAL counter DAY);
        
        -- ─────────────────────────────────────────────────────────
        -- A. GENERATE DUMMY MOOD LOGS
        -- ─────────────────────────────────────────────────────────
        SET random_mood = FLOOR(1 + (RAND() * 5)); 
        
        INSERT IGNORE INTO ema_mood_logs (id_user, skor_mood, mood, notes, log_date)
        VALUES (
            target_user_id, 
            random_mood, 
            CASE random_mood 
                WHEN 5 THEN 'Happy' 
                WHEN 4 THEN 'Good' 
                WHEN 3 THEN 'Neutral' 
                WHEN 2 THEN 'Sad' 
                ELSE 'Angry' 
            END,
            CONCAT('Catatan emosional harian pada H-', counter),
            current_dt
        );

        -- ─────────────────────────────────────────────────────────
        -- B. GENERATE DUMMY CALORIE LOGS
        -- ─────────────────────────────────────────────────────────
        SET random_cal = FLOOR(1300 + (RAND() * 1100)); 
        
        INSERT IGNORE INTO calorie_logs (id_user, nama_makanan, jumlah_kalori, meal_type, log_date)
        VALUES 
        (target_user_id, 'Nasi Goreng Telur + Ayam', FLOOR(random_cal * 0.45), 'Breakfast', current_dt),
        (target_user_id, 'Daging Sapi Panggang Kedelai', FLOOR(random_cal * 0.55), 'Lunch', current_dt);

        -- ─────────────────────────────────────────────────────────
        -- C. GENERATE DUMMY WORKOUT SESSIONS
        -- ─────────────────────────────────────────────────────────
        IF (counter % 7) < 4 THEN
            SET session_type = CASE (counter % 4)
                WHEN 0 THEN 'Push Day'
                WHEN 1 THEN 'Pull Day'
                WHEN 2 THEN 'Legs Day'
                ELSE 'Core & Cardio Day'
            END;

            INSERT IGNORE INTO workout_sessions (id_user, session_name, status, log_date)
            VALUES (
                target_user_id, 
                session_type, 
                IF(RAND() > 0.20, 'completed', 'skipped'), 
                current_dt
            );
            
            IF ROW_COUNT() > 0 THEN
                SET sess_id = LAST_INSERT_ID();

                INSERT INTO workout_session_exercises (id_session, title, body_part, equipment, level, is_done)
                VALUES 
                (sess_id, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
                (sess_id, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1);
            END IF;
        END IF;

        SET counter = counter + 1;
    END WHILE;

    SET foreign_key_checks = 1;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `cache`
--

CREATE TABLE `cache` (
  `key` varchar(255) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` bigint(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cache_locks`
--

CREATE TABLE `cache_locks` (
  `key` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `expiration` bigint(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `calorie_logs`
--

CREATE TABLE `calorie_logs` (
  `id_calorie_log` int(11) NOT NULL,
  `id_user` int(11) NOT NULL,
  `nama_makanan` varchar(255) NOT NULL,
  `jumlah_kalori` int(11) NOT NULL,
  `meal_type` varchar(50) NOT NULL,
  `logged_time` varchar(20) NOT NULL,
  `log_date` date NOT NULL,
  `logged_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `calorie_logs`
--

INSERT INTO `calorie_logs` (`id_calorie_log`, `id_user`, `nama_makanan`, `jumlah_kalori`, `meal_type`, `logged_time`, `log_date`, `logged_at`) VALUES
(203, 15, 'Oats with milk', 455, 'Breakfast', '12:58 PM', '2026-06-16', '2026-06-16 05:58:41'),
(204, 13, 'tes', 233, 'Breakfast', '1:04 PM', '2026-06-16', '2026-06-16 06:04:54'),
(205, 8, 'tes', 544, 'Breakfast', '7:08 PM', '2026-06-17', '2026-06-17 12:08:31'),
(207, 9, 'Nasi Goreng Telur + Ayam', 922, 'Breakfast', '', '2026-06-17', '2026-06-18 03:41:06'),
(208, 9, 'Daging Sapi Panggang Kedelai', 1126, 'Lunch', '', '2026-06-17', '2026-06-18 03:41:06'),
(209, 9, 'Nasi Goreng Telur + Ayam', 887, 'Breakfast', '', '2026-06-16', '2026-06-18 03:41:06'),
(210, 9, 'Daging Sapi Panggang Kedelai', 1085, 'Lunch', '', '2026-06-16', '2026-06-18 03:41:06'),
(211, 9, 'Nasi Goreng Telur + Ayam', 883, 'Breakfast', '', '2026-06-15', '2026-06-18 03:41:06'),
(212, 9, 'Daging Sapi Panggang Kedelai', 1080, 'Lunch', '', '2026-06-15', '2026-06-18 03:41:06'),
(213, 9, 'Nasi Goreng Telur + Ayam', 989, 'Breakfast', '', '2026-06-14', '2026-06-18 03:41:06'),
(214, 9, 'Daging Sapi Panggang Kedelai', 1209, 'Lunch', '', '2026-06-14', '2026-06-18 03:41:06'),
(215, 9, 'Nasi Goreng Telur + Ayam', 850, 'Breakfast', '', '2026-06-13', '2026-06-18 03:41:06'),
(216, 9, 'Daging Sapi Panggang Kedelai', 1040, 'Lunch', '', '2026-06-13', '2026-06-18 03:41:06'),
(217, 9, 'Nasi Goreng Telur + Ayam', 1011, 'Breakfast', '', '2026-06-12', '2026-06-18 03:41:06'),
(218, 9, 'Daging Sapi Panggang Kedelai', 1235, 'Lunch', '', '2026-06-12', '2026-06-18 03:41:06'),
(219, 9, 'Nasi Goreng Telur + Ayam', 840, 'Breakfast', '', '2026-06-11', '2026-06-18 03:41:06'),
(220, 9, 'Daging Sapi Panggang Kedelai', 1027, 'Lunch', '', '2026-06-11', '2026-06-18 03:41:06'),
(221, 9, 'Nasi Goreng Telur + Ayam', 976, 'Breakfast', '', '2026-06-10', '2026-06-18 03:41:06'),
(222, 9, 'Daging Sapi Panggang Kedelai', 1193, 'Lunch', '', '2026-06-10', '2026-06-18 03:41:06'),
(223, 9, 'Nasi Goreng Telur + Ayam', 763, 'Breakfast', '', '2026-06-09', '2026-06-18 03:41:06'),
(224, 9, 'Daging Sapi Panggang Kedelai', 932, 'Lunch', '', '2026-06-09', '2026-06-18 03:41:06'),
(225, 9, 'Nasi Goreng Telur + Ayam', 825, 'Breakfast', '', '2026-06-08', '2026-06-18 03:41:06'),
(226, 9, 'Daging Sapi Panggang Kedelai', 1009, 'Lunch', '', '2026-06-08', '2026-06-18 03:41:06'),
(227, 9, 'Nasi Goreng Telur + Ayam', 693, 'Breakfast', '', '2026-06-07', '2026-06-18 03:41:06'),
(228, 9, 'Daging Sapi Panggang Kedelai', 847, 'Lunch', '', '2026-06-07', '2026-06-18 03:41:06'),
(229, 9, 'Nasi Goreng Telur + Ayam', 1070, 'Breakfast', '', '2026-06-06', '2026-06-18 03:41:06'),
(230, 9, 'Daging Sapi Panggang Kedelai', 1308, 'Lunch', '', '2026-06-06', '2026-06-18 03:41:06'),
(231, 9, 'Nasi Goreng Telur + Ayam', 921, 'Breakfast', '', '2026-06-05', '2026-06-18 03:41:06'),
(232, 9, 'Daging Sapi Panggang Kedelai', 1126, 'Lunch', '', '2026-06-05', '2026-06-18 03:41:06'),
(233, 9, 'Nasi Goreng Telur + Ayam', 634, 'Breakfast', '', '2026-06-04', '2026-06-18 03:41:06'),
(234, 9, 'Daging Sapi Panggang Kedelai', 776, 'Lunch', '', '2026-06-04', '2026-06-18 03:41:06'),
(235, 9, 'Nasi Goreng Telur + Ayam', 741, 'Breakfast', '', '2026-06-03', '2026-06-18 03:41:06'),
(236, 9, 'Daging Sapi Panggang Kedelai', 905, 'Lunch', '', '2026-06-03', '2026-06-18 03:41:06'),
(237, 9, 'Nasi Goreng Telur + Ayam', 861, 'Breakfast', '', '2026-06-02', '2026-06-18 03:41:06'),
(238, 9, 'Daging Sapi Panggang Kedelai', 1053, 'Lunch', '', '2026-06-02', '2026-06-18 03:41:06'),
(239, 9, 'Nasi Goreng Telur + Ayam', 701, 'Breakfast', '', '2026-06-01', '2026-06-18 03:41:06'),
(240, 9, 'Daging Sapi Panggang Kedelai', 857, 'Lunch', '', '2026-06-01', '2026-06-18 03:41:06'),
(241, 9, 'Nasi Goreng Telur + Ayam', 960, 'Breakfast', '', '2026-05-31', '2026-06-18 03:41:06'),
(242, 9, 'Daging Sapi Panggang Kedelai', 1174, 'Lunch', '', '2026-05-31', '2026-06-18 03:41:06'),
(243, 9, 'Nasi Goreng Telur + Ayam', 785, 'Breakfast', '', '2026-05-30', '2026-06-18 03:41:06'),
(244, 9, 'Daging Sapi Panggang Kedelai', 960, 'Lunch', '', '2026-05-30', '2026-06-18 03:41:06'),
(245, 9, 'Nasi Goreng Telur + Ayam', 1019, 'Breakfast', '', '2026-05-29', '2026-06-18 03:41:06'),
(246, 9, 'Daging Sapi Panggang Kedelai', 1245, 'Lunch', '', '2026-05-29', '2026-06-18 03:41:06'),
(247, 9, 'Nasi Goreng Telur + Ayam', 595, 'Breakfast', '', '2026-05-28', '2026-06-18 03:41:06'),
(248, 9, 'Daging Sapi Panggang Kedelai', 727, 'Lunch', '', '2026-05-28', '2026-06-18 03:41:06'),
(249, 9, 'Nasi Goreng Telur + Ayam', 787, 'Breakfast', '', '2026-05-27', '2026-06-18 03:41:06'),
(250, 9, 'Daging Sapi Panggang Kedelai', 963, 'Lunch', '', '2026-05-27', '2026-06-18 03:41:06'),
(251, 9, 'Nasi Goreng Telur + Ayam', 708, 'Breakfast', '', '2026-05-26', '2026-06-18 03:41:06'),
(252, 9, 'Daging Sapi Panggang Kedelai', 865, 'Lunch', '', '2026-05-26', '2026-06-18 03:41:06'),
(253, 9, 'Nasi Goreng Telur + Ayam', 1035, 'Breakfast', '', '2026-05-25', '2026-06-18 03:41:06'),
(254, 9, 'Daging Sapi Panggang Kedelai', 1265, 'Lunch', '', '2026-05-25', '2026-06-18 03:41:06'),
(255, 9, 'Nasi Goreng Telur + Ayam', 630, 'Breakfast', '', '2026-05-24', '2026-06-18 03:41:06'),
(256, 9, 'Daging Sapi Panggang Kedelai', 770, 'Lunch', '', '2026-05-24', '2026-06-18 03:41:06'),
(257, 9, 'Nasi Goreng Telur + Ayam', 1070, 'Breakfast', '', '2026-05-23', '2026-06-18 03:41:06'),
(258, 9, 'Daging Sapi Panggang Kedelai', 1307, 'Lunch', '', '2026-05-23', '2026-06-18 03:41:06'),
(259, 9, 'Nasi Goreng Telur + Ayam', 981, 'Breakfast', '', '2026-05-22', '2026-06-18 03:41:06'),
(260, 9, 'Daging Sapi Panggang Kedelai', 1200, 'Lunch', '', '2026-05-22', '2026-06-18 03:41:06'),
(261, 9, 'Nasi Goreng Telur + Ayam', 796, 'Breakfast', '', '2026-05-21', '2026-06-18 03:41:06'),
(262, 9, 'Daging Sapi Panggang Kedelai', 972, 'Lunch', '', '2026-05-21', '2026-06-18 03:41:06'),
(263, 9, 'Nasi Goreng Telur + Ayam', 1038, 'Breakfast', '', '2026-05-20', '2026-06-18 03:41:06'),
(264, 9, 'Daging Sapi Panggang Kedelai', 1269, 'Lunch', '', '2026-05-20', '2026-06-18 03:41:06'),
(265, 9, 'Nasi Goreng Telur + Ayam', 1001, 'Breakfast', '', '2026-05-19', '2026-06-18 03:41:06'),
(266, 9, 'Daging Sapi Panggang Kedelai', 1223, 'Lunch', '', '2026-05-19', '2026-06-18 03:41:06'),
(267, 9, 'Nasi Goreng Telur + Ayam', 870, 'Breakfast', '', '2026-05-18', '2026-06-18 03:41:06'),
(268, 9, 'Daging Sapi Panggang Kedelai', 1063, 'Lunch', '', '2026-05-18', '2026-06-18 03:41:06'),
(269, 9, 'Nasi Goreng Telur + Ayam', 777, 'Breakfast', '', '2026-05-17', '2026-06-18 03:41:06'),
(270, 9, 'Daging Sapi Panggang Kedelai', 949, 'Lunch', '', '2026-05-17', '2026-06-18 03:41:06'),
(271, 9, 'Nasi Goreng Telur + Ayam', 950, 'Breakfast', '', '2026-05-16', '2026-06-18 03:41:06'),
(272, 9, 'Daging Sapi Panggang Kedelai', 1162, 'Lunch', '', '2026-05-16', '2026-06-18 03:41:06'),
(273, 9, 'Nasi Goreng Telur + Ayam', 859, 'Breakfast', '', '2026-05-15', '2026-06-18 03:41:06'),
(274, 9, 'Daging Sapi Panggang Kedelai', 1050, 'Lunch', '', '2026-05-15', '2026-06-18 03:41:06'),
(275, 9, 'Nasi Goreng Telur + Ayam', 1022, 'Breakfast', '', '2026-05-14', '2026-06-18 03:41:06'),
(276, 9, 'Daging Sapi Panggang Kedelai', 1249, 'Lunch', '', '2026-05-14', '2026-06-18 03:41:06'),
(277, 9, 'Nasi Goreng Telur + Ayam', 938, 'Breakfast', '', '2026-05-13', '2026-06-18 03:41:06'),
(278, 9, 'Daging Sapi Panggang Kedelai', 1147, 'Lunch', '', '2026-05-13', '2026-06-18 03:41:06'),
(279, 9, 'Nasi Goreng Telur + Ayam', 756, 'Breakfast', '', '2026-05-12', '2026-06-18 03:41:06'),
(280, 9, 'Daging Sapi Panggang Kedelai', 925, 'Lunch', '', '2026-05-12', '2026-06-18 03:41:06'),
(281, 9, 'Nasi Goreng Telur + Ayam', 854, 'Breakfast', '', '2026-05-11', '2026-06-18 03:41:06'),
(282, 9, 'Daging Sapi Panggang Kedelai', 1044, 'Lunch', '', '2026-05-11', '2026-06-18 03:41:06'),
(283, 9, 'Nasi Goreng Telur + Ayam', 670, 'Breakfast', '', '2026-05-10', '2026-06-18 03:41:06'),
(284, 9, 'Daging Sapi Panggang Kedelai', 818, 'Lunch', '', '2026-05-10', '2026-06-18 03:41:06'),
(285, 9, 'Nasi Goreng Telur + Ayam', 764, 'Breakfast', '', '2026-05-09', '2026-06-18 03:41:06'),
(286, 9, 'Daging Sapi Panggang Kedelai', 934, 'Lunch', '', '2026-05-09', '2026-06-18 03:41:06'),
(287, 9, 'Nasi Goreng Telur + Ayam', 758, 'Breakfast', '', '2026-05-08', '2026-06-18 03:41:06'),
(288, 9, 'Daging Sapi Panggang Kedelai', 927, 'Lunch', '', '2026-05-08', '2026-06-18 03:41:06'),
(289, 9, 'Nasi Goreng Telur + Ayam', 789, 'Breakfast', '', '2026-05-07', '2026-06-18 03:41:06'),
(290, 9, 'Daging Sapi Panggang Kedelai', 965, 'Lunch', '', '2026-05-07', '2026-06-18 03:41:06'),
(291, 9, 'Nasi Goreng Telur + Ayam', 950, 'Breakfast', '', '2026-05-06', '2026-06-18 03:41:06'),
(292, 9, 'Daging Sapi Panggang Kedelai', 1162, 'Lunch', '', '2026-05-06', '2026-06-18 03:41:06'),
(293, 9, 'Nasi Goreng Telur + Ayam', 585, 'Breakfast', '', '2026-05-05', '2026-06-18 03:41:06'),
(294, 9, 'Daging Sapi Panggang Kedelai', 715, 'Lunch', '', '2026-05-05', '2026-06-18 03:41:06'),
(295, 9, 'Nasi Goreng Telur + Ayam', 639, 'Breakfast', '', '2026-05-04', '2026-06-18 03:41:06'),
(296, 9, 'Daging Sapi Panggang Kedelai', 781, 'Lunch', '', '2026-05-04', '2026-06-18 03:41:06'),
(297, 9, 'Nasi Goreng Telur + Ayam', 933, 'Breakfast', '', '2026-05-03', '2026-06-18 03:41:06'),
(298, 9, 'Daging Sapi Panggang Kedelai', 1140, 'Lunch', '', '2026-05-03', '2026-06-18 03:41:06'),
(299, 9, 'Nasi Goreng Telur + Ayam', 744, 'Breakfast', '', '2026-05-02', '2026-06-18 03:41:06'),
(300, 9, 'Daging Sapi Panggang Kedelai', 909, 'Lunch', '', '2026-05-02', '2026-06-18 03:41:06'),
(301, 9, 'Nasi Goreng Telur + Ayam', 973, 'Breakfast', '', '2026-05-01', '2026-06-18 03:41:06'),
(302, 9, 'Daging Sapi Panggang Kedelai', 1189, 'Lunch', '', '2026-05-01', '2026-06-18 03:41:06'),
(303, 9, 'Nasi Goreng Telur + Ayam', 595, 'Breakfast', '', '2026-04-30', '2026-06-18 03:41:06'),
(304, 9, 'Daging Sapi Panggang Kedelai', 727, 'Lunch', '', '2026-04-30', '2026-06-18 03:41:06'),
(305, 10, 'Nasi Goreng Telur + Ayam', 703, 'Breakfast', '', '2026-06-17', '2026-06-18 03:41:06'),
(306, 10, 'Daging Sapi Panggang Kedelai', 860, 'Lunch', '', '2026-06-17', '2026-06-18 03:41:06'),
(307, 10, 'Nasi Goreng Telur + Ayam', 902, 'Breakfast', '', '2026-06-16', '2026-06-18 03:41:06'),
(308, 10, 'Daging Sapi Panggang Kedelai', 1103, 'Lunch', '', '2026-06-16', '2026-06-18 03:41:06'),
(309, 10, 'Nasi Goreng Telur + Ayam', 1025, 'Breakfast', '', '2026-06-15', '2026-06-18 03:41:06'),
(310, 10, 'Daging Sapi Panggang Kedelai', 1253, 'Lunch', '', '2026-06-15', '2026-06-18 03:41:06'),
(311, 10, 'Nasi Goreng Telur + Ayam', 1035, 'Breakfast', '', '2026-06-14', '2026-06-18 03:41:06'),
(312, 10, 'Daging Sapi Panggang Kedelai', 1265, 'Lunch', '', '2026-06-14', '2026-06-18 03:41:06'),
(313, 10, 'Nasi Goreng Telur + Ayam', 968, 'Breakfast', '', '2026-06-13', '2026-06-18 03:41:06'),
(314, 10, 'Daging Sapi Panggang Kedelai', 1184, 'Lunch', '', '2026-06-13', '2026-06-18 03:41:06'),
(315, 10, 'Nasi Goreng Telur + Ayam', 858, 'Breakfast', '', '2026-06-12', '2026-06-18 03:41:06'),
(316, 10, 'Daging Sapi Panggang Kedelai', 1048, 'Lunch', '', '2026-06-12', '2026-06-18 03:41:06'),
(317, 10, 'Nasi Goreng Telur + Ayam', 835, 'Breakfast', '', '2026-06-11', '2026-06-18 03:41:06'),
(318, 10, 'Daging Sapi Panggang Kedelai', 1020, 'Lunch', '', '2026-06-11', '2026-06-18 03:41:06'),
(319, 10, 'Nasi Goreng Telur + Ayam', 836, 'Breakfast', '', '2026-06-10', '2026-06-18 03:41:06'),
(320, 10, 'Daging Sapi Panggang Kedelai', 1021, 'Lunch', '', '2026-06-10', '2026-06-18 03:41:06'),
(321, 10, 'Nasi Goreng Telur + Ayam', 1070, 'Breakfast', '', '2026-06-09', '2026-06-18 03:41:06'),
(322, 10, 'Daging Sapi Panggang Kedelai', 1307, 'Lunch', '', '2026-06-09', '2026-06-18 03:41:06'),
(323, 10, 'Nasi Goreng Telur + Ayam', 955, 'Breakfast', '', '2026-06-08', '2026-06-18 03:41:06'),
(324, 10, 'Daging Sapi Panggang Kedelai', 1168, 'Lunch', '', '2026-06-08', '2026-06-18 03:41:06'),
(325, 10, 'Nasi Goreng Telur + Ayam', 824, 'Breakfast', '', '2026-06-07', '2026-06-18 03:41:06'),
(326, 10, 'Daging Sapi Panggang Kedelai', 1007, 'Lunch', '', '2026-06-07', '2026-06-18 03:41:06'),
(327, 10, 'Nasi Goreng Telur + Ayam', 785, 'Breakfast', '', '2026-06-06', '2026-06-18 03:41:06'),
(328, 10, 'Daging Sapi Panggang Kedelai', 960, 'Lunch', '', '2026-06-06', '2026-06-18 03:41:06'),
(329, 10, 'Nasi Goreng Telur + Ayam', 763, 'Breakfast', '', '2026-06-05', '2026-06-18 03:41:06'),
(330, 10, 'Daging Sapi Panggang Kedelai', 933, 'Lunch', '', '2026-06-05', '2026-06-18 03:41:06'),
(331, 10, 'Nasi Goreng Telur + Ayam', 684, 'Breakfast', '', '2026-06-04', '2026-06-18 03:41:06'),
(332, 10, 'Daging Sapi Panggang Kedelai', 836, 'Lunch', '', '2026-06-04', '2026-06-18 03:41:06'),
(333, 10, 'Nasi Goreng Telur + Ayam', 679, 'Breakfast', '', '2026-06-03', '2026-06-18 03:41:06'),
(334, 10, 'Daging Sapi Panggang Kedelai', 830, 'Lunch', '', '2026-06-03', '2026-06-18 03:41:06'),
(335, 10, 'Nasi Goreng Telur + Ayam', 1026, 'Breakfast', '', '2026-06-02', '2026-06-18 03:41:06'),
(336, 10, 'Daging Sapi Panggang Kedelai', 1254, 'Lunch', '', '2026-06-02', '2026-06-18 03:41:06'),
(337, 10, 'Nasi Goreng Telur + Ayam', 670, 'Breakfast', '', '2026-06-01', '2026-06-18 03:41:06'),
(338, 10, 'Daging Sapi Panggang Kedelai', 818, 'Lunch', '', '2026-06-01', '2026-06-18 03:41:06'),
(339, 10, 'Nasi Goreng Telur + Ayam', 945, 'Breakfast', '', '2026-05-31', '2026-06-18 03:41:06'),
(340, 10, 'Daging Sapi Panggang Kedelai', 1155, 'Lunch', '', '2026-05-31', '2026-06-18 03:41:06'),
(341, 10, 'Nasi Goreng Telur + Ayam', 1047, 'Breakfast', '', '2026-05-30', '2026-06-18 03:41:06'),
(342, 10, 'Daging Sapi Panggang Kedelai', 1279, 'Lunch', '', '2026-05-30', '2026-06-18 03:41:06'),
(343, 10, 'Nasi Goreng Telur + Ayam', 679, 'Breakfast', '', '2026-05-29', '2026-06-18 03:41:06'),
(344, 10, 'Daging Sapi Panggang Kedelai', 830, 'Lunch', '', '2026-05-29', '2026-06-18 03:41:06'),
(345, 10, 'Nasi Goreng Telur + Ayam', 701, 'Breakfast', '', '2026-05-28', '2026-06-18 03:41:06'),
(346, 10, 'Daging Sapi Panggang Kedelai', 857, 'Lunch', '', '2026-05-28', '2026-06-18 03:41:06'),
(347, 10, 'Nasi Goreng Telur + Ayam', 935, 'Breakfast', '', '2026-05-27', '2026-06-18 03:41:06'),
(348, 10, 'Daging Sapi Panggang Kedelai', 1143, 'Lunch', '', '2026-05-27', '2026-06-18 03:41:06'),
(349, 10, 'Nasi Goreng Telur + Ayam', 758, 'Breakfast', '', '2026-05-26', '2026-06-18 03:41:06'),
(350, 10, 'Daging Sapi Panggang Kedelai', 926, 'Lunch', '', '2026-05-26', '2026-06-18 03:41:06'),
(351, 10, 'Nasi Goreng Telur + Ayam', 1023, 'Breakfast', '', '2026-05-25', '2026-06-18 03:41:06'),
(352, 10, 'Daging Sapi Panggang Kedelai', 1251, 'Lunch', '', '2026-05-25', '2026-06-18 03:41:06'),
(353, 10, 'Nasi Goreng Telur + Ayam', 840, 'Breakfast', '', '2026-05-24', '2026-06-18 03:41:06'),
(354, 10, 'Daging Sapi Panggang Kedelai', 1026, 'Lunch', '', '2026-05-24', '2026-06-18 03:41:06'),
(355, 10, 'Nasi Goreng Telur + Ayam', 837, 'Breakfast', '', '2026-05-23', '2026-06-18 03:41:06'),
(356, 10, 'Daging Sapi Panggang Kedelai', 1023, 'Lunch', '', '2026-05-23', '2026-06-18 03:41:06'),
(357, 10, 'Nasi Goreng Telur + Ayam', 607, 'Breakfast', '', '2026-05-22', '2026-06-18 03:41:06'),
(358, 10, 'Daging Sapi Panggang Kedelai', 742, 'Lunch', '', '2026-05-22', '2026-06-18 03:41:06'),
(359, 10, 'Nasi Goreng Telur + Ayam', 727, 'Breakfast', '', '2026-05-21', '2026-06-18 03:41:06'),
(360, 10, 'Daging Sapi Panggang Kedelai', 888, 'Lunch', '', '2026-05-21', '2026-06-18 03:41:06'),
(361, 10, 'Nasi Goreng Telur + Ayam', 839, 'Breakfast', '', '2026-05-20', '2026-06-18 03:41:06'),
(362, 10, 'Daging Sapi Panggang Kedelai', 1026, 'Lunch', '', '2026-05-20', '2026-06-18 03:41:06'),
(363, 10, 'Nasi Goreng Telur + Ayam', 791, 'Breakfast', '', '2026-05-19', '2026-06-18 03:41:06'),
(364, 10, 'Daging Sapi Panggang Kedelai', 967, 'Lunch', '', '2026-05-19', '2026-06-18 03:41:06'),
(365, 10, 'Nasi Goreng Telur + Ayam', 823, 'Breakfast', '', '2026-05-18', '2026-06-18 03:41:06'),
(366, 10, 'Daging Sapi Panggang Kedelai', 1007, 'Lunch', '', '2026-05-18', '2026-06-18 03:41:06'),
(367, 10, 'Nasi Goreng Telur + Ayam', 787, 'Breakfast', '', '2026-05-17', '2026-06-18 03:41:06'),
(368, 10, 'Daging Sapi Panggang Kedelai', 963, 'Lunch', '', '2026-05-17', '2026-06-18 03:41:06'),
(369, 10, 'Nasi Goreng Telur + Ayam', 664, 'Breakfast', '', '2026-05-16', '2026-06-18 03:41:06'),
(370, 10, 'Daging Sapi Panggang Kedelai', 812, 'Lunch', '', '2026-05-16', '2026-06-18 03:41:06'),
(371, 10, 'Nasi Goreng Telur + Ayam', 768, 'Breakfast', '', '2026-05-15', '2026-06-18 03:41:06'),
(372, 10, 'Daging Sapi Panggang Kedelai', 938, 'Lunch', '', '2026-05-15', '2026-06-18 03:41:06'),
(373, 10, 'Nasi Goreng Telur + Ayam', 878, 'Breakfast', '', '2026-05-14', '2026-06-18 03:41:06'),
(374, 10, 'Daging Sapi Panggang Kedelai', 1073, 'Lunch', '', '2026-05-14', '2026-06-18 03:41:06'),
(375, 10, 'Nasi Goreng Telur + Ayam', 895, 'Breakfast', '', '2026-05-13', '2026-06-18 03:41:06'),
(376, 10, 'Daging Sapi Panggang Kedelai', 1094, 'Lunch', '', '2026-05-13', '2026-06-18 03:41:06'),
(377, 10, 'Nasi Goreng Telur + Ayam', 679, 'Breakfast', '', '2026-05-12', '2026-06-18 03:41:06'),
(378, 10, 'Daging Sapi Panggang Kedelai', 829, 'Lunch', '', '2026-05-12', '2026-06-18 03:41:06'),
(379, 10, 'Nasi Goreng Telur + Ayam', 714, 'Breakfast', '', '2026-05-11', '2026-06-18 03:41:06'),
(380, 10, 'Daging Sapi Panggang Kedelai', 873, 'Lunch', '', '2026-05-11', '2026-06-18 03:41:06'),
(381, 10, 'Nasi Goreng Telur + Ayam', 999, 'Breakfast', '', '2026-05-10', '2026-06-18 03:41:06'),
(382, 10, 'Daging Sapi Panggang Kedelai', 1221, 'Lunch', '', '2026-05-10', '2026-06-18 03:41:06'),
(383, 10, 'Nasi Goreng Telur + Ayam', 895, 'Breakfast', '', '2026-05-09', '2026-06-18 03:41:06'),
(384, 10, 'Daging Sapi Panggang Kedelai', 1093, 'Lunch', '', '2026-05-09', '2026-06-18 03:41:06'),
(385, 10, 'Nasi Goreng Telur + Ayam', 774, 'Breakfast', '', '2026-05-08', '2026-06-18 03:41:06'),
(386, 10, 'Daging Sapi Panggang Kedelai', 946, 'Lunch', '', '2026-05-08', '2026-06-18 03:41:06'),
(387, 10, 'Nasi Goreng Telur + Ayam', 889, 'Breakfast', '', '2026-05-07', '2026-06-18 03:41:06'),
(388, 10, 'Daging Sapi Panggang Kedelai', 1086, 'Lunch', '', '2026-05-07', '2026-06-18 03:41:06'),
(389, 10, 'Nasi Goreng Telur + Ayam', 663, 'Breakfast', '', '2026-05-06', '2026-06-18 03:41:06'),
(390, 10, 'Daging Sapi Panggang Kedelai', 810, 'Lunch', '', '2026-05-06', '2026-06-18 03:41:06'),
(391, 10, 'Nasi Goreng Telur + Ayam', 648, 'Breakfast', '', '2026-05-05', '2026-06-18 03:41:06'),
(392, 10, 'Daging Sapi Panggang Kedelai', 793, 'Lunch', '', '2026-05-05', '2026-06-18 03:41:06'),
(393, 10, 'Nasi Goreng Telur + Ayam', 623, 'Breakfast', '', '2026-05-04', '2026-06-18 03:41:06'),
(394, 10, 'Daging Sapi Panggang Kedelai', 761, 'Lunch', '', '2026-05-04', '2026-06-18 03:41:06'),
(395, 10, 'Nasi Goreng Telur + Ayam', 924, 'Breakfast', '', '2026-05-03', '2026-06-18 03:41:06'),
(396, 10, 'Daging Sapi Panggang Kedelai', 1130, 'Lunch', '', '2026-05-03', '2026-06-18 03:41:06'),
(397, 10, 'Nasi Goreng Telur + Ayam', 748, 'Breakfast', '', '2026-05-02', '2026-06-18 03:41:06'),
(398, 10, 'Daging Sapi Panggang Kedelai', 915, 'Lunch', '', '2026-05-02', '2026-06-18 03:41:06'),
(399, 10, 'Nasi Goreng Telur + Ayam', 643, 'Breakfast', '', '2026-05-01', '2026-06-18 03:41:06'),
(400, 10, 'Daging Sapi Panggang Kedelai', 787, 'Lunch', '', '2026-05-01', '2026-06-18 03:41:06'),
(401, 10, 'Nasi Goreng Telur + Ayam', 725, 'Breakfast', '', '2026-04-30', '2026-06-18 03:41:06'),
(402, 10, 'Daging Sapi Panggang Kedelai', 887, 'Lunch', '', '2026-04-30', '2026-06-18 03:41:06'),
(403, 11, 'Nasi Goreng Telur + Ayam', 884, 'Breakfast', '', '2026-06-17', '2026-06-18 03:41:06'),
(404, 11, 'Daging Sapi Panggang Kedelai', 1080, 'Lunch', '', '2026-06-17', '2026-06-18 03:41:06'),
(405, 11, 'Nasi Goreng Telur + Ayam', 929, 'Breakfast', '', '2026-06-16', '2026-06-18 03:41:06'),
(406, 11, 'Daging Sapi Panggang Kedelai', 1135, 'Lunch', '', '2026-06-16', '2026-06-18 03:41:06'),
(407, 11, 'Nasi Goreng Telur + Ayam', 761, 'Breakfast', '', '2026-06-15', '2026-06-18 03:41:06'),
(408, 11, 'Daging Sapi Panggang Kedelai', 930, 'Lunch', '', '2026-06-15', '2026-06-18 03:41:06'),
(409, 11, 'Nasi Goreng Telur + Ayam', 960, 'Breakfast', '', '2026-06-14', '2026-06-18 03:41:06'),
(410, 11, 'Daging Sapi Panggang Kedelai', 1173, 'Lunch', '', '2026-06-14', '2026-06-18 03:41:06'),
(411, 11, 'Nasi Goreng Telur + Ayam', 589, 'Breakfast', '', '2026-06-13', '2026-06-18 03:41:06'),
(412, 11, 'Daging Sapi Panggang Kedelai', 720, 'Lunch', '', '2026-06-13', '2026-06-18 03:41:06'),
(413, 11, 'Nasi Goreng Telur + Ayam', 760, 'Breakfast', '', '2026-06-12', '2026-06-18 03:41:06'),
(414, 11, 'Daging Sapi Panggang Kedelai', 930, 'Lunch', '', '2026-06-12', '2026-06-18 03:41:06'),
(415, 11, 'Nasi Goreng Telur + Ayam', 921, 'Breakfast', '', '2026-06-11', '2026-06-18 03:41:06'),
(416, 11, 'Daging Sapi Panggang Kedelai', 1126, 'Lunch', '', '2026-06-11', '2026-06-18 03:41:06'),
(417, 11, 'Nasi Goreng Telur + Ayam', 755, 'Breakfast', '', '2026-06-10', '2026-06-18 03:41:06'),
(418, 11, 'Daging Sapi Panggang Kedelai', 923, 'Lunch', '', '2026-06-10', '2026-06-18 03:41:06'),
(419, 11, 'Nasi Goreng Telur + Ayam', 692, 'Breakfast', '', '2026-06-09', '2026-06-18 03:41:06'),
(420, 11, 'Daging Sapi Panggang Kedelai', 846, 'Lunch', '', '2026-06-09', '2026-06-18 03:41:06'),
(421, 11, 'Nasi Goreng Telur + Ayam', 621, 'Breakfast', '', '2026-06-08', '2026-06-18 03:41:06'),
(422, 11, 'Daging Sapi Panggang Kedelai', 759, 'Lunch', '', '2026-06-08', '2026-06-18 03:41:06'),
(423, 11, 'Nasi Goreng Telur + Ayam', 1076, 'Breakfast', '', '2026-06-07', '2026-06-18 03:41:06'),
(424, 11, 'Daging Sapi Panggang Kedelai', 1315, 'Lunch', '', '2026-06-07', '2026-06-18 03:41:06'),
(425, 11, 'Nasi Goreng Telur + Ayam', 682, 'Breakfast', '', '2026-06-06', '2026-06-18 03:41:06'),
(426, 11, 'Daging Sapi Panggang Kedelai', 833, 'Lunch', '', '2026-06-06', '2026-06-18 03:41:06'),
(427, 11, 'Nasi Goreng Telur + Ayam', 981, 'Breakfast', '', '2026-06-05', '2026-06-18 03:41:06'),
(428, 11, 'Daging Sapi Panggang Kedelai', 1199, 'Lunch', '', '2026-06-05', '2026-06-18 03:41:06'),
(429, 11, 'Nasi Goreng Telur + Ayam', 809, 'Breakfast', '', '2026-06-04', '2026-06-18 03:41:06'),
(430, 11, 'Daging Sapi Panggang Kedelai', 988, 'Lunch', '', '2026-06-04', '2026-06-18 03:41:06'),
(431, 11, 'Nasi Goreng Telur + Ayam', 748, 'Breakfast', '', '2026-06-03', '2026-06-18 03:41:06'),
(432, 11, 'Daging Sapi Panggang Kedelai', 914, 'Lunch', '', '2026-06-03', '2026-06-18 03:41:06'),
(433, 11, 'Nasi Goreng Telur + Ayam', 674, 'Breakfast', '', '2026-06-02', '2026-06-18 03:41:06'),
(434, 11, 'Daging Sapi Panggang Kedelai', 823, 'Lunch', '', '2026-06-02', '2026-06-18 03:41:06'),
(435, 11, 'Nasi Goreng Telur + Ayam', 835, 'Breakfast', '', '2026-06-01', '2026-06-18 03:41:06'),
(436, 11, 'Daging Sapi Panggang Kedelai', 1020, 'Lunch', '', '2026-06-01', '2026-06-18 03:41:06'),
(437, 11, 'Nasi Goreng Telur + Ayam', 894, 'Breakfast', '', '2026-05-31', '2026-06-18 03:41:06'),
(438, 11, 'Daging Sapi Panggang Kedelai', 1093, 'Lunch', '', '2026-05-31', '2026-06-18 03:41:06'),
(439, 11, 'Nasi Goreng Telur + Ayam', 917, 'Breakfast', '', '2026-05-30', '2026-06-18 03:41:06'),
(440, 11, 'Daging Sapi Panggang Kedelai', 1120, 'Lunch', '', '2026-05-30', '2026-06-18 03:41:06'),
(441, 11, 'Nasi Goreng Telur + Ayam', 642, 'Breakfast', '', '2026-05-29', '2026-06-18 03:41:06'),
(442, 11, 'Daging Sapi Panggang Kedelai', 785, 'Lunch', '', '2026-05-29', '2026-06-18 03:41:06'),
(443, 11, 'Nasi Goreng Telur + Ayam', 675, 'Breakfast', '', '2026-05-28', '2026-06-18 03:41:06'),
(444, 11, 'Daging Sapi Panggang Kedelai', 825, 'Lunch', '', '2026-05-28', '2026-06-18 03:41:06'),
(445, 11, 'Nasi Goreng Telur + Ayam', 621, 'Breakfast', '', '2026-05-27', '2026-06-18 03:41:06'),
(446, 11, 'Daging Sapi Panggang Kedelai', 759, 'Lunch', '', '2026-05-27', '2026-06-18 03:41:06'),
(447, 11, 'Nasi Goreng Telur + Ayam', 589, 'Breakfast', '', '2026-05-26', '2026-06-18 03:41:06'),
(448, 11, 'Daging Sapi Panggang Kedelai', 720, 'Lunch', '', '2026-05-26', '2026-06-18 03:41:06'),
(449, 11, 'Nasi Goreng Telur + Ayam', 946, 'Breakfast', '', '2026-05-25', '2026-06-18 03:41:06'),
(450, 11, 'Daging Sapi Panggang Kedelai', 1156, 'Lunch', '', '2026-05-25', '2026-06-18 03:41:06'),
(451, 11, 'Nasi Goreng Telur + Ayam', 679, 'Breakfast', '', '2026-05-24', '2026-06-18 03:41:06'),
(452, 11, 'Daging Sapi Panggang Kedelai', 831, 'Lunch', '', '2026-05-24', '2026-06-18 03:41:06'),
(453, 11, 'Nasi Goreng Telur + Ayam', 585, 'Breakfast', '', '2026-05-23', '2026-06-18 03:41:06'),
(454, 11, 'Daging Sapi Panggang Kedelai', 716, 'Lunch', '', '2026-05-23', '2026-06-18 03:41:06'),
(455, 11, 'Nasi Goreng Telur + Ayam', 739, 'Breakfast', '', '2026-05-22', '2026-06-18 03:41:06'),
(456, 11, 'Daging Sapi Panggang Kedelai', 903, 'Lunch', '', '2026-05-22', '2026-06-18 03:41:06'),
(457, 11, 'Nasi Goreng Telur + Ayam', 1038, 'Breakfast', '', '2026-05-21', '2026-06-18 03:41:06'),
(458, 11, 'Daging Sapi Panggang Kedelai', 1268, 'Lunch', '', '2026-05-21', '2026-06-18 03:41:06'),
(459, 11, 'Nasi Goreng Telur + Ayam', 746, 'Breakfast', '', '2026-05-20', '2026-06-18 03:41:06'),
(460, 11, 'Daging Sapi Panggang Kedelai', 911, 'Lunch', '', '2026-05-20', '2026-06-18 03:41:06'),
(461, 11, 'Nasi Goreng Telur + Ayam', 766, 'Breakfast', '', '2026-05-19', '2026-06-18 03:41:06'),
(462, 11, 'Daging Sapi Panggang Kedelai', 937, 'Lunch', '', '2026-05-19', '2026-06-18 03:41:06'),
(463, 11, 'Nasi Goreng Telur + Ayam', 878, 'Breakfast', '', '2026-05-18', '2026-06-18 03:41:06'),
(464, 11, 'Daging Sapi Panggang Kedelai', 1073, 'Lunch', '', '2026-05-18', '2026-06-18 03:41:06'),
(465, 11, 'Nasi Goreng Telur + Ayam', 837, 'Breakfast', '', '2026-05-17', '2026-06-18 03:41:06'),
(466, 11, 'Daging Sapi Panggang Kedelai', 1024, 'Lunch', '', '2026-05-17', '2026-06-18 03:41:06'),
(467, 11, 'Nasi Goreng Telur + Ayam', 988, 'Breakfast', '', '2026-05-16', '2026-06-18 03:41:06'),
(468, 11, 'Daging Sapi Panggang Kedelai', 1207, 'Lunch', '', '2026-05-16', '2026-06-18 03:41:06'),
(469, 11, 'Nasi Goreng Telur + Ayam', 1024, 'Breakfast', '', '2026-05-15', '2026-06-18 03:41:06'),
(470, 11, 'Daging Sapi Panggang Kedelai', 1251, 'Lunch', '', '2026-05-15', '2026-06-18 03:41:06'),
(471, 11, 'Nasi Goreng Telur + Ayam', 844, 'Breakfast', '', '2026-05-14', '2026-06-18 03:41:06'),
(472, 11, 'Daging Sapi Panggang Kedelai', 1031, 'Lunch', '', '2026-05-14', '2026-06-18 03:41:06'),
(473, 11, 'Nasi Goreng Telur + Ayam', 865, 'Breakfast', '', '2026-05-13', '2026-06-18 03:41:06'),
(474, 11, 'Daging Sapi Panggang Kedelai', 1057, 'Lunch', '', '2026-05-13', '2026-06-18 03:41:06'),
(475, 11, 'Nasi Goreng Telur + Ayam', 672, 'Breakfast', '', '2026-05-12', '2026-06-18 03:41:06'),
(476, 11, 'Daging Sapi Panggang Kedelai', 821, 'Lunch', '', '2026-05-12', '2026-06-18 03:41:06'),
(477, 11, 'Nasi Goreng Telur + Ayam', 989, 'Breakfast', '', '2026-05-11', '2026-06-18 03:41:06'),
(478, 11, 'Daging Sapi Panggang Kedelai', 1209, 'Lunch', '', '2026-05-11', '2026-06-18 03:41:06'),
(479, 11, 'Nasi Goreng Telur + Ayam', 914, 'Breakfast', '', '2026-05-10', '2026-06-18 03:41:06'),
(480, 11, 'Daging Sapi Panggang Kedelai', 1117, 'Lunch', '', '2026-05-10', '2026-06-18 03:41:06'),
(481, 11, 'Nasi Goreng Telur + Ayam', 604, 'Breakfast', '', '2026-05-09', '2026-06-18 03:41:06'),
(482, 11, 'Daging Sapi Panggang Kedelai', 738, 'Lunch', '', '2026-05-09', '2026-06-18 03:41:06'),
(483, 11, 'Nasi Goreng Telur + Ayam', 961, 'Breakfast', '', '2026-05-08', '2026-06-18 03:41:06'),
(484, 11, 'Daging Sapi Panggang Kedelai', 1175, 'Lunch', '', '2026-05-08', '2026-06-18 03:41:06'),
(485, 11, 'Nasi Goreng Telur + Ayam', 642, 'Breakfast', '', '2026-05-07', '2026-06-18 03:41:06'),
(486, 11, 'Daging Sapi Panggang Kedelai', 785, 'Lunch', '', '2026-05-07', '2026-06-18 03:41:06'),
(487, 11, 'Nasi Goreng Telur + Ayam', 894, 'Breakfast', '', '2026-05-06', '2026-06-18 03:41:06'),
(488, 11, 'Daging Sapi Panggang Kedelai', 1092, 'Lunch', '', '2026-05-06', '2026-06-18 03:41:06'),
(489, 11, 'Nasi Goreng Telur + Ayam', 980, 'Breakfast', '', '2026-05-05', '2026-06-18 03:41:06'),
(490, 11, 'Daging Sapi Panggang Kedelai', 1197, 'Lunch', '', '2026-05-05', '2026-06-18 03:41:06'),
(491, 11, 'Nasi Goreng Telur + Ayam', 596, 'Breakfast', '', '2026-05-04', '2026-06-18 03:41:06'),
(492, 11, 'Daging Sapi Panggang Kedelai', 729, 'Lunch', '', '2026-05-04', '2026-06-18 03:41:06'),
(493, 11, 'Nasi Goreng Telur + Ayam', 765, 'Breakfast', '', '2026-05-03', '2026-06-18 03:41:06'),
(494, 11, 'Daging Sapi Panggang Kedelai', 935, 'Lunch', '', '2026-05-03', '2026-06-18 03:41:06'),
(495, 11, 'Nasi Goreng Telur + Ayam', 918, 'Breakfast', '', '2026-05-02', '2026-06-18 03:41:06'),
(496, 11, 'Daging Sapi Panggang Kedelai', 1123, 'Lunch', '', '2026-05-02', '2026-06-18 03:41:06'),
(497, 11, 'Nasi Goreng Telur + Ayam', 853, 'Breakfast', '', '2026-05-01', '2026-06-18 03:41:06'),
(498, 11, 'Daging Sapi Panggang Kedelai', 1043, 'Lunch', '', '2026-05-01', '2026-06-18 03:41:06'),
(499, 11, 'Nasi Goreng Telur + Ayam', 709, 'Breakfast', '', '2026-04-30', '2026-06-18 03:41:06'),
(500, 11, 'Daging Sapi Panggang Kedelai', 867, 'Lunch', '', '2026-04-30', '2026-06-18 03:41:06'),
(501, 9, 'Nasi ayam', 500, 'Lunch', '11:13 AM', '2026-06-18', '2026-06-18 04:13:55'),
(502, 12, 'makanan asuik', 233, 'Lunch', '8:26 PM', '2026-06-22', '2026-06-22 13:26:26'),
(504, 12, 'tes', 233, 'Breakfast', '8:38 PM', '2026-06-22', '2026-06-22 13:38:22'),
(505, 12, 'tes', 333, 'Dinner', '8:38 PM', '2026-06-22', '2026-06-22 13:38:53'),
(506, 12, 'tes', 233, 'Lunch', '8:40 PM', '2026-06-22', '2026-06-22 13:40:41'),
(507, 12, 'awaw', 544, 'Dinner', '8:40 PM', '2026-06-22', '2026-06-22 13:40:49'),
(508, 9, 'tes', 4333, 'Breakfast', '8:51 PM', '2026-06-22', '2026-06-22 13:51:51'),
(509, 14, 'Oatmeal Protein Bowl with Banana', 450, 'Breakfast', '08:15', '2026-06-22', '2026-06-22 01:15:00'),
(510, 14, 'Grilled Chicken Breast & Brown Rice', 700, 'Lunch', '13:00', '2026-06-22', '2026-06-22 06:00:00'),
(511, 14, 'Baked Salmon Fillet with Potato', 500, 'Dinner', '19:45', '2026-06-22', '2026-06-22 12:45:00'),
(512, 14, 'Whey Isolate Protein Shake', 200, 'Snack', '16:30', '2026-06-22', '2026-06-22 09:30:00'),
(513, 14, 'Scrambled Eggs & Avocado Toast', 500, 'Breakfast', '07:45', '2026-06-23', '2026-06-23 00:45:00'),
(514, 14, 'Ribeye Steak with French Fries', 1100, 'Lunch', '12:30', '2026-06-23', '2026-06-23 05:30:00'),
(515, 14, 'Two Pizza Slices & Zero Cola', 650, 'Dinner', '20:00', '2026-06-23', '2026-06-23 13:00:00'),
(516, 14, 'Gelato Ice Cream Cup', 200, 'Snack', '15:15', '2026-06-23', '2026-06-23 08:15:00'),
(517, 14, 'Low Fat Greek Yogurt with Honey', 300, 'Breakfast', '08:30', '2026-06-24', '2026-06-24 01:30:00'),
(518, 14, 'Tuna Salad Whole Wheat Wrap', 600, 'Lunch', '13:15', '2026-06-24', '2026-06-24 06:15:00'),
(519, 14, 'Boiled Chicken Breast & Veggies', 500, 'Dinner', '19:00', '2026-06-24', '2026-06-24 12:00:00'),
(520, 14, 'Organic Red Apple & Almonds', 200, 'Snack', '17:00', '2026-06-24', '2026-06-24 10:00:00'),
(521, 14, 'Banana & Peanut Butter Smoothie', 500, 'Breakfast', '08:00', '2026-06-25', '2026-06-25 01:00:00'),
(522, 14, 'Smoked Turkey Breast Sandwich', 600, 'Lunch', '12:45', '2026-06-25', '2026-06-25 05:45:00'),
(523, 14, 'Minced Beef Pasta Bolognese', 800, 'Dinner', '19:30', '2026-06-25', '2026-06-25 12:30:00'),
(524, 14, 'Dark Chocolate Bar', 200, 'Snack', '16:00', '2026-06-25', '2026-06-25 09:00:00'),
(525, 14, 'Fluffy Pancakes with Maple Syrup', 600, 'Breakfast', '09:00', '2026-06-26', '2026-06-26 02:00:00'),
(526, 14, 'Special Fried Rice & Sunny Egg', 850, 'Lunch', '13:00', '2026-06-26', '2026-06-26 06:00:00'),
(527, 14, 'Steamed Fish Fillet & Tofu Soup', 500, 'Dinner', '20:15', '2026-06-26', '2026-06-26 13:15:00'),
(528, 14, 'Crunchy Protein Bar', 300, 'Snack', '15:45', '2026-06-26', '2026-06-26 08:45:00'),
(529, 14, 'Sunny Side Up Eggs & Beef Bacon', 550, 'Breakfast', '09:30', '2026-06-27', '2026-06-27 02:30:00'),
(530, 14, 'Double Grilled Cheeseburger', 900, 'Lunch', '14:00', '2026-06-27', '2026-06-27 07:00:00'),
(531, 14, 'Clear Chicken Soup & Crackers', 400, 'Dinner', '19:00', '2026-06-27', '2026-06-27 12:00:00'),
(532, 14, 'Salted Potato Chips', 150, 'Snack', '16:30', '2026-06-27', '2026-06-27 09:30:00'),
(533, 14, 'Strawberry Chia Seed Pudding', 400, 'Breakfast', '08:45', '2026-06-28', '2026-06-28 01:45:00'),
(534, 14, 'Shredded Chicken Breast Congee', 500, 'Lunch', '12:15', '2026-06-28', '2026-06-28 05:15:00'),
(535, 14, 'White Fish Fillet & Asparagus', 400, 'Dinner', '18:30', '2026-06-28', '2026-06-28 11:30:00'),
(536, 14, 'Crispy Rice Cakes', 200, 'Snack', '15:00', '2026-06-28', '2026-06-28 08:00:00'),
(537, 9, 'nasi ayam', 400, 'Lunch', '1:44 PM', '2026-06-23', '2026-06-23 06:44:20'),
(538, 24, 'Omellete', 150, 'Breakfast', '7:08 AM', '2026-06-27', '2026-06-27 00:08:39'),
(539, 24, 'Chicken And Rice', 650, 'Lunch', '7:08 AM', '2026-06-27', '2026-06-27 00:09:01'),
(540, 24, 'Steak', 900, 'Dinner', '7:09 AM', '2026-06-27', '2026-06-27 00:09:24'),
(541, 24, 'Greek Yogurt', 100, 'Snack', '7:09 AM', '2026-06-27', '2026-06-27 00:09:47');

-- --------------------------------------------------------

--
-- Table structure for table `email_verification_tokens`
--

CREATE TABLE `email_verification_tokens` (
  `email` varchar(100) NOT NULL,
  `token` varchar(10) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `email_verification_tokens`
--

INSERT INTO `email_verification_tokens` (`email`, `token`, `created_at`) VALUES
('tes@gmail.com', '657341', '2026-06-28 09:37:04');

-- --------------------------------------------------------

--
-- Table structure for table `ema_mood_logs`
--

CREATE TABLE `ema_mood_logs` (
  `id_mood_log` int(11) NOT NULL,
  `id_user` int(11) NOT NULL,
  `skor_mood` int(11) NOT NULL,
  `mood` varchar(50) NOT NULL,
  `influences` text DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `log_date` date NOT NULL,
  `logged_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `ema_mood_logs`
--

INSERT INTO `ema_mood_logs` (`id_mood_log`, `id_user`, `skor_mood`, `mood`, `influences`, `notes`, `log_date`, `logged_at`) VALUES
(108, 15, 1, 'Very Low', '[\"Rested\"]', NULL, '2026-06-16', '2026-06-16 05:59:59'),
(109, 13, 1, 'Very Low', '[\"Anxious\",\"Lonely\"]', NULL, '2026-06-16', '2026-06-16 06:03:55'),
(111, 8, 5, 'Great', '[]', NULL, '2026-06-17', '2026-06-17 12:08:19'),
(261, 13, 1, 'Very Low', '[\"Rested\"]', NULL, '2026-06-18', '2026-06-18 04:17:34'),
(307, 9, 5, '🤩 Energetic', 'Sleep, Workout', 'Feeling amazing today!', '2026-06-22', '2026-06-22 13:07:38'),
(308, 9, 4, '🙂 Good', 'Food, Friends', 'Productive day.', '2026-06-21', '2026-06-21 13:07:38'),
(309, 9, 5, '🤩 Awesome', 'Workout', 'Smashed my goals.', '2026-06-20', '2026-06-20 13:07:38'),
(310, 9, 4, '🙂 Pleased', 'Sleep', 'Well rested.', '2026-06-19', '2026-06-19 13:07:38'),
(311, 9, 5, '🤩 Happy', 'Food', 'Great mood overall.', '2026-06-18', '2026-06-18 13:07:38'),
(312, 10, 2, '😟 Stressed', 'Work, Deadline', 'Too much work load.', '2026-06-22', '2026-06-22 13:07:39'),
(313, 10, 5, '🤩 Amazing', 'Sleep, Social', 'Weekend was great.', '2026-06-21', '2026-06-21 13:07:39'),
(314, 10, 4, '🙂 Calm', 'Hobbies', 'Relaxing evening.', '2026-06-20', '2026-06-20 13:07:39'),
(315, 10, 4, '🙂 Good', 'Food', 'Normal day.', '2026-06-19', '2026-06-19 13:07:39'),
(316, 11, 2, '😟 Exhausted', 'Insomnia', 'Did not sleep well.', '2026-06-22', '2026-06-22 13:07:39'),
(317, 11, 2, '😟 Tired', 'Overwork', 'Body feels heavy.', '2026-06-21', '2026-06-21 13:07:39'),
(318, 11, 2, '😟 Low Energy', 'Stress', 'Mentally drained.', '2026-06-20', '2026-06-20 13:07:39'),
(319, 11, 4, '🙂 Normal', 'Food', 'Just okay.', '2026-06-19', '2026-06-19 13:07:39'),
(320, 11, 4, '🙂 Happy', 'Workout', 'Good session.', '2026-06-18', '2026-06-18 13:07:39'),
(321, 11, 4, '🙂 Good', 'Sleep', 'Felt fine.', '2026-06-17', '2026-06-17 13:07:39'),
(322, 17, 1, '😔 Depressed', 'Personal Issues', 'Feeling very low.', '2026-06-22', '2026-06-22 13:07:39'),
(323, 17, 1, '😔 Awful', 'Insomnia', 'No sleep at all.', '2026-06-21', '2026-06-21 13:07:39'),
(324, 17, 2, '😟 Burnout', 'Work', 'Cant focus.', '2026-06-20', '2026-06-20 13:07:39'),
(325, 17, 1, '😔 Sad', 'None', 'Dreadful day.', '2026-06-19', '2026-06-19 13:07:39'),
(326, 17, 2, '😟 Overwhelmed', 'Everything', 'Too much pressure.', '2026-06-18', '2026-06-18 13:07:39'),
(327, 17, 1, '😔 Empty', 'None', 'No motivation.', '2026-06-17', '2026-06-17 13:07:39'),
(328, 17, 1, '😔 Numb', 'Work Stress', 'Just tired.', '2026-06-16', '2026-06-16 13:07:39'),
(329, 12, 4, 'Good', '[\"Stressed\"]', NULL, '2026-06-22', '2026-06-22 13:28:35'),
(330, 14, 4, '🙂 Good', 'Sleep', 'Had a solid rest.', '2026-06-22', '2026-06-22 13:56:35'),
(331, 14, 3, '😐 Normal', 'Work', 'Busy day at the office.', '2026-06-21', '2026-06-21 13:56:35'),
(332, 14, 2, '😟 Stressed', 'Deadline', 'Coding bugs everywhere.', '2026-06-20', '2026-06-20 13:56:35'),
(333, 14, 5, '🤩 Energetic', 'Workout', 'Smashed leg day!', '2026-06-19', '2026-06-19 13:56:35'),
(334, 14, 4, '🙂 Content', 'Friends', 'Nice dinner out.', '2026-06-18', '2026-06-18 13:56:35'),
(335, 14, 5, '🤩 Awesome', 'Hobbies', 'Productive weekend.', '2026-06-17', '2026-06-17 13:56:35'),
(336, 14, 3, '😐 Flat', 'Weather', 'Raining all day.', '2026-06-16', '2026-06-16 13:56:35'),
(337, 14, 4, '🙂 Good', 'Food', 'Cheated with a good burger.', '2026-06-15', '2026-06-15 13:56:35'),
(338, 14, 2, '😟 Tired', 'Insomnia', 'Woke up too early.', '2026-06-14', '2026-06-14 13:56:35'),
(339, 14, 1, '😔 Depressed', 'Burnout', 'Need a vacation badly.', '2026-06-13', '2026-06-13 13:56:35'),
(340, 14, 3, '😐 Okay', 'None', 'Just another regular day.', '2026-06-12', '2026-06-12 13:56:35'),
(341, 14, 4, '🙂 Pleased', 'Family', 'Called my parents.', '2026-06-11', '2026-06-11 13:56:35'),
(342, 14, 5, '🤩 Motivated', 'Gym', 'New personal record!', '2026-06-10', '2026-06-10 13:56:35'),
(343, 14, 4, '🙂 Calm', 'Meditation', 'Mind feels clear.', '2026-06-09', '2026-06-09 13:56:35'),
(344, 14, 3, '😐 Tired', 'Work', 'Long meetings.', '2026-06-08', '2026-06-08 13:56:35'),
(345, 14, 2, '😟 Anxious', 'Finances', 'Thinking about bills.', '2026-06-07', '2026-06-07 13:56:35'),
(346, 14, 4, '🙂 Happy', 'Movie', 'Watched a great show.', '2026-06-06', '2026-06-06 13:56:35'),
(347, 14, 5, '🤩 Inspired', 'Books', 'Read an amazing chapter.', '2026-06-05', '2026-06-05 13:56:35'),
(348, 14, 4, '🙂 Relaxed', 'Weekend', 'No alarms set today.', '2026-06-04', '2026-06-04 13:56:35'),
(349, 14, 3, '😐 Neutral', 'None', 'Normal routine.', '2026-06-03', '2026-06-03 13:56:35'),
(350, 14, 4, '🙂 Satisfied', 'Achieve', 'Finished my project tasks.', '2026-06-02', '2026-06-02 13:56:35'),
(351, 14, 5, '🤩 Hyper', 'Coffee', 'Three espresso shots.', '2026-06-01', '2026-06-01 13:56:35'),
(352, 14, 3, '😐 Bored', 'Routine', 'Nothing exciting happening.', '2026-05-31', '2026-05-31 13:56:35'),
(353, 14, 2, '😟 Annoyed', 'Traffic', 'Stuck for 2 hours.', '2026-05-30', '2026-05-30 13:56:35'),
(354, 14, 4, '🙂 Cheerful', 'Weather', 'Sunny and beautiful sky.', '2026-05-29', '2026-05-29 13:56:35'),
(355, 14, 5, '🤩 Vibrant', 'Music', 'Found a great new album.', '2026-05-28', '2026-05-28 13:56:35'),
(356, 14, 4, '🙂 Cozy', 'Rain', 'Perfect day to stay inside.', '2026-05-27', '2026-05-27 13:56:35'),
(357, 14, 3, '😐 Indifferent', 'None', 'Middle of the week blur.', '2026-05-26', '2026-05-26 13:56:35'),
(358, 14, 1, '😔 Exhausted', 'Overtime', 'Worked until midnight.', '2026-05-25', '2026-05-25 13:56:35'),
(359, 14, 4, '🙂 Hopeful', 'Planning', 'Setting goals for next month.', '2026-05-24', '2026-05-24 13:56:35'),
(360, 9, 5, 'Great', '[\"Energetic\"]', NULL, '2026-06-23', '2026-06-23 06:43:26');

-- --------------------------------------------------------

--
-- Table structure for table `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(255) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobs`
--

CREATE TABLE `jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` tinyint(3) UNSIGNED NOT NULL,
  `reserved_at` int(10) UNSIGNED DEFAULT NULL,
  `available_at` int(10) UNSIGNED NOT NULL,
  `created_at` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `job_batches`
--

CREATE TABLE `job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '0001_01_01_000001_create_cache_table', 1),
(2, '0001_01_01_000002_create_jobs_table', 1);

-- --------------------------------------------------------

--
-- Table structure for table `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `email` varchar(100) NOT NULL,
  `token` varchar(10) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `personal_access_tokens`
--

INSERT INTO `personal_access_tokens` (`id`, `tokenable_type`, `tokenable_id`, `name`, `token`, `abilities`, `last_used_at`, `expires_at`, `created_at`, `updated_at`) VALUES
(1, 'App\\Models\\User', 5, 'auth_token', '2ef1c8958b314788c1958ecf643e6b5df0b8b5956228b19586c4ae8e7ae068d8', '[\"User\"]', NULL, NULL, '2026-06-07 07:29:08', '2026-06-07 07:29:08'),
(2, 'App\\Models\\User', 6, 'auth_token', '8861bc1ec3f0af9c6c542a69dcc1a539b04936735279a652af59acee9ae4f0d9', '[\"Admin\"]', NULL, NULL, '2026-06-07 07:29:24', '2026-06-07 07:29:24'),
(3, 'App\\Models\\User', 6, 'auth_token', '45cfa8aeceb7e86d703ba3f82d8d61784b510578b167bb5294d77469f7ff300a', '[\"Admin\"]', NULL, NULL, '2026-06-07 07:33:11', '2026-06-07 07:33:11'),
(4, 'App\\Models\\User', 7, 'auth_token', 'cfa3bcfebf834a4f7986eb1b8289824217cf3e647630d65ff10ecc4164c41bcb', '[\"User\"]', NULL, NULL, '2026-06-14 05:19:22', '2026-06-14 05:19:22'),
(5, 'App\\Models\\User', 7, 'auth_token', 'fbcf888081e236830b2e80426022a3726aeddd9ad11de356ef4bf326e3d318dd', '[\"User\"]', NULL, NULL, '2026-06-14 05:19:34', '2026-06-14 05:19:34'),
(6, 'App\\Models\\User', 7, 'auth_token', 'a2c39f18248a630237573448bb57465bcabd96cfc8179c5c069234acb3facf42', '[\"User\"]', NULL, NULL, '2026-06-14 05:34:32', '2026-06-14 05:34:32'),
(9, 'App\\Models\\User', 7, 'auth_token', '283425fadd6db5a849d681810cd4163c30e2e922c02f12677dd200de7ea9b8a5', '[\"User\"]', '2026-06-14 07:42:55', NULL, '2026-06-14 07:42:40', '2026-06-14 07:42:55'),
(10, 'App\\Models\\User', 8, 'auth_token', '03988bf069e0e0a3386697ca8427db46cb6cd2a5227c16f83488142374cf430d', '[\"User\"]', '2026-06-14 07:47:42', NULL, '2026-06-14 07:47:21', '2026-06-14 07:47:42'),
(11, 'App\\Models\\User', 8, 'auth_token', '1002c56df459594a9d349d00730aae814a8f6977460dc24f8d926a9acd5a2870', '[\"User\"]', '2026-06-15 05:15:38', NULL, '2026-06-15 04:54:22', '2026-06-15 05:15:38'),
(12, 'App\\Models\\User', 8, 'auth_token', 'e959df4d76d1f118ea6e0278f24e8cdc9a37036cd5fa561162f3d0f51721c65e', '[\"User\"]', '2026-06-15 05:05:51', NULL, '2026-06-15 05:00:18', '2026-06-15 05:05:51'),
(13, 'App\\Models\\User', 8, 'auth_token', 'e1091bb7c0037eaeb9a78478970b0bc25c315ac06fc65d8f7677d9c424c250b1', '[\"User\"]', NULL, NULL, '2026-06-15 05:21:18', '2026-06-15 05:21:18'),
(14, 'App\\Models\\User', 8, 'auth_token', '6a731bb352e930998c631cf33a36724351eaf563d255a43fa22d389faa14e4fb', '[\"User\"]', NULL, NULL, '2026-06-15 05:23:45', '2026-06-15 05:23:45'),
(15, 'App\\Models\\User', 8, 'auth_token', 'f0d697be272346bad29fa600a1c28c240a136fc7851ba14b2d0c2566ef6f94e3', '[\"User\"]', '2026-06-15 05:36:36', NULL, '2026-06-15 05:24:13', '2026-06-15 05:36:36'),
(16, 'App\\Models\\User', 8, 'auth_token', '206a360e87266ba1710358b4aff9599a37536d07737e86e8c2284417c896b3ab', '[\"User\"]', NULL, NULL, '2026-06-15 05:47:17', '2026-06-15 05:47:17'),
(17, 'App\\Models\\User', 8, 'auth_token', 'e51c869e56b097ce0a25b36e6f306745bb743d186a04c55e41ec7e5ca86bc142', '[\"User\"]', NULL, NULL, '2026-06-15 05:48:07', '2026-06-15 05:48:07'),
(18, 'App\\Models\\User', 8, 'auth_token', '8ecee3872d331720306912750268ed4312c4029fb5bbc25096ed1e81746c8a15', '[\"User\"]', NULL, NULL, '2026-06-15 05:49:58', '2026-06-15 05:49:58'),
(19, 'App\\Models\\User', 8, 'auth_token', 'f9aaf3fb27551f2525d1b2e3a741656cb4938bcf5d784a947db1989f5ad38d1a', '[\"User\"]', NULL, NULL, '2026-06-15 05:51:01', '2026-06-15 05:51:01'),
(20, 'App\\Models\\User', 8, 'auth_token', 'e148d86a39160c72147d3a823ac4495f1cf7f0c372b06bc8ce5dc09e29ecfd60', '[\"User\"]', NULL, NULL, '2026-06-15 05:53:08', '2026-06-15 05:53:08'),
(21, 'App\\Models\\User', 8, 'auth_token', '97c38c145004b9f5c597fcc9493fc40aa5ed55fbac503bc9bfa9bcbaccd0b95a', '[\"User\"]', '2026-06-15 05:57:16', NULL, '2026-06-15 05:54:43', '2026-06-15 05:57:16'),
(22, 'App\\Models\\User', 8, 'auth_token', 'c6f469c06b6e1f2e23a1ae52b30240af8f01a258c716fff03641786a53495c65', '[\"User\"]', '2026-06-15 06:09:03', NULL, '2026-06-15 06:08:05', '2026-06-15 06:09:03'),
(23, 'App\\Models\\User', 8, 'auth_token', 'cb1f7f102dd8aaae9075ca68623d39a79572c5dd1a29cc8b80b36667cd7f6273', '[\"User\"]', '2026-06-15 06:18:49', NULL, '2026-06-15 06:13:20', '2026-06-15 06:18:49'),
(24, 'App\\Models\\User', 8, 'auth_token', '1162ec74451d8584e39b4e0827040249ab41ba3ac167029a327c30e6b23e8d2b', '[\"User\"]', '2026-06-15 07:08:28', NULL, '2026-06-15 06:19:37', '2026-06-15 07:08:28'),
(25, 'App\\Models\\User', 8, 'auth_token', 'de3f1fd9fc887b290afe665d59244b56b769762f3b2812e8d4b68e004ba685a1', '[\"User\"]', '2026-06-15 06:26:13', NULL, '2026-06-15 06:20:29', '2026-06-15 06:26:13'),
(26, 'App\\Models\\User', 8, 'auth_token', 'e4296d2a5302e930edc1e72511870001abbb0df80db40debf5ce33801d4e5952', '[\"User\"]', '2026-06-15 07:30:35', NULL, '2026-06-15 07:10:34', '2026-06-15 07:30:35'),
(27, 'App\\Models\\User', 8, 'auth_token', 'aaa27ddfd74ed5b1a9140bdbdaa0a43f1d6f75daceb4322cf0cd1949771a08dc', '[\"User\"]', '2026-06-15 07:35:01', NULL, '2026-06-15 07:30:49', '2026-06-15 07:35:01'),
(28, 'App\\Models\\User', 8, 'auth_token', '9f29aa6025d34887206d5f1b684fc9146822319e219faff936c966f17c5397a6', '[\"User\"]', '2026-06-15 07:37:48', NULL, '2026-06-15 07:35:19', '2026-06-15 07:37:48'),
(29, 'App\\Models\\User', 8, 'auth_token', 'e13c9839a564da3de7391cb1faa2bf2d989d3beffaf97618c6aeea33cbde4609', '[\"User\"]', '2026-06-15 11:00:42', NULL, '2026-06-15 08:07:39', '2026-06-15 11:00:42'),
(30, 'App\\Models\\User', 8, 'auth_token', '19970cf9a34c98feef2d098e458a7ed248c3db55052195d35a17cc2e4bda90ee', '[\"User\"]', '2026-06-15 11:14:45', NULL, '2026-06-15 11:05:15', '2026-06-15 11:14:45'),
(31, 'App\\Models\\User', 8, 'auth_token', '6d588619c1cf484da9c6857f63e4c65c1174188ec7638b90a6b288e6ea1fc70a', '[\"User\"]', '2026-06-15 11:19:09', NULL, '2026-06-15 11:15:38', '2026-06-15 11:19:09'),
(32, 'App\\Models\\User', 8, 'auth_token', '92906ee1851a9459caaf597267ac85a967aa04f0ccbe2a356e0bc9a177dbe97c', '[\"User\"]', '2026-06-15 11:21:47', NULL, '2026-06-15 11:20:44', '2026-06-15 11:21:47'),
(33, 'App\\Models\\User', 8, 'auth_token', '8cde0a8e2aa2cacefe93e19d83b7cfe40012bef9396581ee9df70e314d311801', '[\"User\"]', '2026-06-15 11:25:34', NULL, '2026-06-15 11:22:05', '2026-06-15 11:25:34'),
(39, 'App\\Models\\User', 9, 'auth_token', 'bc93f144ec61ecd9e409df5198dd5c278d8604bc92d1adda092a07d96b682a7e', '[\"User\"]', '2026-06-15 12:02:08', NULL, '2026-06-15 11:49:06', '2026-06-15 12:02:08'),
(40, 'App\\Models\\User', 9, 'auth_token', '8bc9169691b8f5a66d4aa09408e2acbee248d1885fb8e990435e061105710f92', '[\"User\"]', '2026-06-15 12:03:21', NULL, '2026-06-15 12:02:30', '2026-06-15 12:03:21'),
(41, 'App\\Models\\User', 9, 'auth_token', '7cdee85898bdaca4623da4b25b08110f6c9d35b5b43a0cf39139610b264add39', '[\"User\"]', '2026-06-15 12:08:34', NULL, '2026-06-15 12:03:45', '2026-06-15 12:08:34'),
(42, 'App\\Models\\User', 9, 'auth_token', '4528d9b11dede1603248d68b9ae8f1539c72a95f552ef5be8dcec3563e23c3e4', '[\"User\"]', '2026-06-15 12:08:56', NULL, '2026-06-15 12:08:54', '2026-06-15 12:08:56'),
(45, 'App\\Models\\User', 11, 'auth_token', 'a8512d6e7cce7f9a84e69d3dce63fb937a57fe5fb00f079277cb059329fd4cf8', '[\"User\"]', '2026-06-15 12:17:28', NULL, '2026-06-15 12:16:49', '2026-06-15 12:17:28'),
(46, 'App\\Models\\User', 11, 'auth_token', 'dfd677df99b6d8ee564769e1e540e596358a7a039feb9ba6dd6ead066a84d37f', '[\"User\"]', NULL, NULL, '2026-06-15 12:22:24', '2026-06-15 12:22:24'),
(47, 'App\\Models\\User', 11, 'auth_token', 'a3c4843d85946cdb8280a085e9c77b5c38bb5f176630df96b820868b717f3727', '[\"User\"]', NULL, NULL, '2026-06-15 12:22:26', '2026-06-15 12:22:26'),
(49, 'App\\Models\\User', 11, 'auth_token', '1b9f2d700531bb36fdf0393260c308e11a724d805413ff22ad8a1ddd2127ba5c', '[\"User\"]', '2026-06-15 12:23:58', NULL, '2026-06-15 12:23:52', '2026-06-15 12:23:58'),
(52, 'App\\Models\\User', 13, 'auth_token', '5b7b8954c2c71083940424bb7d02eed75e8de4ef38ff1dba72d17099ea6386b8', '[\"User\"]', '2026-06-15 13:10:14', NULL, '2026-06-15 13:09:36', '2026-06-15 13:10:14'),
(53, 'App\\Models\\User', 13, 'auth_token', '932fd977c0812a44fd3f5822d4f806fce97a6d636426135e1e6015c121fb2bec', '[\"User\"]', '2026-06-15 13:11:39', NULL, '2026-06-15 13:11:36', '2026-06-15 13:11:39'),
(55, 'App\\Models\\User', 14, 'auth_token', '532423e123a8dceffd00ebfc9889279cf9cb61884613265d2b0a8f2c5b3b2ecc', '[\"User\"]', '2026-06-15 13:31:36', NULL, '2026-06-15 13:14:41', '2026-06-15 13:31:36'),
(56, 'App\\Models\\User', 13, 'auth_token', '777f63f834fa5b616eea140393ce225718c16afe7ee853a05fcd2a181908272d', '[\"User\"]', '2026-06-15 13:32:23', NULL, '2026-06-15 13:31:59', '2026-06-15 13:32:23'),
(58, 'App\\Models\\User', 15, 'auth_token', '877c24a7ba8b880e638f7a70ac2e511965430a1b9c58a5d3ded7636d1093e68d', '[\"User\"]', '2026-06-15 13:34:19', NULL, '2026-06-15 13:33:20', '2026-06-15 13:34:19'),
(59, 'App\\Models\\User', 15, 'auth_token', '592f88f4a431ebe7b2c7145006ba84732aea952c007d39616834b86d0f1d1502', '[\"User\"]', '2026-06-15 13:46:24', NULL, '2026-06-15 13:35:57', '2026-06-15 13:46:24'),
(60, 'App\\Models\\User', 15, 'auth_token', '540182c2f3aea93badc4ecf3c98b421efa89534db85de0a862025aaeb711eca5', '[\"User\"]', '2026-06-15 23:00:04', NULL, '2026-06-15 13:47:05', '2026-06-15 23:00:04'),
(61, 'App\\Models\\User', 13, 'auth_token', 'acf88c1df286550ab94754c084fec6c51246e8e340d33086ce57afac7125eed3', '[\"User\"]', '2026-06-15 23:04:05', NULL, '2026-06-15 23:03:11', '2026-06-15 23:04:05'),
(62, 'App\\Models\\User', 13, 'auth_token', '6006dce2866aa3d681a242dfb2b726bbd04db119675e455bc19c8d32b9525b7c', '[\"User\"]', '2026-06-15 23:06:09', NULL, '2026-06-15 23:04:25', '2026-06-15 23:06:09'),
(63, 'App\\Models\\User', 9, 'auth_token', 'eaa02a967e2d57c0390fb41e38ab11ba8843c0d5778043044f05677cdb0373f2', '[\"User\"]', '2026-06-17 04:55:16', NULL, '2026-06-17 04:54:47', '2026-06-17 04:55:16'),
(64, 'App\\Models\\User', 9, 'auth_token', '1f35093180363e0bcf6f9ff0c86bb1720301427a05ef6653ce9aa883bff11e5e', '[\"User\"]', '2026-06-17 04:56:29', NULL, '2026-06-17 04:56:23', '2026-06-17 04:56:29'),
(65, 'App\\Models\\User', 9, 'auth_token', 'af9a617771715b6a5ef506334da711eb026ba9c3548cfbebca8346628928c19e', '[\"User\"]', '2026-06-17 04:57:03', NULL, '2026-06-17 04:57:02', '2026-06-17 04:57:03'),
(66, 'App\\Models\\User', 9, 'auth_token', '674a93e231ae81dbb251cfd07b7133cad1e30c0f16bea346cc5047b026bdefda', '[\"User\"]', '2026-06-17 04:59:59', NULL, '2026-06-17 04:59:25', '2026-06-17 04:59:59'),
(68, 'App\\Models\\User', 10, 'auth_token', 'eac5b4d2325273b9498e5c13ad3bafeabfff00c411f73dc304288789cf313efa', '[\"User\"]', '2026-06-17 05:11:56', NULL, '2026-06-17 05:10:07', '2026-06-17 05:11:56'),
(70, 'App\\Models\\User', 9, 'auth_token', '063cbb67c9cefbc4880affaa0c4bc5c64f43e48abca991f34786c7125ddecc63', '[\"User\"]', '2026-06-17 20:41:50', NULL, '2026-06-17 20:41:25', '2026-06-17 20:41:50'),
(71, 'App\\Models\\User', 9, 'auth_token', 'c60dec0071c3e69be56868a2a019b53df54577da56ee97f9a8b0cb386e64eb5a', '[\"User\"]', '2026-06-17 21:13:55', NULL, '2026-06-17 21:13:05', '2026-06-17 21:13:55'),
(72, 'App\\Models\\User', 9, 'auth_token', 'cf2949b4d958de7e15003fd17198039bfe33a1762b0a39b5f6f2bf41019de591', '[\"User\"]', '2026-06-17 21:15:58', NULL, '2026-06-17 21:15:14', '2026-06-17 21:15:58'),
(73, 'App\\Models\\User', 9, 'auth_token', '39a64edef912970141d9f2bb3f458349a7bc157d0bb8b0a29fe8c35b4c5a89e6', '[\"User\"]', '2026-06-17 21:16:58', NULL, '2026-06-17 21:16:14', '2026-06-17 21:16:58'),
(75, 'App\\Models\\User', 10, 'auth_token', '2274bb63c5c492acd5e54418d3897950517f9d1ae79ec0a4f38ef1e60965f4bd', '[\"User\"]', '2026-06-17 21:21:45', NULL, '2026-06-17 21:19:45', '2026-06-17 21:21:45'),
(76, 'App\\Models\\User', 10, 'auth_token', '2c397116061bfdf6c1bc72a82a57d5b7aa5f07c28604e16706f40512d5952c5c', '[\"User\"]', '2026-06-17 21:24:40', NULL, '2026-06-17 21:22:08', '2026-06-17 21:24:40'),
(79, 'App\\Models\\User', 9, 'auth_token', '1f23e2479fd27bc33f5a7fff73070607c7857c81007c142d1429a513328664cf', '[\"User\"]', '2026-06-22 05:37:29', NULL, '2026-06-22 05:34:12', '2026-06-22 05:37:29'),
(80, 'App\\Models\\User', 9, 'auth_token', 'ca2f22369fd9adc862195fa0ca4e32e9cc8323797e96bf3208f12e7a2514d152', '[\"User\"]', '2026-06-22 05:37:50', NULL, '2026-06-22 05:37:44', '2026-06-22 05:37:50'),
(83, 'App\\Models\\User', 9, 'auth_token', '71067bf4b3542fe77c21c67d0d400e14c93f254dd3f0a3b364be121874e80cf3', '[\"User\"]', '2026-06-22 05:53:37', NULL, '2026-06-22 05:53:36', '2026-06-22 05:53:37'),
(84, 'App\\Models\\User', 9, 'auth_token', '785c4516c336ea45a05f8d78b1957a991533d3366bde2fbb824624fe77aa56ea', '[\"User\"]', '2026-06-22 05:54:12', NULL, '2026-06-22 05:54:10', '2026-06-22 05:54:12'),
(85, 'App\\Models\\User', 9, 'auth_token', 'a6b481b49a267dbd832c49975f37effda4a222e0ce8a631a8af93c10b826193f', '[\"User\"]', '2026-06-22 05:55:37', NULL, '2026-06-22 05:54:41', '2026-06-22 05:55:37'),
(91, 'App\\Models\\User', 9, 'auth_token', 'f1722548e72ee9641f3b9fada0681114a9b76af678cd1099d6f2e56c4f629eef', '[\"User\"]', '2026-06-22 06:04:23', NULL, '2026-06-22 06:04:01', '2026-06-22 06:04:23'),
(98, 'App\\Models\\User', 12, 'auth_token', '50c5793a382345f7513130fce402717b7eed4aad3941019bd8e8056df10addae', '[\"User\"]', '2026-06-22 06:38:27', NULL, '2026-06-22 06:26:12', '2026-06-22 06:38:27'),
(99, 'App\\Models\\User', 12, 'auth_token', 'd59898ef96b316d56950a533f87709f2ec73875118d8fadefb7ccd4b81fb40b5', '[\"User\"]', '2026-06-22 06:38:57', NULL, '2026-06-22 06:38:46', '2026-06-22 06:38:57'),
(102, 'App\\Models\\User', 14, 'auth_token', 'bb4d3931345e591dc076c0f3bac7a218c456692dfcfc4460724f3c5d3294d801', '[\"User\"]', '2026-06-22 07:03:57', NULL, '2026-06-22 06:56:48', '2026-06-22 07:03:57'),
(103, 'App\\Models\\User', 14, 'auth_token', '365c82fec5574c9bcd5af2faa5c68f6b12cc66a0e7ef059b690a39647fba5889', '[\"User\"]', '2026-06-22 10:48:21', NULL, '2026-06-22 07:04:31', '2026-06-22 10:48:21'),
(104, 'App\\Models\\User', 9, 'auth_token', '456c2cc8a1eab7833be74bcc737fdd2dfd8ae17e62af0c5e3847d9e88fb83d33', '[\"User\"]', '2026-06-22 23:38:39', NULL, '2026-06-22 23:32:56', '2026-06-22 23:38:39'),
(109, 'App\\Models\\User', 18, 'auth_token', 'a3b2d4cceff51f806f2e9674ff0607cfbfbfcb5c8b400e773ecd8f6852498e18', '[\"User\"]', '2026-06-23 06:39:29', NULL, '2026-06-22 23:55:40', '2026-06-23 06:39:29'),
(111, 'App\\Models\\User', 17, 'auth_token', '47f168478331257f46b851402d63abccce44672d33125c17bea27ce97c925c1f', '[\"User\"]', '2026-06-23 06:40:54', NULL, '2026-06-23 06:40:44', '2026-06-23 06:40:54'),
(113, 'App\\Models\\User', 19, 'auth_token', '0e58bbe378517886dfc30fe17afdcfcc6a84b21ac9a1eba9369f94c77ad1444a', '[\"Admin\"]', NULL, NULL, '2026-06-25 19:09:07', '2026-06-25 19:09:07'),
(116, 'App\\Models\\User', 19, 'auth_token', '5163e4c336ed21e2188e31b1ba836ac8653ac41c2c70d615f2d5efd225b4cd4c', '[\"Admin\"]', NULL, NULL, '2026-06-25 19:12:47', '2026-06-25 19:12:47'),
(118, 'App\\Models\\User', 19, 'auth_token', 'c7adabeb27070977c13ee99c8cc3069093fb4b1556443d4003d1abd60ecc5a14', '[\"Admin\"]', NULL, NULL, '2026-06-25 19:20:50', '2026-06-25 19:20:50'),
(123, 'App\\Models\\User', 20, 'auth_token', 'a4172122a0f716e4e99ceae6078618844c306e1b55a44e2004348c1fb2e4cf6e', '[\"User\"]', NULL, NULL, '2026-06-25 19:54:59', '2026-06-25 19:54:59'),
(124, 'App\\Models\\User', 21, 'auth_token', '408469388b63f3a1836891e2a016f157c37f25ea24ba88f9993f80705da6415a', '[\"User\"]', '2026-06-25 19:56:24', NULL, '2026-06-25 19:55:45', '2026-06-25 19:56:24'),
(126, 'App\\Models\\User', 22, 'auth_token', 'def64ff1828dc5753de22d8dab8898a9cf3f1eb36b0cf73fd68f1ce0f43fbd74', '[\"User\"]', NULL, NULL, '2026-06-25 20:07:29', '2026-06-25 20:07:29'),
(127, 'App\\Models\\User', 23, 'auth_token', 'e94fa94b5a0cbc2d5b93faa4ded045b75d288eead3d0964c368cf6742d742a2c', '[\"User\"]', NULL, NULL, '2026-06-25 20:16:38', '2026-06-25 20:16:38'),
(129, 'App\\Models\\User', 23, 'auth_token', 'ed5f376c10157de769b56e6cf285ee88b8ef20be6eece8e83437e8a8dfab0b21', '[\"User\"]', '2026-06-25 20:26:56', NULL, '2026-06-25 20:25:17', '2026-06-25 20:26:56'),
(131, 'App\\Models\\User', 24, 'auth_token', '2723445437968dceed81d1dea1eb7db798784ff2ee7dd194e7bade57d9b3ee4b', '[\"User\"]', NULL, NULL, '2026-06-26 17:01:42', '2026-06-26 17:01:42'),
(136, 'App\\Models\\User', 17, 'auth_token', 'b0548bd2286d96f43108379111c3aeb1b70f10022bc805036de41ba351f3481b', '[\"User\"]', '2026-06-26 17:15:40', NULL, '2026-06-26 17:15:38', '2026-06-26 17:15:40'),
(138, 'App\\Models\\User', 25, 'auth_token', 'fb83e890897d1ca743d557c850003c0c20b9289aa311edc65130554e9534f9af', '[\"User\"]', NULL, NULL, '2026-06-28 09:37:10', '2026-06-28 09:37:10'),
(139, 'App\\Models\\User', 25, 'auth_token', 'e283e4b5475a791bafd58db90a66e3f422076e0fab63cf224804d3633bf2a6d0', '[\"User\"]', NULL, NULL, '2026-06-28 09:37:10', '2026-06-28 09:37:10'),
(140, 'App\\Models\\User', 21, 'auth_token', '115984206f056840997c202da561510a603bdf4ed5050c7627a591f5e797c702', '[\"User\"]', '2026-06-28 09:39:24', NULL, '2026-06-28 09:39:22', '2026-06-28 09:39:24'),
(141, 'App\\Models\\User', 21, 'auth_token', 'f09c028fe0d35c9c3b78e6bf23a4aae9f24422433b05e737b72b8d9360030a78', '[\"User\"]', '2026-06-29 08:35:10', NULL, '2026-06-29 08:34:38', '2026-06-29 08:35:10');

-- --------------------------------------------------------

--
-- Table structure for table `roles`
--

CREATE TABLE `roles` (
  `id_role` int(11) NOT NULL,
  `nama_role` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `roles`
--

INSERT INTO `roles` (`id_role`, `nama_role`) VALUES
(1, 'Admin'),
(2, 'User');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id_user` int(11) NOT NULL,
  `id_role` int(11) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `status_akun` varchar(20) NOT NULL DEFAULT 'Active',
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id_user`, `id_role`, `email`, `password`, `status_akun`, `email_verified_at`, `created_at`, `updated_at`) VALUES
(1, 1, 'admin@mail.com', '$2y$12$7kH6Zp5sZ8KjN8V8eH8eHeuFjV7M2n8oY9vK3p.7n8u9i8o7p6q5r', 'Active', NULL, '2026-06-07 13:42:35', NULL),
(2, 2, 'user@mail.com', '$2y$12$7kH6Zp5sZ8KjN8V8eH8eHeuFjV7M2n8oY9vK3p.7n8u9i8o7p6q5r', 'Active', NULL, '2026-06-07 13:42:35', NULL),
(3, 2, 'suspend@mail.com', '$2y$12$7kH6Zp5sZ8KjN8V8eH8eHeuFjV7M2n8oY9vK3p.7n8u9i8o7p6q5r', 'Suspended', NULL, '2026-06-07 13:42:35', NULL),
(4, 2, 'user_baru@mail.com', '$2y$12$GgE3K7P6nrbapBYu18TkW.q4qHxD9kvqq3wP3wW2jBMDrNUNj7deq', 'Active', NULL, '2026-06-07 14:13:50', NULL),
(5, 2, 'user_baru2@mail.com', '$2y$12$EP4W4loF26v2O0UJTTzSauGpjABVTp43Fsc9hbreU8KGlk2F4hoUq', 'Active', NULL, '2026-06-07 14:29:08', NULL),
(6, 1, 'admin_baru@mail.com', '$2y$12$DFxW5HzIHYxNInLqHLd3gup/G.Ohj670SZwEUEkfyOsv971xTGx1a', 'Active', NULL, '2026-06-07 14:29:24', NULL),
(7, 2, 'user2@mail.com', '$2y$12$S5Np/6x63OmhBMMmNV3TCu9FtAqZKVdtd0lRWJ1K6N56uan5mXEIm', 'Active', NULL, '2026-06-14 12:19:21', NULL),
(8, 2, 'keren@mail.com', '$2y$12$XT3adoTTEQjWe7iuT5Ef8.yXom9d9HU0hLDtVz186GmVjjIEhMhKW', 'Active', NULL, '2026-06-14 14:47:21', NULL),
(9, 2, 'dummy@mail.com', '$2y$12$3gxPUWUnO.3xlNR2JOItPOjZxF1NCYsA81LQz2W97X3MvwTWgPpFS', 'Active', NULL, '2026-06-15 18:31:45', NULL),
(10, 2, 'dummy2@mail.com', '$2y$12$oAsoRb40.lsjG9UJ8u8mGeWsEnOA4Gp9b4k6QlPQoVseGVeHeJBni', 'Active', NULL, '2026-06-15 19:12:54', NULL),
(11, 2, 'dummy3@mail.com', '$2y$12$n1DXTIMKoMrgE3DuUiwIp.HtK2zfo3kuqdhtkzTVk1MeezC5gseHu', 'Active', NULL, '2026-06-15 19:16:49', NULL),
(12, 2, 'keefe@mail.com', '$2y$12$FKySYb/0DJYQroHwxdcxKOIdi.ayYbyn7b4/86cOUNky8jl7H1EHK', 'Active', NULL, '2026-06-15 19:26:19', NULL),
(13, 2, 'tesrendah1@mail.com', '$2y$12$gv1P09T7svbBbs3GxhQ7iOuuXTtq1.DLzph5fGji3KH9LbxsCIwwG', 'Active', NULL, '2026-06-15 20:09:36', NULL),
(14, 2, 'tes@mail.com', '$2y$12$sL8h4P1hu4Hckkeat.sg1.zBVnpfViYEdQWimjKtvw2hgh3aeYn/C', 'Active', NULL, '2026-06-15 20:14:41', NULL),
(15, 2, 'tesrendah2@mail.com', '$2y$12$Ob1XD16V1K2nwxUmnBl6PObEP0yYpw2VeUdtUB8T6h7A52LHSgPi.', 'Active', NULL, '2026-06-15 20:33:20', NULL),
(16, 2, 'tesdemo@mail.com', '$2y$12$e8./cssSyzopZjcBnn0iCOMdz5CBwuiQqGeKJgK8jXrGb0p5CHsUK', 'Active', NULL, '2026-06-18 04:26:29', NULL),
(17, 2, 'dummy4@mail.com', '$2y$12$jo.YmsZTBFbO7dLjzlm43etae/PjkZhk0sR58yILMcay9/PssLg9i', 'Active', NULL, '2026-06-22 12:47:12', NULL),
(18, 2, 'tesdemo2@gmail.com', '$2y$12$jslaTW2K9SGfqIYWZu9QNuGwYORGJtN45YhC0InBet/w1GGXg3sKm', 'Active', NULL, '2026-06-23 06:55:40', NULL),
(19, 1, 'admintes@mail.com', '$2y$12$q1AUhLBKadoCEfT/NasI9.GCoTG6wSqE.73p0CXejJNk.O3sXnbNu', 'Active', NULL, '2026-06-26 02:09:07', NULL),
(21, 2, 'nathanaelesmondhartono@gmail.com', '$2y$12$UNwDKkKxXUeISYCwcrD1JemKzDXUn7IS8AxtzJKDq9mHXjbzYY7xW', 'Active', NULL, '2026-06-26 02:55:45', NULL),
(22, 2, 'teserrorhandling@mail.com', '$2y$12$x2HaI0fKO3.Pdyfl1cY.pO15h.oiEvqzgzoHUIaU7j3/2.1noCqxS', 'Active', NULL, '2026-06-26 03:07:29', NULL),
(23, 2, 'nathanaelesmond13@gmail.com', '$2y$12$vryAsiaOJb2Gca0ND62mpuKo149.waEFXtj4wcukx/3apk2f9viaq', 'Active', '2026-06-25 20:34:40', '2026-06-26 03:16:35', NULL),
(24, 2, 'aliang334chen@gmail.com', '$2y$12$.8QgJrUXFXf3B095KalHyerBuuMoqZikffMhaAS3RTb8XX2R9qOv6', 'Active', '2026-06-26 17:02:13', '2026-06-27 00:01:35', NULL),
(25, 2, 'tes@gmail.com', '$2y$12$3aBqTnzEw0IgALOe1NZaCOUZl9jPeP4gdM.OVkWm/eezq6PMrx/wS', 'Active', NULL, '2026-06-28 16:37:04', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `user_equipments`
--

CREATE TABLE `user_equipments` (
  `id_user_equipment` int(11) NOT NULL,
  `id_user` int(11) NOT NULL,
  `nama_alat` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `user_equipments`
--

INSERT INTO `user_equipments` (`id_user_equipment`, `id_user`, `nama_alat`) VALUES
(1, 7, 'Full Gym'),
(2, 7, 'Dumbbells'),
(36, 8, 'Dumbbell'),
(37, 8, 'Machine'),
(38, 8, 'Barbell'),
(42, 12, 'Full Gym'),
(43, 13, 'Full Gym'),
(45, 15, 'Full Gym'),
(48, 16, 'Full Gym'),
(62, 10, 'Body Only'),
(63, 11, 'Full Gym'),
(64, 17, 'Dumbbell'),
(76, 9, 'Dumbbell'),
(77, 9, 'Barbell'),
(78, 14, 'Dumbbell'),
(79, 14, 'Barbell'),
(80, 14, 'Cable'),
(84, 18, 'Full Gym'),
(85, 18, 'Dumbbells'),
(86, 18, 'Barbell'),
(87, 21, 'Full Gym'),
(88, 23, 'Full Gym'),
(89, 24, 'Full Gym');

-- --------------------------------------------------------

--
-- Table structure for table `user_profiles`
--

CREATE TABLE `user_profiles` (
  `id_profile` int(11) NOT NULL,
  `id_user` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `usia` int(11) NOT NULL,
  `gender` varchar(50) NOT NULL,
  `tinggi_badan` double NOT NULL,
  `berat_badan` double NOT NULL,
  `fitness_level` varchar(100) NOT NULL,
  `gym_membership` varchar(50) NOT NULL,
  `target_kesehatan` varchar(255) NOT NULL,
  `target_calorie` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `user_profiles`
--

INSERT INTO `user_profiles` (`id_profile`, `id_user`, `name`, `usia`, `gender`, `tinggi_badan`, `berat_badan`, `fitness_level`, `gym_membership`, `target_kesehatan`, `target_calorie`) VALUES
(1, 7, 'Alex Johnson', 22, 'Male', 178, 72.3, 'Intermediate', 'Yes', 'Build Muscle', NULL),
(2, 8, 'keren jones2', 22, 'Male', 146, 66, 'Beginner', 'Yes', 'Improve Endurance', NULL),
(6, 12, 'keefe ', 22, 'Male', 174, 78, 'Beginner', 'Yes', 'Build Muscle', NULL),
(7, 13, 'tesrendah1', 23, 'Male', 178, 78, 'Intermediate', 'Yes', 'Build Muscle', NULL),
(9, 15, 'tesrendah', 25, 'Male', 157, 66, 'Intermediate', 'Yes', 'Build Muscle', NULL),
(10, 16, 'tes demo2', 22, 'Male', 170, 60, 'Intermediate', 'Yes', 'Build Muscle', NULL),
(20, 9, 'Budi Vigor', 24, 'Male', 175, 70.5, 'Intermediate', 'Yes', 'Build Muscle', NULL),
(21, 10, 'Siti Akut Stres', 22, 'Female', 160, 55, 'Beginner', 'No', 'Stay Active', NULL),
(22, 11, 'Iwan Kronis Lelah', 29, 'Male', 182, 80.2, 'Advanced', 'Yes', 'Improve Endurance', NULL),
(23, 17, 'Dewi Burnout Total', 27, 'Female', 165, 65, 'Intermediate', 'Yes', 'Lose Weight', NULL),
(26, 14, 'Kevin Testing', 25, 'Male', 178, 74.2, 'Intermediate', 'Yes', 'Build Muscle', NULL),
(27, 18, 'tesdemo 2', 22, 'Male', 170, 78, 'Beginner', 'Yes', 'Improve Endurance', NULL),
(28, 4, 'tesactibve', 0, 'Not Set', 0, 0, 'Beginner', 'No', 'Not Set', NULL),
(29, 21, 'Nathanael Esmond Hartono', 22, 'Male', 173, 95, 'Intermediate', 'Yes', 'Lose Weight', NULL),
(30, 23, 'xeno', 22, 'Male', 245, 134, 'Intermediate', 'Yes', 'Build Muscle', NULL),
(31, 24, 'Christopher William', 21, 'Male', 170, 67, 'Intermediate', 'Yes', 'Build Muscle', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `workouts`
--

CREATE TABLE `workouts` (
  `id_workout` int(11) NOT NULL,
  `nama_latihan` varchar(100) NOT NULL,
  `kategori` varchar(50) NOT NULL,
  `intensitas_dasar` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `workout_sessions`
--

CREATE TABLE `workout_sessions` (
  `id_session` int(11) NOT NULL,
  `id_user` int(11) NOT NULL,
  `session_name` varchar(100) NOT NULL,
  `status` enum('pending','completed','skipped') DEFAULT 'pending',
  `log_date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `workout_sessions`
--

INSERT INTO `workout_sessions` (`id_session`, `id_user`, `session_name`, `status`, `log_date`, `created_at`) VALUES
(136, 12, 'Push Day', 'pending', '2026-06-15', '2026-06-15 19:26:56'),
(137, 13, 'Push Day', 'skipped', '2026-06-15', '2026-06-15 20:10:13'),
(138, 13, 'Push Day', 'pending', '2026-06-16', '2026-06-15 20:14:13'),
(139, 14, 'Push Day', 'pending', '2026-06-15', '2026-06-15 20:15:08'),
(140, 15, 'Push Day', 'completed', '2026-06-15', '2026-06-15 20:33:45'),
(141, 13, 'Pull Day', 'completed', '2026-06-16', '2026-06-16 06:03:15'),
(142, 13, 'Recovery Flexibility Day', 'completed', '2026-06-16', '2026-06-16 06:04:30'),
(146, 8, 'Push Day', 'completed', '2026-06-17', '2026-06-17 12:08:07'),
(150, 13, 'Recovery Flexibility Day', 'skipped', '2026-06-17', '2026-06-17 12:12:16'),
(151, 13, 'Recovery Flexibility Day', 'pending', '2026-06-18', '2026-06-17 12:12:20'),
(152, 13, 'Recovery Flexibility Day', 'skipped', '2026-06-17', '2026-06-17 12:12:26'),
(153, 13, 'Recovery Flexibility Day', 'pending', '2026-06-18', '2026-06-17 12:12:28'),
(154, 13, 'Recovery Flexibility Day', 'skipped', '2026-06-17', '2026-06-17 12:12:35'),
(155, 13, 'Recovery Flexibility Day', 'pending', '2026-06-18', '2026-06-17 12:12:36'),
(156, 9, 'Pull Day', 'completed', '2026-06-17', '2026-06-18 03:41:06'),
(157, 9, 'Legs Day', 'completed', '2026-06-16', '2026-06-18 03:41:06'),
(158, 9, 'Core & Cardio Day', 'completed', '2026-06-15', '2026-06-18 03:41:06'),
(159, 9, 'Core & Cardio Day', 'completed', '2026-06-11', '2026-06-18 03:41:06'),
(160, 9, 'Push Day', 'completed', '2026-06-10', '2026-06-18 03:41:06'),
(161, 9, 'Pull Day', 'completed', '2026-06-09', '2026-06-18 03:41:06'),
(162, 9, 'Legs Day', 'completed', '2026-06-08', '2026-06-18 03:41:06'),
(163, 9, 'Legs Day', 'completed', '2026-06-04', '2026-06-18 03:41:06'),
(164, 9, 'Core & Cardio Day', 'skipped', '2026-06-03', '2026-06-18 03:41:06'),
(165, 9, 'Push Day', 'completed', '2026-06-02', '2026-06-18 03:41:06'),
(166, 9, 'Pull Day', 'completed', '2026-06-01', '2026-06-18 03:41:06'),
(167, 9, 'Pull Day', 'completed', '2026-05-28', '2026-06-18 03:41:06'),
(168, 9, 'Legs Day', 'completed', '2026-05-27', '2026-06-18 03:41:06'),
(169, 9, 'Core & Cardio Day', 'skipped', '2026-05-26', '2026-06-18 03:41:06'),
(170, 9, 'Push Day', 'completed', '2026-05-25', '2026-06-18 03:41:06'),
(171, 9, 'Push Day', 'completed', '2026-05-21', '2026-06-18 03:41:06'),
(172, 9, 'Pull Day', 'completed', '2026-05-20', '2026-06-18 03:41:06'),
(173, 9, 'Legs Day', 'completed', '2026-05-19', '2026-06-18 03:41:06'),
(174, 9, 'Core & Cardio Day', 'skipped', '2026-05-18', '2026-06-18 03:41:06'),
(175, 9, 'Core & Cardio Day', 'skipped', '2026-05-14', '2026-06-18 03:41:06'),
(176, 9, 'Push Day', 'skipped', '2026-05-13', '2026-06-18 03:41:06'),
(177, 9, 'Pull Day', 'completed', '2026-05-12', '2026-06-18 03:41:06'),
(178, 9, 'Legs Day', 'completed', '2026-05-11', '2026-06-18 03:41:06'),
(179, 9, 'Legs Day', 'completed', '2026-05-07', '2026-06-18 03:41:06'),
(180, 9, 'Core & Cardio Day', 'completed', '2026-05-06', '2026-06-18 03:41:06'),
(181, 9, 'Push Day', 'completed', '2026-05-05', '2026-06-18 03:41:06'),
(182, 9, 'Pull Day', 'completed', '2026-05-04', '2026-06-18 03:41:06'),
(183, 9, 'Pull Day', 'completed', '2026-04-30', '2026-06-18 03:41:06'),
(184, 10, 'Pull Day', 'skipped', '2026-06-17', '2026-06-18 03:41:06'),
(185, 10, 'Legs Day', 'completed', '2026-06-16', '2026-06-18 03:41:06'),
(186, 10, 'Core & Cardio Day', 'skipped', '2026-06-15', '2026-06-18 03:41:06'),
(187, 10, 'Core & Cardio Day', 'completed', '2026-06-11', '2026-06-18 03:41:06'),
(188, 10, 'Push Day', 'completed', '2026-06-10', '2026-06-18 03:41:06'),
(189, 10, 'Pull Day', 'completed', '2026-06-09', '2026-06-18 03:41:06'),
(190, 10, 'Legs Day', 'completed', '2026-06-08', '2026-06-18 03:41:06'),
(191, 10, 'Legs Day', 'completed', '2026-06-04', '2026-06-18 03:41:06'),
(192, 10, 'Core & Cardio Day', 'completed', '2026-06-03', '2026-06-18 03:41:06'),
(193, 10, 'Push Day', 'completed', '2026-06-02', '2026-06-18 03:41:06'),
(194, 10, 'Pull Day', 'completed', '2026-06-01', '2026-06-18 03:41:06'),
(195, 10, 'Pull Day', 'completed', '2026-05-28', '2026-06-18 03:41:06'),
(196, 10, 'Legs Day', 'completed', '2026-05-27', '2026-06-18 03:41:06'),
(197, 10, 'Core & Cardio Day', 'skipped', '2026-05-26', '2026-06-18 03:41:06'),
(198, 10, 'Push Day', 'completed', '2026-05-25', '2026-06-18 03:41:06'),
(199, 10, 'Push Day', 'completed', '2026-05-21', '2026-06-18 03:41:06'),
(200, 10, 'Pull Day', 'completed', '2026-05-20', '2026-06-18 03:41:06'),
(201, 10, 'Legs Day', 'completed', '2026-05-19', '2026-06-18 03:41:06'),
(202, 10, 'Core & Cardio Day', 'completed', '2026-05-18', '2026-06-18 03:41:06'),
(203, 10, 'Core & Cardio Day', 'completed', '2026-05-14', '2026-06-18 03:41:06'),
(204, 10, 'Push Day', 'completed', '2026-05-13', '2026-06-18 03:41:06'),
(205, 10, 'Pull Day', 'completed', '2026-05-12', '2026-06-18 03:41:06'),
(206, 10, 'Legs Day', 'completed', '2026-05-11', '2026-06-18 03:41:06'),
(207, 10, 'Legs Day', 'skipped', '2026-05-07', '2026-06-18 03:41:06'),
(208, 10, 'Core & Cardio Day', 'skipped', '2026-05-06', '2026-06-18 03:41:06'),
(209, 10, 'Push Day', 'skipped', '2026-05-05', '2026-06-18 03:41:06'),
(210, 10, 'Pull Day', 'completed', '2026-05-04', '2026-06-18 03:41:06'),
(211, 10, 'Pull Day', 'skipped', '2026-04-30', '2026-06-18 03:41:06'),
(212, 11, 'Pull Day', 'completed', '2026-06-17', '2026-06-18 03:41:06'),
(213, 11, 'Legs Day', 'skipped', '2026-06-16', '2026-06-18 03:41:06'),
(214, 11, 'Core & Cardio Day', 'completed', '2026-06-15', '2026-06-18 03:41:06'),
(215, 11, 'Core & Cardio Day', 'completed', '2026-06-11', '2026-06-18 03:41:06'),
(216, 11, 'Push Day', 'completed', '2026-06-10', '2026-06-18 03:41:06'),
(217, 11, 'Pull Day', 'completed', '2026-06-09', '2026-06-18 03:41:06'),
(218, 11, 'Legs Day', 'skipped', '2026-06-08', '2026-06-18 03:41:06'),
(219, 11, 'Legs Day', 'completed', '2026-06-04', '2026-06-18 03:41:06'),
(220, 11, 'Core & Cardio Day', 'completed', '2026-06-03', '2026-06-18 03:41:06'),
(221, 11, 'Push Day', 'completed', '2026-06-02', '2026-06-18 03:41:06'),
(222, 11, 'Pull Day', 'completed', '2026-06-01', '2026-06-18 03:41:06'),
(223, 11, 'Pull Day', 'completed', '2026-05-28', '2026-06-18 03:41:06'),
(224, 11, 'Legs Day', 'skipped', '2026-05-27', '2026-06-18 03:41:06'),
(225, 11, 'Core & Cardio Day', 'completed', '2026-05-26', '2026-06-18 03:41:06'),
(226, 11, 'Push Day', 'completed', '2026-05-25', '2026-06-18 03:41:06'),
(227, 11, 'Push Day', 'completed', '2026-05-21', '2026-06-18 03:41:06'),
(228, 11, 'Pull Day', 'completed', '2026-05-20', '2026-06-18 03:41:06'),
(229, 11, 'Legs Day', 'completed', '2026-05-19', '2026-06-18 03:41:06'),
(230, 11, 'Core & Cardio Day', 'completed', '2026-05-18', '2026-06-18 03:41:06'),
(231, 11, 'Core & Cardio Day', 'skipped', '2026-05-14', '2026-06-18 03:41:06'),
(232, 11, 'Push Day', 'completed', '2026-05-13', '2026-06-18 03:41:06'),
(233, 11, 'Pull Day', 'completed', '2026-05-12', '2026-06-18 03:41:06'),
(234, 11, 'Legs Day', 'skipped', '2026-05-11', '2026-06-18 03:41:06'),
(235, 11, 'Legs Day', 'completed', '2026-05-07', '2026-06-18 03:41:06'),
(236, 11, 'Core & Cardio Day', 'skipped', '2026-05-06', '2026-06-18 03:41:06'),
(237, 11, 'Push Day', 'completed', '2026-05-05', '2026-06-18 03:41:06'),
(238, 11, 'Pull Day', 'completed', '2026-05-04', '2026-06-18 03:41:06'),
(239, 11, 'Pull Day', 'completed', '2026-04-30', '2026-06-18 03:41:06'),
(240, 9, 'Legs Day', 'completed', '2026-06-18', '2026-06-18 03:41:41'),
(241, 9, 'Core & Cardio Day', 'pending', '2026-06-18', '2026-06-18 04:15:22'),
(242, 9, 'Core & Cardio Day', 'pending', '2026-06-18', '2026-06-18 04:16:17'),
(243, 13, 'Recovery Flexibility Day', 'completed', '2026-06-18', '2026-06-18 04:17:37'),
(244, 10, 'Legs Day', 'pending', '2026-06-18', '2026-06-18 04:21:47'),
(245, 10, 'Legs Day', 'completed', '2026-06-18', '2026-06-18 04:22:11'),
(246, 10, 'Core & Cardio Day', 'completed', '2026-06-18', '2026-06-18 04:25:03'),
(247, 9, 'Core & Cardio Day', 'skipped', '2026-06-22', '2026-06-22 12:34:26'),
(248, 9, 'Core & Cardio Day', 'pending', '2026-06-23', '2026-06-22 12:34:59'),
(249, 9, 'Push Day', 'completed', '2026-06-22', '2026-06-22 12:37:18'),
(250, 9, 'Pull Day', 'skipped', '2026-06-22', '2026-06-22 12:37:47'),
(251, 9, 'Pull Day', 'pending', '2026-06-23', '2026-06-22 12:37:50'),
(252, 9, 'Legs Day', 'pending', '2026-06-22', '2026-06-22 12:54:43'),
(253, 10, 'Push Day', 'completed', '2026-06-22', '2026-06-22 12:56:14'),
(254, 9, 'Legs Day', 'completed', '2026-06-22', '2026-06-22 13:04:50'),
(255, 9, 'Core & Cardio Day', 'pending', '2026-06-22', '2026-06-22 13:05:17'),
(256, 10, 'Pull Day', 'pending', '2026-06-22', '2026-06-22 13:05:33'),
(257, 11, 'Active Recovery & De-load', 'completed', '2026-06-22', '2026-06-22 13:06:06'),
(258, 11, 'Active Recovery & De-load', 'completed', '2026-06-22', '2026-06-22 13:06:33'),
(259, 17, 'Rest & Deep Recovery Day', 'pending', '2026-06-22', '2026-06-22 13:07:19'),
(260, 9, 'Core & Cardio Day', 'completed', '2026-06-23', '2026-06-23 06:47:47'),
(261, 17, 'Rest & Deep Recovery Day', 'completed', '2026-06-23', '2026-06-23 06:50:05'),
(262, 18, 'Push Day', 'pending', '2026-06-23', '2026-06-23 13:39:29'),
(263, 18, 'Push Day', 'pending', '2026-06-23', '2026-06-23 13:39:30'),
(264, 9, 'Push Day', 'pending', '2026-06-23', '2026-06-23 13:40:30'),
(265, 17, 'Rest & Deep Recovery Day', 'pending', '2026-06-23', '2026-06-23 13:40:47'),
(266, 9, 'Push Day', 'pending', '2026-06-27', '2026-06-27 00:11:51'),
(267, 10, 'Pull Day', 'pending', '2026-06-27', '2026-06-27 00:13:15'),
(268, 11, 'Active Recovery & De-load', 'pending', '2026-06-27', '2026-06-27 00:14:03'),
(269, 17, 'Rest & Deep Recovery Day', 'pending', '2026-06-27', '2026-06-27 00:15:40');

-- --------------------------------------------------------

--
-- Table structure for table `workout_session_exercises`
--

CREATE TABLE `workout_session_exercises` (
  `id_session_exercise` int(11) NOT NULL,
  `id_session` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `body_part` varchar(100) NOT NULL,
  `equipment` varchar(100) NOT NULL,
  `level` varchar(50) NOT NULL,
  `is_done` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `workout_session_exercises`
--

INSERT INTO `workout_session_exercises` (`id_session_exercise`, `id_session`, `title`, `body_part`, `equipment`, `level`, `is_done`) VALUES
(337, 139, 'incline cable chest fly', 'chest', 'cable', 'intermediate', 0),
(338, 139, 'cable crossover', 'chest', 'cable', 'intermediate', 0),
(339, 139, 'single-arm palm-in dumbbell shoulder press', 'shoulders', 'dumbbell', 'intermediate', 0),
(340, 139, 'standing palms-in shoulder press', 'shoulders', 'dumbbell', 'intermediate', 0),
(341, 139, 'reverse grip triceps pushdown', 'triceps', 'cable', 'intermediate', 0),
(342, 139, 'kneeling cable triceps extension', 'triceps', 'cable', 'intermediate', 0),
(343, 140, 'dumbbell flyes', 'chest', 'dumbbell', 'intermediate', 0),
(344, 140, 'incline dumbbell bench press', 'chest', 'dumbbell', 'intermediate', 0),
(345, 140, 'military press', 'shoulders', 'barbell', 'intermediate', 0),
(346, 140, 'seated barbell shoulder press', 'shoulders', 'barbell', 'intermediate', 0),
(347, 140, 'ez-bar skullcrusher', 'triceps', 'e-z curl bar', 'intermediate', 0),
(348, 140, 'ez-bar skullcrusher-', 'triceps', 'e-z curl bar', 'intermediate', 0),
(349, 141, 'shotgun row', 'lats', 'cable', 'intermediate', 0),
(350, 141, 'seated cable rows', 'middle back', 'cable', 'intermediate', 0),
(351, 141, 'concentration curl', 'biceps', 'dumbbell', 'intermediate', 0),
(352, 141, 'cable shrug', 'traps', 'cable', 'intermediate', 0),
(367, 146, 'leverage chest press', 'chest', 'machine', 'beginner', 0),
(368, 146, 'decline smith press', 'chest', 'machine', 'beginner', 0),
(369, 146, 'dumbbell raise', 'shoulders', 'dumbbell', 'beginner', 0),
(370, 146, 'reverse flyes with external rotation', 'shoulders', 'dumbbell', 'beginner', 0),
(371, 146, 'one arm pronated dumbbell triceps extension', 'triceps', 'dumbbell', 'beginner', 0),
(372, 146, 'one arm supinated dumbbell triceps extension', 'triceps', 'dumbbell', 'beginner', 0),
(389, 156, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(390, 156, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(391, 157, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(392, 157, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(393, 158, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(394, 158, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(395, 159, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(396, 159, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(397, 160, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(398, 160, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(399, 161, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(400, 161, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(401, 162, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(402, 162, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(403, 163, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(404, 163, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(405, 164, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(406, 164, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(407, 165, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(408, 165, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(409, 166, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(410, 166, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(411, 167, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(412, 167, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(413, 168, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(414, 168, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(415, 169, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(416, 169, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(417, 170, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(418, 170, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(419, 171, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(420, 171, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(421, 172, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(422, 172, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(423, 173, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(424, 173, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(425, 174, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(426, 174, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(427, 175, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(428, 175, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(429, 176, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(430, 176, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(431, 177, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(432, 177, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(433, 178, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(434, 178, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(435, 179, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(436, 179, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(437, 180, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(438, 180, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(439, 181, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(440, 181, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(441, 182, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(442, 182, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(443, 183, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(444, 183, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(445, 184, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(446, 184, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(447, 185, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(448, 185, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(449, 186, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(450, 186, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(451, 187, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(452, 187, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(453, 188, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(454, 188, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(455, 189, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(456, 189, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(457, 190, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(458, 190, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(459, 191, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(460, 191, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(461, 192, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(462, 192, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(463, 193, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(464, 193, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(465, 194, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(466, 194, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(467, 195, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(468, 195, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(469, 196, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(470, 196, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(471, 197, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(472, 197, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(473, 198, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(474, 198, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(475, 199, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(476, 199, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(477, 200, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(478, 200, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(479, 201, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(480, 201, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(481, 202, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(482, 202, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(483, 203, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(484, 203, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(485, 204, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(486, 204, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(487, 205, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(488, 205, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(489, 206, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(490, 206, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(491, 207, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(492, 207, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(493, 208, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(494, 208, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(495, 209, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(496, 209, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(497, 210, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(498, 210, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(499, 211, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(500, 211, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(501, 212, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(502, 212, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(503, 213, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(504, 213, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(505, 214, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(506, 214, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(507, 215, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(508, 215, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(509, 216, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(510, 216, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(511, 217, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(512, 217, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(513, 218, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(514, 218, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(515, 219, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(516, 219, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(517, 220, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(518, 220, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(519, 221, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(520, 221, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(521, 222, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(522, 222, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(523, 223, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(524, 223, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(525, 224, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(526, 224, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(527, 225, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(528, 225, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(529, 226, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(530, 226, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(531, 227, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(532, 227, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(533, 228, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(534, 228, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(535, 229, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(536, 229, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(537, 230, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(538, 230, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(539, 231, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(540, 231, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(541, 232, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(542, 232, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(543, 233, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(544, 233, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(545, 234, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(546, 234, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(547, 235, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(548, 235, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(549, 236, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(550, 236, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(551, 237, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(552, 237, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(553, 238, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(554, 238, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(555, 239, 'Dumbbell Press', 'Chest', 'Dumbbell', 'Intermediate', 1),
(556, 239, 'Cable Row', 'Middle Back', 'Cable', 'Intermediate', 1),
(557, 240, 'leg press', 'quadriceps', 'machine', 'intermediate', 0),
(558, 240, 'lying leg curl - gethin variation', 'hamstrings', 'machine', 'intermediate', 0),
(559, 240, 'cable rope pull-through deadlift', 'glutes', 'cable', 'intermediate', 0),
(560, 240, 'seated calf raise', 'calves', 'machine', 'intermediate', 0),
(561, 241, 'single-arm high-cable side bend', 'abdominals', 'cable', 'intermediate', 0),
(562, 241, 'kneeling cable oblique crunch', 'abdominals', 'cable', 'intermediate', 0),
(563, 241, 'kneeling cable crunch', 'abdominals', 'cable', 'intermediate', 0),
(564, 241, 'dumbbell skier', 'lower back', 'dumbbell', 'intermediate', 0),
(565, 241, 'tbs dumbbell romanian deadlift', 'lower back', 'dumbbell', 'intermediate', 0),
(566, 241, 'stiff-legged dumbbell deadlift - gethin variation', 'lower back', 'dumbbell', 'intermediate', 0),
(567, 242, 'bottoms up', 'abdominals', 'body only', 'intermediate', 0),
(568, 242, 'spider crawl', 'abdominals', 'body only', 'intermediate', 0),
(569, 242, 'cocoons', 'abdominals', 'body only', 'intermediate', 0),
(570, 242, 'tbs back extension', 'lower back', 'body only', 'intermediate', 0),
(571, 242, 'lower back stretch - yates variation', 'lower back', 'body only', 'intermediate', 0),
(572, 242, 'hyperextension - gethin variation', 'lower back', 'body only', 'intermediate', 0),
(573, 244, 'leg press', 'quadriceps', 'machine', 'intermediate', 0),
(574, 244, 'lying leg curl - gethin variation', 'hamstrings', 'machine', 'intermediate', 0),
(575, 244, 'single-arm triceps kick-back', 'glutes', 'dumbbell', 'intermediate', 0),
(576, 244, 'seated calf raise', 'calves', 'machine', 'intermediate', 0),
(577, 245, 'leg press', 'quadriceps', 'machine', 'intermediate', 1),
(578, 245, 'lying leg curl - gethin variation', 'hamstrings', 'machine', 'intermediate', 0),
(579, 245, 'single-arm triceps kick-back', 'glutes', 'dumbbell', 'intermediate', 0),
(580, 245, 'seated calf raise', 'calves', 'machine', 'intermediate', 0),
(581, 246, 'dumbbell side bend', 'abdominals', 'dumbbell', 'intermediate', 0),
(582, 246, 'dumbbell crunch', 'abdominals', 'dumbbell', 'intermediate', 0),
(583, 246, 'dumbbell fix dumbbell sprawl', 'abdominals', 'dumbbell', 'intermediate', 0),
(584, 246, 'seated cable deadlift', 'lower back', 'cable', 'intermediate', 0),
(585, 246, 'cable stiff-legged deadlift', 'lower back', 'cable', 'intermediate', 0),
(586, 246, 'single-leg cable stiff-legged deadlift', 'lower back', 'cable', 'intermediate', 0),
(587, 247, 'bottoms up', 'abdominals', 'body only', 'intermediate', 0),
(588, 247, 'spider crawl', 'abdominals', 'body only', 'intermediate', 0),
(589, 247, 'cocoons', 'abdominals', 'body only', 'intermediate', 0),
(590, 247, 'tbs back extension', 'lower back', 'body only', 'intermediate', 0),
(591, 247, 'lower back stretch - yates variation', 'lower back', 'body only', 'intermediate', 0),
(592, 247, 'hyperextension - gethin variation', 'lower back', 'body only', 'intermediate', 0),
(593, 248, 'bottoms up', 'abdominals', 'body only', 'intermediate', 0),
(594, 248, 'spider crawl', 'abdominals', 'body only', 'intermediate', 0),
(595, 248, 'cocoons', 'abdominals', 'body only', 'intermediate', 0),
(596, 248, 'tbs back extension', 'lower back', 'body only', 'intermediate', 0),
(597, 248, 'lower back stretch - yates variation', 'lower back', 'body only', 'intermediate', 0),
(598, 248, 'hyperextension - gethin variation', 'lower back', 'body only', 'intermediate', 0),
(599, 249, 'incline push-up', 'chest', 'body only', 'intermediate', 0),
(600, 249, 'decline push-up', 'chest', 'body only', 'intermediate', 1),
(601, 249, 'hand stand push-up', 'shoulders', 'body only', 'intermediate', 1),
(602, 249, 'wall walk', 'shoulders', 'body only', 'intermediate', 0),
(603, 249, 'weighted bench dip', 'triceps', 'body only', 'intermediate', 0),
(604, 249, 'push-ups - close triceps position', 'triceps', 'body only', 'intermediate', 0),
(605, 250, 'muscle up', 'lats', 'body only', 'intermediate', 0),
(606, 250, 'tbs pull-up', 'middle back', 'body only', 'intermediate', 0),
(607, 250, 'pull-up - gethin variation', 'biceps', 'body only', 'intermediate', 1),
(608, 250, 'band seated row', 'traps', 'bands', 'intermediate', 1),
(609, 251, 'muscle up', 'lats', 'body only', 'intermediate', 0),
(610, 251, 'tbs pull-up', 'middle back', 'body only', 'intermediate', 0),
(611, 251, 'pull-up - gethin variation', 'biceps', 'body only', 'intermediate', 0),
(612, 251, 'band seated row', 'traps', 'bands', 'intermediate', 0),
(613, 252, 'dumbbell squat', 'quadriceps', 'dumbbell', 'intermediate', 0),
(614, 252, 'power clean', 'hamstrings', 'barbell', 'intermediate', 0),
(615, 252, 'holman lateral high knees to quad touch jump', 'glutes', 'dumbbell', 'intermediate', 0),
(616, 252, 'single-leg standing dumbbell calf raise', 'calves', 'dumbbell', 'intermediate', 0),
(617, 253, 'single-arm push-up', 'chest', 'body only', 'beginner', 0),
(618, 253, 'wide-grip hands-elevated push-up', 'chest', 'body only', 'beginner', 0),
(619, 253, 'hand stand push-up', 'shoulders', 'body only', 'intermediate', 0),
(620, 253, 'wall walk', 'shoulders', 'body only', 'intermediate', 0),
(621, 253, 'triceps dip', 'triceps', 'body only', 'intermediate', 0),
(622, 253, 'weighted bench dip', 'triceps', 'body only', 'intermediate', 0),
(623, 254, 'dumbbell squat', 'quadriceps', 'dumbbell', 'intermediate', 1),
(624, 254, 'dumbbell fix dumbbell swing', 'hamstrings', 'dumbbell', 'intermediate', 1),
(625, 254, 'holman lateral high knees to quad touch jump', 'glutes', 'dumbbell', 'intermediate', 1),
(626, 254, 'single-leg standing dumbbell calf raise', 'calves', 'dumbbell', 'intermediate', 1),
(627, 255, 'dumbbell side bend', 'abdominals', 'dumbbell', 'intermediate', 0),
(628, 255, 'dumbbell crunch', 'abdominals', 'dumbbell', 'intermediate', 0),
(629, 255, 'dumbbell fix dumbbell sprawl', 'abdominals', 'dumbbell', 'intermediate', 0),
(630, 255, 'dumbbell skier', 'lower back', 'dumbbell', 'intermediate', 0),
(631, 255, 'tbs dumbbell romanian deadlift', 'lower back', 'dumbbell', 'intermediate', 0),
(632, 255, 'stiff-legged dumbbell deadlift - gethin variation', 'lower back', 'dumbbell', 'intermediate', 0),
(633, 256, 'wide-grip rear pull-up', 'lats', 'body only', 'beginner', 0),
(634, 256, 'tbs pull-up', 'middle back', 'body only', 'intermediate', 0),
(635, 256, 'tbs chin-up', 'biceps', 'body only', 'intermediate', 0),
(636, 256, 'band seated row', 'traps', 'bands', 'intermediate', 0),
(637, 257, 'cable reverse crunch', 'abdominals', 'cable', 'beginner', 1),
(638, 257, 'cable russian twists', 'abdominals', 'cable', 'beginner', 1),
(639, 257, 'cable seated crunch', 'abdominals', 'cable', 'beginner', 1),
(640, 258, 'cable reverse crunch', 'abdominals', 'cable', 'beginner', 0),
(641, 258, 'cable russian twists', 'abdominals', 'cable', 'beginner', 0),
(642, 258, 'cable seated crunch', 'abdominals', 'cable', 'beginner', 0),
(643, 260, 'barbell ab rollout - on knees', 'abdominals', 'barbell', 'intermediate', 1),
(644, 260, 'decline bar press sit-up', 'abdominals', 'barbell', 'intermediate', 1),
(645, 260, 'seated bar twist', 'abdominals', 'barbell', 'intermediate', 1),
(646, 260, 'tbs good morning', 'lower back', 'barbell', 'intermediate', 1),
(647, 260, 'tbs romanian deadlift', 'lower back', 'barbell', 'intermediate', 0),
(648, 260, 'barbell deadlift-', 'lower back', 'barbell', 'intermediate', 0),
(649, 262, 'wide-grip decline barbell bench press', 'chest', 'barbell', 'beginner', 0),
(650, 262, 'neck press', 'chest', 'barbell', 'beginner', 0),
(651, 262, 'bradford/rocky presses', 'shoulders', 'barbell', 'beginner', 0),
(652, 262, 'smith incline shoulder raise', 'shoulders', 'barbell', 'beginner', 0),
(653, 262, 'one arm pronated dumbbell triceps extension', 'triceps', 'dumbbell', 'beginner', 0),
(654, 262, 'one arm supinated dumbbell triceps extension', 'triceps', 'dumbbell', 'beginner', 0),
(655, 263, 'hammer grip incline db bench press', 'chest', 'dumbbell', 'beginner', 0),
(656, 263, 'incline dumbbell bench with palms facing in', 'chest', 'dumbbell', 'beginner', 0),
(657, 263, 'dumbbell raise', 'shoulders', 'dumbbell', 'beginner', 0),
(658, 263, 'reverse flyes with external rotation', 'shoulders', 'dumbbell', 'beginner', 0),
(659, 263, 'decline ez-bar skullcrusher', 'triceps', 'e-z curl bar', 'intermediate', 0),
(660, 263, 'ez-bar skullcrusher', 'triceps', 'e-z curl bar', 'intermediate', 0),
(661, 264, 'dumbbell flyes', 'chest', 'dumbbell', 'intermediate', 0),
(662, 264, 'incline dumbbell bench press', 'chest', 'dumbbell', 'intermediate', 0),
(663, 264, 'single-arm palm-in dumbbell shoulder press', 'shoulders', 'dumbbell', 'intermediate', 0),
(664, 264, 'standing palms-in shoulder press', 'shoulders', 'dumbbell', 'intermediate', 0),
(665, 264, 'tricep dumbbell kickback', 'triceps', 'dumbbell', 'intermediate', 0),
(666, 264, 'standing dumbbell triceps extension', 'triceps', 'dumbbell', 'intermediate', 0),
(667, 266, 'dumbbell flyes', 'chest', 'dumbbell', 'intermediate', 0),
(668, 266, 'incline dumbbell bench press', 'chest', 'dumbbell', 'intermediate', 0),
(669, 266, 'single-arm palm-in dumbbell shoulder press', 'shoulders', 'dumbbell', 'intermediate', 0),
(670, 266, 'standing palms-in shoulder press', 'shoulders', 'dumbbell', 'intermediate', 0),
(671, 266, 'tricep dumbbell kickback', 'triceps', 'dumbbell', 'intermediate', 0),
(672, 266, 'standing dumbbell triceps extension', 'triceps', 'dumbbell', 'intermediate', 0),
(673, 267, 'wide-grip rear pull-up', 'lats', 'body only', 'beginner', 0),
(674, 267, 'tbs pull-up', 'middle back', 'body only', 'intermediate', 0),
(675, 267, 'tbs chin-up', 'biceps', 'body only', 'intermediate', 0),
(676, 267, 'band seated row', 'traps', 'bands', 'intermediate', 0),
(677, 268, 'barbell side bend', 'abdominals', 'barbell', 'beginner', 0),
(678, 268, 'barbell roll-out', 'abdominals', 'barbell', 'intermediate', 0),
(679, 268, 'barbell ab rollout - on knees', 'abdominals', 'barbell', 'intermediate', 0);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `cache`
--
ALTER TABLE `cache`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_expiration_index` (`expiration`);

--
-- Indexes for table `cache_locks`
--
ALTER TABLE `cache_locks`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_locks_expiration_index` (`expiration`);

--
-- Indexes for table `calorie_logs`
--
ALTER TABLE `calorie_logs`
  ADD PRIMARY KEY (`id_calorie_log`),
  ADD KEY `fk_calorie_logs_users` (`id_user`);

--
-- Indexes for table `email_verification_tokens`
--
ALTER TABLE `email_verification_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `ema_mood_logs`
--
ALTER TABLE `ema_mood_logs`
  ADD PRIMARY KEY (`id_mood_log`),
  ADD UNIQUE KEY `unique_user_per_day` (`id_user`,`log_date`);

--
-- Indexes for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indexes for table `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `jobs_queue_index` (`queue`);

--
-- Indexes for table `job_batches`
--
ALTER TABLE `job_batches`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`);

--
-- Indexes for table `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id_role`),
  ADD UNIQUE KEY `uq_nama_role` (`nama_role`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id_user`),
  ADD UNIQUE KEY `uq_email` (`email`),
  ADD KEY `fk_users_roles` (`id_role`);

--
-- Indexes for table `user_equipments`
--
ALTER TABLE `user_equipments`
  ADD PRIMARY KEY (`id_user_equipment`),
  ADD KEY `fk_user_equipments_users` (`id_user`);

--
-- Indexes for table `user_profiles`
--
ALTER TABLE `user_profiles`
  ADD PRIMARY KEY (`id_profile`),
  ADD KEY `fk_user_profiles_users` (`id_user`);

--
-- Indexes for table `workouts`
--
ALTER TABLE `workouts`
  ADD PRIMARY KEY (`id_workout`);

--
-- Indexes for table `workout_sessions`
--
ALTER TABLE `workout_sessions`
  ADD PRIMARY KEY (`id_session`),
  ADD KEY `fk_workout_sessions_users` (`id_user`);

--
-- Indexes for table `workout_session_exercises`
--
ALTER TABLE `workout_session_exercises`
  ADD PRIMARY KEY (`id_session_exercise`),
  ADD KEY `fk_session_exercises_parent` (`id_session`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `calorie_logs`
--
ALTER TABLE `calorie_logs`
  MODIFY `id_calorie_log` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=542;

--
-- AUTO_INCREMENT for table `ema_mood_logs`
--
ALTER TABLE `ema_mood_logs`
  MODIFY `id_mood_log` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=361;

--
-- AUTO_INCREMENT for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobs`
--
ALTER TABLE `jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=142;

--
-- AUTO_INCREMENT for table `roles`
--
ALTER TABLE `roles`
  MODIFY `id_role` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id_user` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `user_equipments`
--
ALTER TABLE `user_equipments`
  MODIFY `id_user_equipment` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=90;

--
-- AUTO_INCREMENT for table `user_profiles`
--
ALTER TABLE `user_profiles`
  MODIFY `id_profile` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT for table `workouts`
--
ALTER TABLE `workouts`
  MODIFY `id_workout` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `workout_sessions`
--
ALTER TABLE `workout_sessions`
  MODIFY `id_session` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=270;

--
-- AUTO_INCREMENT for table `workout_session_exercises`
--
ALTER TABLE `workout_session_exercises`
  MODIFY `id_session_exercise` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=680;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `calorie_logs`
--
ALTER TABLE `calorie_logs`
  ADD CONSTRAINT `fk_calorie_logs_users` FOREIGN KEY (`id_user`) REFERENCES `users` (`id_user`) ON DELETE CASCADE;

--
-- Constraints for table `ema_mood_logs`
--
ALTER TABLE `ema_mood_logs`
  ADD CONSTRAINT `fk_ema_mood_logs_users` FOREIGN KEY (`id_user`) REFERENCES `users` (`id_user`) ON DELETE CASCADE;

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_users_roles` FOREIGN KEY (`id_role`) REFERENCES `roles` (`id_role`) ON UPDATE CASCADE;

--
-- Constraints for table `user_equipments`
--
ALTER TABLE `user_equipments`
  ADD CONSTRAINT `fk_user_equipments_users` FOREIGN KEY (`id_user`) REFERENCES `users` (`id_user`) ON DELETE CASCADE;

--
-- Constraints for table `user_profiles`
--
ALTER TABLE `user_profiles`
  ADD CONSTRAINT `fk_user_profiles_users` FOREIGN KEY (`id_user`) REFERENCES `users` (`id_user`) ON DELETE CASCADE;

--
-- Constraints for table `workout_sessions`
--
ALTER TABLE `workout_sessions`
  ADD CONSTRAINT `fk_workout_sessions_users` FOREIGN KEY (`id_user`) REFERENCES `users` (`id_user`) ON DELETE CASCADE;

--
-- Constraints for table `workout_session_exercises`
--
ALTER TABLE `workout_session_exercises`
  ADD CONSTRAINT `fk_session_exercises_parent` FOREIGN KEY (`id_session`) REFERENCES `workout_sessions` (`id_session`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
