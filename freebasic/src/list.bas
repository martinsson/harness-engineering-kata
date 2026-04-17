Type StringList
    private:
        Const MAX_ITEMS = 100
        items(MAX_ITEMS) As String
        count As Integer

    public:
        Declare Constructor()
        Declare Sub Add(item As String)
        Declare Function Get(index As Integer) As String
        Declare Sub PrintItemsOneLine()
        Declare Sub PrintItems()
End Type

Constructor StringList()
    count = 0
End Constructor

Sub StringList.Add(item As String)
    If count < MAX_ITEMS Then
        items(count) = item
        count = count + 1
    End If
End Sub

Function StringList.Get(index As Integer) As String
    If index >= 0 And index < count Then
        Return items(index)
    Else
        Return ""
    End If
End Function

Sub StringList.PrintItemsOneLine()
    Dim i As Integer
    For i = 0 To count - 1
        Print items(i) + " ";
    Next i
End Sub

Sub StringList.PrintItems()
    Dim i As Integer
    For i = 0 To count - 1
        Print " - "; items(i)
    Next i
End Sub
