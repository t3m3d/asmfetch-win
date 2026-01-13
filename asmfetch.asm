.686
.model flat, stdcall
option casemap:none

; ----------------------------
; Prototypes
; ----------------------------

WriteStr            PROTO lpStr:DWORD
StrLen              PROTO lpStr:DWORD

GetStdHandle        PROTO :DWORD
WriteConsoleA       PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
ExitProcess         PROTO :DWORD
GetVersionExA       PROTO :DWORD
GlobalMemoryStatusEx PROTO :DWORD

; wsprintfA is cdecl, so declare with C
wsprintfA           PROTO C :DWORD, :DWORD, :VARARG

; ----------------------------
; Structures
; ----------------------------

; OSVERSIONINFOA structure
OSVERSIONINFOA STRUCT
    dwOSVersionInfoSize DWORD ?
    dwMajorVersion      DWORD ?
    dwMinorVersion      DWORD ?
    dwBuildNumber       DWORD ?
    dwPlatformId        DWORD ?
    szCSDVersion        BYTE 128 dup(0)
OSVERSIONINFOA ENDS

; MEMORYSTATUSEX structure
MEMORYSTATUSEX STRUCT
    dwLength                DWORD ?
    dwMemoryLoad            DWORD ?
    ullTotalPhys            QWORD ?
    ullAvailPhys            QWORD ?
    ullTotalPageFile        QWORD ?
    ullAvailPageFile        QWORD ?
    ullTotalVirtual         QWORD ?
    ullAvailVirtual         QWORD ?
    ullAvailExtendedVirtual QWORD ?
MEMORYSTATUSEX ENDS

; ----------------------------
; Data section
; ----------------------------

.data

; Messages
msgHello        db "asmfetch starting...", 13, 10, 0
msgCPU          db "CPU: ", 0
msgOS           db "OS: Windows ", 0
msgBuildOpen    db " (Build ", 0
msgBuildClose   db ")", 0
msgRAM          db "RAM: ", 0
msgDot          db ".", 0

newline         db 13, 10, 0

; Format strings for wsprintfA
fmtUInt         db "%u", 0
fmtRAM          db "%u MB", 0

; Buffers
cpuBrand        db 48 dup(0)
buffer          db 128 dup(0)

; Structures
osvi            OSVERSIONINFOA <>
memstat         MEMORYSTATUSEX <>

; ----------------------------
; Code section
; ----------------------------

.code

; --------------------------------
; WriteStr(lpStr)
; Writes a null-terminated string to stdout.
; --------------------------------
WriteStr PROC uses ebx lpStr:DWORD
    ; GetStdHandle(STD_OUTPUT_HANDLE = -11)
    invoke GetStdHandle, -11
    mov ebx, eax

    ; Get string length
    invoke StrLen, lpStr
    ; EAX = length

    ; WriteConsoleA(hConsole, lpBuffer, nChars, lpNumberOfCharsWritten, lpReserved)
    invoke WriteConsoleA, ebx, lpStr, eax, 0, 0

    ret
WriteStr ENDP

; --------------------------------
; StrLen(lpStr)
; Returns length of null-terminated string.
; --------------------------------
StrLen PROC uses ecx edi lpStr:DWORD
    mov edi, lpStr
    xor ecx, ecx
@@:
    cmp byte ptr [edi+ecx], 0
    je  done
    inc ecx
    jmp @B
done:
    mov eax, ecx
    ret
StrLen ENDP

; --------------------------------
; WriteNewline()
; Writes CRLF.
; --------------------------------
WriteNewline PROC
    invoke WriteStr, offset newline
    ret
WriteNewline ENDP

; --------------------------------
; GetCPUBrand()
; Fills cpuBrand[] with the CPU brand string using CPUID.
; --------------------------------
GetCPUBrand PROC
    ; CPUID extended function 0x80000002
    mov eax, 80000002h
    cpuid
    mov dword ptr cpuBrand[0],  eax
    mov dword ptr cpuBrand[4],  ebx
    mov dword ptr cpuBrand[8],  ecx
    mov dword ptr cpuBrand[12], edx

    mov eax, 80000003h
    cpuid
    mov dword ptr cpuBrand[16], eax
    mov dword ptr cpuBrand[20], ebx
    mov dword ptr cpuBrand[24], ecx
    mov dword ptr cpuBrand[28], edx

    mov eax, 80000004h
    cpuid
    mov dword ptr cpuBrand[32], eax
    mov dword ptr cpuBrand[36], ebx
    mov dword ptr cpuBrand[40], ecx
    mov dword ptr cpuBrand[44], edx

    ; cpuBrand is already null-terminated by zeroed buffer
    ret
GetCPUBrand ENDP

; --------------------------------
; PrintOSVersion()
; Prints: OS: Windows X.Y (Build Z)
; --------------------------------
PrintOSVersion PROC
    ; Initialize structure
    mov osvi.dwOSVersionInfoSize, SIZEOF OSVERSIONINFOA
    invoke GetVersionExA, addr osvi

    invoke WriteNewline
    invoke WriteStr, offset msgOS

    ; Major version
    mov eax, osvi.dwMajorVersion
    invoke wsprintfA, addr buffer, addr fmtUInt, eax
    invoke WriteStr, addr buffer

    ; "."
    invoke WriteStr, offset msgDot

    ; Minor version
    mov eax, osvi.dwMinorVersion
    invoke wsprintfA, addr buffer, addr fmtUInt, eax
    invoke WriteStr, addr buffer

    ; " (Build "
    invoke WriteStr, offset msgBuildOpen

    ; Build number
    mov eax, osvi.dwBuildNumber
    invoke wsprintfA, addr buffer, addr fmtUInt, eax
    invoke WriteStr, addr buffer

    ; ")"
    invoke WriteStr, offset msgBuildClose
    invoke WriteNewline

    ret
PrintOSVersion ENDP

; --------------------------------
; PrintRAM()
; Prints: RAM: N MB
; --------------------------------
PrintRAM PROC uses edx ecx
    ; Initialize structure
    mov memstat.dwLength, SIZEOF MEMORYSTATUSEX
    invoke GlobalMemoryStatusEx, addr memstat

    invoke WriteStr, offset msgRAM

    ; 64-bit total phys in ullTotalPhys → divide by 1048576 to get MB
    mov eax, dword ptr memstat.ullTotalPhys      ; low 32 bits
    mov edx, dword ptr memstat.ullTotalPhys+4    ; high 32 bits

    mov ecx, 1048576                             ; 1024 * 1024
    div ecx                                      ; EDX:EAX / ECX -> EAX = MB

    invoke wsprintfA, addr buffer, addr fmtRAM, eax
    invoke WriteStr, addr buffer
    invoke WriteNewline

    ret
PrintRAM ENDP

; --------------------------------
; Program entry point
; --------------------------------
start:
    ; Startup banner
    invoke WriteStr, offset msgHello
    invoke WriteNewline

    ; CPU
    invoke GetCPUBrand
    invoke WriteStr, offset msgCPU
    invoke WriteStr, addr cpuBrand
    invoke WriteNewline

    ; OS version
    invoke PrintOSVersion

    ; RAM
    invoke PrintRAM

    ; Exit
    invoke ExitProcess, 0

END start