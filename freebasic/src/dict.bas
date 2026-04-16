Const MAX_ITEMS = 100

Type DictIntType
    keys(MAX_ITEMS) As String
    values(MAX_ITEMS) As Integer
    count As Integer

    Declare Constructor()
    Declare Sub Set(key As String, value As Integer)
    Declare Function Get(key As String, defaultValue As Integer) As Integer
End Type

Constructor DictIntType()
    count = 0
End Constructor

Sub DictIntType.Set(key As String, value As Integer)
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

Function DictIntType.Get(key As String, defaultValue As Integer) As Integer
    Dim i As Integer
    For i = 0 To count - 1
        If keys(i) = key Then
            Return values(i)
        End If
    Next i
    Return defaultValue
End Function

Type DictDoubleType
    keys(MAX_ITEMS) As String
    values(MAX_ITEMS) As Double
    count As Integer

    Declare Constructor()
    Declare Sub Set(key As String, value As Double)
    Declare Function Get(key As String, defaultValue As Double) As Double
End Type

Constructor DictDoubleType()
    count = 0
End Constructor

Sub DictDoubleType.Set(key As String, value As Double)
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

Function DictDoubleType.Get(key As String, defaultValue As Double) As Double
    Dim i As Integer
    For i = 0 To count - 1
        If keys(i) = key Then
            Return values(i)
        End If
    Next i
    Return defaultValue
End Function

Type DictStringType
    keys(MAX_ITEMS) As String
    values(MAX_ITEMS) As String
    count As Integer

    Declare Constructor()
    Declare Sub Set(key As String, value As String)
    Declare Function Get(key As String, defaultValue As String) As String
End Type

Constructor DictStringType()
    count = 0
End Constructor

Sub DictStringType.Set(key As String, value As String)
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

Function DictStringType.Get(key As String, defaultValue As String) As String
    Dim i As Integer
    For i = 0 To count - 1
        If keys(i) = key Then
            Return values(i)
        End If
    Next i
    Return defaultValue
End Function
