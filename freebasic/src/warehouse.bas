#include "dict.bas"

Type WarehouseDeskApp
    stock(MAX_ITEMS) As Integer
    stockKeys(MAX_ITEMS) As String
    stockCount As Integer

    reserved(MAX_ITEMS) As Integer
    reservedKeys(MAX_ITEMS) As String
    reservedCount As Integer

    price(MAX_ITEMS) As Double
    priceKeys(MAX_ITEMS) As String
    priceCount As Integer

    orderStatus(MAX_ITEMS) As String
    orderStatusKeys(MAX_ITEMS) As String
    orderStatusCount As Integer

    orderSku(MAX_ITEMS) As String
    orderSkuKeys(MAX_ITEMS) As String
    orderSkuCount As Integer

    orderQty(MAX_ITEMS) As Integer
    orderQtyKeys(MAX_ITEMS) As String
    orderQtyCount As Integer

    eventLog(MAX_ITEMS) As String
    eventLogCount As Integer

    cashBalance As Double
    nextOrderNumber As Integer

    Declare Constructor()
    Declare Sub SeedData()
    Declare Sub RunDemoDay()
    Declare Sub ProcessLine(cmdLine As String)
    Declare Sub PrintEndOfDayReport()
    Declare Sub AddEvent(eventText As String)
End Type

Constructor WarehouseDeskApp()
    InitDictInt(stockKeys(), stock(), stockCount)
    InitDictInt(reservedKeys(), reserved(), reservedCount)
    InitDictDouble(priceKeys(), price(), priceCount)
    InitDictString(orderStatusKeys(), orderStatus(), orderStatusCount)
    InitDictString(orderSkuKeys(), orderSku(), orderSkuCount)
    InitDictInt(orderQtyKeys(), orderQty(), orderQtyCount)
    eventLogCount = 0

    cashBalance = 0.0
    nextOrderNumber = 1001
End Constructor

Sub WarehouseDeskApp.SeedData()
    DictSetInt(stockKeys(), stock(), stockCount, "PEN-BLACK", 40)
    DictSetInt(stockKeys(), stock(), stockCount, "PEN-BLUE", 25)
    DictSetInt(stockKeys(), stock(), stockCount, "NOTE-A5", 15)
    DictSetInt(stockKeys(), stock(), stockCount, "STAPLER", 4)

    DictSetInt(reservedKeys(), reserved(), reservedCount, "PEN-BLACK", 0)
    DictSetInt(reservedKeys(), reserved(), reservedCount, "PEN-BLUE", 0)
    DictSetInt(reservedKeys(), reserved(), reservedCount, "NOTE-A5", 0)
    DictSetInt(reservedKeys(), reserved(), reservedCount, "STAPLER", 0)

    DictSetDouble(priceKeys(), price(), priceCount, "PEN-BLACK", 1.5)
    DictSetDouble(priceKeys(), price(), priceCount, "PEN-BLUE", 1.6)
    DictSetDouble(priceKeys(), price(), priceCount, "NOTE-A5", 4.0)
    DictSetDouble(priceKeys(), price(), priceCount, "STAPLER", 12.0)

    cashBalance = 300.0
    nextOrderNumber = 1001
End Sub

Sub WarehouseDeskApp.RunDemoDay()
    Dim commands(10) As String
    Dim commandCount As Integer = 9

    commands(0) = "RECV;NOTE-A5;5;2.20"
    commands(1) = "SELL;alice;PEN-BLACK;10"
    commands(2) = "SELL;bob;STAPLER;5"
    commands(3) = "CANCEL;O1002"
    commands(4) = "COUNT;STAPLER"
    commands(5) = "SELL;carol;STAPLER;2"
    commands(6) = "SELL;dan;NOTE-A5;14"
    commands(7) = "COUNT;NOTE-A5"
    commands(8) = "DUMP"

    Dim i As Integer
    For i = 0 To commandCount - 1
        ProcessLine(commands(i))
    Next i

    PrintEndOfDayReport()
End Sub

