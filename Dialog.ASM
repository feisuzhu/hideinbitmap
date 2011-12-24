;By Proton
;MASMPlus 代码模板 - 以对话框做为主窗口的程序

.586
.Model Flat, StdCall
Option Casemap :None

assume fs:nothing

Include windows.inc
Include user32.inc
Include kernel32.inc
Include gdi32.inc
include comctl32.inc
include comdlg32.inc
include ole32.inc
include shell32.inc
include PBarCore.inc
include sha1.inc
include ufmod.inc
include FlatButton.inc

;include masm32.inc
include resource.inc
include BrowseFolder.asm

includelib gdi32.lib
IncludeLib user32.lib
includelib comctl32.lib
includelib comdlg32.lib
IncludeLib kernel32.lib
includelib ole32.lib
includelib shell32.lib
includelib PBarCore.lib
includelib sha1.lib
includelib FlatButton.lib
;includelib masm32.lib

include macro.asm
	
	DlgProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
	SetDataToDIBits proto lpDIBits:DWORD,lpData:DWORD,cbData:DWORD
	GetDataFromDIBits proto lpDIBits:DWORD,lpData:DWORD,cbData:DWORD
	SetDlgCtrlsStatus proto hDlg:DWORD,dwStatus:DWORD
	LoadIntoMap proto Filename:DWORD,FileMap:ptr FILE_MAP,Creation:DWORD
	FreeMap proto hFilemap:ptr FILE_MAP
	Defrag proto
	DoStatistics proto bFlag:DWORD
	SplitFileName proto szModFullPathName:DWORD
	RefreshListView proto
	CDataHexStream proto lpData:DWORD,cbData:DWORD,lpOut:DWORD
	GetFile proto dwFileID:DWORD,lpszFilename:DWORD;It's not my fault masm32.lib ^_^
	PutFile proto lpszFilename:DWORD 
	DataCompare proto pSrc:DWORD,pDst:DWORD,cbData:DWORD
	TEAEncrypt proto lpData:DWORD,cbData:DWORD,lpKey:DWORD
	TEADecrypt proto lpData:DWORD,cbData:DWORD,lpKey:DWORD
	AlignTo64 proto cb:DWORD
	InputBox proto hWnd:DWORD,lpszCaption:DWORD,lpOut:DWORD
	VaildatePassword proto
	ModifyPassword proto
	CenterWindow proto hWnd:DWORD
	QueryIfOverwrite proto lpszFilename:DWORD,dwFileID:DWORD
	DemoDlgProc proto hWnd:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
	
SHARESULT struct
	wHead dw ?
	dwMid1 dd ?
	dwMid2 dd ?
	dwMid3 dd ?
	dwMid4 dd ?
	wTail dw ?
SHARESULT ends

HID_FAT struct
	szFilename db 56 dup (?)
	dwFileOffsetBegin dd ?
	dwFileSize dd ?
	stDataSHA SHARESULT <?>
	dwVaild dd ?
HID_FAT ends

HID_HEADER struct
	szSignature db 32 dup(?)
	dwFileCount dd ?
	stKeySHA SHARESULT <?>
	stFileRecords HID_FAT 25 dup(<>)
HID_HEADER ends

FILE_MAP	STRUCT
	Pointer DWORD ?
	hMapObject DWORD ?
	hFile DWORD ?
	dwSize DWORD ?
FILE_MAP ENDS

.const
	CSTATUS_OPEN equ 1
	CSTATUS_INVAILDPASSWORD equ 2
	CSTATUS_FULL equ 3
	DIBDATABEGIN equ SIZEOF BITMAPFILEHEADER+SIZEOF BITMAPINFOHEADER+3*SIZEOF HID_HEADER
	ID_STATUSBAR equ 12345h
	szStatistics  db "%lu KB",0
	sz08lx db "%08lX",0
	StatusBarParts dd 80,400,-1
	szCorrectSignature db "HideInBitmap! V2.0 By Proton $%",0
	szBmpFilter	DB "BMP文件(*.bmp)",0,"*.bmp",0,"所有文件(*.*)",0,"*.*",0,0
	szFileFilter DB "所有文件(*.*)",0,"*.*",0,0
	
	szErrOpenfile DB "打开文件 %s 失败!",0
	szErrNotVaild DB "%s 不是一个有效的位图文件!",0
	szErrNot24Bit DB "%s 不是一个24-Bit真色彩位图文件!",0
	szErrBmpCorrupted DB "位图 %s 已损坏!",0
	szErrCompressed DB "%s 是一个压缩位图!",0
	szErrFileToolong DB "文件 %s 太长，不能放到当前提供的位图!",0
	szErrFileCountLimit DB "无法容纳更多的文件!一个位图最多可以储存25个文件!",0
	szErrFileCorrupted DB "文件 %s 已损坏，通常是由于BMP文件被修改所致。",0dh,0ah,"请慎重处理损坏的文件！",0
	szErrFilenameToolong DB "文件 %s 的文件名过长，请控制在56个字符以内！",0
	szErrFileSizeZero DB "文件 %s 的长度为0！",0
	szLogo DB "藏宝图 V2.0",0
	szTitle DB "藏宝图 V2.0 - %s",0
	szSHA DB "文件SHA: %s",0
	szDateTime DB "%02d-%02d-%02d %02d:%02d",0
	
	szDemo db "这是一个实用的小软件，它可以将多个文件储存在一个标准的24-Bit",0
	db "真色彩位图中，位图的体积不增加。图像质量会稍微有所下降，但是",0
	db "如果图片选择的合适（比如说明星图片，或者是你的靓照），肉眼是",0
	db "看不出来它与原位图有什么区别的。",0
	db " ",0
	db "程序提供了加密功能，这样即使有人发现图片中藏着东西，不知道密",0
	db "码是不能取出藏在图片里的文件的。特别适合一些如日记之类的不想",0
	db "让别人知道的东西。程序采用的128轮的TEAN加密算法，即使程序被",0
	db "逆向工程、破解，也无法将文件还原。",0
	db " ",0
	db "程序采用纯汇编语言编写，不依赖于任何的除系统提供以外的DLL。",0
	db "经优化后，程序的体积仅为36K。没有拖带的数据文件，不需要安装,",0
	db "是一款小巧的绿色软件。",0
	db " ",0
	db "程序在 Microsoft Windows 2000 with Service Pack 4 上测试成功",0
	db " ",0
	db "升级简史 & What's New",0
	db "v2.0",0
	db "就是这个版本^_^",0
	db "重写了大部分代码,比v1.1强大很多",0
	db "-采用了TEAN加密算法,不再是脆弱的XOR",0
	db "-更易于操作的人机界面",0
	db "-最多可以存储16个文件（以前版本是单个文件）",0
	db "-文件损坏效验(会看到另一个图标和提示)",0
	db "-漂亮的进度条(不知道能不能算-_-bb)",0
	db " ",0
	db "v1.1",0
	db "-提供了XOR加密",0
	db "-程序采用了GUI界面",0
	db " ",0
	db "v1.0",0
	db "-第一个版本，工作在控制台（平常所说的DOS窗",0
	db "口）模式下",0
	db " ",0
	db "参考资料 & 引用的代码",0
	db "OllyDBG（图标）",0
	db "Linux安装程序（进度条的图像）",0
	db "MSDN（ListView,各种消息，通用对话框）",0
	db "http://blog.sina.com.cn/u/471082780100022j（TEA算法）",0
	db "《Windows环境下的32位汇编语言程序设计》（StatusBar用法和",0
	db "GDI,By 罗云彬）",0
	db " ",0
	db "ReloX V1.0 （音乐，By MackT/uCF）",0
	db "uFMOD v1.19（音乐引擎，By Asterix and Quantum）",0
	db "《Windows环境下的32位汇编语言程序设计》（目录选择框）",0
	db "SHA1函数（By 狂编，取自www.aogosoft.com）",0
	db 0
.data
	
.data?
	hInstance dd ?
	hDialog dd ?
	hStatusBar dd ?
	commonbuf db MAX_PATH*25 dup(?)
	szBmpFilename db MAX_PATH dup(?)
	LVItemsSelected db 25 dup(?)
	pDIBits dd ?
	stHidHeader HID_HEADER <>
	stMapBmp FILE_MAP <>
	stMapTmp FILE_MAP <>
	
	wPasswordVaild dw ?
	wPasswordReq dw ?
	
	stEncryptSeed SHARESULT <?>
	
	dwStatTotalSpace dd ?
	dwStatTotalSize dd ?
	dwStatRemainSpace dd ?
	
	hBuf dd ?
	
	;for demostration
	hRollerBmp dd ?
	hRollerDC dd ?
	hBkndBmp dd ?
	hBkndDC dd ?
	hBufBmp dd ?
	hBufDC dd ?
	dwCurCount dd ?
	
