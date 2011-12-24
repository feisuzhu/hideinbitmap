;By Proton 2006-11

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

PBARINFOSTRUCT struct
	hWnd dd ?
	hdcCache dd ?
	hbmpCache dd ?
	hdcBknd dd ?
	hbmpBknd dd ?
	dwMax dd ?
	dwMin dd ?
	dwCur dd ?
PBARINFOSTRUCT ends

.DATA
	szClassName db "LinuxProgressBar",0
	; E:\DESKTOP\LinuxProgressBar\hehe.bmp is 232 bytes long
	bmpBaseBitmap equ this BYTE
	db 40,0,0,0,3,0,0,0,16,0,0,0,1,0,24,0
	db 0,0,0,0,192,0,0,0,196,14,0,0,196,14,0,0
	db 0,0,0,0,0,0,0,0,239,178,156,255,255,255,255,255
	db 255,0,0,0,231,174,148,255,255,255,255,255,255,0,0,0
	db 231,166,140,255,255,255,255,255,255,0,0,0,222,162,140,255
	db 255,255,255,255,255,0,0,0,214,158,132,239,178,156,189,105
	db 66,0,0,0,214,150,123,189,105,66,115,77,57,0,0,0
	db 206,146,115,115,77,57,189,105,66,0,0,0,198,138,115,189
	db 105,66,239,178,156,0,0,0,198,134,107,189,105,66,189,105
	db 66,0,0,0,189,125,99,115,77,57,189,105,66,0,0,0
	db 181,121,90,189,105,66,189,105,66,0,0,0,181,117,90,189
	db 105,66,239,178,156,0,0,0,173,109,82,239,178,156,189,105
	db 66,0,0,0,165,105,74,189,105,66,189,105,66,0,0,0
	db 165,97,74,189,105,66,239,178,156,0,0,0,156,93,66,189
	db 105,66,189,105,66,0,0,0
	
.DATA?
	hInstance	dd ?
	hBorderPen dd ?
	hFillBrush dd ?
	;hdcBaseBitmap dd ?
	hBaseBitmap dd ?
	stProgbars PBARINFOSTRUCT 100 dup(<?>)

.const
	BKND_BORDER EQU 09C9A9Ch
	BKND_BODY EQU 0C6C7C6h
	BODYSZX EQU 1
	BODYSZY EQU 16
	BODYX EQU 0
	BODYY EQU 0
	CORNERSZX EQU 2
	CORNERSZY EQU 2
	NWX EQU 1
	NWY EQU 0
	NEX EQU 1
	NEY EQU 2
	SWX EQU 1
	SWY EQU 4
	SEX EQU 0
	SEY EQU 6
	LEFTX EQU 1
	LEFTY EQU 8
	RIGHTX EQU 1
	RIGHTY EQU 9
	LRSZX EQU 2
	LRSZY EQU 1
	TOPX EQU 1
	TOPY EQU 10
	BOTX EQU 2
	BOTY EQU 10
	TBSZX EQU 1
	TBSZY EQU 2
	IDB_PBARPICS EQU 102
	
.CODE

LinuxProgressBarInit proc uses esi
	LOCAL wc:WNDCLASSEX
	invoke RtlZeroMemory,ADDR wc,sizeof WNDCLASSEX
	invoke RtlZeroMemory,ADDR stProgbars,100*SIZEOF PBARINFOSTRUCT
	invoke GetModuleHandle,0
	mov hInstance,eax
	mov wc.cbSize,sizeof WNDCLASSEX
	mov wc.style,CS_HREDRAW or CS_VREDRAW
	mov wc.lpfnWndProc,offset PBarWndProc
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
	
	;invoke GetDC,0
	;push eax
	;invoke CreateCompatibleDC,eax
;	mov hdcBaseBitmap,eax
;	pop eax
;	mov esi,eax
;	invoke CreateDIBitmap,esi,offset bmpBaseBitmap,CBM_INIT,offset bmpBaseBitmap+SIZEOF BITMAPINFOHEADER,offset bmpBaseBitmap,DIB_RGB_COLORS
;	mov hBaseBitmap,eax
;	invoke SelectObject,hdcBaseBitmap,eax
;	invoke DeleteObject,eax
	;invoke ReleaseDC,0,esi
	mov eax,TRUE
	ret
LinuxProgressBarInit endp

