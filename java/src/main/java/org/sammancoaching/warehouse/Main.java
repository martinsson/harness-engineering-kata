package org.sammancoaching.warehouse;

import java.util.List;

public class Main {
    public static void main(String[] args) {
        WarehouseDeskApp app = new WarehouseDeskApp();
        app.seedData(
            List.of(
                new WarehouseDeskApp.SeedItem("PEN-BLACK", 1.5, 40),
                new WarehouseDeskApp.SeedItem("PEN-BLUE", 1.6, 25),
                new WarehouseDeskApp.SeedItem("NOTE-A5", 4.0, 15),
                new WarehouseDeskApp.SeedItem("STAPLER", 12.0, 4)
            ),
            300.0,
            1001
        );

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

        app.process(commands);

        app.printEndOfDayReport();
    }
}
