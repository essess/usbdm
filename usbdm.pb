; -----------------------------------------------------------------------------
; Copyright (c) 2014 Sean Stasiak. All rights reserved.
; Developed by: Sean Stasiak <sstasiak@gmail.com>
; Refer to license terms in license.txt; In the absence of such a file,
; contact me at the above email address and I can provide you with one.
; -----------------------------------------------------------------------------
EnableExplicit

XIncludeFile "assert.pbi"
XIncludeFile "dll.pbi"

If OpenConsole()
  If USBDM_Load()
    PrintN("DLL Loaded.")
    If USBDM_SUCCESS( USBDM_Init() )
      PrintN("USBDM_DllVersion(): $"+RSet(Hex(USBDM_DLLVersion()),8,"0"))
      Print("Found: ")
      Define cnt.i=0, str.String
      If USBDM_SUCCESS( USBDM_FindDevices(@cnt) )
        PrintN( Str(cnt)+" USBDM" )
        USBDM_Open(0)
        
        USBDM_GetBDMSerialNumber( @str ) : PrintN("Serial Number: "+Chr(34)+str\s+Chr(34))
        USBDM_GetBDMDescription( @str )  : PrintN("Description: "+Chr(34)+str\s+Chr(34))
        
        USBDM_SetTargetType( #T_HCS12 )
        USBDM_TargetReset( #RESET_NORMAL|#RESET_HARDWARE )
        USBDM_Connect()
        USBDM_TargetHalt()
        
        DataSection
          
          start_hcs12x_code0:        ; 1.715MHz @ 8MHz busclock (modifies pp entirely)
          Data.b  $86, $80          ;ldaa   #$80
          Data.b  $7a, $02, $5a     ;staa   $025a
          Data.b  $7a, $02, $58     ;staa   $0258
          Data.b  $88, $80          ;eora   #$80
          Data.b  $20, -7           ;bra    -7 ($f9)
          end_hcs12x_code0:
          
          start_hcs12x_code1:        ; 1.2MHz @ 8MHz busclock (modifies pp7 only)
          Data.b  $c6, $80          ;ldab   #$80
          Data.b  $b7, $10          ;tfr    b, a
          Data.b  $b8, $02, $5a     ;eora   $025a
          Data.b  $7a, $02, $5a     ;staa   $025a
          Data.b  $b7, $10          ;tfr    b, a
          Data.b  $b8, $02, $58     ;eora   $0258
          Data.b  $7a, $02, $58     ;staa   $0258
          Data.b  $20, -10          ;bra    -10 ($f6)
          end_hcs12x_code1:
          
        EndDataSection
        
        ;USBDM_WriteMemory( #MS_Byte, ?end_hcs12x_code0-?start_hcs12x_code0, $2000, ?start_hcs12x_code0 )
        USBDM_WriteMemory( #MS_Byte, ?end_hcs12x_code1-?start_hcs12x_code1, $2000, ?start_hcs12x_code1 )
        USBDM_WriteReg( #HCS12_RegPC, $2000 )
        USBDM_TargetGo()
        PrintN("Code Loaded and Running.")
        
        USBDM_Close()
        USBDM_ReleaseDevices()
      Else
        PrintN("0 Devices")
      EndIf
      USBDM_Exit()
    EndIf
  Else
    PrintN("Unable to load USBDM DLL.")
    Delay(2000)
  EndIf
  PrintN("Press Return") : Input()
EndIf
