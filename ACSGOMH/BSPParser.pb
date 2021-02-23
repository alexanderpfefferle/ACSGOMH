
#LUMP_PLANES = 1
#LUMP_NODES = 5
#LUMP_LEAFS = 10

Structure Vector3D
  x.f
  y.f
  z.f
EndStructure

Structure dnode_t
  m_PlaneNum.i
  m_Children.i[2]
  m_Mins.w[3]
  m_Maxs.w[3]
  m_Firstface.u
  m_Numfaces.u
  m_Area.w
  padding.w
EndStructure

Structure dleaf_t
  m_Contents.i
  m_Cluster.w
  m_Area.i
  m_Flags.i
  m_Mins.w[3]
  m_Maxs.w[3]
  m_Firstleafface.i
  m_Numleaffaces.i
  m_Firstleafbrush.i
  m_Numleafbrushes.i
  m_LeafWaterDataID.w
EndStructure

Structure dplane_t
  m_Normal.Vector3D
  distance.f
  type.i
EndStructure

Structure lump_t
  m_FileOffset.i
  m_FileLength.i
  m_Version.i
  padding.i
EndStructure

Structure dheader_t
  m_Identifier.i
  m_Version.i
  m_Lumps.lump_t[64]
  m_MapRevision.i
EndStructure

Global pMap.dheader_t

