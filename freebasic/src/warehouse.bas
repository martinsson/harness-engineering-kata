#include "dict.bas"
#include "list.bas"

Type SeedItem
    sku As String
    price As Double
    stock As Integer
End Type

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
        Declare Sub SeedData(items() As SeedItem, startingCash As Double, startingOrderNumber As Integer)
        Declare Sub Process(commands() As String)

    private:
        Declare Sub ProcessLine(cmdLine As String)
        Declare Function Split(text As String, delimiter As String) As StringList

    public:
        Declare Sub PrintEndOfDayReport()
End Type

Sub WarehouseDeskApp.SeedData(items() As SeedItem, startingCash As Double, startingOrderNumber As Integer)
    stock.Clear()
    reserved.Clear()
    price.Clear()
    orderStatus.Clear()
    orderSku.Clear()
    orderQty.Clear()
    eventLog.Clear()

    Dim seenSkus As StringList
    Dim i As Integer
    For i = LBound(items) To UBound(items)
        Dim sku As String = Trim(items(i).sku)
        If sku = "" Then
            Print "sku cannot be blank"
            End
        End If
        If items(i).price < 0 Then
            Print "price cannot be negative for " + sku
            End
        End If
        If items(i).stock < 0 Then
            Print "stock cannot be negative for " + sku
            End
        End If
        If seenSkus.Contains(sku) Then
            Print "duplicate sku in seed data: " + sku
            End
        End If
        seenSkus.Add(sku)

        stock.Set(sku, items(i).stock)
        price.Set(sku, items(i).price)
        reserved.Set(sku, 0)
    Next i

    cashBalance = startingCash
    nextOrderNumber = startingOrderNumber
End Sub

Sub WarehouseDeskApp.Process(commands() As String)
    Dim i As Integer
    For i = LBound(commands) To UBound(commands)
        ProcessLine(commands(i))
    Next i
End Sub

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
