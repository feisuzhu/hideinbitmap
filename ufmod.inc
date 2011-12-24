XM_RESOURCE EQU 0
XM_MEMORY   EQU 1
XM_FILE     EQU 2
XM_NOLOOP   EQU 8

; The uFMOD_PlaySong function starts playing an XM song.
; --------------
; HWAVEOUT* uFMOD_PlaySong(
;   LPVOID lpXM,
;   DWORD  param,
;   DWORD  fdwSong
; );
; Parameters:
;   lpXM
;      Specifies the song to play. If this parameter is NULL,
;      any currently playing song is stopped. In such a case, function
;      does not return a meaningful value.
;      fdwSong parameter determines whether this value is interpreted
;      as a filename, as a resource identifier or a pointer to an image
;      of the song in memory.
;   param
;      Handle to the executable file that contains the resource to be
;      loaded or size of the image of the song in memory. This parameter
;      is ignored unless XM_RESOURCE or XM_MEMORY is specified in fdwSong.
;   fdwSong
;      Flags for playing the song. The following values are defined:
;      Value        Meaning
;      XM_FILE      lpXM points to filename.
;                   param is ignored.
;      XM_MEMORY    lpXM points to an image of a song in memory.
;                   param is the image size. Once, uFMOD_PlaySong
;                   returns, it's safe to free/discard the memory buffer.
;      XM_RESOURCE  lpXM Specifies the name of the resource.
;                   param identifies the module whose executable file
;                   contains the resource. Could be NULL if the given
;                   resource is located in the current module.
;                   The resource type must be RCDATA.
;      XM_NOLOOP    An XM track plays repeatedly by default. Specify
;                   this flag to play it only once.
; Return Values:
;    Returns a pointer to HWAVEOUT on success or NULL otherwise.
uFMOD_PlaySong PROTO :DWORD,:DWORD,:DWORD

; The uFMOD_Pause function pauses the currently playing song, if any.
uFMOD_Pause PROTO

; The uFMOD_Resume function resumes the currently paused song, if any.
uFMOD_Resume PROTO

; The uFMOD_GetStats function returns the current RMS volume coefficients
; in L and R channels.
; --------------
; Return Values:
;    low-order word : RMS volume in R channel
;    hi-order  word : RMS volume in L channel
uFMOD_GetStats PROTO

; The uFMOD_GetTime function returns the time in milliseconds since the
; song was started. This is useful for synchronizing purposes.
; --------------
; Return Values:
;    Returns the time in milliseconds since the song was started.
uFMOD_GetTime PROTO

; The uFMOD_GetTitle function returns the current track's title, if any.
; --------------
; Return Values:
;    Returns the track's title in ASCIIZ format.
uFMOD_GetTitle PROTO

; The uFMOD_SetVolume function sets the global volume.
; --------------
; 0:  muting
; 64: maximum volume
; NOTE: Any value above 64 maps to maximum volume too.
; The volume scale is linear. Maximum volume is set by default.
uFMOD_SetVolume PROTO :DWORD