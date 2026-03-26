package org.sammancoaching.warehouse;

public class Main {
    public static void main(String[] args) {
        WarehouseDeskApp app = new WarehouseDeskApp();
        app.seedData();
        app.runDemoDay();
    }
}
