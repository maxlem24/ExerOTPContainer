-- MariaDB dump 10.19  Distrib 10.5.21-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: exer_db
-- ------------------------------------------------------
-- Server version	10.5.21-MariaDB-0+deb11u1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `exer_db`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `exer_db` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */;

USE `exer_db`;

--
-- Table structure for table `otp_actif`
--

DROP TABLE IF EXISTS `otp_actif`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `otp_actif` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip_publisher` varchar(255) NOT NULL,
  `ip_subscriber` varchar(255) NOT NULL,
  `status` varchar(255) NOT NULL,
  `created_at` date NOT NULL,
  `last_synchro` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `otp_actif`
--

LOCK TABLES `otp_actif` WRITE;
/*!40000 ALTER TABLE `otp_actif` DISABLE KEYS */;
/*!40000 ALTER TABLE `otp_actif` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `otp_companies`
--

DROP TABLE IF EXISTS `otp_companies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `otp_companies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `corpid` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `folder` varchar(255) NOT NULL,
  `contact_email` varchar(255) NOT NULL,
  `logosrc` text NOT NULL,
  `expire_date` varchar(20) NOT NULL,
  `created_at` date NOT NULL,
  `token` text NOT NULL,
  `users_max` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `otp_companies`
--

LOCK TABLES `otp_companies` WRITE;
/*!40000 ALTER TABLE `otp_companies` DISABLE KEYS */;
/*!40000 ALTER TABLE `otp_companies` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `otp_connections`
--

DROP TABLE IF EXISTS `otp_connections`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `otp_connections` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `userid` int(11) NOT NULL,
  `ipaddress` text NOT NULL,
  `location` text NOT NULL,
  `connected_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `otp_connections`
--

LOCK TABLES `otp_connections` WRITE;
/*!40000 ALTER TABLE `otp_connections` DISABLE KEYS */;
INSERT INTO `otp_connections` VALUES (3,1,'10.0.0.252','','2023-12-04 12:08:13'),(4,1,'172.16.2.172','','2024-11-15 11:03:05');
/*!40000 ALTER TABLE `otp_connections` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `otp_firewall`
--

DROP TABLE IF EXISTS `otp_firewall`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `otp_firewall` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `corpid` int(11) NOT NULL,
  `short_name` varchar(50) NOT NULL,
  `client` varchar(255) NOT NULL,
  `ipaddr` text NOT NULL,
  `secret` text NOT NULL,
  `2auth` enum('0','1') NOT NULL,
  `tokenID` text NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `otp_firewall`
--

LOCK TABLES `otp_firewall` WRITE;
/*!40000 ALTER TABLE `otp_firewall` DISABLE KEYS */;
/*!40000 ALTER TABLE `otp_firewall` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `otp_ldap`
--

DROP TABLE IF EXISTS `otp_ldap`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `otp_ldap` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `corpid` int(11) NOT NULL,
  `client` varchar(255) NOT NULL,
  `loginattribute` varchar(255) NOT NULL,
  `base_dn` varchar(255) NOT NULL,
  `ldap_uri` text NOT NULL,
  `ldap_uri2` text NOT NULL,
  `sslproto` varchar(255) NOT NULL,
  `binddn` varchar(255) NOT NULL,
  `created_at` datetime NOT NULL,
  `token` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `otp_ldap`
--

LOCK TABLES `otp_ldap` WRITE;
/*!40000 ALTER TABLE `otp_ldap` DISABLE KEYS */;
/*!40000 ALTER TABLE `otp_ldap` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `otp_mailing`
--

DROP TABLE IF EXISTS `otp_mailing`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `otp_mailing` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `corpid` int(11) NOT NULL DEFAULT 0,
  `host` varchar(150) NOT NULL,
  `transport` int(11) NOT NULL,
  `port` int(11) NOT NULL,
  `fqdn` text NOT NULL,
  `issuer` text NOT NULL,
  `sendmail` text NOT NULL,
  `auth_user` text NOT NULL,
  `auth_password` text NOT NULL,
  `content` longtext NOT NULL,
  `content_link` longtext NOT NULL,
  `link_custom_btn1` longtext NOT NULL,
  `link_custom_btn2` longtext NOT NULL,
  `created_at` datetime NOT NULL,
  `token` longtext NOT NULL,
  `subject` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Stockage des paramètres des relais SMTP.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `otp_mailing`
--

LOCK TABLES `otp_mailing` WRITE;
/*!40000 ALTER TABLE `otp_mailing` DISABLE KEYS */;
/*!40000 ALTER TABLE `otp_mailing` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `otp_tokens`
--

DROP TABLE IF EXISTS `otp_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `otp_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `userid` int(11) NOT NULL,
  `login` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `issuer` text NOT NULL,
  `corpid` int(11) NOT NULL,
  `key_name` varchar(255) NOT NULL,
  `serialnumber_card` varchar(255) NOT NULL,
  `qr_code` text NOT NULL,
  `created_at` datetime NOT NULL,
  `otp_last_connected` datetime NOT NULL,
  `otp_firewall` longtext NOT NULL,
  `token` text NOT NULL,
  `externalToken` text NOT NULL,
  `upn` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `otp_tokens`
--

LOCK TABLES `otp_tokens` WRITE;
/*!40000 ALTER TABLE `otp_tokens` DISABLE KEYS */;
/*!40000 ALTER TABLE `otp_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `otp_users`
--

DROP TABLE IF EXISTS `otp_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `otp_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `corp` varchar(255) DEFAULT 'NOT_DEFINED',
  `lastname` varchar(255) NOT NULL,
  `firstname` varchar(255) NOT NULL,
  `username` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `level` int(11) NOT NULL COMMENT '1=user;2=admin',
  `lastip` text NOT NULL,
  `last_connected` datetime NOT NULL,
  `enable` tinyint(1) NOT NULL,
  `token` text NOT NULL,
  `created_at` datetime NOT NULL,
  `search` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `otp_users`
--

LOCK TABLES `otp_users` WRITE;
/*!40000 ALTER TABLE `otp_users` DISABLE KEYS */;
INSERT INTO `otp_users` VALUES (1,'NOT_DEFINED','EXER','Superviseur','supervisor','supervisor@exer-otp.local','$2y$10$.I51pm3eP.76BtjFPxPKeekL8pzfHgHIhvCnrVIUjNOSv7rfGJ5.2',3,'172.16.2.172','2024-11-15 11:03:05',1,'b369160250386ad51d4c46ddf6bca9f06265e4cf','2023-12-01 00:00:00','');
/*!40000 ALTER TABLE `otp_users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2024-11-15 12:01:38