RegisterProgressBar proc private hWnd1:DWORD
	assume eax:ptr PBARINFOSTRUCT
	lea eax,stProgbars
	xor ecx,ecx
	.while [eax].hWnd!=0
		add eax,sizeof PBARINFOSTRUCT
		inc ecx
		.if ecx>100
			mov eax,FALSE
			ret
		.endif
	.endw
	push hWnd1
	pop [eax].hWnd
	mov [eax].dwMin,0
	mov [eax].dwMax,100
	mov [eax].dwCur,0
	assume eax:nothing
	ret
RegisterProgressBar endp

FindProgressBar proc private hWnd1:DWORD
	assume eax:ptr PBARINFOSTRUCT
	lea eax,stProgbars
	xor ecx,ecx
	mov edx,[eax].hWnd
	.while edx!=hWnd1
		add eax,sizeof PBARINFOSTRUCT
		inc ecx
		.if ecx>100
			mov eax,FALSE
			ret
		.endif
		mov edx,[eax].hWnd
	.endw
	assume eax:nothing
	ret
FindProgressBar endp

DeleteProgressBar proc private hPBar:DWORD
	invoke RtlZeroMemory,hPBar,SIZEOF PBARINFOSTRUCT
	mov eax,TRUE
	ret
DeleteProgressBar endp

RedrawProgressBar proc private uses esi edi hPBar:DWORD
LOCAL stClientRect:RECT
LOCAL CliX:DWORD
LOCAL CliY:DWORD
LOCAL X:DWORD
LOCAL RawX:DWORD
	
	;int 3
	;invoke RegisterProgressBar,324
	;invoke FindProgressBar,324
	;invoke DeleteProgressBar,324
	
	mov esi,hPBar
	assume esi:ptr PBARINFOSTRUCT
	mov edi,[esi].hdcCache
	invoke GetClientRect,[esi].hWnd,ADDR stClientRect
	mov eax,stClientRect.right
	sub eax,stClientRect.left
	mov ecx,stClientRect.bottom
	sub ecx,stClientRect.top
	mov CliX,eax
	mov CliY,ecx
	mov eax,[esi].dwMax
	sub eax,[esi].dwMin
	mov X,eax
	invoke Rectangle,[esi].hdcCache,stClientRect.left,stClientRect.top,stClientRect.right,stClientRect.bottom
	mov eax,[esi].dwCur
	sub eax,[esi].dwMin
	.if eax>80000000h ;for cur < min
		ret
	.endif
	mov eax,[esi].dwCur
	mov edx,CliX
	mul edx
	mov ecx,X
	cdq
	div ecx
	mov RawX,eax
	.if RawX<3
		invoke InvalidateRect,[esi].hWnd,NULL,FALSE
		ret
	.endif
	;invoke BitBlt,hdcDest,nXDest,nYDest,nWidth,nHeight,hdcSrc,nXSrc,nYSrc,dwRop
	invoke BitBlt,[esi].hdcCache,0,0,CORNERSZX,CORNERSZX,[esi].hdcBknd,NWX,NWY,SRCCOPY
	mov edx,CliY
	sub edx,2
	invoke BitBlt,[esi].hdcCache,0,edx,CORNERSZX,CORNERSZY,[esi].hdcBknd,SWX,SWY,SRCCOPY
	mov edx,RawX
	sub edx,2
	invoke BitBlt,[esi].hdcCache,edx,0,CORNERSZX,CORNERSZY,[esi].hdcBknd,NEX,NEY,SRCCOPY
	mov ecx,CliY
	sub ecx,2
	mov edx,RawX
	sub edx,2
	invoke BitBlt,[esi].hdcCache,edx,ecx,CORNERSZX,CORNERSZY,[esi].hdcBknd,NWX,NWX,SRCCOPY
	mov edx,RawX
	sub edx,3
	;invoke StretchBlt,hdcDest,nXOriginDest,nYOriginDest,nWidthDest,nHeightDest,hdcSrc,nXOriginSrc,nYOriginSrc,nWidthSrc,nHeightSrc,dwRop
	invoke StretchBlt,[esi].hdcCache,2,0,edx,2,[esi].hdcBknd,TOPX,TOPY,TBSZX,TBSZY,SRCCOPY
	mov edx,CliY
	sub edx,2
	mov ecx,RawX
	sub ecx,3
	invoke StretchBlt,[esi].hdcCache,2,edx,ecx,2,[esi].hdcBknd,BOTX,BOTY,TBSZX,TBSZY,SRCCOPY
	mov edx,CliY
	sub edx,3
	invoke StretchBlt,[esi].hdcCache,0,2,2,edx,[esi].hdcBknd,LEFTX,LEFTY,LRSZX,LRSZY,SRCCOPY
	mov ecx,CliY
	sub ecx,3
	mov edx,RawX
	sub edx,2
	invoke StretchBlt,[esi].hdcCache,edx,2,2,ecx,[esi].hdcBknd,RIGHTX,RIGHTY,LRSZX,LRSZY,SRCCOPY
	mov ecx,CliY
	sub ecx,4
	mov edx,RawX
	sub edx,4
	invoke StretchBlt,[esi].hdcCache,2,2,edx,ecx,[esi].hdcBknd,BODYX,BODYY,BODYSZX,BODYSZY,SRCCOPY
	invoke InvalidateRect,[esi].hWnd,NULL,FALSE
	ret
	assume esi:nothing