.CODE
START:
	push ExceptionHandler
	push fs:[0]
	mov fs:[0],esp
	
	invoke GetModuleHandle,NULL
	mov hInstance,eax
	invoke LinuxProgressBarInit
	invoke FlatButtonInit
	invoke DialogBoxParam,hInstance,IDD_MAIN,0,offset DlgProc,0
	invoke ExitProcess,0

DumpMemory proc lpszFilename:DWORD,lpMem:DWORD,cbData:DWORD ;just for debug
LOCAL fm:FILE_MAP
	pushad
	invoke LoadIntoMap,lpszFilename,ADDR fm,cbData
	invoke RtlMoveMemory,fm.Pointer,lpMem,cbData
	invoke FreeMap,ADDR fm
	popad
	ret
DumpMemory endp

Error proc lpszErrString:DWORD,lpszFilename:DWORD
LOCAL buf [MAX_PATH]:BYTE
	invoke wsprintf,ADDR buf,lpszErrString,lpszFilename
	invoke MessageBox,hDialog,ADDR buf,ADDR szLogo,MB_ICONEXCLAMATION
	ret
Error endp

DlgProc proc uses ebx esi edi hWnd,uMsg,wParam,lParam
LOCAL FileItem:LVITEM
LOCAL NotifyHeader:NMHDR
LOCAL stOpenFile:OPENFILENAME
LOCAL SHAResult:SHARESULT
LOCAL tempbuf [MAX_PATH]:BYTE
	
	.if uMsg==WM_INITDIALOG
		;Initialization
		push hWnd
		pop hDialog
		invoke LoadIcon,hInstance,IDI_MAIN
		invoke SendMessage,hWnd,WM_SETICON,TRUE,eax
		invoke DoStatistics,FALSE
		invoke ImageList_Create,32,32,ILC_COLOR32 OR ILC_MASK,2,0
		mov ebx,eax
		invoke LoadBitmap,hInstance,IDB_FILE
		mov esi,eax
		invoke LoadBitmap,hInstance,IDB_FILEMASK
		mov edi,eax
		invoke ImageList_Add,ebx,esi,edi
		invoke LoadBitmap,hInstance,IDB_FILECORRUPTED
		mov esi,eax
		invoke LoadBitmap,hInstance,IDB_FILECORRUPTEDMASK
		mov edi,eax
		invoke ImageList_Add,ebx,esi,edi
		
		invoke CreateStatusWindow,WS_CHILD OR WS_VISIBLE OR CCS_BOTTOM,NULL,hWnd,ID_STATUSBAR
		mov hStatusBar,eax
		invoke SendDlgItemMessage,hWnd,ID_STATUSBAR,SB_SETPARTS,3,offset StatusBarParts
		invoke SendDlgItemMessage,hWnd,IDC_FILELIST,LVM_SETIMAGELIST,LVSIL_NORMAL,ebx
		invoke SendDlgItemMessage,hWnd,ID_STATUSBAR,SB_SETTEXT,2,CTXT("By Proton")
		invoke SetDlgCtrlsStatus,hWnd,CSTATUS_OPEN
		;-----------------------------------------------------------------------------------------
		invoke CenterWindow,hWnd
		
	.elseif uMsg==WM_COMMAND
		mov eax,wParam
		and eax,0ffffh
		.if eax==IDC_OPEN
			invoke FreeMap,ADDR stMapBmp
			invoke RtlZeroMemory,ADDR stOpenFile,SIZEOF OPENFILENAME
			mov stOpenFile.lStructSize,SIZEOF OPENFILENAME
			push hWnd
			pop stOpenFile.hwndOwner
			mov stOpenFile.lpstrFilter,offset szBmpFilter
			mov eax,offset szBmpFilename
			mov DWORD ptr [eax],0
			mov stOpenFile.lpstrFile,eax
			mov stOpenFile.nMaxFile,MAX_PATH
			mov stOpenFile.Flags,(OFN_EXPLORER OR OFN_FILEMUSTEXIST OR OFN_HIDEREADONLY)
			invoke GetOpenFileName,ADDR stOpenFile
			.if eax==NULL
				ret
			.endif
			invoke LoadIntoMap,offset szBmpFilename,offset stMapBmp,0
			.if eax==-1
				invoke Error,offset szErrOpenfile,offset szBmpFilename
				invoke FreeMap,ADDR stMapBmp
				ret
			.endif
			mov esi,stMapBmp.Pointer
			
			.if stMapBmp.dwSize<(SIZEOF BITMAPFILEHEADER + SIZEOF BITMAPINFOHEADER)
				invoke Error,ADDR szErrNotVaild,offset szBmpFilename
				invoke FreeMap,ADDR stMapBmp
				ret
			.endif
			.if (WORD ptr [esi])!=4d42h ;"BM"
				invoke Error,ADDR szErrNotVaild,offset szBmpFilename
				invoke FreeMap,ADDR stMapBmp
				ret
			.endif
			lea esi,[esi+(SIZEOF BITMAPFILEHEADER)]
			movzx eax,(BITMAPINFOHEADER ptr [esi]).biBitCount
			.if eax!=24 ;24-Bit true color
				invoke Error,ADDR szErrNot24Bit,offset szBmpFilename
				invoke FreeMap,ADDR stMapBmp
				ret
			.endif
			mov eax,(BITMAPINFOHEADER ptr [esi]).biCompression
			.if eax!=BI_RGB
				invoke Error,ADDR szErrCompressed,offset szBmpFilename
				invoke FreeMap,ADDR stMapBmp
				ret
			.endif
			mov esi,stMapBmp.Pointer
			mov eax,(BITMAPFILEHEADER ptr [esi]).bfOffBits
			add esi,eax
			mov pDIBits,esi
			
			mov eax,stMapBmp.dwSize
			.if eax<=DIBDATABEGIN
				invoke MessageBox,hWnd,CTXT("BMP文件过小,无法储存文件!"),addr szLogo,MB_ICONEXCLAMATION
				invoke SendMessage,hWnd,WM_COMMAND,IDC_CLOSE,0
				ret
			.endif
			invoke SetDlgCtrlsStatus,hWnd,CSTATUS_FULL
			invoke GetDataFromDIBits,pDIBits,offset stHidHeader,SIZEOF HID_HEADER
			invoke SetDlgCtrlsStatus,hWnd,CSTATUS_FULL
			invoke lstrcmp,addr stHidHeader.szSignature,addr szCorrectSignature
			
			.if eax
				invoke MessageBox,hWnd,CTXT("这个位图还没有进行初始化，无法储存文件。",0dh,0ah,"要现在初始化吗？"),ADDR szLogo,MB_ICONQUESTION OR MB_YESNO
				.if eax==IDYES
					invoke SendMessage,hWnd,WM_COMMAND,IDC_INIT,84065234
				.else
					invoke SendMessage,hWnd,WM_COMMAND,IDC_CLOSE,0
					ret
				.endif
			.endif
			invoke wsprintf,ADDR commonbuf,ADDR szTitle,stOpenFile.lpstrFile
			invoke SetWindowText,hWnd,ADDR commonbuf
			
			invoke RtlZeroMemory,offset commonbuf,SIZEOF SHARESULT
			invoke DataCompare,offset stHidHeader.stKeySHA,offset commonbuf,SIZEOF SHARESULT
			.if eax!=1
				mov wPasswordReq,1
				invoke VaildatePassword
				.if eax==0
					invoke SetDlgCtrlsStatus,hWnd,CSTATUS_INVAILDPASSWORD
					invoke DoStatistics,TRUE
					ret
				.endif
			.else
				mov wPasswordReq,0
			.endif
			invoke DoStatistics,TRUE
			mov eax,dwStatTotalSpace
			add eax,25*8
			
			invoke VirtualAlloc,NULL,eax,MEM_COMMIT,PAGE_READWRITE
			mov hBuf,eax
			invoke DoStatistics,TRUE
			invoke RefreshListView
		.elseif eax==IDC_INIT
			.if lParam!=84065234
				invoke MessageBox,hWnd,CTXT("初始化后存入的文件将丢失！",0dh,0ah,"你确定要初始化吗？"),addr szLogo,MB_ICONQUESTION OR MB_YESNO
				.if eax==IDNO
					ret
				.endif
			.endif
			invoke RtlZeroMemory,ADDR stHidHeader,SIZEOF stHidHeader
			invoke RtlMoveMemory,ADDR stHidHeader,ADDR szCorrectSignature,SIZEOF szCorrectSignature
			mov eax,stMapBmp.dwSize
			.if eax<=DIBDATABEGIN
				invoke MessageBox,hWnd,CTXT("BMP文件过小,无法储存文件!"),addr szLogo,MB_ICONEXCLAMATION
				invoke SendMessage,hWnd,WM_COMMAND,IDC_CLOSE,0
				ret
			.endif
			invoke SetDataToDIBits,pDIBits,ADDR stHidHeader,SIZEOF HID_HEADER
			invoke DoStatistics,TRUE
			invoke SetDlgCtrlsStatus,hWnd,CSTATUS_FULL
			xor eax,eax
			mov wPasswordVaild,ax
			mov wPasswordReq,ax
			invoke DoStatistics,TRUE
			invoke RefreshListView
		.elseif eax==IDC_ADD
			invoke VaildatePassword
			.if eax==0
				ret
			.endif
			.if stHidHeader.dwFileCount==25
				invoke MessageBox,hWnd,ADDR szErrFileCountLimit,addr szLogo,MB_ICONEXCLAMATION
				ret
			.endif
			invoke RtlZeroMemory,ADDR stOpenFile,SIZEOF OPENFILENAME
			mov stOpenFile.lStructSize,SIZEOF OPENFILENAME
			push hWnd
			pop stOpenFile.hwndOwner
			mov stOpenFile.lpstrFilter,offset szFileFilter
			invoke RtlFillMemory,addr commonbuf,MAX_PATH*25,255
			mov commonbuf,0
			mov stOpenFile.lpstrFile,offset commonbuf
			mov stOpenFile.nMaxFile,MAX_PATH*25
			mov stOpenFile.Flags,(OFN_EXPLORER OR OFN_ALLOWMULTISELECT OR OFN_HIDEREADONLY)
			invoke GetOpenFileName,ADDR stOpenFile ;damn micro$oft, TERRIBLE design about single and multiple selection
			.if eax==0
				ret
			.endif
			invoke Sleep,20 ; just wait for the common dialog closed
			invoke lstrlen,stOpenFile.lpstrFile
			mov edi,eax
			add eax,stOpenFile.lpstrFile
			.if WORD ptr [eax]==0
				invoke PutFile,stOpenFile.lpstrFile
			.else
				mov ebx,offset commonbuf
				add ebx,edi
				inc ebx
				lea esi,tempbuf
				add edi,esi
				invoke RtlZeroMemory,esi,MAX_PATH
				invoke lstrcpy,esi,offset commonbuf
				mov BYTE ptr [edi],"\"
				inc edi
				.while BYTE ptr [ebx]!=0
					mov BYTE ptr [edi],0
					invoke lstrcat,esi,ebx
					invoke PutFile,esi
					.if stHidHeader.dwFileCount==25
						invoke MessageBox,hWnd,ADDR szErrFileCountLimit,addr szLogo,MB_ICONEXCLAMATION
						invoke DoStatistics,TRUE
						invoke RefreshListView
						ret
					.endif
					invoke lstrlen,ebx
					add ebx,eax
					inc ebx
				.endw
			.endif
			invoke DoStatistics,TRUE
			invoke RefreshListView
		.elseif eax==IDC_CLOSE
			invoke SetWindowText,hWnd,offset szLogo
			invoke SetDlgCtrlsStatus,hWnd,CSTATUS_OPEN
			invoke FreeMap,ADDR stMapBmp
			invoke DoStatistics,FALSE
			invoke SendDlgItemMessage,hWnd,IDC_FILELIST,LVM_DELETEALLITEMS,0,0
			invoke SetWindowText,hWnd,ADDR szLogo
			invoke VirtualFree,hBuf,0,MEM_RELEASE
			ret
		.elseif eax==IDC_EXTRACT
			invoke VaildatePassword
			.if eax==0
				ret
			.endif
			lea esi,tempbuf
			mov edi,esi
			invoke RtlZeroMemory,esi,SIZEOF tempbuf
			invoke _BrowseFolder,hDialog,esi
			.if eax==FALSE
				ret
			.endif
			invoke Sleep,5
			invoke lstrlen,esi
			add edi,eax
			mov BYTE ptr [edi],"\"
			inc edi
			invoke RtlZeroMemory,ADDR FileItem,SIZEOF LVITEM
			mov FileItem.imask,(LVIF_TEXT OR LVIF_IMAGE OR LVIF_PARAM)
			mov FileItem.pszText,offset commonbuf
			mov FileItem.cchTextMax,MAX_PATH*25
			xor ecx,ecx
			.while ecx<25
				push ecx
				.if LVItemsSelected[ecx] & LVIS_SELECTED
					mov FileItem.iItem,ecx
					invoke SendDlgItemMessage,hWnd,IDC_FILELIST,LVM_GETITEM,NULL,ADDR FileItem
					invoke lstrcpy,edi,offset commonbuf
					invoke QueryIfOverwrite,esi,FileItem.lParam
					.if eax
						invoke GetFile,FileItem.lParam,esi
					.endif
				.endif
				pop ecx
				inc ecx
			.endw
		.elseif eax==IDC_DELETE
			invoke RtlZeroMemory,ADDR FileItem,SIZEOF LVITEM
			mov FileItem.imask,(LVIF_TEXT OR LVIF_IMAGE OR LVIF_PARAM)
			mov FileItem.pszText,offset commonbuf
			mov FileItem.cchTextMax,MAX_PATH*25
			xor ecx,ecx
			.while ecx<25
				push ecx
				.if LVItemsSelected[ecx] & LVIS_SELECTED 
					mov FileItem.iItem,ecx
					invoke SendDlgItemMessage,hWnd,IDC_FILELIST,LVM_GETITEM,NULL,ADDR FileItem
					mov eax,FileItem.lParam
					mov edx,SIZEOF HID_FAT
					mul edx
					add eax,offset stHidHeader.stFileRecords
					invoke RtlZeroMemory,eax,SIZEOF HID_FAT
					dec stHidHeader.dwFileCount
				.endif
				pop ecx
				inc ecx
			.endw
			invoke Defrag
			invoke DoStatistics,TRUE
			invoke RefreshListView
		.elseif eax==IDC_PASSMODIFY
			invoke ModifyPassword
		.elseif eax==IDC_ABOUT
			invoke DialogBoxParam,hInstance,IDD_ABOUT,hWnd,offset DemoDlgProc,0
			ret
		.endif
	.elseif uMsg==WM_NOTIFY
		.if wParam==IDC_FILELIST
			mov ebx,lParam
			assume ebx:ptr NMHDR
			.if [ebx].code==LVN_ITEMACTIVATE
				;I DON'T BELIEVE THERE IS A BUG ABOUT THE LPARAM!
				;mov eax,(NMITEMACTIVATE ptr [ebx]).lParam
				
				invoke RtlZeroMemory,ADDR FileItem,SIZEOF FileItem
				mov FileItem.imask,(LVIF_PARAM OR LVIF_TEXT OR LVIF_IMAGE)
				mov eax,(NMITEMACTIVATE ptr [ebx]).iItem
				mov FileItem.iItem,eax
				mov FileItem.pszText,offset commonbuf
				mov FileItem.cchTextMax,MAX_PATH*25
				invoke SendDlgItemMessage,hWnd,IDC_FILELIST,LVM_GETITEM,0,ADDR FileItem
				invoke lstrcpy,offset commonbuf+200,offset commonbuf
				mov edi,FileItem.lParam
				invoke RtlZeroMemory,ADDR stOpenFile,SIZEOF OPENFILENAME
				mov stOpenFile.lStructSize,SIZEOF OPENFILENAME
				push hWnd
				pop stOpenFile.hwndOwner
				mov stOpenFile.lpstrFilter,offset szFileFilter
				mov stOpenFile.lpstrFile,offset commonbuf
				mov stOpenFile.nMaxFile,MAX_PATH*25
				mov stOpenFile.Flags,(OFN_EXPLORER OR OFN_PATHMUSTEXIST OR OFN_OVERWRITEPROMPT)
				invoke GetSaveFileName,ADDR stOpenFile
				.if eax==0
					ret
				.endif
				invoke GetFile,edi,offset commonbuf
				.if FileItem.iImage==1
					invoke Error,ADDR szErrFileCorrupted,offset commonbuf+200
				.endif
			.elseif [ebx].code==LVN_ITEMCHANGED
				mov eax,(NMLISTVIEW ptr [ebx]).iItem
				mov ecx,(NMLISTVIEW ptr [ebx]).uNewState
				mov LVItemsSelected[eax],cl
				.if cl==(LVIS_SELECTED OR LVIS_FOCUSED)
					mov edx,SIZEOF HID_FAT
					mul edx
					mov esi,eax
					add esi,offset stHidHeader.stFileRecords
					assume esi:ptr HID_FAT
					lea edx,[esi].stDataSHA
					invoke CDataHexStream,edx,SIZEOF SHARESULT,offset commonbuf+200
					invoke wsprintf,offset commonbuf,offset szSHA,offset commonbuf+200
					invoke SendDlgItemMessage,hWnd,ID_STATUSBAR,SB_SETTEXT,1,offset commonbuf
					assume esi:nothing
					invoke RtlZeroMemory,ADDR FileItem,SIZEOF FileItem
					mov FileItem.imask,(LVIF_IMAGE)
					mov eax,(NMLISTVIEW ptr [ebx]).iItem
					mov FileItem.iItem,eax
					invoke SendDlgItemMessage,hWnd,IDC_FILELIST,LVM_GETITEM,0,ADDR FileItem
					.if FileItem.iImage==0
						invoke SendDlgItemMessage,hWnd,ID_STATUSBAR,SB_SETTEXT,0,CTXT("文件正常")
					.else
						invoke SendDlgItemMessage,hWnd,ID_STATUSBAR,SB_SETTEXT,0,CTXT("文件已损坏")
					.endif
				.endif
			.endif
		.endif
		assume esi:nothing
	.elseif uMsg==WM_CLOSE
		invoke EndDialog,hWnd,wParam
	.else
		mov eax,FALSE
		ret
	.endif
	mov eax,TRUE
	ret
