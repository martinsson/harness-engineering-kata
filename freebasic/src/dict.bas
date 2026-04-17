
Type IntegerDict
    private:
        Const MAX_ITEMS = 100
    public:
        keys(MAX_ITEMS) As String
        values(MAX_ITEMS) As Integer
        count As Integer

        Declare Constructor()
        Declare Sub Set(key As String, value As Integer)
        Declare Function Get(key As String, defaultValue As Integer) As Integer
        Declare Sub PrintKeyValues()
End Type

Constructor IntegerDict()
    count = 0
End Constructor

Sub IntegerDict.Set(key As String, value As Integer)
    Dim i As Integer
    For i = 0 To count - 1
        If keys(i) = key Then
            values(i) = value
            Exit Sub
        End If
    Next i

    If count < MAX_ITEMS Then
        keys(count) = key
        values(count) = value
        count = count + 1
    End If
End Sub

Function IntegerDict.Get(key As String, defaultValue As Integer) As Integer
    Dim i As Integer
    For i = 0 To count - 1
        If keys(i) = key Then
            Return values(i)
        End If
    Next i
    Return defaultValue
End Function

Sub IntegerDict.PrintKeyValues()
    Dim i As Integer
    For i = 0 To count - 1
        Print keys(i) + "=" + Str(values(i)) + " ";
    Next i
    Print
End Sub

Type DoubleDict
    private:
        Const MAX_ITEMS = 100
        keys(MAX_ITEMS) As String
        values(MAX_ITEMS) As Double
        count As Integer

    public:
        Declare Constructor()
        Declare Sub Set(key As String, value As Double)
        Declare Function Get(key As String, defaultValue As Double) As Double
        Declare Sub PrintKeyValues()
End Type

Constructor DoubleDict()
    count = 0
End Constructor

Sub DoubleDict.Set(key As String, value As Double)
    Dim i As Integer
    For i = 0 To count - 1
        If keys(i) = key Then
            values(i) = value
            Exit Sub
        End If
    Next i

    If count < MAX_ITEMS Then
        keys(count) = key
        values(count) = value
        count = count + 1
    End If
End Sub

Function DoubleDict.Get(key As String, defaultValue As Double) As Double
    Dim i As Integer
    For i = 0 To count - 1
        If keys(i) = key Then
            Return values(i)
        End If
    Next i
    Return defaultValue
End Function

Sub DoubleDict.PrintKeyValues()
    Dim i As Integer
    For i = 0 To count - 1
        Print keys(i) + "=" + Str(values(i)) + " ";
    Next i
    Print
End Sub

Type StringDict
    private:
        Const MAX_ITEMS = 100
    public:
        keys(MAX_ITEMS) As String
        values(MAX_ITEMS) As String
        count As Integer

        Declare Constructor()
        Declare Sub Set(key As String, value As String)
        Declare Function Get(key As String, defaultValue As String) As String
        Declare Sub PrintKeyValues()
End Type

Constructor StringDict()
    count = 0
End Constructor

Sub StringDict.Set(key As String, value As String)
    Dim i As Integer
    For i = 0 To count - 1
        If keys(i) = key Then
            values(i) = value
            Exit Sub
        End If
    Next i

    If count < MAX_ITEMS Then
        keys(count) = key
        values(count) = value
        count = count + 1
    End If
End Sub

Function StringDict.Get(key As String, defaultValue As String) As String
    Dim i As Integer
    For i = 0 To count - 1
        If keys(i) = key Then
            Return values(i)
        End If
    Next i
    Return defaultValue
End Function

Sub StringDict.PrintKeyValues()
    Dim i As Integer
    For i = 0 To count - 1
        Print keys(i) + "=" + values(i) + " ";
    Next i
    Print
End Sub
