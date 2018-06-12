<?php

while (true) {
  try {
    $conn = new PDO('mysql:host=db;dbname=magento', 'root', 'magento');
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $conn->exec('CREATE DATABASE IF NOT EXISTS test');
    exit();
  } catch (Exception $e) {
  }
  sleep(1);
}
