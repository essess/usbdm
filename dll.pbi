; -----------------------------------------------------------------------------
; Copyright (c) 2014 Sean Stasiak. All rights reserved.
; Developed by: Sean Stasiak <sstasiak@gmail.com>
; Refer to license terms in license.txt; In the absence of such a file,
; contact me at the above email address and I can provide you with one.
; -----------------------------------------------------------------------------
EnableExplicit
XIncludeFile "assert.pbi"

; PUBLIC
;{
Structure tUSBDM_Version Align #PB_Structure_AlignC
  bdmSoftwareVersion.a        ;< Version of USBDM Firmware
  bdmHardwareVersion.a        ;< Version of USBDM Hardware
  icpSoftwareVersion.a        ;< Version of ICP bootloader Firmware
  icpHardwareVersion.a        ;< Version of Hardware (reported by ICP code)
EndStructure

Structure tUSBDM_bdmInformation Align #PB_Structure_AlignC
  size.i                      ;< Size of this structure
  BDMsoftwareVersion.i        ;< BDM Firmware version as 3 bytes (4.10.4 => 0x040A04)
  BDMhardwareVersion.i        ;< Hardware version reported by BDM firmware
  ICPsoftwareVersion.i        ;< ICP Firmware version
  ICPhardwareVersion.i        ;< Hardware version reported by ICP firmware
  capabilities.i              ;< BDM Capabilities (HardwareCapabilities_t)
  commandBufferSize.i         ;< Size of BDM Communication buffer
  jtagBufferSize.i            ;< Size of JTAG buffer (if supported)
EndStructure

Structure tUSBDM_ExtendedOptions Align #PB_Structure_AlignC
  size.i                            ;< Size of this Structure - must be initialised!
  targetType.i                      ;< Target type (TargetType_t)
  
  ; somehow this comes out to 72 bytes, when it should be 60 -
  ; something in the middle here is wrong and it might be because
  ; I'm using a JS device
  
  FILLER.b[32]
  
;   targetVdd.?                     ;< Target Vdd (off, 3.3V Or 5V) (TargetVddSelect_t)
;2? cycleVddOnReset.?               ;< Cycle target Power  when resetting
;2? cycleVddOnConnect.?             ;< Cycle target Power If connection problems)
;2? leaveTargetPowered.?            ;< Leave target power on exit
;   autoReconnect.?                 ;< Automatically re-connect To target (For speed change) (AutoConnect_t)
;2? guessSpeed.?                    ;< Guess speed For target w/o ACKN
;   bdmClockSource.?                ;< BDM clock source in target (ClkSwValues_t)
;2? useResetSignal.?                ;< Whether To use RESET signal on BDM Interface
;2? maskInterrupts.?                ;< Whether To mask interrupts when  stepping
;4  interfaceFrequency.i            ;< CFVx/JTAG etc - Interface speed (kHz)
;2? usePSTSignals.?                 ;< CFVx, PST Signal monitors
  
  powerOffDuration.i                ;< How long To remove power (ms)
  powerOnRecoveryInterval.i         ;< How long To wait after power enabled (ms)
  resetDuration.i                   ;< How long To assert reset (ms)
  resetReleaseInterval.i            ;< How long To wait after reset release To release other signals (ms)
  resetRecoveryInterval.i           ;< How long To wait after reset sequence completes (ms)
EndStructure

Structure tUSBDM_Status Align #PB_Structure_AlignC
   target_type.i        ;< {TargetType_t}      Type of target (HCS12, HCS08 etc) @deprecated
   ackn_state.i         ;< {AcknMode_t}        Supports ACKN ?
   connection_state.i   ;< {SpeedMode_t}       Connection status & speed determination method
   reset_state.i        ;< {ResetState_t}      Current target RST0 state
   reset_recent.i       ;< {ResetMode_t}       Target reset recently?
   halt_state.i         ;< {TargetRunState_t}  CFVx halted (from ALLPST)?
   power_state.i        ;< {TargetVddState_t}  Target has power?
   flash_state.i        ;< {TargetVppSelect_t} State of Target Vpp
EndStructure

Enumeration ;< AcknMode_t
  #WAIT  = 0    ;< Use WAIT (delay) instead
  #ACKN  = 1    ;< Target supports ACKN feature And it is enabled
EndEnumeration

Enumeration ;< SpeedMode_t
  #SPEED_NO_INFO        = 0   ;< Not connected
  #SPEED_SYNC           = 1   ;< Speed determined by SYNC
  #SPEED_GUESSED        = 2   ;< Speed determined by trial & error
  #SPEED_USER_SUPPLIED  = 3   ;< User has specified the speed To use
EndEnumeration

Enumeration ;< ResetState_t
  #RSTO_ACTIVE    =0    ;< RSTO* is currently active [low]
  #RSTO_INACTIVE  =1    ;< RSTO* is currently inactive [high]
