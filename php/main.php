<?php

require_once __DIR__ . '/vendor/autoload.php';

use Warehouse\WarehouseDeskApp;

$app = new WarehouseDeskApp();
$app->seedData();
$app->runDemoDay();
