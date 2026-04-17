<?php

namespace Warehouse;

class WarehouseDeskApp
{
    private $stockBySku = [];
    private $reservedBySku = [];
    private $priceBySku = [];
    private $orderStatus = [];
    private $orderSku = [];
    private $orderQty = [];
    private $eventLog = [];
    private $cashBalance;
    private $nextOrderNumber;

    public function seedData()
    {
        $this->stockBySku = [
            "PEN-BLACK" => 40,
            "PEN-BLUE" => 25,
            "NOTE-A5" => 15,
            "STAPLER" => 4
        ];

        $this->reservedBySku = [
            "PEN-BLACK" => 0,
            "PEN-BLUE" => 0,
            "NOTE-A5" => 0,
            "STAPLER" => 0
        ];

        $this->priceBySku = [
            "PEN-BLACK" => 1.5,
            "PEN-BLUE" => 1.6,
            "NOTE-A5" => 4.0,
            "STAPLER" => 12.0
        ];

        $this->cashBalance = 300.0;
        $this->nextOrderNumber = 1001;
    }

    public function runDemoDay()
    {
        $commands = [
            "RECV;NOTE-A5;5;2.20",
            "SELL;alice;PEN-BLACK;10",
            "SELL;bob;STAPLER;5",
            "CANCEL;O1002",
            "COUNT;STAPLER",
            "SELL;carol;STAPLER;2",
            "SELL;dan;NOTE-A5;14",
            "COUNT;NOTE-A5",
            "DUMP"
        ];

        foreach ($commands as $command) {
            $this->processLine($command);
        }
        $this->printEndOfDayReport();
    }

    public function processLine($line)
    {
        $parts = explode(";", $line);
        $type = $parts[0];

        if ("RECV" === $type) {
            $sku = $parts[1];
            $qty = $this->parseInt($parts[2]);
            $unitCost = $this->parseDouble($parts[3]);
            $current = $this->stockBySku[$sku] ?? 0;
            $this->stockBySku[$sku] = $current + $qty;
            $this->cashBalance = $this->cashBalance - ($qty * $unitCost);
            $this->eventLog[] = "received " . $qty . " of " . $sku . " at " . $unitCost;
            return;
        }

        if ("SELL" === $type) {
            $customer = $parts[1];
            $sku = $parts[2];
            $qty = $this->parseInt($parts[3]);
            $orderId = "O" . $this->nextOrderNumber;
            $this->nextOrderNumber = $this->nextOrderNumber + 1;
            $this->orderSku[$orderId] = $sku;
            $this->orderQty[$orderId] = $qty;

            $onHand = $this->stockBySku[$sku] ?? 0;
            $reserved = $this->reservedBySku[$sku] ?? 0;
            $available = $onHand - $reserved;
            if ($available < $qty) {
                $this->orderStatus[$orderId] = "BACKORDER";
                $this->eventLog[] = "order " . $orderId . " backordered for " . $customer . " sku=" . $sku . " qty=" . $qty;
            } else {
                $this->stockBySku[$sku] = $onHand - $qty;
                $unitPrice = $this->priceBySku[$sku] ?? 0.0;
                $orderTotal = $unitPrice * $qty;
                $this->cashBalance = $this->cashBalance + $orderTotal;
                $this->orderStatus[$orderId] = "SHIPPED";
                $this->eventLog[] = "order " . $orderId . " shipped to " . $customer . " amount=" . $orderTotal;
            }
            return;
        }

        if ("CANCEL" === $type) {
            $orderId = $parts[1];
            $status = $this->orderStatus[$orderId] ?? null;
            if ($status === null) {
                $this->eventLog[] = "cannot cancel " . $orderId . " because it does not exist";
                return;
            }

            if ("BACKORDER" === $status) {
                $this->orderStatus[$orderId] = "CANCELLED";
                $this->eventLog[] = "cancelled backorder " . $orderId;
                return;
            }

            if ("SHIPPED" === $status) {
                $sku = $this->orderSku[$orderId] ?? null;
                $qty = $this->orderQty[$orderId] ?? 0;
                $current = $this->stockBySku[$sku] ?? 0;
                $this->stockBySku[$sku] = $current + $qty;
                $unitPrice = $this->priceBySku[$sku] ?? 0.0;
                $this->cashBalance = $this->cashBalance - ($unitPrice * $qty);
                $this->orderStatus[$orderId] = "CANCELLED_AFTER_SHIP";
                $this->eventLog[] = "cancelled shipped order " . $orderId . " with restock";
                return;
            }

            $this->eventLog[] = "order " . $orderId . " could not be cancelled from state " . $status;
            return;
        }

        if ("COUNT" === $type) {
            $sku = $parts[1];
            $onHand = $this->stockBySku[$sku] ?? 0;
            $reserved = $this->reservedBySku[$sku] ?? 0;
            $available = $onHand - $reserved;
            $this->eventLog[] = "count " . $sku . " onHand=" . $onHand . " reserved=" . $reserved . " available=" . $available;
            return;
        }

        if ("DUMP" === $type) {
            echo "---- dump ----\n";
            echo "stock=" . print_r($this->stockBySku, true) . "\n";
            echo "reserved=" . print_r($this->reservedBySku, true) . "\n";
            echo "orders=" . print_r($this->orderStatus, true) . "\n";
            echo "cashBalance=" . $this->cashBalance . "\n";
            return;
        }

        $this->eventLog[] = "unknown command: " . $line;
    }

    private function parseInt($value)
    {
        return intval(trim($value));
    }

    private function parseDouble($value)
    {
        return floatval(trim($value));
    }

    public function printEndOfDayReport()
    {
        $shipped = 0;
        $backorder = 0;
        $cancelled = 0;
        foreach ($this->orderStatus as $status) {
            if ("SHIPPED" === $status) {
                $shipped = $shipped + 1;
            } elseif ("BACKORDER" === $status) {
                $backorder = $backorder + 1;
            } elseif (strpos($status, "CANCELLED") === 0) {
                $cancelled = $cancelled + 1;
            }
        }

        $lowStock = [];
        foreach ($this->stockBySku as $sku => $quantity) {
            if ($quantity < 5) {
                $lowStock[] = $sku;
            }
        }

        echo "\n";
        echo "==== end of day ====\n";
        echo "orders shipped: " . $shipped . "\n";
        echo "orders backordered: " . $backorder . "\n";
        echo "orders cancelled: " . $cancelled . "\n";
        echo "cash balance: " . number_format($this->cashBalance, 2) . "\n";
        echo "low stock skus: " . implode(", ", $lowStock) . "\n";
        echo "\n";
        echo "events:\n";
        foreach ($this->eventLog as $event) {
            echo " - " . $event . "\n";
        }
    }
}