EndEnumeration

Enumeration ;< ResetMode_t
  #NO_RESET_ACTIVITY    = 0   ;< No reset activity since last polled
  #RESET_INACTIVE       = #NO_RESET_ACTIVITY
  #RESET_DETECTED       = 1   ;< Reset since last polled
EndEnumeration

Enumeration ;< TargetRunState_t
  #TARGET_RUNNING    = 0    ;< CFVx target running (ALLPST == 0)
  #TARGET_HALTED     = 1    ;< CFVx target halted (ALLPST == 1)
EndEnumeration

Enumeration ;< TargetVddState_t
  #BDM_TARGET_VDD_NONE  = 0   ;< Target Vdd Not detected
  #BDM_TARGET_VDD_EXT   = 1   ;< Target Vdd external
  #BDM_TARGET_VDD_INT   = 2   ;< Target Vdd internal
  #BDM_TARGET_VDD_ERR   = 3   ;< Target Vdd error
EndEnumeration

Enumeration ;< TargetVppSelect_t
  #BDM_TARGET_VPP_OFF       = 0   ;< Target Vpp Off
  #BDM_TARGET_VPP_STANDBY   = 1   ;< Target Vpp Standby (Inverter on, Vpp off)
  #BDM_TARGET_VPP_ON        = 2   ;< Target Vpp On
  #BDM_TARGET_VPP_ERROR     = 3   ;< Target Vpp ??
EndEnumeration

Enumeration ;< ClkSwValues_t
  #CS_DEFAULT     = $FF   ;< Use Default clock selection (don't modify target's reset Default)
  #CS_ALT_CLK     = 0     ;< Force ALT clock (CLKSW = 0)
  #CS_NORMAL_CLK  = 1     ;< Force Normal clock (CLKSW = 1)
EndEnumeration

Enumeration ;< AutoConnect_t
  #AUTOCONNECT_NEVER   = 0    ;< Only connect explicitly
  #AUTOCONNECT_STATUS  = 1    ;< Reconnect on USBDM_ReadStatusReg()
  #AUTOCONNECT_ALWAYS  = 2    ;< Reconnect before every command
EndEnumeration

Enumeration ;< TargetType_t
  #T_HC12      = 0         ;< HC12 or HCS12 target
  #T_HCS12     = #T_HC12   ;< HC12 or HCS12 target
  #T_HCS08     = 1         ;< HCS08 target
  #T_RS08      = 2         ;< RS08 target
  #T_CFV1      = 3         ;< Coldfire Version 1 target
  #T_CFVx      = 4         ;< Coldfire Version 2,3,4 target
  #T_JTAG      = 5         ;< JTAG target - TAP is set to \b RUN-TEST/IDLE
  #T_EZFLASH   = 6         ;< EzPort Flash interface (SPI?)
  #T_MC56F80xx = 7         ;< JTAG target with MC56F80xx optimised subroutines
  #T_ARM_JTAG  = 8         ;< ARM target using JTAG
  #T_ARM_SWD   = 9         ;< ARM target using SWD
  #T_ARM       = 10        ;< ARM target using either SWD (preferred) or JTAG as supported
  #T_S12Z      = 11        ;< S12Z target
  #T_LAST      = #T_S12Z
  #T_ILLEGAL   = $FE       ;< - Used to indicate error in selecting target
  #T_OFF       = $FF       ;< Turn off interface (no target)
  #T_NONE      = $FF       ;
EndEnumeration

Enumeration ;< TargetVddSelect_t
  #BDM_TARGET_VDD_OFF       = 0     ;< Target Vdd Off
  #BDM_TARGET_VDD_3V3       = 1     ;< Target Vdd internal 3.3V
  #BDM_TARGET_VDD_5V        = 2     ;< Target Vdd internal 5.0V
  #BDM_TARGET_VDD_ENABLE    = $10   ;< Target Vdd internal at last set level
  #BDM_TARGET_VDD_DISABLE   = $11   ;< Target Vdd Off but previously set level unchanged
EndEnumeration

