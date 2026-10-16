<?php

declare(strict_types=1);

require_once __DIR__ . '/vendor/autoload.php';

use Warehouse\SeedItem;
use Warehouse\WarehouseDeskApp;

$app = new WarehouseDeskApp();
$app->seedData(
    [
        new SeedItem("PEN-BLACK", 1.5, 40),
        new SeedItem("PEN-BLUE", 1.6, 25),
        new SeedItem("NOTE-A5", 4.0, 15),
        new SeedItem("STAPLER", 12.0, 4),
    ],
    300.0,
    1001,
);

$commands = [
    "RECV;NOTE-A5;5;2.20",
    "SELL;alice;PEN-BLACK;10",
    "SELL;bob;STAPLER;5",
    "CANCEL;O1002",
    "COUNT;STAPLER",
    "SELL;carol;STAPLER;2",
    "SELL;dan;NOTE-A5;14",
    "COUNT;NOTE-A5",
    "DUMP",
];

$app->process($commands);
$app->printEndOfDayReport();
