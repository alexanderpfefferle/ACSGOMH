DeclareModule PepperMemory
  Declare.q GetProcessID(ProcessName.s)
  Declare.q PepperMemory(ProcessName.s)
  Declare.q GetModuleBase(ProcessID.q, ModuleName.s)
  Declare.q GetModuleSize(ProcessID.q, ModuleName.s)
  Declare.q RPM(p.q, addr.q)
  Declare.l RPM_Int(p.q, addr.q)
  Declare.b RPM_Byte(p.q, addr.q)
  Declare.c RPM_Char(p.q, addr.q)
  Declare.w RPM_Word(p.q, addr.q)
  Declare.f RPM_Float(p.q, addr.q)
  Declare.s RPM_AsciiString(p.q, addr.q, len.q)
  Declare.s RPM_UnicodeString(p.q, addr.q, len.q)
  Declare.q WPM(p.q, addr.q, value.q)
  Declare.q WPM_Int(p.q, addr.q, value.l)
  Declare.q WPM_Word(p.q, addr.q, value.w)
  Declare.q WPM_Float(p.q, addr.q, value.f)
  Declare.q WPM_AsciiString(p.q, addr.q, value.s)
  Declare.q WPM_UnicodeString(p.q, addr.q, value.s)
  Declare.q WPM_Byte(p.q, addr.q, value.b)
  Declare InjectDll(ProcessName.s, DLLPath.s)
  Declare.q ScanSignature(ProcessHandle.q, ProcessID.l, ModuleName.s, Extra.l, Offset.l, Signature.s, fRead=1, fSubtract.l=1)
EndDeclareModule

Module PepperMemory