DlgProc endp

ExceptionDlgProc proc uses ebx esi edi hWnd,uMsg,wParam,lParam
LOCAL buf [10]:BYTE
	.if uMsg==WM_COMMAND
		mov eax,wParam
		and eax,0FFFFh
		invoke EndDialog,hWnd,eax
	.elseif uMsg==WM_CLOSE
		invoke EndDialog,hWnd,IDC_EXITPROGRAM
	.elseif uMsg==WM_INITDIALOG
		invoke CenterWindow,hWnd
		mov esi,lParam
		assume esi:ptr EXCEPTION_RECORD
		invoke RtlZeroMemory,ADDR buf,10
		invoke wsprintf,ADDR buf,ADDR sz08lx,[esi].ExceptionCode
		invoke SetDlgItemText,hWnd,IDC_EXCEPTIONCODE,ADDR buf
		invoke wsprintf,ADDR buf,ADDR sz08lx,[esi].ExceptionFlags
		invoke SetDlgItemText,hWnd,IDC_EXCEPTIONFLAG,ADDR buf
		invoke wsprintf,ADDR buf,ADDR sz08lx,[esi].ExceptionAddress
		invoke SetDlgItemText,hWnd,IDC_EXCEPTIONADDRESS,ADDR buf
		assume esi:nothing
	.else
		mov eax,FALSE
		ret
	.endif
	mov eax,TRUE
	ret