RedrawProgressBar endp

PBarWndProc proc private uses esi edi hWin:DWORD,uMsg:DWORD,wParam :DWORD,lParam :DWORD
LOCAL stClientRect:RECT
LOCAL hDC:DWORD
LOCAL stPaint:PAINTSTRUCT

	.if uMsg==WM_CREATE
		invoke RegisterProgressBar,hWin
		mov esi,eax
		assume esi:ptr PBARINFOSTRUCT
		invoke GetDC,hWin
		mov hDC,eax
		invoke CreateCompatibleDC,eax
		mov [esi].hdcCache,eax
		invoke CreateCompatibleDC,hDC
		mov [esi].hdcBknd,eax
		invoke CreateDIBitmap,hDC,offset bmpBaseBitmap,CBM_INIT,offset bmpBaseBitmap+SIZEOF BITMAPINFOHEADER,offset bmpBaseBitmap,DIB_RGB_COLORS
		mov [esi].hbmpBknd,eax
		invoke SelectObject,[esi].hdcBknd,eax
		invoke DeleteObject,eax
		
		invoke SelectObject,[esi].hdcCache,hBorderPen
		invoke DeleteObject,eax
		invoke SelectObject,[esi].hdcCache,hFillBrush
		invoke DeleteObject,eax
		invoke GetClientRect,hWin,ADDR stClientRect
		mov ecx,stClientRect.right
		sub ecx,stClientRect.left
		mov edx,stClientRect.bottom
		sub edx,stClientRect.top
		invoke CreateCompatibleBitmap,hDC,ecx,edx
		mov [esi].hbmpCache,eax
		invoke SelectObject,[esi].hdcCache,eax
		invoke DeleteObject,eax
		invoke ReleaseDC,hWin,hDC
		invoke RedrawProgressBar,esi
		assume esi:nothing
	.elseif uMsg == PBM_SETRANGE32
		invoke FindProgressBar,hWin
		assume eax:ptr PBARINFOSTRUCT
		push wParam
		pop [eax].dwMin
		.if lParam!=0
			push lParam
		.else
			push 100
		.endif
		pop [eax].dwMax
		mov [eax].dwCur,0
		assume eax:nothing
	.elseif uMsg == PBM_SETPOS
		;int 3
		invoke FindProgressBar,hWin
		assume eax:ptr PBARINFOSTRUCT
		push wParam
		pop [eax].dwCur
		assume eax:nothing
		invoke RedrawProgressBar,eax
	.elseif uMsg == WM_DESTROY
		invoke FindProgressBar,hWin
		mov esi,eax
		assume esi: ptr PBARINFOSTRUCT
		invoke DeleteObject,[esi].hbmpCache
		invoke DeleteDC,[esi].hdcCache
		assume esi:nothing
		invoke DeleteProgressBar,esi
	.elseif uMsg == WM_PAINT
		;int 3
		;invoke BeginPaint,hWin,ADDR stPaint
		;mov hDC,eax
		invoke FindProgressBar,hWin
		mov esi,eax
		;mov eax,stPaint.rcPaint.right
		;sub eax,stPaint.rcPaint.left
		;mov ecx,stPaint.rcPaint.bottom
		;sub ecx,stPaint.rcPaint.top
		;invoke BitBlt,hDC,stPaint.rcPaint.left,stPaint.rcPaint.top,eax,ecx,(PBARINFOSTRUCT ptr [esi]).hdcCache,stPaint.rcPaint.left,stPaint.rcPaint.top,SRCCOPY
		invoke GetClientRect,hWin,addr stClientRect
		invoke GetDC,hWin
		mov hDC,eax
		invoke BitBlt,hDC,0,0,stClientRect.right,stClientRect.bottom,(PBARINFOSTRUCT ptr [esi]).hdcCache,stClientRect.left,stClientRect.top,SRCCOPY
		invoke ValidateRect,hWin,NULL
		invoke ReleaseDC,hWin,hDC
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
	.endif
	ret
PBarWndProc endp

END