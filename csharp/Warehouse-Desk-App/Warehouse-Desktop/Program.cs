using Warehouse_Desktop;

WarehouseDeskApp app = new WarehouseDeskApp();

app.SeedData(
    new List<WarehouseDeskApp.SeedItem>
    {
        new("PEN-BLACK", 1.5, 40),
        new("PEN-BLUE", 1.6, 25),
        new("NOTE-A5", 4.0, 15),
        new("STAPLER", 12.0, 4)
    },
    startingCash: 300.0,
    startingOrderNumber: 1001
);

List<string> commands = new List<string>
{
    "RECV;NOTE-A5;5;2.20",
    "SELL;alice;PEN-BLACK;10",
    "SELL;bob;STAPLER;5",
    "CANCEL;O1002",
    "COUNT;STAPLER",
    "SELL;carol;STAPLER;2",
    "SELL;dan;NOTE-A5;14",
    "COUNT;NOTE-A5",
    "DUMP"
};

app.Process(commands);
app.PrintEndOfDayReport();