ExceptionDlgProc endp

ExceptionHandler proc C uses esi edi lpExceptionRecord:DWORD,lpSEH:DWORD,lpCONTEXT:DWORD,lpDispatcherContext:DWORD
	mov esi,lpExceptionRecord
	mov eax,(EXCEPTION_RECORD ptr [esi]).ExceptionCode
	.if eax!=0C0000027h ;EXCEPTION_UNWIND
		invoke DialogBoxParam,hInstance,IDD_EXCEPTION,hDialog,offset ExceptionDlgProc,esi
		.if eax==IDC_RESTART
			invoke GetCommandLine
			invoke WinExec,eax,SW_NORMAL
			invoke ExitProcess,0
		.elseif eax==IDC_EXITPROGRAM
			invoke ExitProcess,0
		.elseif eax==IDC_DEBUG
			mov eax,ExceptionContinueSearch
			ret
		.endif
	.else
		mov eax,ExceptionContinueSearch
	.endif
	ret
ExceptionHandler endp

GetDataFromDIBits proc uses esi edi ebx lpDIBits:DWORD,lpOut:DWORD,cbData:DWORD
	xor ecx,ecx
	mov ebx,lpOut
	mov esi,lpDIBits
	;-----------------CORE!
	.repeat
		lodsd
		dec esi       ;3 bytes per loop
		and eax,0003030Fh ;MASK!  B ->4 bits G & R -> 2 bits*2 first byte is the next blue
		mov edx,eax
		xor eax,eax
		
		push edx ;Blue 
		;----------    ; |00000000| |00000000| |00000000| |&&&&XXXX| total -> 0 bits
		and edx,0000000Fh ;mask look above
		or eax,edx
		
		mov edx,[esp] ;Green
		shr edx,4      ; |00000000| |00000000| |000000--| |&&XX&&&&| total -> 4 bits
		and edx,00000030h ; ..
		or eax,edx
		
		pop edx ;Red
		shr edx,10     ; |00000000| |000000--| |00000000| |XX&&&&&&| total -> 1 BYTE +2 bits  -> 10 bits
		and edx,000000C0h
		or eax,edx
		
		mov BYTE ptr [ebx+ecx],al
		inc ecx
	.until ecx>=cbData
	ret
GetDataFromDIBits endp

SetDataToDIBits proc uses esi edi ebx lpDIBits:DWORD,lpData:DWORD,cbData:DWORD
	xor ecx,ecx
	mov ebx,lpData
	mov esi,lpDIBits
	mov edi,esi
	;-----------------CORE!
	.repeat
		lodsd
		dec esi       ;3 bytes per loop
		and eax,0FFFCFCF0h ;MASK!  B ->4 bits G & R -> 2 bits*2 first byte is the next blue
		push eax
		movzx edx,BYTE ptr [ebx+ecx]
		push edx ;Blue 
		;----------    ; |00000000| |00000000| |00000000| |&&&&XXXX| total -> 0 bits
		and edx,0000000Fh ;mask look above
		or eax,edx
		
		mov edx,[esp] ;Green
		shl edx,4      ; |00000000| |00000000| |0000&&XX| |&&&&0000| total -> 4 bits
		and edx,00000300h ; ..
		or eax,edx
		
		pop edx ;Red
		shl edx,10     ; |00000000| |000000XX| |&&&&&&00| |00000000| total -> 1 BYTE +2 bits  -> 10 bits
		and edx,00030000h
		or eax,edx
		
		pop edx
		or eax,edx
		stosd
		dec edi
		inc ecx
	.until ecx>=cbData
	ret
SetDataToDIBits endp

SetDlgCtrlsStatus proc uses ebx esi edi hDlg:DWORD,dwStatus:DWORD
;CSTATUS_OPEN equ 1
;CSTATUS_INVAILDPASSWORD equ 2
;CSTATUS_FULL equ 3
	.if dwStatus==CSTATUS_OPEN
		lea edi,CStatusOpen
	.elseif dwStatus==CSTATUS_INVAILDPASSWORD
		lea edi,CStatusInvaildPass
	.elseif dwStatus==CSTATUS_FULL
		lea edi,CStatusFull
	.else
		ret
	.endif
	lea esi,ControlsList
	xor ebx,ebx
	.repeat
		invoke GetDlgItem,hDlg,[esi+4*ebx]
		mov ecx,[edi+4*ebx]
		invoke EnableWindow,eax,ecx
		inc ebx
	.until ebx==7
	ret
ControlsList:
dd IDC_OPEN,IDC_CLOSE,IDC_INIT,IDC_ADD,IDC_EXTRACT,IDC_DELETE,IDC_PASSMODIFY
CStatusOpen:
dd 1,0,0,0,0,0,0
CStatusFull:
dd 1,1,1,1,1,1,1
CStatusInvaildPass:
dd 1,1,1,0,0,0,0
;cc=7
SetDlgCtrlsStatus endp

LoadIntoMap proc uses ecx esi edi Filename:DWORD,FileMap:ptr FILE_MAP,Creation:DWORD
	assume ecx:ptr FILE_MAP
	mov ecx,FileMap
	push ecx ;protect -> APIs using
	invoke RtlZeroMemory,FileMap,SIZEOF FILE_MAP
	.if Creation
		invoke CreateFile,Filename,GENERIC_READ OR GENERIC_WRITE,FILE_SHARE_READ,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
	.else
		invoke CreateFile,Filename,GENERIC_READ OR GENERIC_WRITE,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.endif
	
	.if eax==-1
		mov eax,-1
		ret
	.endif
	mov ecx,[esp] 
	mov [ecx].hFile,eax
	invoke GetFileSize,eax,0
	mov ecx,[esp]
	.if Creation
		push Creation
		pop [ecx].dwSize
		invoke CreateFileMapping,[ecx].hFile,0,PAGE_READWRITE,0,Creation,0
	.else
		mov [ecx].dwSize,eax
		invoke CreateFileMapping,[ecx].hFile,0,PAGE_READWRITE,0,0,0
	.endif
	mov ecx,[esp]
	mov [ecx].hMapObject,eax
	invoke MapViewOfFile,eax,FILE_MAP_ALL_ACCESS,0,0,0
	pop ecx
	mov [ecx].Pointer,eax
	xor eax,eax
	inc eax
	assume ecx:nothing
	ret
