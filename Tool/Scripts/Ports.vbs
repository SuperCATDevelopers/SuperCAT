On Error Resume Next
Set oWMI = GetObject("WinMgmts://./root/cimv2") 
Set cProcesses = oWMI.ExecQuery("SELECT * FROM Win32_Process")
ReDim aProcesses(cProcesses.Count - 1)                                                          
i = 0 
For Each oProcess In cProcesses
    Set aProcesses(i) = New PROCESS
    aProcesses(i).Name = oProcess.Name
    aProcesses(i).PID =  oProcess.ProcessID
    i = i + 1
Next

Set cProcesses = Nothing
Set oWMI = Nothing 

Set oWshShell = CreateObject("WScript.Shell")
Set oExec = oWshShell.Exec("netstat.exe -ano")
sOutput = oExec.StdOut.ReadAll
Set oExec = Nothing

Set oRegExp = New RegExp
oRegExp.Global = True 
 
oRegExp.Pattern = "TCP +[0-9\.]+:([0-9]{1,5}) [ 0-9\.:]+ LISTENING +([0-9]{1,5})"
Set cMatches = oRegExp.Execute(sOutput) 
For Each sMatch in cMatches
    sPort = sMatch.SubMatches.Item(0)
    sPID  = sMatch.SubMatches.Item(1)                              
    For Each oProc In aProcesses
        If oProc.PID = sPID Then oProc.TcpPorts = oProc.TcpPorts & "TCP:" & sPort & " "
    Next
Next
 
oRegExp.Pattern = "UDP +[0-9\.]+:([0-9]{1,5}).+ ([0-9]{1,5})"
Set cMatches = oRegExp.Execute(sOutput) 
For Each sMatch in cMatches
    sPort = sMatch.SubMatches.Item(0)
    sPID  = sMatch.SubMatches.Item(1)                              
    For Each oProc In aProcesses
        If oProc.PID = sPID Then oProc.UdpPorts = oProc.UdpPorts & ";UDP:" & sPort & " "
    Next
Next

Set cMatches = Nothing
Set oRegExp = Nothing 
 
For Each oProc In aProcesses
        oProc.PrintList
Next        

Class PROCESS
    Public Name
    Public UdpPorts
    Public TcpPorts
    Private pvtPID
    Public ServiceName
    Private pvtReport
    
    Public Property Let PID(ByVal sPID) 
        pvtPID = CStr(sPID)
    End Property
    
    Public Property Get PID
        PID = CStr(pvtPID)
    End Property    
 
    Public Sub PrintList
        pvtReport = "" 
        pvtReport = pvtReport & Name & "," & CStr(pvtPID)& "," & Replace(Trim(TcpPorts)," ",";") & Replace(Trim(UdpPorts)," ","")
        WScript.Echo(pvtReport)
    End Sub
End Class