Global kernel32=OpenLibrary(#PB_Any, "kernel32.dll")

Procedure.q GetProcessID(ProcessName.s)
   Protected hSnapshot.l
   Protected ProcessInfo.PROCESSENTRY32
   If kernel32
      hSnapshot=CreateToolhelp32Snapshot_(#TH32CS_SNAPPROCESS, 0)
      If hSnapshot
         ProcessInfo\dwSize=SizeOf(PROCESSENTRY32)
         If Process32First_(hSnapshot, @ProcessInfo)
            Repeat
               If ProcessName=PeekS(@ProcessInfo\szExeFile, -1, #PB_Unicode)
                  ProcedureReturn ProcessInfo\th32ProcessID
               EndIf
            Until Not Process32Next_(hSnapshot, @ProcessInfo)
         EndIf
         CloseHandle_(hSnapshot)
      EndIf
   EndIf
   ProcedureReturn -1
EndProcedure

Procedure.q PepperMemory(ProcessName.s)
  ProcedureReturn OpenProcess_(#PROCESS_ALL_ACCESS, 0, GetProcessID(ProcessName))
EndProcedure

Procedure.q GetModuleBase(ProcessID.q, ModuleName.s)
   Protected hSnapshot.l
   Protected ModuleInfo.MODULEENTRY32
   If kernel32
      hSnapshot=CreateToolhelp32Snapshot_(#TH32CS_SNAPMODULE | #TH32CS_SNAPMODULE32, ProcessID)
      If hSnapshot
         ModuleInfo\dwSize=SizeOf(MODULEENTRY32)
         If Module32First_(hSnapshot, @ModuleInfo)
            Repeat
               Protected moduleName$=PeekS(@ModuleInfo\szModule, -1, #PB_Unicode)
               If moduleName$=ModuleName
                  ProcedureReturn ModuleInfo\modBaseAddr
               EndIf
            Until Not Module32Next_(hSnapshot, @ModuleInfo)
         EndIf
         CloseHandle_(hSnapshot)
      EndIf
   EndIf
   ProcedureReturn -1
EndProcedure
 
Procedure.q GetModuleSize(ProcessID.q, ModuleName.s)
   Protected hSnapshot.l
   Protected ModuleInfo.MODULEENTRY32
   If kernel32
      hSnapshot=CreateToolhelp32Snapshot_(#TH32CS_SNAPMODULE | #TH32CS_SNAPMODULE32, ProcessID)
      If hSnapshot
         ModuleInfo\dwSize=SizeOf(MODULEENTRY32)
         If Module32First_(hSnapshot, @ModuleInfo)
            Repeat
               Protected moduleName$=PeekS(@ModuleInfo\szModule, -1, #PB_Unicode)
               If moduleName$=ModuleName
                  ProcedureReturn ModuleInfo\modBaseSize
               EndIf
            Until Not Module32Next_(hSnapshot, @ModuleInfo)
         EndIf
         CloseHandle_(hSnapshot)
      EndIf
   EndIf
   ProcedureReturn -1
EndProcedure
 
;----Read----;

Procedure.q RPM(p.q, addr.q)
  Protected qtr.l
  If addr <> 0
    ReadProcessMemory_(p, addr, @qtr, SizeOf(qtr), 0)
    ProcedureReturn qtr&$FFFFFFFF
  EndIf
EndProcedure

Procedure.l RPM_Int(p.q, addr.q)
  Protected itr.l
  If addr <> 0
    ReadProcessMemory_(p, addr, @itr, SizeOf(itr), 0)
    ProcedureReturn itr
  EndIf
EndProcedure

Procedure.b RPM_Byte(p.q, addr.q)
  Protected itr.b
  If addr <> 0
    ReadProcessMemory_(p, addr, @itr, SizeOf(itr), 0)
    ProcedureReturn itr
  EndIf
EndProcedure

Procedure.c RPM_Char(p.q, addr.q)
  Protected ctr.c
  If addr <> 0
    ReadProcessMemory_(p, addr, @ctr, SizeOf(ctr), 0)
    ProcedureReturn ctr
  EndIf
EndProcedure

Procedure.w RPM_Word(p.q, addr.q)
  Protected wtr.w
  If addr <> 0
    ReadProcessMemory_(p, addr, @wtr, SizeOf(wtr), 0)
    ProcedureReturn wtr
  EndIf
EndProcedure

Procedure.f RPM_Float(p.q, addr.q)
  Protected ftr.f
  If addr <> 0
    ReadProcessMemory_(p, addr, @ftr, SizeOf(ftr), 0)
    ProcedureReturn ftr
  EndIf
EndProcedure

Procedure.s RPM_AsciiString(p.q, addr.q, len.q)
  Protected *stringbuffer=0
  Protected str.s=Space(len)
  If addr <> 0
    *stringbuffer=AllocateMemory(len)
    ReadProcessMemory_(p, addr, *stringbuffer, len, 0)
    str=PeekS(*stringbuffer, len, #PB_Ascii)
    FreeMemory(*stringbuffer)
    ProcedureReturn str
  EndIf
EndProcedure

Procedure.s RPM_UnicodeString(p.q, addr.q, len.q)
  Protected str.s=Space(len)
  If addr <> 0
    ReadProcessMemory_(p, addr, @str, len+1, 0)
    ProcedureReturn str
  EndIf
EndProcedure

;----Write----;

Procedure.q WPM(p.q, addr.q, value.q)
  If addr <> 0
    ProcedureReturn WriteProcessMemory_(p, addr, @value, SizeOf(value), 0)
  EndIf
EndProcedure

Procedure.q WPM_Int(p.q, addr.q, value.l)
  If addr <> 0
    ProcedureReturn WriteProcessMemory_(p, addr, @value, SizeOf(value), 0)
  EndIf
EndProcedure

Procedure.q WPM_Word(p.q, addr.q, value.w)
  If addr <> 0
    ProcedureReturn WriteProcessMemory_(p, addr, @value, SizeOf(value), 0)
  EndIf
EndProcedure

Procedure.q WPM_Float(p.q, addr.q, value.f)
  If addr <> 0
    ProcedureReturn WriteProcessMemory_(p, addr, @value, SizeOf(value), 0)
  EndIf
EndProcedure

Procedure.q WPM_AsciiString(p.q, addr.q, value.s)
  Protected *stringbuffer = AllocateMemory(Len(value))
  PokeS(*stringbuffer, value, -1, #PB_Ascii)
  If addr <> 0
    ProcedureReturn WriteProcessMemory_(p, addr, *stringbuffer, Len(value)+1, 0)
  EndIf
EndProcedure

Procedure.q WPM_UnicodeString(p.q, addr.q, value.s)
  If addr <> 0
    ProcedureReturn WriteProcessMemory_(p, addr, @value, Len(value)*2+1, 0)
  EndIf
EndProcedure

Procedure.q WPM_Byte(p.q, addr.q, value.b)
  If addr <> 0
    ProcedureReturn WriteProcessMemory_(p, addr, @value, SizeOf(value), 0)
  EndIf
EndProcedure

;----LoadLibraryDLLInjection----;

Procedure InjectDll(ProcessName.s, DLLPath.s)
Protected hProc.l
Protected LoadLibraryAddress.l
Protected ParameterAddress.l
Protected hThread.l
Protected pathLen = Len(DLLPath)*2+1

hProc=OpenProcess_(#PROCESS_ALL_ACCESS, 0, GetProcessID(ProcessName))
LoadLibraryAddress=GetFunction(kernel32, "LoadLibraryW")
ParameterAddress=VirtualAllocEx_(hProc, 0, pathLen, #MEM_RESERVE | #MEM_COMMIT, #PAGE_READWRITE)
WriteProcessMemory_(hProc, ParameterAddress, @DLLPath, pathLen, 0)
hThread=CreateRemoteThread_(hProc, 0, 0, LoadLibraryAddress, ParameterAddress, 0, 0)
WaitForSingleObject_(hThread, -1)
CloseHandle_(hThread)
CloseHandle_(hProc)
ProcedureReturn 1
EndProcedure

;----SignatureScanning----;

Procedure HextoByte(HexValue.s)
  Protected temp.l
  temp=Val("$" + HexValue)
  If temp > 127
    ProcedureReturn temp - 256
  Else
    ProcedureReturn temp
  EndIf
EndProcedure

Procedure compareData(Array ModuleData.b(1), currentOffset.l, Array Sig.b(1), Array Mask.b(1))
  Protected x.l
  For x=0 To ArraySize(Sig())
    If Mask(x) And Not (Sig(x) = ModuleData(currentOffset+x))
      ProcedureReturn 0
    EndIf
  Next x
  ProcedureReturn 1
EndProcedure

Procedure.q ScanSignature(ProcessHandle.q, ProcessID.l, ModuleName.s, Extra.l, Offset.l, Signature.s, fRead=1, fSubtract.l=1)
  Protected x.l
  Protected moduleBase.l
  Protected maxScanOffset.l
  Protected Sigsize=CountString(Signature, " ")+1
  
  Dim sig.b(Sigsize-1)
  Dim mask.b(Sigsize-1)
  
  For x=0 To Sigsize-1
    sig(x)=HextoByte(StringField(ReplaceString(Signature, "?", "00"), x+1, " "))
    If StringField(Signature, x+1, " ") = "?"
      mask(x)=0
    Else
      mask(x)=1
    EndIf
  Next x 
  
  moduleBase = GetModuleBase(ProcessID, ModuleName)
  maxScanOffset = GetModuleSize(ProcessID, ModuleName) - Sigsize
  
  Dim ModuleData.b(maxScanOffset + Sigsize - 1)
  ReadProcessMemory_(ProcessHandle, moduleBase, @ModuleData(), maxScanOffset + Sigsize, 0)
  
  For x=0 To maxScanOffset
    If compareData(ModuleData(), x, sig(), mask())
      x + moduleBase + Extra
      If fRead
        x = RPM(ProcessHandle, x)
      EndIf
      If fSubtract
        x - moduleBase
      EndIf
      x + Offset
      ProcedureReturn x
    EndIf
  Next x
  ProcedureReturn -1
EndProcedure

EndModule

; IDE Options = PureBasic 5.62 (Windows - x64)
; Folding = -----
; EnableXP
; EnableUnicode