<?php

declare(strict_types=1);

namespace Warehouse;

class SeedItem
{
    public function __construct(
        public string $sku,
        public float $price,
        public int $stock
    ) {
    }
}

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

    public function seedData(array $items, float $startingCash, int $startingOrderNumber)
    {
        $this->stockBySku = [];
        $this->reservedBySku = [];
        $this->priceBySku = [];
        $this->orderStatus = [];
        $this->orderSku = [];
        $this->orderQty = [];
        $this->eventLog = [];

        $seenSkus = [];
        foreach ($items as $item) {
            if ($item === null) {
                throw new \InvalidArgumentException("seed item cannot be null");
            }

            $sku = trim($item->sku);
            if ($sku === "") {
                throw new \InvalidArgumentException("sku cannot be blank");
            }
            if ($item->price < 0) {
                throw new \InvalidArgumentException("price cannot be negative for " . $sku);
            }
            if ($item->stock < 0) {
                throw new \InvalidArgumentException("stock cannot be negative for " . $sku);
            }
            if (in_array($sku, $seenSkus, true)) {
                throw new \InvalidArgumentException("duplicate sku in seed data: " . $sku);
            }

            $seenSkus[] = $sku;
            $this->stockBySku[$sku] = $item->stock;
            $this->reservedBySku[$sku] = 0;
            $this->priceBySku[$sku] = $item->price;
        }

        $this->cashBalance = $startingCash;
        $this->nextOrderNumber = $startingOrderNumber;
    }

    public function process(array $commands)
    {
        foreach ($commands as $command) {
            $this->processLine($command);
        }
    }

    private function processLine($line)
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
            $this->eventLog[] = "received " . $qty . " of " . $sku . " at " . $this->formatDouble($unitCost);
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
                $this->eventLog[] = "order " . $orderId . " shipped to " . $customer . " amount=" . $this->formatDouble($orderTotal);
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
                $sku = $this->orderSku[$orderId];
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
            echo "stock=" . $this->printMap($this->stockBySku) . "\n";
            echo "reserved=" . $this->printMap($this->reservedBySku) . "\n";
            echo "orders=" . $this->printMap($this->orderStatus) . "\n";
            echo "cashBalance=" . $this->formatDouble($this->cashBalance) . "\n";
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

    private function formatDouble($value): string
    {
        $s = (string) $value;
        return strpos($s, '.') !== false ? $s : $s . '.0';
    }

    private function printMap(array $map): string
    {
        $entries = [];
        foreach ($map as $k => $v) {
            $entries[] = $k . '=' . $v;
        }
        return '{' . implode(', ', $entries) . '}';
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
        echo "low stock skus: [" . implode(", ", $lowStock) . "]\n";
        echo "\n";
        echo "events:\n";
        foreach ($this->eventLog as $event) {
            echo " - " . $event . "\n";
        }
    }
}
