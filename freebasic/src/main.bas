#include "warehouse.bas"

Dim app As WarehouseDeskApp

Dim items(0 To 3) As SeedItem
items(0).sku = "PEN-BLACK"
items(0).price = 1.5
items(0).stock = 40
items(1).sku = "PEN-BLUE"
items(1).price = 1.6
items(1).stock = 25
items(2).sku = "NOTE-A5"
items(2).price = 4.0
items(2).stock = 15
items(3).sku = "STAPLER"
items(3).price = 12.0
items(3).stock = 4

app.SeedData(items(), 300.0, 1001)

Dim commands(0 To 8) As String
commands(0) = "RECV;NOTE-A5;5;2.20"
commands(1) = "SELL;alice;PEN-BLACK;10"
commands(2) = "SELL;bob;STAPLER;5"
commands(3) = "CANCEL;O1002"
commands(4) = "COUNT;STAPLER"
commands(5) = "SELL;carol;STAPLER;2"
commands(6) = "SELL;dan;NOTE-A5;14"
commands(7) = "COUNT;NOTE-A5"
commands(8) = "DUMP"

app.Process(commands())
app.PrintEndOfDayReport()
