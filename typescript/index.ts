import { WarehouseDeskApp, SeedItem } from './src/WarehouseDeskApp';

const app = new WarehouseDeskApp();
app.seedData(
    [
        { sku: "PEN-BLACK", price: 1.5, stock: 40 },
        { sku: "PEN-BLUE", price: 1.6, stock: 25 },
        { sku: "NOTE-A5", price: 4.0, stock: 15 },
        { sku: "STAPLER", price: 12.0, stock: 4 },
    ],
    300.0,
    1001,
);

const commands = [
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

app.process(commands);
app.printEndOfDayReport();