Enumeration ;< HardwareCapabilities_t
  #BDM_CAP_NONE       = (0)
  #BDM_CAP_ALL        = ($FFFF)
  #BDM_CAP_HCS12      = (1<<0)   ;< Supports HCS12
  #BDM_CAP_RS08       = (1<<1)   ;< 12 V Flash programming supply available (RS08 support)
  #BDM_CAP_VDDCONTROL = (1<<2)   ;< Control over target Vdd
  #BDM_CAP_VDDSENSE   = (1<<3)   ;< Sensing of target Vdd
  #BDM_CAP_CFVx       = (1<<4)   ;< Support for CFV 1,2 & 3
  #BDM_CAP_HCS08      = (1<<5)   ;< Supports HCS08 targets - inverted when queried
  #BDM_CAP_CFV1       = (1<<6)   ;< Supports CFV1 targets  - inverted when queried
  #BDM_CAP_JTAG       = (1<<7)   ;< Supports JTAG targets
  #BDM_CAP_DSC        = (1<<8)   ;< Supports DSC targets
  #BDM_CAP_ARM_JTAG   = (1<<9)   ;< Supports ARM targets via JTAG
  #BDM_CAP_RST        = (1<<10)  ;< Control & sensing of RESET
  #BDM_CAP_PST        = (1<<11)  ;< Supports PST signal sensing
  #BDM_CAP_CDC        = (1<<12)  ;< Supports CDC Serial over USB interface
  #BDM_CAP_ARM_SWD    = (1<<13)  ;< Supports ARM targets via SWD
  #BDM_CAP_S12Z       = (1<<14)  ;< Supports HCS12Z targets via SWD. 
EndEnumeration

Enumeration ;< MemorySpace_t
  
  #MS_SIZE     = %111 << 0  ;< size mask
  #MS_Byte     = 1          ;< Byte (8-bit) access
  #MS_Word     = 2          ;< Word (16-bit) access
  #MS_Long     = 4          ;< Long (32-bit) access
  
  #MS_SPACE    = %111 << 4  ;< mem space mask
  #MS_None     = 0<<4       ;< Memory space unused/undifferentiated
  #MS_Program  = 1<<4       ;< Program memory Space (e.g. P: on DSC)
  #MS_Data     = 2<<4       ;< Data memory Space (e.g. X: on DSC)
  #MS_Global   = 3<<4       ;< HCS12 Global addresses (Using BDMPPR register)
  
  #MS_Fast     = 1<<7       ;< Fast memory access For HCS08/HCS12 (stopped target, regs. are modified
EndEnumeration

Enumeration ;< HCS12_Registers_t
  #HCS12_RegPC    = 3   ;< PC reg
  #HCS12_RegD     = 4   ;< D reg
  #HCS12_RegX     = 5   ;< X reg
  #HCS12_RegY     = 6   ;< Y reg
  #HCS12_RegSP    = 7   ;< SP reg
  #HCS12_RegCCR   = $80 ;< CCR reg - redirected To USBDM_ReadDReg()
EndEnumeration

Enumeration ;< HCS12_DRegisters_t
  ;// 8-bit accesses using READ_BD_BYTE
  #HCS12_DRegBDMSTS = $FF01   ;< BDMSTS (Debug status/control) register
  #HCS12_DRegCCR    = $FF06   ;< Saved Target CCR
  #HCS12_DRegBDMINR = $FF07   ;< BDM Internal Register Position Register
  ;// Others may be device dependent
EndEnumeration

Enumeration ;< TargetMode_t
  #RESET_MODE_MASK   = (3<<0)   ;< Mask For reset mode (SPECIAL/NORMAL)
  #RESET_SPECIAL     = (0<<0)   ;< Special mode [BDM active, Target halted]
  #RESET_NORMAL      = (1<<0)   ;< Normal mode [usual reset, Target executes]
  
  #RESET_METHOD_MASK = (7<<2)   ;< Mask For reset type (Hardware/Software/Power)
  #RESET_ALL         = (0<<2)   ;< Use all reset strategies As appropriate
  #RESET_HARDWARE    = (1<<2)   ;< Use hardware RESET pin reset
  #RESET_SOFTWARE    = (2<<2)   ;< Use software (BDM commands) reset
  #RESET_POWER       = (3<<2)   ;< Cycle power
  #RESET_DEFAULT     = (7<<2)   ;< Use target specific Default method
EndEnumeration

Declare.i USBDM_Load()
Declare.i USBDM_Init()
Declare.i USBDM_Exit()
Declare.i USBDM_DLLVersion()
Declare.s USBDM_DLLVersionString()
Declare.s USBDM_GetErrorString( e.i )
Declare.i USBDM_FindDevices( *cnt )
Declare.i USBDM_ReleaseDevices()
Declare.i USBDM_Open( id.i )
Declare.i USBDM_Close()
Declare.i USBDM_GetBDMSerialNumber( *s.String )
Declare.i USBDM_GetBDMDescription( *s.String )
Declare.i USBDM_GetVersion( *v.tUSBDM_Version )
Declare.i USBDM_GetCapabilities( *caps )
Declare.i USBDM_GetBdmInformation( *i.tUSBDM_bdmInformation )
Declare.i USBDM_GetDefaultExtendedOptions( *eo.tUSBDM_ExtendedOptions )
Declare.i USBDM_GetExtendedOptions( *eo.tUSBDM_ExtendedOptions )
Declare.i USBDM_SetExtendedOptions( *eo.tUSBDM_ExtendedOptions )
Declare.i USBDM_SetTarget( t.i )
Declare.i USBDM_GetSpeed( *s )
Declare.i USBDM_SetSpeed( s )
Declare.i USBDM_Connect()
Declare.i USBDM_GetBDMStatus( *s.tUSBDM_Status )
Declare.i USBDM_ReadMemory( space.i, cnt.i, addr.i, *data )
Declare.i USBDM_WriteMemory( space.i, cnt.i, addr.i, *data )
Declare.i USBDM_ReadReg( r.i, *rval )
Declare.i USBDM_WriteReg( r.i, rval )
Declare.i USBDM_ReadDReg( r.i, *rval )
Declare.i USBDM_WriteDReg( r.i, rval )
Declare.i USBDM_TargetReset( r.i )
Declare.i USBDM_TargetGo()
Declare.i USBDM_TargetHalt()
Declare.i USBDM_TargetStep()


