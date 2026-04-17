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
        Declare Constructor()
        Declare Sub SeedData()
        Declare Sub ProcessLine(cmdLine As String)
        Declare Sub PrintEndOfDayReport()
        Declare Sub RunDemoDay()
End Type

Constructor WarehouseDeskApp()
    cashBalance = 0.0
    nextOrderNumber = 1001
End Constructor

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

    If partCount = 0 Then Exit Sub
    cmd = parts(0)

    If cmd = "RECV" Then
        Dim sku As String = parts(1)
        Dim qty As Integer = Val(parts(2))
        Dim unitCost As Double = Val(parts(3))

        Dim currentStock As Integer = stock.Get(sku, 0)
        stock.Set(sku, currentStock + qty)

        cashBalance = cashBalance - (qty * unitCost)
        eventLog.Add("received " + Str(qty) + " of " + sku + " at " + Str(unitCost))
        Exit Sub
    End If

    If cmd = "SELL" Then
        Dim customer As String = parts(1)
        Dim sku As String = parts(2)
        Dim qty As Integer = Val(parts(3))
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
        Dim orderId As String = parts(1)
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
        Dim sku As String = parts(1)
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
    Dim shipped As Integer = 0
    Dim backorder As Integer = 0
    Dim cancelled As Integer = 0
    Dim i As Integer

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