LoadIntoMap endp

FreeMap proc uses ebx esi edi hFilemap:ptr FILE_MAP
	assume ebx:ptr FILE_MAP
	pushad
	mov ebx,hFilemap
	invoke UnmapViewOfFile,[ebx].Pointer
	invoke CloseHandle,[ebx].hMapObject
	invoke CloseHandle,[ebx].hFile
	assume ebx:nothing
	popad
	ret
FreeMap endp

DoStatistics proc uses ebx esi edi bFlag:DWORD
	.if bFlag==FALSE
		invoke SetDlgItemInt,hDialog,IDC_TOTALFILE,0,FALSE
		invoke wsprintf,ADDR commonbuf,ADDR szStatistics,0
		invoke SetDlgItemText,hDialog,IDC_TOTALMEM,ADDR commonbuf
		invoke SetDlgItemText,hDialog,IDC_USEDMEM,ADDR commonbuf
		invoke SetDlgItemText,hDialog,IDC_REMAINMEM,ADDR commonbuf
		invoke SendDlgItemMessage,hDialog,IDC_PBAR,PBM_SETRANGE32,0,100
		invoke SendDlgItemMessage,hDialog,IDC_PBAR,PBM_SETPOS,0,0
		xor eax,eax
		mov dwStatTotalSpace,eax
		mov dwStatTotalSize,eax
		mov dwStatRemainSpace,eax
		
	.else
		mov esi,offset stHidHeader.stFileRecords
		mov eax,(HID_FAT ptr [esi]).dwVaild
		push 0
		pop dwStatTotalSize
		mov eax,stMapBmp.dwSize
		sub eax,DIBDATABEGIN
		push eax
		mov ecx,3
		cdq
		div ecx
		sub eax,25*8 ;last few bytes for no ACCESS_VIOLATION
		mov dwStatTotalSpace,eax
		pop eax
		xor ecx,ecx
		.while eax!=0
			.break .if ecx==25
			mov eax,(HID_FAT ptr [esi]).dwFileSize
			invoke AlignTo64,eax
			add dwStatTotalSize,eax
			add esi,SIZEOF HID_FAT
			inc ecx
		.endw
		pop eax ;for @B <push eax>
		mov esi,dwStatTotalSpace
		sub esi,dwStatTotalSize
		mov dwStatRemainSpace,esi
		invoke SetDlgItemInt,hDialog,IDC_TOTALFILE,stHidHeader.dwFileCount,FALSE
		mov eax,dwStatTotalSpace
		shr eax,10
		invoke wsprintf,ADDR commonbuf,addr szStatistics,eax
		invoke SetDlgItemText,hDialog,IDC_TOTALMEM,offset commonbuf
		mov eax,dwStatTotalSize
		shr eax,10
		invoke wsprintf,ADDR commonbuf,addr szStatistics,eax
		invoke SetDlgItemText,hDialog,IDC_USEDMEM,offset commonbuf
		mov eax,dwStatRemainSpace
		shr eax,10
		invoke wsprintf,ADDR commonbuf,addr szStatistics,eax
		invoke SetDlgItemText,hDialog,IDC_REMAINMEM,offset commonbuf
		
		invoke SendDlgItemMessage,hDialog,IDC_PBAR,PBM_SETRANGE32,0,dwStatTotalSpace
		invoke SendDlgItemMessage,hDialog,IDC_PBAR,PBM_SETPOS,dwStatTotalSize,0
	.endif
	ret
DoStatistics endp

Defrag proc uses ebx esi edi ;    T_T to face the music
LOCAL hehehe [SIZEOF HID_FAT*25]:BYTE
LOCAL hMem:DWORD
LOCAL pFOffs:DWORD
	invoke RtlZeroMemory,ADDR hehehe,SIZEOF hehehe
	mov esi,offset stHidHeader.stFileRecords
	lea edi,hehehe
	assume esi:ptr HID_FAT,edi:ptr HID_FAT
	.if stHidHeader.dwFileCount==0
		ret
	.endif
	xor ecx,ecx
	.while ecx<25
		.if [esi].dwVaild
			push ecx
			invoke RtlMoveMemory,edi,esi,SIZEOF HID_FAT
			pop ecx
			add esi,SIZEOF HID_FAT
			add edi,SIZEOF HID_FAT
		.else
			add esi,SIZEOF HID_FAT
		.endif
		inc ecx
	.endw
	assume esi:nothing,edi:nothing
	invoke RtlMoveMemory,offset stHidHeader.stFileRecords,ADDR hehehe,SIZEOF hehehe
	;begin data defragment
	invoke VirtualAlloc,NULL,dwStatTotalSize,MEM_COMMIT,PAGE_READWRITE
	mov edi,eax
	mov esi,edi
	mov eax,stMapBmp.Pointer
	add eax,DIBDATABEGIN
	invoke GetDataFromDIBits,eax,edi,dwStatTotalSize
	xor ecx,ecx
	mov ebx,offset stHidHeader.stFileRecords
	assume ebx:ptr HID_FAT
	push 0
	pop pFOffs
	.while ecx<stHidHeader.dwFileCount
		push ecx
		mov edx,[ebx].dwFileOffsetBegin
		add edx,esi
		mov eax,[ebx].dwFileSize
		invoke AlignTo64,eax
		invoke RtlMoveMemory,edi,edx,eax
		push pFOffs
		pop [ebx].dwFileOffsetBegin
		mov eax,[ebx].dwFileSize
		invoke AlignTo64,eax
		add pFOffs,eax
		add edi,eax
		
		pop ecx
		inc ecx
		add ebx,SIZEOF HID_FAT
	.endw
	mov eax,stMapBmp.Pointer
	add eax,DIBDATABEGIN
	invoke SetDataToDIBits,eax,esi,dwStatTotalSize
	invoke SetDataToDIBits,pDIBits,ADDR stHidHeader,SIZEOF HID_HEADER
	invoke VirtualAlloc,esi,0,MEM_COMMIT,PAGE_READWRITE
	assume ebx:nothing
	ret
Defrag endp

RefreshListView proc uses ebx esi edi
LOCAL Item:LVITEM
LOCAL CurSHA:SHARESULT
LOCAL hMem:DWORD
LOCAL SizeAligned:DWORD
	invoke VirtualAlloc,NULL,dwStatTotalSize,MEM_COMMIT,PAGE_READWRITE
	mov hMem,eax
   invoke SendDlgItemMessage,hDialog,IDC_FILELIST,LVM_DELETEALLITEMS,0,0
   invoke RtlZeroMemory,ADDR Item,SIZEOF LVITEM
   mov esi,offset stHidHeader.stFileRecords
   assume esi:ptr HID_FAT
   xor ecx,ecx
   .while [esi].dwVaild
   	push ecx
      mov Item.imask,(LVIF_IMAGE OR LVIF_PARAM OR LVIF_TEXT)
   	mov Item.pszText,esi ;actually addr [esi].szFilename 
   	mov Item.lParam,ecx
   	mov edx,[esi].dwFileOffsetBegin
		lea edx,[edx+2*edx]
		add edx,DIBDATABEGIN
		add edx,stMapBmp.Pointer
		mov eax,[esi].dwFileSize
		invoke AlignTo64,eax
		mov SizeAligned,eax
		invoke GetDataFromDIBits,edx,hMem,eax
   	invoke SHA1_GetCode,hMem,SizeAligned,ADDR CurSHA
   	invoke DataCompare,ADDR CurSHA,ADDR [esi].stDataSHA,SIZEOF SHARESULT
   	.if eax
   		mov Item.iImage,0
   	.else
   		mov Item.iImage,1
   	.endif
   	
   	invoke SendDlgItemMessage,hDialog,IDC_FILELIST,LVM_INSERTITEM,NULL,ADDR Item
   	pop ecx
   	add esi,SIZEOF HID_FAT
   	inc ecx
   	.break .if ecx==26
   .endw
   invoke VirtualFree,hMem,0,MEM_RELEASE
   invoke RtlZeroMemory,ADDR LVItemsSelected,SIZEOF LVItemsSelected
	ret
RefreshListView endp

SplitFileName proc uses edi lpszFullPathName:DWORD
	mov edi,lpszFullPathName
	xor ecx,ecx
	not ecx
	xor eax,eax
	repnz scasb
	not ecx
	dec ecx
	std
	mov edi,ecx
	mov edx,ecx
	add edi,lpszFullPathName
	mov eax,"\"
	xor ecx,ecx
	dec ecx
	repnz scasb
	cld
	mov eax,edi
	add eax,2
	ret