Sub WarehouseDeskApp.ProcessLine(cmdLine As String)
    Dim parts(10) As String
    Dim partCount As Integer
    Dim i As Integer
    Dim cmd As String

    partCount = 0
    Dim tempStr As String = ""
    For i = 1 To Len(cmdLine)
        Dim c As String = Mid(cmdLine, i, 1)
        If c = ";" Then
            If partCount < 10 Then
                parts(partCount) = tempStr
                partCount = partCount + 1
            End If
            tempStr = ""
        Else
            tempStr = tempStr + c
        End If
    Next i
    If partCount < 10 Then
        parts(partCount) = tempStr
        partCount = partCount + 1
    End If

    cmd = parts(0)

    If cmd = "RECV" Then
        If partCount >= 4 Then
            Dim sku As String = parts(1)
            Dim qty As Integer = Val(parts(2))
            Dim unitCost As Double = Val(parts(3))

            Dim currentStock As Integer = DictGetInt(stockKeys(), stock(), stockCount, sku, 0)
            DictSetInt(stockKeys(), stock(), stockCount, sku, currentStock + qty)

            cashBalance = cashBalance - (qty * unitCost)
            AddEvent("received " + Str(qty) + " of " + sku + " at " + Str(unitCost))
        End If
        Exit Sub
    End If

    If cmd = "SELL" Then
        If partCount >= 4 Then
            Dim customer As String = parts(1)
            Dim sku As String = parts(2)
            Dim qty As Integer = Val(parts(3))
            Dim orderId As String = "O" + Str(nextOrderNumber)

            nextOrderNumber = nextOrderNumber + 1

            DictSetString(orderSkuKeys(), orderSku(), orderSkuCount, orderId, sku)
            DictSetInt(orderQtyKeys(), orderQty(), orderQtyCount, orderId, qty)

            Dim onHand As Integer = DictGetInt(stockKeys(), stock(), stockCount, sku, 0)
            Dim reserved As Integer = DictGetInt(reservedKeys(), reserved, reservedCount, sku, 0)
            Dim available As Integer = onHand - reserved

            If available < qty Then
                DictSetString(orderStatusKeys(), orderStatus(), orderStatusCount, orderId, "BACKORDER")
                AddEvent("order " + orderId + " backordered for " + customer + " sku=" + sku + " qty=" + Str(qty))
            Else
                DictSetInt(stockKeys(), stock(), stockCount, sku, onHand - qty)

                Dim orderTotal As Double = DictGetDouble(priceKeys(), price(), priceCount, sku, 0.0) * qty
                cashBalance = cashBalance + orderTotal

                DictSetString(orderStatusKeys(), orderStatus(), orderStatusCount, orderId, "SHIPPED")
                AddEvent("order " + orderId + " shipped to " + customer + " amount=" + Str(orderTotal))
            End If
        End If
        Exit Sub
    End If

    If cmd = "CANCEL" Then
        If partCount >= 2 Then
            Dim orderId As String = parts(1)
            Dim status As String = DictGetString(orderStatusKeys(), orderStatus(), orderStatusCount, orderId, "")

            If status = "" Then
                AddEvent("cannot cancel " + orderId + " because it does not exist")
                Exit Sub
            End If

            If status = "BACKORDER" Then
                DictSetString(orderStatusKeys(), orderStatus(), orderStatusCount, orderId, "CANCELLED")
                AddEvent("cancelled backorder " + orderId)
                Exit Sub
            End If

            If status = "SHIPPED" Then
                Dim sku As String = DictGetString(orderSkuKeys(), orderSku(), orderSkuCount, orderId, "")
                Dim qty As Integer = DictGetInt(orderQtyKeys(), orderQty(), orderQtyCount, orderId, 0)

                Dim currentStock As Integer = DictGetInt(stockKeys(), stock(), stockCount, sku, 0)
                DictSetInt(stockKeys(), stock(), stockCount, sku, currentStock + qty)

                Dim price As Double = DictGetDouble(priceKeys(), price, priceCount, sku, 0.0)
                cashBalance = cashBalance - (price * qty)

                DictSetString(orderStatusKeys(), orderStatus(), orderStatusCount, orderId, "CANCELLED_AFTER_SHIP")
                AddEvent("cancelled shipped order " + orderId + " with restock")
                Exit Sub
            End If

            AddEvent("order " + orderId + " could not be cancelled from state " + status)
        End If
        Exit Sub
    End If

    If cmd = "COUNT" Then
        If partCount >= 2 Then
            Dim sku As String = parts(1)
            Dim onHand As Integer = DictGetInt(stockKeys(), stock(), stockCount, sku, 0)
            Dim reserved As Integer = DictGetInt(reservedKeys(), reserved(), reservedCount, sku, 0)
            Dim available As Integer = onHand - reserved

            AddEvent("count " + sku + " onHand=" + Str(onHand) + " reserved=" + Str(reserved) + " available=" + Str(available))
        End If
        Exit Sub
    End If

    If cmd = "DUMP" Then
        Print "---- dump ----"
        Print "stock=";
        For i = 0 To stockCount - 1
            Print stockKeys(i) + "=" + Str(stock(i)) + " ";
        Next i
        Print

        Print "reserved=";
        For i = 0 To reservedCount - 1
            Print reservedKeys(i) + "=" + Str(reserved(i)) + " ";
        Next i
        Print

        Print "orders=";
        For i = 0 To orderStatusCount - 1
            Print orderStatusKeys(i) + "=" + orderStatus(i) + " ";
        Next i
        Print

        Print "cashBalance=" + Str(cashBalance)
        Exit Sub
    End If

    AddEvent("unknown command: " + cmdLine)
End Sub

Sub WarehouseDeskApp.PrintEndOfDayReport()
    Dim shipped As Integer = 0
    Dim backorder As Integer = 0
    Dim cancelled As Integer = 0
    Dim i As Integer

    For i = 0 To orderStatusCount - 1
        Dim status As String = orderStatus(i)
        If status = "SHIPPED" Then
            shipped = shipped + 1
        ElseIf status = "BACKORDER" Then
            backorder = backorder + 1
        ElseIf Left(status, 8) = "CANCELLED" Then
            cancelled = cancelled + 1
        End If
    Next i

    Dim lowStock(MAX_ITEMS) As String
    Dim lowStockCount As Integer = 0
    For i = 0 To stockCount - 1
        If stock(i) < 5 Then
            lowStock(lowStockCount) = stockKeys(i)
            lowStockCount = lowStockCount + 1
        End If
    Next i

    Print
    Print "==== end of day ===="
    Print "orders shipped: " + Str(shipped)
    Print "orders backordered: " + Str(backorder)
    Print "orders cancelled: " + Str(cancelled)
    Print "cash balance: " + Str(cashBalance)
    Print "low stock skus: ";
    For i = 0 To lowStockCount - 1
        Print lowStock(i) + " ";
    Next i
    Print
    Print "events:"
    For i = 0 To eventLogCount - 1
        Print " - " + eventLog(i)
    Next i
End Sub

Sub WarehouseDeskApp.AddEvent(eventText As String)
    If eventLogCount < MAX_ITEMS Then
        eventLog(eventLogCount) = eventText
        eventLogCount = eventLogCount + 1
    End If
End Sub