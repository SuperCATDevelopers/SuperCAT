SET objFS=CreateObject("Scripting.FileSystemObject")
SET objArgs=Wscript.Arguments
strFile1=objArgs(0)
SET objFile1=objFS.GetFile(strFile1)
DateModified=objFile1.DateLastModified
If Left(DateModified,1) < 10 Then 
	Wscript.StdOut.Write(Left(DateModified,9) & " ")
Else
	Wscript.StdOut.Write(Left(DateModified,10))
End If