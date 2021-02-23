CompilerIf #PB_Compiler_IsMainFile
XIncludeFile "PepperMemory.pbi"

Global hProc=PepperMemory::PepperMemory("csgo.exe")
Global processId=PepperMemory::GetProcessId("csgo.exe")
CompilerEndIf

Global NewMap NetVars.i()

Procedure.s StringToHexSig(string.s)
  Protected hex.s
  Protected i.i
  For i=1 To Len(string)
    hex+Hex(Asc(Mid(string, i, 1)), #PB_Byte)+" "
  Next i
  ProcedureReturn Left(hex, Len(hex)-1)
EndProcedure

Procedure.s IntToHexSig(int.i)
  ProcedureReturn Hex(int&$FF ,#PB_Byte)+" "+Hex((int>>8)&$FF ,#PB_Byte)+" "+Hex((int>>16)&$FF ,#PB_Byte)+" "+Hex((int>>24)&$FF ,#PB_Byte)
EndProcedure

Procedure IsStringValid(string.s)
  Protected i.i, asciiindex.i
  For i=1 To Len(string)
    asciiindex=Asc(Mid(string, i, 1))
    If Not (asciiindex > 47 And asciiindex < 123)
      ProcedureReturn 0
    EndIf
  Next i
  ProcedureReturn 1
EndProcedure

Procedure recScanTable(TableBase.i, Offset.i, ClassName.s)
  Protected TablePropsAmount.i, PropBase.i, PropOffset.i, ChildTable.i, i.i
  Protected PropName.s
  TablePropsAmount=PepperMemory::RPM(hProc, TableBase+4)
  If  TablePropsAmount > (1 << 10) : ProcedureReturn : EndIf
  ;Debug TablePropsAmount
  For i=0 To TablePropsAmount
    PropBase=PepperMemory::RPM(hProc, TableBase)+i*$3C
    PropOffset=PepperMemory::RPM(hProc, PropBase+$2C)+Offset
    PropName.s=PepperMemory::RPM_AsciiString(hProc, PepperMemory::RPM(hProc, PropBase), 64)
    If Len(PropName) = 0 : Continue : EndIf
    If Asc(PropName) > 47 And Asc(PropName) < 58 : Continue : EndIf
    If Not IsStringValid(PropName) : Continue : EndIf
    If Not PropOffset = 0
      NetVars(ClassName+"->"+PropName)=PropOffset
      ;Debug ClassName +"->"+ PropName +": 0x"+ Hex(PropOffset)
    EndIf
    ChildTable=PepperMemory::RPM(hProc, PropBase+$28)
    If Not ChildTable=0 : recScanTable(ChildTable, PropOffset, ClassName) : EndIf
  Next i
EndProcedure

Procedure GetNetVars()
  Protected FirstClass.i, ClientClassBase.i, TableBase.i, TablePropsAmount.i
  Protected TableName.s
  FirstClass = PepperMemory::ScanSignature(hProc, processId, "client.dll", 0, 0, StringtoHexSig("DT_TEWorldDecal"), 0, 0)
  ClientClassBase = PepperMemory::ScanSignature(hProc, processId, "client.dll", $2B, 0, IntToHexSig(FirstClass), 1, 0)
  While ClientClassBase
    TableBase=PepperMemory::RPM(hProc, ClientClassBase+$C)
    TableName.s=PepperMemory::RPM_AsciiString(hProc, PepperMemory::RPM(hProc, TableBase+$C), 32)
    TablePropsAmount=PepperMemory::RPM(hProc, TableBase+4)
    If Len(TableName) > 0 And TablePropsAmount > 0
      recScanTable(TableBase, 0, TableName)
    EndIf
    ClientClassBase=PepperMemory::RPM(hProc, ClientClassBase+$10)
  Wend
EndProcedure

CompilerIf #PB_Compiler_IsMainFile
GetNetVars()
CompilerEndIf

; IDE Options = PureBasic 5.62 (Windows - x64)
; CursorPosition = 59
; FirstLine = 26
; Folding = --
; EnableXP
; EnableUnicode