Enumeration ;<  USBDM_ErrorCode
  #BDM_RC_ERROR_HANDLED            = $10000   ;< Indicates error has already been notified to user
  #BDM_RC_OK                       = 0        ;< No error
  #BDM_RC_ILLEGAL_PARAMS           = 1        ;< Illegal parameters to command
  #BDM_RC_FAIL                     = 2        ;< General Fail
  #BDM_RC_BUSY                     = 3        ;< Busy with last command - try again - don't change
  #BDM_RC_ILLEGAL_COMMAND          = 4        ;< Illegal (unknown) command (may be in wrong target mode)
  #BDM_RC_NO_CONNECTION            = 5        ;< No connection to target
  #BDM_RC_OVERRUN                  = 6        ;< New command before previous command completed
  #BDM_RC_CF_ILLEGAL_COMMAND       = 7        ;< Coldfire BDM interface did not recognize the command
  #BDM_RC_DEVICE_OPEN_FAILED       = 8        ;< BDM Open Failed - Other LIBUSB error on open
  #BDM_RC_USB_DEVICE_BUSY          = 9        ;< BDM Open Failed - LIBUSB_ERROR_ACCESS on open - Probably open in another app
  #BDM_RC_USB_DEVICE_NOT_INSTALLED = 10       ;< BDM Open Failed - LIBUSB_ERROR_ACCESS on claim I/F - Probably driver not installed
  #BDM_RC_USB_DEVICE_REMOVED       = 11       ;< BDM Open Failed - LIBUSB_ERROR_NO_DEVICE - enumerated device has been removed
  #BDM_RC_USB_RETRY_OK             = 12       ;< USB Debug use only
  #BDM_RC_UNKNOWN_TARGET           = 15       ;< Target unknown or not supported by this BDM
  #BDM_RC_NO_TX_ROUTINE            = 16       ;< No Tx routine available at measured BDM communication speed
  #BDM_RC_NO_RX_ROUTINE            = 17       ;< No Rx routine available at measured BDM communication speed
  #BDM_RC_BDM_EN_FAILED            = 18       ;< Failed to enable BDM mode in target (warning)
  #BDM_RC_RESET_TIMEOUT_FALL       = 19       ;< RESET signal failed to fall
  #BDM_RC_BKGD_TIMEOUT             = 20       ;< BKGD signal failed to rise/fall
  #BDM_RC_SYNC_TIMEOUT             = 21       ;< No response to SYNC sequence
  #BDM_RC_UNKNOWN_SPEED            = 22       ;< Communication speed is not known or cannot be determined
  #BDM_RC_WRONG_PROGRAMMING_MODE   = 23       ;< Attempted Flash programming when in wrong mode (e.g. Vpp off)
  #BDM_RC_FLASH_PROGRAMING_BUSY    = 24       ;< Busy with last Flash programming command
  #BDM_RC_VDD_NOT_REMOVED          = 25       ;< Target Vdd failed to fall
  #BDM_RC_VDD_NOT_PRESENT          = 26       ;< Target Vdd not present/failed to rise
  #BDM_RC_VDD_WRONG_MODE           = 27       ;< Attempt to cycle target Vdd when not controlled by BDM interface
  #BDM_RC_CF_BUS_ERROR             = 28       ;< Illegal bus cycle on target (Coldfire)
  #BDM_RC_USB_ERROR                = 29       ;< Indicates USB transfer failed (returned by driver not BDM)
  #BDM_RC_ACK_TIMEOUT              = 30       ;< Indicates an expected ACK was missing
  #BDM_RC_FAILED_TRIM              = 31       ;< Trimming of target clock failed (out of clock range?).
  #BDM_RC_FEATURE_NOT_SUPPORTED    = 32       ;< Feature not supported by this version of hardware/firmware
  #BDM_RC_RESET_TIMEOUT_RISE       = 33       ;< RESET signal failed to rise
  #BDM_RC_WRONG_BDM_REVISION       = 34       ;< BDM Hardware is incompatible with driver/program
  #BDM_RC_WRONG_DLL_REVISION       = 35       ;< Program is incompatible with DLL
  #BDM_RC_NO_USBDM_DEVICE          = 36       ;< No usbdm device was located
  #BDM_RC_JTAG_UNMATCHED_REPEAT    = 37       ;< Unmatched REPEAT-END_REPEAT
  #BDM_RC_JTAG_UNMATCHED_RETURN    = 38       ;< Unmatched CALL-RETURN
  #BDM_RC_JTAG_UNMATCHED_IF        = 39       ;< Unmatched IF-END_IF
  #BDM_RC_JTAG_STACK_ERROR         = 40       ;< Underflow in call/return sequence, unmatched REPEAT etc.
  #BDM_RC_JTAG_ILLEGAL_SEQUENCE    = 41       ;< Illegal JTAG sequence
  #BDM_RC_TARGET_BUSY              = 42       ;< Target is busy (executing?)
  #BDM_RC_JTAG_TOO_LARGE           = 43       ;< Subroutine is too large to cache
  #BDM_RC_DEVICE_NOT_OPEN          = 44       ;< USBDM Device has not been opened
  #BDM_RC_UNKNOWN_DEVICE           = 45       ;< Device is not in database
  #BDM_RC_DEVICE_DATABASE_ERROR    = 46       ;< Device database not found or failed to open/parse
  #BDM_RC_ARM_PWR_UP_FAIL          = 47       ;< ARM System power failed
  #BDM_RC_ARM_ACCESS_ERROR         = 48       ;< ARM Access error
  #BDM_JTAG_TOO_MANY_DEVICES       = 49       ;< JTAG chain is too long (or greater than 1!)
  #BDM_RC_SECURED                  = 50       ;< ARM Device is secured (& operation failed?)
  #BDM_RC_ARM_PARITY_ERROR         = 51       ;< ARM PARITY error
  #BDM_RC_ARM_FAULT_ERROR          = 52       ;< ARM FAULT response error
  #BDM_RC_UNEXPECTED_RESPONSE      = 53       ;< Unexpected/inconsistent response from BDM
