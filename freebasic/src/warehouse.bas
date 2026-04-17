#include "dict.bas"
#include "list.bas"

Type WarehouseDeskApp
    private:
        stock As IntegerDict
        reserved As IntegerDict
        price As DoubleDict
        orderStatus As StringDict
        orderSku As StringDict
        orderQty As IntegerDict
        eventLog As StringList
        cashBalance As Double
        nextOrderNumber As Integer

    public:
        Declare Sub SeedData()
        Declare Sub ProcessLine(cmdLine As String)
        Declare Sub PrintEndOfDayReport()
        Declare Sub RunDemoDay()
        Declare Function Split(text As String, delimiter As String) As StringList
End Type

Sub WarehouseDeskApp.SeedData()
    stock.Set("PEN-BLACK", 40)
    stock.Set("PEN-BLUE", 25)
    stock.Set("NOTE-A5", 15)
    stock.Set("STAPLER", 4)

    reserved.Set("PEN-BLACK", 0)
    reserved.Set("PEN-BLUE", 0)
    reserved.Set("NOTE-A5", 0)
    reserved.Set("STAPLER", 0)

    price.Set("PEN-BLACK", 1.5)
    price.Set("PEN-BLUE", 1.6)
    price.Set("NOTE-A5", 4.0)
    price.Set("STAPLER", 12.0)

    cashBalance = 300.0
    nextOrderNumber = 1001
End Sub

Function WarehouseDeskApp.Split(text As String, delimiter As String) As StringList
    Dim i As Integer
    Dim tempStr As String = ""
    Dim result As StringList

    For i = 1 To Len(text)
        Dim c As String = Mid(text, i, 1)
        If c = delimiter Then
            result.Add(tempStr)
            tempStr = ""
        Else
            tempStr = tempStr + c
        End If
    Next i
    result.Add(tempStr)

    Return result
End Function

Sub WarehouseDeskApp.ProcessLine(cmdLine As String)
    Dim parts As StringList = Split(cmdLine, ";")
    Dim cmd As String = parts.Get(0)

    If cmd = "RECV" Then
        Dim sku As String = parts.Get(1)
        Dim qty As Integer = Val(parts.Get(2))
        Dim unitCost As Double = Val(parts.Get(3))

        Dim currentStock As Integer = stock.Get(sku, 0)
        stock.Set(sku, currentStock + qty)

        cashBalance = cashBalance - (qty * unitCost)
        eventLog.Add("received " + Str(qty) + " of " + sku + " at " + Str(unitCost))
        Exit Sub
    End If

    If cmd = "SELL" Then
        Dim customer As String = parts.Get(1)
        Dim sku As String = parts.Get(2)
        Dim qty As Integer = Val(parts.Get(3))
        Dim orderId As String = "O" + Str(nextOrderNumber)
        nextOrderNumber = nextOrderNumber + 1
        orderSku.Set(orderId, sku)
        orderQty.Set(orderId, qty)

        Dim onHand As Integer = stock.Get(sku, 0)
        Dim reservedQty As Integer = reserved.Get(sku, 0)
        Dim available As Integer = onHand - reservedQty
        If available < qty Then
            orderStatus.Set(orderId, "BACKORDER")
            eventLog.Add("order " + orderId + " backordered for " + customer + " sku=" + sku + " qty=" + Str(qty))
        Else
            stock.Set(sku, onHand - qty)
            Dim orderTotal As Double = price.Get(sku, 0.0) * qty
            cashBalance = cashBalance + orderTotal
            orderStatus.Set(orderId, "SHIPPED")
            eventLog.Add("order " + orderId + " shipped to " + customer + " amount=" + Str(orderTotal))
        End If
        Exit Sub
    End If

    If cmd = "CANCEL" Then
        Dim orderId As String = parts.Get(1)
        Dim status As String = orderStatus.Get(orderId, "")
        If status = "" Then
            eventLog.Add("cannot cancel " + orderId + " because it does not exist")
            Exit Sub
        End If

        If status = "BACKORDER" Then
            orderStatus.Set(orderId, "CANCELLED")
            eventLog.Add("cancelled backorder " + orderId)
            Exit Sub
        End If

        If status = "SHIPPED" Then
            Dim sku As String = orderSku.Get(orderId, "")
            Dim qty As Integer = orderQty.Get(orderId, 0)
            Dim currentStock As Integer = stock.Get(sku, 0)
            stock.Set(sku, currentStock + qty)
            Dim priceVal As Double = price.Get(sku, 0.0)
            cashBalance = cashBalance - (priceVal * qty)
            orderStatus.Set(orderId, "CANCELLED_AFTER_SHIP")
            eventLog.Add("cancelled shipped order " + orderId + " with restock")
            Exit Sub
        End If

        eventLog.Add("order " + orderId + " could not be cancelled from state " + status)
        Exit Sub
    End If

    If cmd = "COUNT" Then
        Dim sku As String = parts.Get(1)
        Dim onHand As Integer = stock.Get(sku, 0)
        Dim reservedQty As Integer = reserved.Get(sku, 0)
        Dim available As Integer = onHand - reservedQty
        eventLog.Add("count " + sku + " onHand=" + Str(onHand) + " reserved=" + Str(reservedQty) + " available=" + Str(available))
        Exit Sub
    End If

    If cmd = "DUMP" Then
        Print "---- dump ----"
        Print "stock=";
        stock.PrintKeyValues()
        Print "reserved=";
        reserved.PrintKeyValues()
        Print "orders=";
        orderStatus.PrintKeyValues()
        Print "cashBalance=" + Str(cashBalance)
        Exit Sub
    End If

    eventLog.Add("unknown command: " + cmdLine)
End Sub

Sub WarehouseDeskApp.PrintEndOfDayReport()
    Dim i As Integer
    Dim shipped As Integer = 0
    Dim backorder As Integer = 0
    Dim cancelled As Integer = 0

    For i = 0 To orderStatus.count - 1
        Dim status As String = orderStatus.values(i)
        If status = "SHIPPED" Then
            shipped = shipped + 1
        ElseIf status = "BACKORDER" Then
            backorder = backorder + 1
        ElseIf Left(status, 9) = "CANCELLED" Then
            cancelled = cancelled + 1
        End If
    Next i

    Dim lowStock As StringList
    For i = 0 To stock.count - 1
        If stock.values(i) < 5 Then
            lowStock.Add(stock.keys(i))
        End If
    Next i

    Print
    Print "==== end of day ===="
    Print "orders shipped: " + Str(shipped)
    Print "orders backordered: " + Str(backorder)
    Print "orders cancelled: " + Str(cancelled)
    Print "cash balance: " + Str(cashBalance)
    Print "low stock skus: ";
    lowStock.PrintItemsOneLine()
    Print
    Print "events:"
    eventLog.PrintItems()
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

