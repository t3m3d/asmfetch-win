.686
.model flat, stdcall
option casemap:none

WriteStr PROTO lpStr:DWORD
StrLen  PROTO lpStr:DWORD

GetStdHandle PROTO :DWORD
WriteConsoleA PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
ExitProcess PROTO :DWORD
GetVersionExA PROTO :DWORD
GlobalMemoryStatusEx PROTO :DWORD

.data

msgHello db "asmfetch starting...", 13,10,0

; buffers
cpuBrand db 48 dup(0)
buffer   db 128 dup(0)

newline db 13,10,0


.code

WriteStr PROC lpStr:DWORD
    push -11
    call GetStdHandle

    push 0
    push 0
    push lpStr
    call StrLen
    push lpStr
    push eax
    call WriteConsoleA
    ret
WriteStr ENDP

StrLen PROC uses ecx edi lpStr:DWORD
    mov edi, lpStr
    xor ecx, ecx
@@:
    cmp byte ptr [edi+ecx], 0
    je done
    inc ecx
    jmp @B
done:
    mov eax, ecx
    ret
StrLen ENDP

start:
    invoke WriteStr, offset msgHello
    invoke ExitProcess, 0

END start