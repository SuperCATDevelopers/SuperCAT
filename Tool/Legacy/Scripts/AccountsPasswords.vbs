On Error Resume Next

Set colItems = GetObject("winmgmts:\\.\root\cimv2").ExecQuery("Select * from Win32_UserAccount")
Set colGroups = GetObject("WinNT://./Administrators,group")
Set colPassword = GetObject("WinNT://.")

Wscript.Echo "AccountType" & "," & "Name" & "," & "Disabled" & "," _
& "Lockout" & "," & "PasswordChangeable" & "," & "PasswordExpires" _
& "," & "PasswordRequired" & "," & "Status" & "," & "Administrator" _
& "," & "BlankPassword" & "," & "Description"

For Each objItem in colItems
	Admin="False"
	BlankPassword="No"
	strPassword=""
	For Each objMember in colGroups.Members
		If objMember.Name = objItem.Name Then Admin = "True"
		objMember.ChangePassword strPassword, strPassword
			If Err=0 or Err=-2147023569 Then BlankPassword="Yes"
		Err.Clear
	Next

	Wscript.Echo objItem.AccountType & "," & objItem.Name & _
	"," & objItem.Disabled & "," & objItem.Lockout & "," & _
	objItem.PasswordChangeable & "," & objItem.PasswordExpires _
	& "," & objItem.PasswordRequired & "," & objItem.Status & "," _
	& Admin & "," & BlankPassword & "," & objItem.Description
Next


