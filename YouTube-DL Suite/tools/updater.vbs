Set http_obj = CreateObject("MSXML2.ServerXMLHTTP")
http_obj.open "GET", "https://api.github.com/repos/MinorMole/YouTube-DL-Suite/releases/latest", False
http_obj.send
If http_obj.Status = 200 Then
	SplitLine = Split(replace(http_obj.responseText,": ",":"), """tag_name"":""")
	CleanChar = Split(SplitLine(1), """,")
	Set objFileToWrite = CreateObject("Scripting.FileSystemObject").OpenTextFile(replace(WScript.ScriptFullName,WScript.ScriptName,"") & "version",2,true)
	objFileToWrite.WriteLine(CleanChar(0))
	objFileToWrite.Close
End If