SplitFileName endp

JustForDebug proc uses eax esi 
	mov eax,dwStatTotalSize
	add eax,DIBDATABEGIN
	push eax
	invoke GlobalAlloc,GPTR,eax
	mov esi,eax
	pop eax
	invoke GetDataFromDIBits,pDIBits,esi,eax
	int 3
	invoke GlobalFree,esi
	ret
JustForDebug endp

CDataHexStream proc uses ebx esi edi lpData:DWORD,cbData:DWORD,lpOut:DWORD
	mov esi,lpData
	mov ecx,cbData
	mov edi,lpOut
	xor eax,eax
	mov ebx,offset HexMapTable
	.repeat
		lodsb
		movzx edx,al
		and edx,0Fh
		mov ah,[ebx+edx]
		movzx edx,al
		shr edx,4
		mov al,[ebx+edx]
		stosw
	.untilcxz
	ret
HexMapTable:
db "0123456789ABCDEF"
CDataHexStream endp

GetFile proc uses esi dwFileID:DWORD,lpszFilename:DWORD;It's not my fault masm32.lib ^_^ ret non zero if succeed
LOCAL SizeAligned:DWORD
	
	mov eax,dwFileID
	mov edx,SIZEOF HID_FAT
	mul edx
	lea esi,[eax+offset stHidHeader.stFileRecords]
	assume esi:ptr HID_FAT
	invoke LoadIntoMap,lpszFilename,addr stMapTmp,[esi].dwFileSize
	.if eax==-1
		xor eax,eax
		ret
	.endif
;	mov eax,[esi].dwFileSize
;	invoke AlignTo64,eax
;	invoke GlobalAlloc,GPTR,eax
;	mov hMem,eax
	mov edx,[esi].dwFileOffsetBegin
	lea edx,[edx+2*edx]
	add edx,DIBDATABEGIN
	add edx,stMapBmp.Pointer
	mov eax,[esi].dwFileSize
	invoke AlignTo64,eax
	mov SizeAligned,eax
	invoke GetDataFromDIBits,edx,hBuf,eax
	.if wPasswordReq
		invoke TEADecrypt,hBuf,SizeAligned,offset stEncryptSeed.dwMid1
	.endif 
	invoke RtlMoveMemory,stMapTmp.Pointer,hBuf,[esi].dwFileSize
	invoke FreeMap,addr stMapTmp
	assume esi:nothing
;	invoke GlobalFree,hMem
	xor eax,eax
	inc eax
	ret
GetFile endp

PutFile proc uses ebx esi edi lpszFilename:DWORD ;return file id
LOCAL SHAResult:SHARESULT
LOCAL SizeAligned:DWORD
	mov ebx,offset stHidHeader.stFileRecords
	xor ecx,ecx
	
	.while TRUE ;look for a free struct
		mov eax,(HID_FAT ptr [ebx]).dwVaild
		.break .if eax==0
		add ebx,SIZEOF HID_FAT
		inc ecx
	.endw
	mov esi,ecx
	
	invoke LoadIntoMap,lpszFilename,ADDR stMapTmp,0
	.if eax==-1
		invoke Error,ADDR szErrOpenfile,lpszFilename
		invoke FreeMap,ADDR stMapTmp
		invoke DoStatistics,TRUE
		xor eax,eax
		ret
	.endif
	mov eax,stMapTmp.dwSize
	.if eax==0
		invoke Error,addr szErrFileSizeZero,lpszFilename
		invoke FreeMap,ADDR stMapTmp
		invoke DoStatistics,TRUE
		ret
	.endif
	invoke AlignTo64,eax
	
	.if eax>=dwStatRemainSpace
		invoke Error,addr szErrFileToolong,lpszFilename
		invoke FreeMap,ADDR stMapTmp
		invoke DoStatistics,TRUE
		;int 3
		ret
	.endif
	
	assume ebx:ptr HID_FAT
	invoke SplitFileName,lpszFilename
	push eax
	invoke lstrlen,eax
	.if eax>=SIZEOF HID_FAT.szFilename
		pop eax
		invoke Error,addr szErrFilenameToolong,eax
		invoke DoStatistics,TRUE
	.endif
	pop eax
	invoke lstrcpy,addr [ebx].szFilename,eax
	
	inc [ebx].dwVaild
	
	.if stHidHeader.dwFileCount==0
		xor edx,edx
	.else
		mov edx,[ebx-SIZEOF HID_FAT].dwFileOffsetBegin
		mov eax,[ebx-SIZEOF HID_FAT].dwFileSize
		invoke AlignTo64,eax
		add edx,eax
	.endif
	mov [ebx].dwFileOffsetBegin,edx
	push edx
	mov eax,stMapTmp.dwSize
	mov [ebx].dwFileSize,eax
	invoke AlignTo64,eax
	mov SizeAligned,eax
	invoke RtlMoveMemory,hBuf,stMapTmp.Pointer,stMapTmp.dwSize
	.if wPasswordReq
		invoke TEAEncrypt,hBuf,SizeAligned,offset stEncryptSeed.dwMid1
	.endif
	invoke SHA1_GetCode,hBuf,SizeAligned,ADDR SHAResult
	
	invoke RtlMoveMemory,ADDR [ebx].stDataSHA,ADDR SHAResult,SIZEOF SHARESULT
	
	inc stHidHeader.dwFileCount
	invoke SetDataToDIBits,pDIBits,ADDR stHidHeader,SIZEOF HID_HEADER
	assume ebx:nothing
	
	pop ebx ;for @B <push edx>
	lea ebx,[ebx+2*ebx]
	add ebx,stMapBmp.Pointer
	add ebx,DIBDATABEGIN
	
	invoke SetDataToDIBits,ebx,hBuf,SizeAligned
	invoke FreeMap,addr stMapTmp
	invoke DoStatistics,TRUE
	mov eax,esi
	ret
PutFile endp

DataCompare proc uses esi edi pSrc:DWORD,pDst:DWORD,cbData:DWORD ;return 1 if equal,only for small amount of data
	mov esi,pSrc
	mov edi,pDst
	mov ecx,cbData
	repz cmpsb
	setz al
	movzx eax,al
	ret
DataCompare endp

TEADELTA equ 09E3779B9h ;(sqrt(5)-1)*2^31
TEALIMIT equ 01BBCDC80h ;DELTA * 128 , because of very small amount of data ,using 128
								;KANAL v2.82 couldn't detect it's TEAN (only said 'Golden ratio' for TEADELTA)

TEAEncrypt proc uses ebx esi edi lpData:DWORD,cbData:DWORD,lpKey:DWORD
	.if cbData==0
		ret
	.endif
	push ebp
	;sub esp,8
	
	mov eax,cbData
	.if eax & 7
		or eax,7
		inc eax
	.endif
	add eax,lpData
	push eax
	push lpData
	mov ebx,lpKey
	.while TRUE
		mov ecx,[esp]
		.break .if ecx==[esp+4]
		add DWORD ptr [esp],8
		mov esi,[ecx]
		mov edi,[ecx+4]
		push ecx
		xor edx,edx
		.while edx!=TEALIMIT
			mov eax,edi
			shl eax,4
			mov ecx,edi
			shr ecx,5
			xor eax,ecx
			mov ebp,eax
			mov eax,edi
			xor eax,edx
			add ebp,eax
			mov eax,edx
			and eax,3
			add ebp,[ebx+4*eax]
			add esi,ebp
			
			add edx,TEADELTA
			
			mov eax,esi
			shl eax,4
			mov ecx,esi
			shr ecx,5
			xor eax,ecx
			mov ebp,eax
			mov eax,esi
			xor eax,edx
			add ebp,eax
			mov eax,edx
			shr eax,11
			and eax,3
			add ebp,[ebx+4*eax]
			add edi,ebp
		.endw
		pop ecx
		mov [ecx],esi
		mov [ecx+4],edi
	.endw
	add esp,8
	pop ebp
	ret
TEAEncrypt endp

