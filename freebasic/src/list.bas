
Type StringList
    private:
        Const MAX_ITEMS = 100
        items(MAX_ITEMS) As String
        count As Integer

    public:
        Declare Constructor()
        Declare Sub Clear()
        Declare Sub Add(item As String)
        Declare Function Get(index As Integer) As String
        Declare Function Contains(item As String) As Integer
        Declare Sub PrintItemsOneLine()
        Declare Sub PrintItems()
End Type

Constructor StringList()
    count = 0
End Constructor

Sub StringList.Clear()
    count = 0
End Sub

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

Function StringList.Contains(item As String) As Integer
    Dim i As Integer
    For i = 0 To count - 1
        If items(i) = item Then
            Return 1
        End If
    Next i
    Return 0
End Function

Sub StringList.PrintItemsOneLine()
    Dim s As String = "["
    Dim i As Integer
    For i = 0 To count - 1
        If i > 0 Then s = s + ", "
        s = s + items(i)
    Next i
    s = s + "]"
    Print s;
End Sub

Sub StringList.PrintItems()
    Dim i As Integer
    For i = 0 To count - 1
        Print " - "; items(i)
    Next i
End Sub
