Set colItems = GetObject("winmgmts:\\.\root\cimv2").ExecQuery("Select * from Win32_UserAccount")
Set colGroups = GetObject("WinNT://./Administrators,group")

Wscript.Echo "AccountType" & "," & "Name" & "," & "Disabled" & "," _
& "Lockout" & "," & "PasswordChangeable" & "," & "PasswordExpires" _
& "," & "PasswordRequired" & "," & "Status" & "," & "Administrator" _
& "," & "Description"

For Each objItem in colItems
	Admin="False"
	For Each objMember in colGroups.Members
		If objMember.Name = objItem.Name Then Admin = "True"
	Next
	Wscript.Echo objItem.AccountType & "," & objItem.Name & _
	"," & objItem.Disabled & "," & objItem.Lockout & "," & _
	objItem.PasswordChangeable & "," & objItem.PasswordExpires _
	& "," & objItem.PasswordRequired & "," & objItem.Status & "," _
	& Admin & "," & objItem.Description
Next