Procedure ParseBSP(FilePath.s="C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\csgo\maps\de_dust2.bsp")
  Protected x.i, y.i
  Protected AreaFlags.i
  If Not ReadFile(0, FilePath, #PB_Ascii)
    ProcedureReturn 0
  EndIf
;----------------
  Global LeafsAmount = 0
  Global PlanesAmount = 0
  Global NodesAmount = 0
  pMap\m_Identifier = ReadInteger(0)
  pMap\m_Version = ReadInteger(0)
  For x=0 To 63
    pMap\m_Lumps[x]\m_FileOffset = ReadInteger(0)
    pMap\m_Lumps[x]\m_FileLength = ReadInteger(0)
    pMap\m_Lumps[x]\m_Version = ReadInteger(0)
    pMap\m_Lumps[x]\padding = ReadInteger(0)
  Next x
  pMap\m_MapRevision = ReadInteger(0)
  FileSeek(0, pMap\m_Lumps[#LUMP_LEAFS]\m_FileOffset)
  LeafsAmount = pMap\m_Lumps[#LUMP_LEAFS]\m_FileLength/56-1
  Global Dim Leafs.dleaf_t(LeafsAmount)
  For x=0 To LeafsAmount
    Leafs(x)\m_Contents = ReadInteger(0)
    Leafs(x)\m_Cluster = ReadWord(0)
    AreaFlags = ReadInteger(0)
    Leafs(x)\m_Area = AreaFlags & $1FF
    Leafs(x)\m_Flags = (AreaFlags >> 9) & $3F
    For y=0 To 2
      Leafs(x)\m_Maxs[y]=ReadWord(0)
    Next y
    For y=0 To 2
      Leafs(x)\m_Mins[y]=ReadWord(0)
    Next y
    Leafs(x)\m_Firstleafface=ReadUnicodeCharacter(0)
    Leafs(x)\m_Numleaffaces=ReadUnicodeCharacter(0)
    Leafs(x)\m_Firstleafbrush=ReadUnicodeCharacter(0)
    Leafs(x)\m_Numleafbrushes=ReadUnicodeCharacter(0)
    Leafs(x)\m_LeafWaterDataID=ReadWord(0)
  Next x
  FileSeek(0, pMap\m_Lumps[#LUMP_PLANES]\m_FileOffset)
  PlanesAmount = pMap\m_Lumps[#LUMP_PLANES]\m_FileLength/20-1
  Global Dim Planes.dplane_t(PlanesAmount)
  For x=0 To PlanesAmount
    Planes(x)\m_Normal\x=ReadFloat(0)
    Planes(x)\m_Normal\y=ReadFloat(0)
    Planes(x)\m_Normal\z=ReadFloat(0)
    Planes(x)\distance=ReadFloat(0)
    Planes(x)\type=ReadInteger(0)
  Next x
  FileSeek(0, pMap\m_Lumps[#LUMP_NODES]\m_FileOffset)
  NodesAmount = pMap\m_Lumps[#LUMP_NODES]\m_FileLength/32-1
  Global Dim Nodes.dnode_t(NodesAmount)
  For x=0 To NodesAmount
    Nodes(x)\m_PlaneNum=ReadInteger(0)
    For y=0 To 1
      Nodes(x)\m_Children[y]=ReadInteger(0)
    Next y
    For y=0 To 2
      Nodes(x)\m_Mins[y]=ReadWord(0)
    Next y
    For y=0 To 2
      Nodes(x)\m_Maxs[y]=ReadWord(0)
    Next y
    Nodes(x)\m_Firstface=ReadUnicodeCharacter(0)
    Nodes(x)\m_Numfaces=ReadUnicodeCharacter(0)
    Nodes(x)\m_Area=ReadWord(0)
    Nodes(x)\padding=ReadWord(0)
  Next x
;----------------
  CloseFile(0)
EndProcedure

Global currentLeaf.dleaf_t

Procedure GetLeafForPoint(*point.Vector3D, *returnLeaf.dleaf_t)
  Protected index = 0
  Protected pNode.dnode_t
  Protected pPlane.dplane_t
  Protected distance.f
  
  While index > -1
    pNode = Nodes(index)
    pPlane = Planes(pNode\m_PlaneNum)
    distance = (*point\x * pPlane\m_Normal\x + *point\y * pPlane\m_Normal\y + *point\z * pPlane\m_Normal\z) - pPlane\distance
    If distance > 0
      index = pNode\m_Children[0]
    Else
      index = pNode\m_Children[1]
    EndIf
  Wend
  
  If -index-1 > -1 And -index-1 < LeafsAmount
    *returnLeaf\m_Area=Leafs(-index-1)\m_Area
    *returnLeaf\m_Contents=Leafs(-index-1)\m_Contents
  Else
    *returnLeaf\m_Area = -1
    *returnLeaf\m_Contents = 0
  EndIf
  
EndProcedure


Procedure.i pIsVisible(*source.Vector3D, *destination.Vector3D)
  Protected steps.f
  Protected direction.Vector3D
  Protected currentPoint.Vector3D
  
  direction\x=*destination\x-*source\x
  direction\y=*destination\y-*source\y
  direction\z=*destination\z-*source\z
  steps=Sqr(direction\x*direction\x + direction\y*direction\y + direction\z*direction\z)
  direction\x=direction\x/steps
  direction\y=direction\y/steps
  direction\z=direction\z/steps
  CopyStructure(*destination, @currentPoint, Vector3D)
  While steps > -1
    currentPoint\x=currentPoint\x-direction\x
    currentPoint\y=currentPoint\y-direction\y
    currentPoint\z=currentPoint\z-direction\z
    GetLeafForPoint(currentPoint, @currentLeaf)
    If currentLeaf\m_Area <> -1
      If currentLeaf\m_Contents&1 <> 0
        ProcedureReturn 0
      EndIf
    EndIf
    steps-1
  Wend
  ProcedureReturn 1
EndProcedure

Procedure.i BSP_IsVisible(firstx.i, firsty.i, firstz.i, secondx.i, secondy.i, secondz.i)
  Protected ftestpos.Vector3D
  Protected stestpos.Vector3D
  ftestpos\x=firstx
  ftestpos\y=firsty
  ftestpos\z=firstz
  stestpos\x=secondx
  stestpos\y=secondy
  stestpos\z=secondz
  ProcedureReturn pIsVisible(ftestpos, stestpos)
EndProcedure

CompilerIf #PB_Compiler_IsMainFile
  ParseBSP()
  Debug BSP_IsVisible(-152.3497619629,2151.1154785156,-62.3950958252,376.8009033203,2096.5656738281,-64.2292785645); true
  Debug BSP_IsVisible(401.8158874512,2115.0153808594,159.5975494385,252.1534881592,2475.6203613281,-58.7042388916); false
CompilerEndIf

; IDE Options = PureBasic 5.43 LTS (Windows - x86)
; CursorPosition = 10
; Folding = -
; EnableUnicode
; EnableThread
; EnableXP