package org.sammancoaching.warehouse;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class WarehouseDeskApp {
    private final Map<String, Integer> stockBySku = new HashMap<>();
    private final Map<String, Integer> reservedBySku = new HashMap<>();
    private final Map<String, Double> priceBySku = new HashMap<>();
    private final Map<String, String> orderStatus = new HashMap<>();
    private final Map<String, String> orderSku = new HashMap<>();
    private final Map<String, Integer> orderQty = new HashMap<>();
    private final List<String> eventLog = new ArrayList<>();
    private double cashBalance;
    private int nextOrderNumber;

    public void seedData() {
        stockBySku.put("PEN-BLACK", 40);
        stockBySku.put("PEN-BLUE", 25);
        stockBySku.put("NOTE-A5", 15);
        stockBySku.put("STAPLER", 4);

        reservedBySku.put("PEN-BLACK", 0);
        reservedBySku.put("PEN-BLUE", 0);
        reservedBySku.put("NOTE-A5", 0);
        reservedBySku.put("STAPLER", 0);

        priceBySku.put("PEN-BLACK", 1.5);
        priceBySku.put("PEN-BLUE", 1.6);
        priceBySku.put("NOTE-A5", 4.0);
        priceBySku.put("STAPLER", 12.0);

        cashBalance = 300.0;
        nextOrderNumber = 1001;
    }

    public void runDemoDay() {
        List<String> commands = List.of(
            "RECV;NOTE-A5;5;2.20",
            "SELL;alice;PEN-BLACK;10",
            "SELL;bob;STAPLER;5",
            "CANCEL;O1002",
            "COUNT;STAPLER",
            "SELL;carol;STAPLER;2",
            "SELL;dan;NOTE-A5;14",
            "COUNT;NOTE-A5",
            "DUMP"
        );

        for (String command : commands) {
            processLine(command);
        }
        printEndOfDayReport();
    }

    public void processLine(String line) {
        String[] parts = line.split(";");
        String type = parts[0];

        if ("RECV".equals(type)) {
            String sku = parts[1];
            int qty = parseInt(parts[2]);
            double unitCost = parseDouble(parts[3]);
            int current = stockBySku.getOrDefault(sku, 0);
            stockBySku.put(sku, current + qty);
            cashBalance = cashBalance - (qty * unitCost);
            eventLog.add("received " + qty + " of " + sku + " at " + unitCost);
            return;
        }

        if ("SELL".equals(type)) {
            String customer = parts[1];
            String sku = parts[2];
            int qty = parseInt(parts[3]);
            String orderId = "O" + nextOrderNumber;
            nextOrderNumber = nextOrderNumber + 1;
            orderSku.put(orderId, sku);
            orderQty.put(orderId, qty);

            int onHand = stockBySku.getOrDefault(sku, 0);
            int reserved = reservedBySku.getOrDefault(sku, 0);
            int available = onHand - reserved;
            if (available < qty) {
                orderStatus.put(orderId, "BACKORDER");
                eventLog.add("order " + orderId + " backordered for " + customer + " sku=" + sku + " qty=" + qty);
            } else {
                stockBySku.put(sku, onHand - qty);
                double unitPrice = priceBySku.getOrDefault(sku, 0.0);
                double orderTotal = unitPrice * qty;
                cashBalance = cashBalance + orderTotal;
                orderStatus.put(orderId, "SHIPPED");
                eventLog.add("order " + orderId + " shipped to " + customer + " amount=" + orderTotal);
            }
            return;
        }

        if ("CANCEL".equals(type)) {
            String orderId = parts[1];
            String status = orderStatus.get(orderId);
            if (status == null) {
                eventLog.add("cannot cancel " + orderId + " because it does not exist");
                return;
            }

            if ("BACKORDER".equals(status)) {
                orderStatus.put(orderId, "CANCELLED");
                eventLog.add("cancelled backorder " + orderId);
                return;
            }

            if ("SHIPPED".equals(status)) {
                String sku = orderSku.get(orderId);
                int qty = orderQty.getOrDefault(orderId, 0);
                int current = stockBySku.getOrDefault(sku, 0);
                stockBySku.put(sku, current + qty);
                double unitPrice = priceBySku.getOrDefault(sku, 0.0);
                cashBalance = cashBalance - (unitPrice * qty);
                orderStatus.put(orderId, "CANCELLED_AFTER_SHIP");
                eventLog.add("cancelled shipped order " + orderId + " with restock");
                return;
            }

            eventLog.add("order " + orderId + " could not be cancelled from state " + status);
            return;
        }

        if ("COUNT".equals(type)) {
            String sku = parts[1];
            int onHand = stockBySku.getOrDefault(sku, 0);
            int reserved = reservedBySku.getOrDefault(sku, 0);
            int available = onHand - reserved;
            eventLog.add("count " + sku + " onHand=" + onHand + " reserved=" + reserved + " available=" + available);
            return;
        }

        if ("DUMP".equals(type)) {
            System.out.println("---- dump ----");
            System.out.println("stock=" + stockBySku);
            System.out.println("reserved=" + reservedBySku);
            System.out.println("orders=" + orderStatus);
            System.out.println("cashBalance=" + cashBalance);
            return;
        }

        eventLog.add("unknown command: " + line);
    }

    private int parseInt(String value) {
        return Integer.parseInt(value.trim());
    }

    private double parseDouble(String value) {
        return Double.parseDouble(value.trim());
    }

    public void printEndOfDayReport() {
        int shipped = 0;
        int backorder = 0;
        int cancelled = 0;
        for (String status : orderStatus.values()) {
            if ("SHIPPED".equals(status)) {
                shipped = shipped + 1;
            } else if ("BACKORDER".equals(status)) {
                backorder = backorder + 1;
            } else if (status.startsWith("CANCELLED")) {
                cancelled = cancelled + 1;
            }
        }

        List<String> lowStock = new ArrayList<>();
        for (Map.Entry<String, Integer> item : stockBySku.entrySet()) {
            if (item.getValue() < 5) {
                lowStock.add(item.getKey());
            }
        }

        System.out.println();
        System.out.println("==== end of day ====");
        System.out.println("orders shipped: " + shipped);
        System.out.println("orders backordered: " + backorder);
        System.out.println("orders cancelled: " + cancelled);
        System.out.println("cash balance: " + String.format("%.2f", cashBalance));
        System.out.println("low stock skus: " + lowStock);
        System.out.println();
        System.out.println("events:");
        for (String event : eventLog) {
            System.out.println(" - " + event);
        }
    }
}