EndEnumeration

Macro USBDM_SUCCESS( e )
  (e = #BDM_RC_OK)
EndMacro

Macro USBDM_FAILURE( e )
  (e <> #BDM_RC_OK)
EndMacro
;}

; PRIVATE
;{
Prototype.i _USBDM_Init()
Prototype.i _USBDM_Exit()
Prototype.i _USBDM_DLLVersion()
Prototype.i _USBDM_DLLVersionString()
Prototype.i _USBDM_GetErrorString( e.i )
Prototype.i _USBDM_FindDevices( *cnt )
Prototype.i _USBDM_ReleaseDevices()
Prototype.i _USBDM_Open( id.i )
Prototype.i _USBDM_Close()
Prototype.i _USBDM_GetBDMSerialNumber( *s )
Prototype.i _USBDM_GetBDMDescription( *s )
Prototype.i _USBDM_GetVersion( *v.tUSBDM_Version )
Prototype.i _USBDM_GetCapabilities( *caps )
Prototype.i _USBDM_GetBdmInformation( *i.tUSBDM_bdmInformation )
Prototype.i _USBDM_GetDefaultExtendedOptions( *eo.tUSBDM_ExtendedOptions )  ;< useless for JS devices
Prototype.i _USBDM_GetExtendedOptions( *eo.tUSBDM_ExtendedOptions )         ;< useless for JS devices
Prototype.i _USBDM_SetExtendedOptions( *eo.tUSBDM_ExtendedOptions )         ;< useless for JS devices
Prototype.i _USBDM_SetTargetType( t.i )
Prototype.i _USBDM_GetSpeed( *s )
Prototype.i _USBDM_GetSpeedHz( *s )
Prototype.i _USBDM_SetSpeed( s )
Prototype.i _USBDM_Connect()
Prototype.i _USBDM_GetBDMStatus( *s.tUSBDM_Status )
Prototype.i _USBDM_ReadMemory( space.i, cnt.i, addr.i, *data )
Prototype.i _USBDM_WriteMemory( space.i, cnt.i, addr.i, *data )
Prototype.i _USBDM_ReadReg( r.i, *rval )
Prototype.i _USBDM_WriteReg( r.i, rval )
Prototype.i _USBDM_ReadDReg( r.i, *rval )
Prototype.i _USBDM_WriteDReg( r.i, rval )
Prototype.i _USBDM_TargetReset( r.i )
Prototype.i _USBDM_TargetGo()
Prototype.i _USBDM_TargetHalt()
Prototype.i _USBDM_TargetStep()

Structure tUSBDMDLL
  *USBDM_Init._USBDM_Init
  *USBDM_Exit._USBDM_Exit
  *USBDM_DLLVersion._USBDM_DLLVersion
  *USBDM_DLLVersionString._USBDM_DLLVersionString
  *USBDM_GetErrorString._USBDM_GetErrorString
  *USBDM_FindDevices._USBDM_FindDevices
  *USBDM_ReleaseDevices._USBDM_ReleaseDevices
  *USBDM_Open._USBDM_Open
  *USBDM_Close._USBDM_Close
  *USBDM_GetBDMSerialNumber._USBDM_GetBDMSerialNumber
  *USBDM_GetBDMDescription._USBDM_GetBDMDescription
  *USBDM_GetVersion._USBDM_GetVersion
  *USBDM_GetCapabilities._USBDM_GetCapabilities
  *USBDM_GetBdmInformation._USBDM_GetBdmInformation
  *USBDM_GetDefaultExtendedOptions._USBDM_GetDefaultExtendedOptions
  *USBDM_GetExtendedOptions._USBDM_GetExtendedOptions
  *USBDM_SetExtendedOptions._USBDM_SetExtendedOptions
  *USBDM_SetTargetType._USBDM_SetTargetType
  *USBDM_GetSpeed._USBDM_GetSpeed
  *USBDM_GetSpeedHz._USBDM_GetSpeedHz
  *USBDM_SetSpeed._USBDM_SetSpeed
  *USBDM_Connect._USBDM_Connect
  *USBDM_GetBDMStatus._USBDM_GetBDMStatus
  *USBDM_ReadMemory._USBDM_ReadMemory
  *USBDM_WriteMemory._USBDM_WriteMemory
  *USBDM_ReadReg._USBDM_ReadReg
  *USBDM_WriteReg._USBDM_WriteReg
  *USBDM_ReadDReg._USBDM_ReadDReg
  *USBDM_WriteDReg._USBDM_WriteDReg
  *USBDM_TargetReset._USBDM_TargetReset
  *USBDM_TargetGo._USBDM_TargetGo
  *USBDM_TargetHalt._USBDM_TargetHalt
  *USBDM_TargetStep._USBDM_TargetStep
EndStructure

Global *usbdmdll.tUSBDMDLL = 0

Procedure.i USBDM_Load()
  If Not *usbdmdll
    *usbdmdll = AllocateMemory( SizeOf(tUSBDMDLL) )
    If *usbdmdll
      Protected lib.i = OpenLibrary( #PB_Any, "usbdm.4.dll" )
      If lib
        With *usbdmdll
          \USBDM_Init = GetFunction( lib, "USBDM_Init@0" ) : assert( \USBDM_Init )
          \USBDM_Exit = GetFunction( lib, "USBDM_Exit@0" ) : assert( \USBDM_Exit )
          \USBDM_DLLVersion = GetFunction( lib, "USBDM_DLLVersion@0" ) : assert( \USBDM_DLLVersion )
          \USBDM_DLLVersionString = GetFunction( lib, "USBDM_DLLVersionString@0" ) : assert( \USBDM_DLLVersionString )
          \USBDM_GetErrorString = GetFunction( lib, "USBDM_GetErrorString@4" ) : assert( \USBDM_GetErrorString )
          \USBDM_FindDevices = GetFunction( lib, "USBDM_FindDevices@4" ) : assert( \USBDM_FindDevices )
          \USBDM_ReleaseDevices = GetFunction( lib, "USBDM_ReleaseDevices@0" ) : assert( \USBDM_ReleaseDevices )
          \USBDM_Open = GetFunction( lib, "USBDM_Open@4" ) : assert( \USBDM_Open )
          \USBDM_Close = GetFunction( lib, "USBDM_Close@0" ) : assert( \USBDM_Close )
          \USBDM_GetBDMSerialNumber = GetFunction( lib, "USBDM_GetBDMSerialNumber@4" ) : assert( \USBDM_GetBDMSerialNumber )
          \USBDM_GetBDMDescription = GetFunction( lib, "USBDM_GetBDMDescription@4" ) : assert( \USBDM_GetBDMDescription )
          \USBDM_GetVersion = GetFunction( lib, "USBDM_GetVersion@4" ) : assert( \USBDM_GetVersion )
          \USBDM_GetCapabilities = GetFunction( lib, "USBDM_GetCapabilities@4" ) : assert( \USBDM_GetCapabilities )
          \USBDM_GetBdmInformation = GetFunction( lib, "USBDM_GetBdmInformation@4" ) : assert( \USBDM_GetBdmInformation )
          \USBDM_GetDefaultExtendedOptions = GetFunction( lib, "USBDM_GetDefaultExtendedOptions@4" ) : assert( \USBDM_GetDefaultExtendedOptions )
          \USBDM_GetExtendedOptions = GetFunction( lib, "USBDM_GetExtendedOptions@4" ) : assert( \USBDM_GetExtendedOptions )
          \USBDM_SetExtendedOptions = GetFunction( lib, "USBDM_SetExtendedOptions@4" ) : assert( \USBDM_SetExtendedOptions )
          \USBDM_SetTargetType = GetFunction( lib, "USBDM_SetTargetType@4" ) : assert( \USBDM_SetTargetType )
          \USBDM_GetSpeed = GetFunction( lib, "USBDM_GetSpeed@4" ) : assert( \USBDM_GetSpeed )
          \USBDM_GetSpeedHz = GetFunction( lib, "USBDM_GetSpeedHz@4" ) : assert( \USBDM_GetSpeedHz )
          \USBDM_SetSpeed = GetFunction( lib, "USBDM_SetSpeed@4" ) : assert( \USBDM_SetSpeed )
          \USBDM_Connect = GetFunction( lib, "USBDM_Connect@0" ) : assert( \USBDM_Connect )
          \USBDM_GetBDMStatus = GetFunction( lib, "USBDM_GetBDMStatus@4" ) : assert( \USBDM_GetBDMStatus )
          \USBDM_ReadMemory = GetFunction( lib, "USBDM_ReadMemory@16" ) : assert( \USBDM_ReadMemory )
          \USBDM_WriteMemory = GetFunction( lib, "USBDM_WriteMemory@16" ) : assert( \USBDM_WriteMemory )
          \USBDM_ReadReg = GetFunction( lib, "USBDM_ReadReg@8" ) : assert( \USBDM_ReadReg )
          \USBDM_WriteReg = GetFunction( lib, "USBDM_WriteReg@8" ) : assert( \USBDM_WriteReg )
          \USBDM_ReadDReg = GetFunction( lib, "USBDM_ReadDReg@8" ) : assert( \USBDM_ReadDReg )
          \USBDM_WriteDReg = GetFunction( lib, "USBDM_WriteDReg@8" ) : assert( \USBDM_WriteDReg )
          \USBDM_TargetReset = GetFunction( lib, "USBDM_TargetReset@4" ) : assert( \USBDM_TargetReset )
          \USBDM_TargetGo = GetFunction( lib, "USBDM_TargetGo@0" ) : assert( \USBDM_TargetGo )
          \USBDM_TargetHalt = GetFunction( lib, "USBDM_TargetHalt@0" ) : assert( \USBDM_TargetHalt )
          \USBDM_TargetStep = GetFunction( lib, "USBDM_TargetStep@0" ) : assert( \USBDM_TargetStep )
        EndWith
      Else
        FreeMemory( *usbdmdll ) : *usbdmdll = 0
      EndIf
    EndIf
  EndIf
  ProcedureReturn *usbdmdll
EndProcedure

Procedure.i USBDM_Init()
  assert( *usbdmdll )
  Protected.i r = *usbdmdll\USBDM_Init() : assert(USBDM_SUCCESS(r))
  Debug "USBDM DLL Version: $"+RSet(Hex(USBDM_DLLVersion()),8,"0")
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_Exit()
  assert( *usbdmdll )
  Protected.i r = *usbdmdll\USBDM_Exit() : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_DLLVersion()
  assert( *usbdmdll )
  ProcedureReturn *usbdmdll\USBDM_DLLVersion()
EndProcedure

Procedure.s USBDM_DLLVersionString()
  assert( *usbdmdll )
  ProcedureReturn PeekS( *usbdmdll\USBDM_DLLVersionString(), -1, #PB_Ascii )
EndProcedure

Procedure.s USBDM_GetErrorString( e.i )
  assert( *usbdmdll )
  ProcedureReturn PeekS( *usbdmdll\USBDM_GetErrorString(e), -1, #PB_Ascii )
EndProcedure

Procedure.i USBDM_FindDevices( *cnt )
  assert( *usbdmdll ) : assert( *cnt )
  Protected.i r = *usbdmdll\USBDM_FindDevices( *cnt )
  assert( USBDM_SUCCESS(r) Or (r=#BDM_RC_NO_USBDM_DEVICE) )
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_ReleaseDevices()
  assert( *usbdmdll )
  Protected.i r = *usbdmdll\USBDM_ReleaseDevices() : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_Open( id.i )
  assert( *usbdmdll )
  Protected.i r = *usbdmdll\USBDM_Open( id ) : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_Close()
  assert( *usbdmdll )
  Protected.i r = *usbdmdll\USBDM_Close() : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_GetBDMSerialNumber( *s.String )
  assert( *usbdmdll ) : assert( *s )
  Protected *m=0, r.i=*usbdmdll\USBDM_GetBDMSerialNumber( @*m ) : assert(USBDM_SUCCESS(r))
  If *m And USBDM_SUCCESS(r)
    *s\s = PeekS( *m, -1, #PB_Unicode )
  EndIf
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_GetBDMDescription( *s.String )
  assert( *usbdmdll ) : assert( *s )
  Protected *m=0, r.i=*usbdmdll\USBDM_GetBDMDescription( @*m ) : assert(USBDM_SUCCESS(r))
  If *m And USBDM_SUCCESS(r)
    *s\s = PeekS( *m, -1, #PB_Unicode )
  EndIf
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_GetVersion( *v.tUSBDM_Version )
  assert( *usbdmdll ) : assert( *v )
  Protected.i r = *usbdmdll\USBDM_GetVersion( *v ) : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_GetCapabilities( *caps )
  assert( *usbdmdll ) : assert( *caps )
  Protected.i r = *usbdmdll\USBDM_GetCapabilities( *caps ) : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_GetBdmInformation( *i.tUSBDM_bdmInformation )
  assert( *usbdmdll ) : assert( *i )
  Protected.i r = *usbdmdll\USBDM_GetBdmInformation( *i ) : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_GetDefaultExtendedOptions( *eo.tUSBDM_ExtendedOptions )
  assert( *usbdmdll ) : assert( *eo )
  Protected.i r = *usbdmdll\USBDM_GetDefaultExtendedOptions( *eo ) : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_GetExtendedOptions( *eo.tUSBDM_ExtendedOptions )
  assert( *usbdmdll ) : assert( *eo )
  Protected.i r = *usbdmdll\USBDM_GetExtendedOptions( *eo ) : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_SetExtendedOptions( *eo.tUSBDM_ExtendedOptions )
  assert( *usbdmdll ) : assert( *eo )
  Protected.i r = *usbdmdll\USBDM_SetExtendedOptions( *eo ) : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_SetTargetType( t.i )
  assert( *usbdmdll )
  Protected.i r = *usbdmdll\USBDM_SetTargetType( t ) : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_GetSpeed( *s )
  assert( *usbdmdll ) : assert( *s )
  Protected.i r = *usbdmdll\USBDM_GetSpeed( *s ) : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_GetSpeedHz( *s )
  assert( *usbdmdll ) : assert( *s )
  Protected.i r = *usbdmdll\USBDM_GetSpeedHz( *s ) : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_SetSpeed( s.i )
  assert( *usbdmdll )
  Protected.i r = *usbdmdll\USBDM_SetSpeed( s ) : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_Connect()
  assert( *usbdmdll )
  Protected.i r = *usbdmdll\USBDM_Connect() : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_GetBDMStatus( *s.tUSBDM_Status )
  assert( *usbdmdll ) : assert( *s )
  Protected.i r = *usbdmdll\USBDM_GetBDMStatus( *s ) : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_ReadMemory( space.i, cnt.i, addr.i, *data )
  assert( *usbdmdll ) : assert( *data )
  Protected.i r = *usbdmdll\USBDM_ReadMemory( space, cnt, addr, *data ) : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_WriteMemory( space.i, cnt.i, addr.i, *data )
  assert( *usbdmdll ) : assert( *data )
  Protected.i r = *usbdmdll\USBDM_WriteMemory( space, cnt, addr, *data ) : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_ReadReg( reg.i, *rval )
  assert( *usbdmdll ) : assert( *rval )
  Protected.i r = *usbdmdll\USBDM_ReadReg( reg, *rval ) : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_WriteReg( reg.i, rval )
  assert( *usbdmdll )
  Protected.i r = *usbdmdll\USBDM_WriteReg( reg, rval ) : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_ReadDReg( reg.i, *rval )
  assert( *usbdmdll ) : assert( *rval )
  Protected.i r = *usbdmdll\USBDM_ReadDReg( reg, *rval ) : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_WriteDReg( reg.i, rval )
  assert( *usbdmdll )
  Protected.i r = *usbdmdll\USBDM_WriteDReg( reg, rval ) : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_TargetReset( rst.i )
  assert( *usbdmdll )
  Protected.i r = *usbdmdll\USBDM_TargetReset( rst ) : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_TargetGo()
  assert( *usbdmdll )
  Protected.i r = *usbdmdll\USBDM_TargetGo() : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_TargetHalt()
  assert( *usbdmdll )
  Protected.i r = *usbdmdll\USBDM_TargetHalt() : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure

Procedure.i USBDM_TargetStep()
  assert( *usbdmdll )
  Protected.i r = *usbdmdll\USBDM_TargetStep() : assert(USBDM_SUCCESS(r))
  ProcedureReturn r
EndProcedure
;}