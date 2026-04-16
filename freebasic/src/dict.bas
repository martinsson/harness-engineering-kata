Const MAX_ITEMS = 100

Sub InitDictInt(keys() As String, values() As Integer, ByRef count As Integer)
    count = 0
End Sub

Sub InitDictDouble(keys() As String, values() As Double, ByRef count As Integer)
    count = 0
End Sub

Sub InitDictString(keys() As String, values() As String, ByRef count As Integer)
    count = 0
End Sub

Sub DictSetInt(keys() As String, values() As Integer, ByRef count As Integer, key As String, value As Integer)
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

Sub DictSetDouble(keys() As String, values() As Double, ByRef count As Integer, key As String, value As Double)
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

Sub DictSetString(keys() As String, values() As String, ByRef count As Integer, key As String, value As String)
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

Function DictGetInt(keys() As String, values() As Integer, count As Integer, key As String, defaultValue As Integer) As Integer
    Dim i As Integer
    For i = 0 To count - 1
        If keys(i) = key Then
            Return values(i)
        End If
    Next i
    Return defaultValue
End Function

Function DictGetDouble(keys() As String, values() As Double, count As Integer, key As String, defaultValue As Double) As Double
    Dim i As Integer
    For i = 0 To count - 1
        If keys(i) = key Then
            Return values(i)
        End If
    Next i
    Return defaultValue
End Function

Function DictGetString(keys() As String, values() As String, count As Integer, key As String, defaultValue As String) As String
    Dim i As Integer
    For i = 0 To count - 1
        If keys(i) = key Then
            Return values(i)
        End If
    Next i
    Return defaultValue
End Function
