from src.warehouse.warehouse_desk_app import SeedItem, WarehouseDeskApp


if __name__ == "__main__":
    app = WarehouseDeskApp()
    app.seed_data(
        [
            SeedItem("PEN-BLACK", 1.5, 40),
            SeedItem("PEN-BLUE", 1.6, 25),
            SeedItem("NOTE-A5", 4.0, 15),
            SeedItem("STAPLER", 12.0, 4),
        ],
        starting_cash=300.0,
        starting_order_number=1001,
    )

    commands = [
        "RECV;NOTE-A5;5;2.20",
        "SELL;alice;PEN-BLACK;10",
        "SELL;bob;STAPLER;5",
        "CANCEL;O1002",
        "COUNT;STAPLER",
        "SELL;carol;STAPLER;2",
        "SELL;dan;NOTE-A5;14",
        "COUNT;NOTE-A5",
        "DUMP",
    ]

    app.process(commands)
    app.print_end_of_day_report()
