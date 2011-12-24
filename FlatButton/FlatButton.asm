;By Proton

.386
.Model Flat, StdCall
Option Casemap :None

Include windows.inc
Include user32.inc
Include kernel32.inc
Include gdi32.inc

includelib gdi32.lib
IncludeLib user32.lib
IncludeLib kernel32.lib
include macro.asm
	
	WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD

FBINFOSTRUCT struct
	hWnd dd ?
	dwStatus dd ?
	hFont dd ?
FBINFOSTRUCT ends

.DATA
	szClassName db "FlatButton",0
	
.DATA?
	hInstance	dd ?
	hBorderPen dd ?
	hFillBrush dd ?
	hNFBorderPen dd ?
	hNFFillBrush dd ?
	hBaseBitmap dd ?
	stFlatButtons FBINFOSTRUCT 100 dup(<?>)

.const
	BKND_BORDER equ 00800000h
	BKND_BODY equ 00D6BDB5h
	NFBKND_BORDER EQU 09C9A9Ch
	NFBKND_BODY EQU 0E1E1E1h
	BS_FOCUS equ 1
	BS_DOWN EQU 2
	BS_DISABLED EQU 4
.CODE

FlatButtonInit proc uses esi
LOCAL wc:WNDCLASSEX
	invoke RtlZeroMemory,ADDR wc,sizeof WNDCLASSEX
	invoke RtlZeroMemory,ADDR stFlatButtons,100*SIZEOF FBINFOSTRUCT
	invoke GetModuleHandle,0
	mov hInstance,eax
	mov wc.cbSize,sizeof WNDCLASSEX
	mov wc.style,CS_HREDRAW or CS_VREDRAW or CS_SAVEBITS
	mov wc.lpfnWndProc,offset FlatWndProc
	mov wc.cbClsExtra,NULL
	mov wc.cbWndExtra,NULL
	push hInstance
	pop wc.hInstance
	mov wc.hbrBackground,NULL
	mov wc.lpszMenuName,NULL
	mov wc.lpszClassName,offset szClassName
	invoke RegisterClassEx, ADDR wc
	invoke CreatePen,PS_SOLID,1,BKND_BORDER
	mov hBorderPen,eax
	invoke CreateSolidBrush,BKND_BODY
	mov hFillBrush,eax
	
	invoke CreatePen,PS_SOLID,1,NFBKND_BORDER
	mov hNFBorderPen,eax
	invoke CreateSolidBrush,NFBKND_BODY
	mov hNFFillBrush,eax
	
	mov eax,TRUE
	ret
FlatButtonInit endp

RegisterFlatButton proc private hWnd1:DWORD
	assume eax:ptr FBINFOSTRUCT
	lea eax,stFlatButtons
	xor ecx,ecx
	.while [eax].hWnd!=0
		add eax,sizeof FBINFOSTRUCT
		inc ecx
		.if ecx>100
			mov eax,FALSE
			ret
		.endif
	.endw
	push hWnd1
	pop [eax].hWnd
	mov [eax].dwStatus,0
	assume eax:nothing
	ret
RegisterFlatButton endp

FindFlatButton proc private hWnd1:DWORD
	assume eax:ptr FBINFOSTRUCT
	lea eax,stFlatButtons
	xor ecx,ecx
	mov edx,[eax].hWnd
	.while edx!=hWnd1
		add eax,sizeof FBINFOSTRUCT
		inc ecx
		.if ecx>100
			mov eax,FALSE
			ret
		.endif
		mov edx,[eax].hWnd
	.endw
	assume eax:nothing
	ret
FindFlatButton endp

DeleteFlatButton proc private hFButton:DWORD
	invoke RtlZeroMemory,hFButton,SIZEOF FBINFOSTRUCT
	mov eax,TRUE
	ret
DeleteFlatButton endp