TEADecrypt proc uses ebx esi edi lpData:DWORD,cbData:DWORD,lpKey:DWORD
	.if cbData==0
		ret
	.endif
	push ebp
	;sub esp,8
	
	mov eax,cbData
	.if eax & 7
		or eax,7
		inc eax
	.endif
	add eax,lpData
	push eax
	push lpData
	mov ebx,lpKey
	.while TRUE
		mov ecx,[esp]
		.break .if ecx==[esp+4]
		add DWORD ptr [esp],8
		mov esi,[ecx]
		mov edi,[ecx+4]
		push ecx
		mov edx,TEALIMIT
		.while edx
			mov eax,esi
			shl eax,4
			mov ecx,esi
			shr ecx,5
			xor eax,ecx
			mov ebp,eax
			mov eax,esi
			xor eax,edx
			add ebp,eax
			mov eax,edx
			shr eax,11
			and eax,3
			add ebp,[ebx+4*eax]
			sub edi,ebp
			
			sub edx,TEADELTA
			
			mov eax,edi
			shl eax,4
			mov ecx,edi
			shr ecx,5
			xor eax,ecx
			mov ebp,eax
			mov eax,edi
			xor eax,edx
			add ebp,eax
			mov eax,edx
			and eax,3
			add ebp,[ebx+4*eax]
			sub esi,ebp
		.endw
		pop ecx
		mov [ecx],esi
		mov [ecx+4],edi
	.endw
	add esp,8
	pop ebp
	ret
TEADecrypt endp

AlignTo64 proc cb:DWORD
	mov eax,cb
	.if eax & 7
		or eax,7
		inc eax
	.endif
	ret
AlignTo64 endp

InputBoxDlgProc proc uses ebx esi edi hWnd,uMsg,wParam,lParam
	.if uMsg==WM_COMMAND
		mov eax,wParam
		and eax,0FFFFh
		.if eax==IDOK
			mov eax,offset commonbuf+400
			invoke GetDlgItemText,hWnd,IDC_E_INPUTBOX,[eax],MAX_PATH
			invoke EndDialog,hWnd,IDOK
		.elseif eax==IDCANCEL
			invoke EndDialog,hWnd,IDCANCEL
		.endif
		
	.elseif uMsg==WM_CLOSE
		invoke EndDialog,hWnd,IDCANCEL
	.elseif uMsg==WM_INITDIALOG
		invoke CenterWindow,hWnd
		mov eax,offset commonbuf+400
		invoke SetWindowText,hWnd,[eax+4]
		invoke SendDlgItemMessage,hWnd,IDC_E_INPUTBOX,EM_SETLIMITTEXT,MAX_PATH,0
		
	.else
		mov eax,FALSE
		ret
	.endif
	mov eax,TRUE
	ret
InputBoxDlgProc endp

InputBox proc hWnd:DWORD,lpszCaption:DWORD,lpOut:DWORD
	mov eax,offset commonbuf+400
	push lpOut
	pop [eax]
	push lpszCaption
	pop [eax+4]
	invoke DialogBoxParam,hInstance,IDD_INPUTBOX,hWnd,offset InputBoxDlgProc,0
	ret
InputBox endp

VaildatePassword proc uses esi edi;-1 for no pass , 0 for user cancel, 1 for vaild pass
LOCAL tempbuf [MAX_PATH+SIZEOF szCorrectSignature]:BYTE
	.if wPasswordReq
		.if wPasswordVaild
			xor eax,eax
			inc eax
			ret
		.else
			lea edi,tempbuf
			invoke RtlZeroMemory,edi,SIZEOF tempbuf
			.while TRUE
				invoke InputBox,hDialog,offset CTXT("请输入密码"),edi
				.if eax==IDCANCEL
					xor eax,eax
					ret
				.endif
				invoke lstrlen,edi
				.if edi==0
					xor eax,eax
					ret
				.endif
				mov esi,eax
				add esi,edi
				invoke lstrcat,edi,offset szCorrectSignature
				invoke lstrlen,edi
				invoke SHA1_GetCode,edi,eax,offset stEncryptSeed
				invoke DataCompare,offset stEncryptSeed,offset stHidHeader.stKeySHA,SIZEOF SHARESULT
				.if eax==1
					mov BYTE ptr [esi],0
					invoke lstrlen,edi
					invoke SHA1_GetCode,edi,eax,offset stEncryptSeed
					xor eax,eax
					inc eax
					mov wPasswordVaild,ax
					ret
				.endif
			.endw
			
		.endif
	.else
		or eax,-1
	.endif
	ret
VaildatePassword endp

ModifyPassword proc uses ebx esi edi
LOCAL NewPass [MAX_PATH+SIZEOF szCorrectSignature]:BYTE
LOCAL Status:DWORD
	invoke VaildatePassword
	.if eax==0
		invoke MessageBox,hDialog,offset CTXT("在不知道原密码的情况下无法更改密码！"),offset szLogo,MB_ICONEXCLAMATION
		ret
	.endif
	mov Status,eax
	invoke Defrag
	invoke RtlZeroMemory,ADDR NewPass,SIZEOF NewPass
	invoke InputBox,hDialog,offset CTXT("请输入新密码"),ADDR NewPass
	
	.if eax==IDCANCEL
		ret
	.endif
	
	invoke RtlMoveMemory,offset commonbuf,offset stEncryptSeed,SIZEOF stEncryptSeed
	lea esi,NewPass
	invoke lstrlen,esi
	.if eax==0
		ret
	.endif
	invoke SHA1_GetCode,esi,eax,offset stEncryptSeed
	invoke lstrcat,esi,offset szCorrectSignature
	invoke lstrlen,esi
	invoke SHA1_GetCode,esi,eax,offset stHidHeader.stKeySHA
	.if dwStatTotalSpace==0
		ret
	.endif
	;invoke GlobalAlloc,GPTR,dwStatTotalSize
	invoke VirtualAlloc,NULL,dwStatTotalSize,MEM_COMMIT,PAGE_READWRITE
	mov edi,eax
	xor ecx,ecx
	mov ebx,offset stHidHeader.stFileRecords
	assume ebx:ptr HID_FAT
	.while ecx<stHidHeader.dwFileCount
		push ecx
		mov eax,[ebx].dwFileSize
		invoke AlignTo64,eax
		mov esi,eax
		mov eax,[ebx].dwFileOffsetBegin
		lea eax,[eax+2*eax]
		add eax,DIBDATABEGIN
		add eax,stMapBmp.Pointer
		push eax
		invoke GetDataFromDIBits,eax,edi,esi
		
		.if Status==0
			invoke TEADecrypt,edi,esi,offset commonbuf+SHARESULT.dwMid1
		.endif
		invoke TEAEncrypt,edi,esi,offset stEncryptSeed.dwMid1
		invoke SHA1_GetCode,edi,esi,ADDR [ebx].stDataSHA
		pop eax
		invoke SetDataToDIBits,eax,edi,esi
		add ebx,SIZEOF HID_FAT
		pop ecx
		inc ecx
	.endw
	assume ebx:nothing
	invoke SetDataToDIBits,pDIBits,offset stHidHeader,SIZEOF HID_HEADER
	xor eax,eax
	inc eax
	mov wPasswordReq,ax
	invoke VirtualFree,edi,0,MEM_RELEASE
	ret
ModifyPassword endp

CenterWindow proc uses esi hWnd:DWORD
LOCAL WndPlace:WINDOWPLACEMENT
LOCAL tmp:DWORD
	lea esi,WndPlace
	assume esi:ptr WINDOWPLACEMENT
	invoke RtlZeroMemory,esi,SIZEOF WndPlace
	mov [esi].iLength,SIZEOF WndPlace
	invoke GetWindowPlacement,hWnd,esi
	invoke GetSystemMetrics,SM_CXSCREEN
	mov edx,eax
	mov eax,[esi].rcNormalPosition.right
	sub eax,[esi].rcNormalPosition.left
	sub edx,eax
	shr edx,1
	mov tmp,edx
	invoke GetSystemMetrics,SM_CYSCREEN
	mov edx,eax
	mov eax,[esi].rcNormalPosition.bottom
	sub eax,[esi].rcNormalPosition.top
	sub edx,eax
	shr edx,1
	invoke SetWindowPos,hWnd,HWND_TOP,tmp,edx,0,0,SWP_NOSIZE
	assume esi:nothing
	ret
CenterWindow endp

FontNumToPixel proc hDC:DWORD,dwFn:DWORD
LOCAL lpy:DWORD
LOCAL tmp:DWORD
	invoke GetDeviceCaps,hDC,LOGPIXELSY
	mov lpy,eax
	mov tmp,72
	finit
	fild dwFn
	fidiv tmp
	fimul lpy
	fistp tmp
	mov eax,tmp
	ret
FontNumToPixel endp

DemoDlgProc proc uses esi edi ebx hWnd,uMsg,wParam,lParam
LOCAL hDC:DWORD
LOCAL rcRect:RECT
LOCAL tmp:DWORD
	
	.if uMsg==WM_TIMER
		inc dwCurCount
		invoke GetPixel,hBkndDC,0,0
		mov esi,eax
		invoke BitBlt,hBkndDC,0,0,191,1,hBkndDC,1,0,SRCCOPY
		invoke SetPixel,hBkndDC,191,0,esi
		invoke GetDC,hWnd
		mov esi,eax