FlatWndProc proc private uses esi edi hWin:DWORD,uMsg:DWORD,wParam :DWORD,lParam :DWORD
LOCAL stClientRect:RECT
LOCAL hDC:DWORD
LOCAL stTEEvent:TRACKMOUSEEVENT
LOCAL szCaption [MAX_PATH]:BYTE

	.if uMsg==WM_CREATE
		invoke RegisterFlatButton,hWin
		mov esi,eax
		invoke GetStockObject,DEFAULT_GUI_FONT
		mov (FBINFOSTRUCT ptr [esi]).hFont,eax
		invoke InvalidateRect,hWin,0,TRUE
	.elseif uMsg == WM_MOUSELEAVE
		invoke FindFlatButton,hWin
		mov esi,eax
		assume esi:ptr FBINFOSTRUCT
		and [esi].dwStatus,NOT(BS_FOCUS)
		and [esi].dwStatus,NOT(BS_DOWN)
		
		invoke InvalidateRect,hWin,NULL,FALSE
		assume esi:nothing
	.elseif uMsg == WM_MOUSEMOVE
		invoke FindFlatButton,hWin
		mov esi,eax
		assume esi:ptr FBINFOSTRUCT
		mov eax,[esi].dwStatus
		.if !(eax & BS_FOCUS)
			or [esi].dwStatus,BS_FOCUS
			invoke RtlZeroMemory,ADDR stTEEvent,SIZEOF stTEEvent
			mov stTEEvent.cbSize,SIZEOF stTEEvent
			mov stTEEvent.dwFlags,TME_LEAVE
			push hWin
			pop stTEEvent.hwndTrack
			invoke TrackMouseEvent,ADDR stTEEvent
			invoke InvalidateRect,hWin,NULL,FALSE
		.endif
		assume esi:nothing
	.elseif uMsg == WM_LBUTTONDOWN
		invoke FindFlatButton,hWin
		mov esi,eax
		assume esi:ptr FBINFOSTRUCT
		or [esi].dwStatus,BS_DOWN
		invoke InvalidateRect,hWin,NULL,FALSE
		assume esi:nothing
	.elseif uMsg == WM_ENABLE
		invoke FindFlatButton,hWin
		mov esi,eax
		assume esi:ptr FBINFOSTRUCT
		mov eax,wParam
		.if eax
			and [esi].dwStatus,NOT(BS_DISABLED)
		.else
			mov [esi].dwStatus,BS_DISABLED
		.endif
		invoke InvalidateRect,hWin,NULL,FALSE
		assume esi:nothing
		mov eax,TRUE
		ret
	.elseif uMsg == WM_LBUTTONUP
		invoke FindFlatButton,hWin
		mov esi,eax
		assume esi:ptr FBINFOSTRUCT
		and [esi].dwStatus,NOT(BS_DOWN)
		invoke InvalidateRect,hWin,NULL,FALSE
		assume esi:nothing
		invoke GetWindowLong,hWin,GWL_ID
		mov esi,eax
		invoke GetParent,hWin
		invoke PostMessage,eax,WM_COMMAND,esi,0
		
	.elseif uMsg == WM_DESTROY
		invoke FindFlatButton,hWin
		invoke DeleteFlatButton,eax
	.elseif uMsg == WM_PAINT
		invoke FindFlatButton,hWin
		mov esi,eax
		invoke GetClientRect,hWin,addr stClientRect
		invoke GetDC,hWin
		mov hDC,eax
		invoke GetStockObject,LTGRAY_BRUSH
		invoke FillRect,hDC,ADDR stClientRect,eax
		mov eax,(FBINFOSTRUCT ptr [esi]).dwStatus
		.if eax & BS_FOCUS
			invoke SelectObject,hDC,hBorderPen
			invoke SelectObject,hDC,hFillBrush
		.else
			invoke SelectObject,hDC,hNFBorderPen
			invoke SelectObject,hDC,hNFFillBrush
		.endif
		mov eax,(FBINFOSTRUCT ptr [esi]).dwStatus
		.if eax & BS_DOWN
			inc stClientRect.left
			inc stClientRect.top
		.else
			dec stClientRect.right
			dec stClientRect.bottom
		.endif
		invoke Rectangle,hDC,stClientRect.left,stClientRect.top,stClientRect.right,stClientRect.bottom
		invoke SetBkMode,hDC,TRANSPARENT
		invoke SelectObject,hDC,(FBINFOSTRUCT ptr [esi]).hFont
		mov eax,(FBINFOSTRUCT ptr [esi]).dwStatus
		.if eax & BS_DISABLED
			invoke SetTextColor,hDC,NFBKND_BORDER
		.else
			invoke SetTextColor,hDC,Black
		.endif
		invoke GetWindowText,hWin,ADDR szCaption,MAX_PATH
		lea edi,stClientRect
		invoke DrawText,hDC,ADDR szCaption,-1,edi,DT_SINGLELINE OR DT_CENTER OR DT_VCENTER
		invoke ValidateRect,hWin,NULL
		invoke ReleaseDC,hWin,hDC
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
	.endif
	ret
FlatWndProc endp

END