;		invoke SetBitmapBits,hBkndBmp,200*125*8,edi
		
		invoke StretchBlt,hBufDC,0,0,400,250,hBkndDC,0,0,198,1,SRCCOPY
		mov eax,dwCurCount
		shr eax,2
		.if eax>1370
			mov dwCurCount,1370*4
			mov eax,1370
		.endif
		invoke BitBlt,hBufDC,0,0,400,250,hRollerDC,0,eax,SRCAND
		
		invoke BitBlt,esi,0,0,400,250,hBufDC,0,0,SRCCOPY
	.elseif uMsg==WM_MOUSEWHEEL
		mov eax,wParam
		shr eax,16
		.if ax>8000h
			add dwCurCount,30
		.else
			sub dwCurCount,30
		.endif
		.if dwCurCount>80000000h
			push 0
			pop dwCurCount
		.endif
	.elseif uMsg==WM_INITDIALOG
		invoke SetWindowPos,hWnd,HWND_TOP,0,0,400,250,SWP_NOMOVE
		invoke CenterWindow,hWnd
		invoke ShowWindow,hWnd,SW_SHOW
		invoke GetDC,hWnd
		mov hDC,eax
		invoke SetTimer,hWnd,1,16,NULL
		mov esi,hDC
		invoke CreateCompatibleDC,esi
		mov hRollerDC,eax
		invoke CreateCompatibleDC,esi
		mov hBkndDC,eax
		invoke CreateCompatibleDC,esi
		mov hBufDC,eax
		invoke LoadBitmap,hInstance,IDB_BACKGROUND
		mov hBkndBmp,eax
		
;		invoke CreateCompatibleBitmap,esi,198,172
;		mov hBkndBmp,eax
		invoke CreateCompatibleBitmap,esi,400,250
		mov hBufBmp,eax
		invoke CreateCompatibleBitmap,esi,400,2500
		mov hRollerBmp,eax
		invoke SelectObject,hRollerDC,hRollerBmp
		invoke DeleteObject,eax
		invoke SelectObject,hBkndDC,hBkndBmp
		invoke DeleteObject,eax
		invoke SelectObject,hBufDC,hBufBmp
		invoke DeleteObject,eax
		
		invoke SelectObject,hRollerDC,eax
		invoke DeleteObject,eax
		invoke GetStockObject,NULL_PEN
		invoke SelectObject,hRollerDC,eax
		lea edi,rcRect
		invoke RtlZeroMemory,edi,SIZEOF rcRect
		mov (RECT ptr [edi]).right,400
		mov (RECT ptr [edi]).bottom,2500
		invoke GetStockObject,BLACK_BRUSH
		invoke FillRect,hRollerDC,edi,eax
		invoke SetTextColor,hRollerDC,0FFFFFFh
		invoke SetBkMode,hRollerDC,TRANSPARENT
		;draw texts
		invoke FontNumToPixel,hRollerDC,26
		mov tmp,eax
		invoke CreateFont,eax,0,0,0,FW_NORMAL,FALSE,FALSE,FALSE,GB2312_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,FF_MODERN,offset CTXT("华文行楷")
		invoke SelectObject,hRollerDC,eax
		invoke DeleteObject,eax
		invoke TextOut,hRollerDC,121,255,offset CTXT("藏宝图V2.0"),10
		invoke TextOut,hRollerDC,144,1220+250+12,offset CTXT("By Proton"),9
		
		invoke FontNumToPixel,hRollerDC,9
		invoke CreateFont,eax,0,0,0,FW_NORMAL,FALSE,FALSE,FALSE,GB2312_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,FF_MODERN,offset CTXT("方正静蕾简体")
		invoke SelectObject,hRollerDC,eax
		invoke DeleteObject,eax
		lea ebx,szDemo
		mov edi,300
		.while TRUE
			invoke lstrlen,ebx
			mov esi,eax
			.break .if esi==0
			invoke TextOut,hRollerDC,20,edi,ebx,esi
			add edi,20
			add ebx,esi
			inc ebx
		.endw
		;-----------
		mov dwCurCount,0
		invoke ReleaseDC,hWnd,hDC
		invoke FindResource,hInstance,IDR_BGM,CTXT("BGM")
		mov esi,eax
		invoke SizeofResource,hInstance,esi
		mov tmp,eax
		invoke LoadResource,hInstance,esi
		mov esi,eax
		invoke LockResource,esi
		
		invoke uFMOD_PlaySong,eax,tmp,XM_MEMORY
		
		invoke FreeResource,esi
		invoke ShowWindow,hDialog,FALSE
	.elseif uMsg==WM_LBUTTONDOWN
		invoke SendMessage,hWnd,WM_CLOSE,0,0
	.elseif uMsg==WM_CLOSE
		invoke DeleteObject,hRollerBmp
		invoke DeleteObject,hBkndBmp
		invoke DeleteObject,hBufBmp
		invoke DeleteDC,hRollerDC
		invoke DeleteDC,hBkndDC
		invoke DeleteDC,hBufDC
		invoke EndDialog,hWnd,TRUE
		
		invoke uFMOD_PlaySong,0,0,0
		
		invoke KillTimer,hWnd,1
		invoke ShowWindow,hDialog,TRUE
	.else
		mov eax,FALSE
		ret
	.endif
	mov eax,TRUE
	ret
DemoDlgProc endp

QueryIfOverwriteDlgProc proc uses esi edi ebx hDlg,uMsg,wParam,lParam
LOCAL buf [MAX_PATH]:BYTE
LOCAL stSysTime:SYSTEMTIME
	.if uMsg==WM_INITDIALOG
		mov esi,lParam
		mov esi,[esi]
		lea edi,buf
		mov edx,(WIN32_FIND_DATA ptr [esi]).nFileSizeLow
		invoke SetDlgItemInt,hDlg,IDC_OVERWRITE_SIZEONDISK,edx,FALSE
		lea edx,(WIN32_FIND_DATA ptr [esi]).cFileName
		invoke SetDlgItemText,hDlg,IDC_OVERWRITE_FILENAME,edx
		lea edx,(WIN32_FIND_DATA ptr [esi]).ftLastWriteTime
		lea ebx,stSysTime
		invoke FileTimeToSystemTime,edx,ebx
		invoke SystemTimeToTzSpecificLocalTime,NULL,ebx,ebx
		xor eax,eax
		mov ax,stSysTime.wMinute ;just for the wsprintf
		push eax
		mov ax,stSysTime.wHour
		push eax
		mov ax,stSysTime.wDay
		push eax
		mov ax,stSysTime.wMonth
		push eax
		mov ax,stSysTime.wYear
		push eax
		invoke wsprintf,edi,ADDR szDateTime
		add esp,14h ; for the args too.
		invoke SetDlgItemText,hDlg,IDC_OVERWRITE_DATEONDISK,edi
		mov esi,lParam
		mov eax,[esi+4]
		mov edx,SIZEOF HID_FAT
		mul edx
		lea esi,[eax+offset stHidHeader.stFileRecords]
		mov esi,(HID_FAT ptr [esi]).dwFileSize
		invoke SetDlgItemInt,hDlg,IDC_OVERWRITE_SIZETOBEEXTRACTED,esi,FALSE
		invoke CenterWindow,hDlg
	.elseif uMsg==WM_COMMAND
		mov eax,wParam
		.if ax==IDOK
			invoke EndDialog,hDlg,TRUE
		.elseif ax==IDCANCEL
			invoke EndDialog,hDlg,FALSE
		.endif
	.elseif uMsg==WM_CLOSE
		invoke EndDialog,hDlg,FALSE
	.else
		mov eax,FALSE
		ret
	.endif
	mov eax,TRUE
	ret
QueryIfOverwriteDlgProc endp

QueryIfOverwrite proc uses esi edi lpszFilename:DWORD,dwFileID:DWORD
LOCAL stFileFind:WIN32_FIND_DATA
LOCAL dwParams [2]:DWORD
	invoke RtlZeroMemory,ADDR stFileFind,SIZEOF stFileFind
	invoke FindFirstFile,lpszFilename,ADDR stFileFind
	.if eax!=INVALID_HANDLE_VALUE
		invoke FindClose,eax
		lea edx,dwParams
		lea eax,stFileFind
		mov [edx],eax
		push dwFileID
		pop [edx+4]
		invoke DialogBoxParam,hInstance,IDD_QUERYIFOVERWRITE,hDialog,offset QueryIfOverwriteDlgProc,ADDR dwParams
	.else
		xor eax,eax
		inc eax
		ret
	.endif
	.if eax==IDOK
		xor eax,eax
		inc eax
		ret
	.else
		xor eax,eax
		ret
	.endif
QueryIfOverwrite endp

END START