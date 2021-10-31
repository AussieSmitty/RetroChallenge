; **************************************************************
; * Commodore 64 RC car control by Steve Smit - V 1.4 31/10/21 *
; * Project submitted to RetroChallenge 2021-10                *
; **************************************************************
;
; Memory Map
; ==========
; $0801 - $080F Basic Loader to call code starting at $0F00, i.e. sys 3840
; $0f00 - $3FFF Application code is loaded here
; $4000 - $7FFF Memory that holds RC sequence, inc timing
; $8000 - $876C Holds arrays sequences on disk
;
; Constants
joy1    = $dc01         ; Address for joystick in port 1
setlfs  = $ffba         ; Kernal call for opening a channel
setnam  = $ffbd         ; Kernal call for setting filenames
settim  = $ffdb         ; Kernal call for setting the time (for reset)
loadit  = $ffd5         ; Kernal call to load a file
saveit  = $ffd8         ; Kernal call to save a file
chkout  = $ffc9         ; Kernal call to open output channel
readst  = $ffb7         ; Kernal call to read the disk status byte
open    = $ffc0         ; Kernal call to open a logical file
close   = $ffc3         ; Kernal call to close a channel
clrchn  = $ffcc         ; Kernal call to clear all open channels
chrout  = $ffd2         ; Kernal call to output character to channel
chkin   = $ffc6         ; Kernal call to Define file as default input
chrin   = $ffcf         ; Kernal call to read a character from the keyboard
plot    = $fff0         ; Kernal call to read/set cursor X/Y screen pos
getin   = $ffe4         ; Kernal call to read a character from Keyboard buffer
screen  = $0400         ; Start of screen memory. $0800 start of Basic
colour  = $d800         ; Colour RAM area
ScnLn   = $d6           ; Current Cursor Line Number 0=first, 1=2nd...
ScnX    = $d3           ; Cursor column on current line
BLNSW   = $cc           ; BLNSW Location in C64 memory map 0=Blink ON 
chrclr  = $286          ; Current Char colour = 14 default, 1 White, 7 Yellow
SeqMEM  = $4000         ; Where a sequence is to be stored in memory
SeqFNS  = $8000         ; Array of 100 16 bytes holding filename strings 
SeqFNL  = $8640         ; Array of 100 single bytes to store filename length
SeqBLK  = $86A4         ; Array of 100 two bytes holding size in blocks
TmpBuf  = $876D         ; Temp buffer-copy of bytes sent to RC car for diag

; Variables
RCarray = $05           ; Dec 5 - 2 byte address for points to $4000
i_Var   = $fb           ; 2 byte temporary variable ($fb and $fc)
j_Var   = $fd           ; Another 2 byte temporary variable ($fd and $fe)
k_Var   = $58           ; Another 2 byte temporary variable
m_Var   = $5a           ; Another 2 byte temporary variable
X_Var   = $61           ; 'X' is bytes sent to rc car
w_Var   = $ae           ; Another 2 byte temporary variable
SeqPos  = $64           ; pointer to position in sequence
LstPos  = $6c           ; Last Position the joystick was in
RecFlg  = $2a7          ; Flag for Record ON = 1, OFF = 0
; CursorX = $6e           ; Current X position of the Cursor
; CursorY = $70           ; Current X position of the Cursor
; LastKey = $313          ; Last key pressed or mouse action
SeqLgth = $334          ; A 2 byte value, i.e. more than 256 steps (3 bytes/n)
DirFlag = $33a          ; Flag if current drive has had the Seq dir read
; Modded  = $3ff          ; 0=no modificatoin, 1=sequence now modified
; PauseA  = $c900         ; 16215 Holds contents of the Acc at debugging routine
SeqBoxP = $c901         ; A one bye var holding which line within box
SeqPntr = $c902         ; A pointer = Seq no. from current disk
a_Var   = $c903         ; Temp 1 byte variable
b_Var   = $c904         ; another temp 1 byte variable
BytVar  = $c905         ; a single byte variable
Seqs    = $c906         ; One byte, holds number of sequences on current disk
filnaml = $c90a         ; 51466 Filename length
filetxt = $c90b         ; Memory to hold up to 20 charaters for filename

; 10 SYS3840:REM rc car run

*=$0801

        BYTE    $19, $08, $0A, $00, $9E, $33, $38, $34, $30, $3a, $8f, $20, $52, $43, $20, $43, $41, $52, $20, $52, $55, $4E, $00, $00, $00

* = $0f00 ; sys 3840

setup   lda #0          ; 
        sta SeqPos      ; Currently only a single byte (i.e. max 255)
        sta Seqs        ; Also set the number of Seqs filenames in mem to 0
        sta SeqPntr     ; Set that we are pointing to the first Sequence
        sta DirFlag     ; Set Directory of Seqs flag=0, not yet read
        sta RecFlg
        lda #2          ; Setup RS232 - Device # 2 = RS232
        ldx #<RSPAR     ; Low address for Baud rate of 1200 BPS
        ldy #>RSPAR     ; Command. 0 = Full Duplex 3 line
        jsr setnam
        lda #2          ; Using Logical Number 2 for all RS232 access
        tax
        ldy #0
        jsr setlfs      ; Open 2,2,RS232 at 1200 baud
        jsr open
;        lda #0          ; Store the pointer for sequence array
;        sta RCarray     ; initially to $4000, LSB = $00
;        lda #$40        ; MSB = $40
;        sta RCarray+1   ; used with sta(RCarray),y, or lda(RCarray),y
        jsr Blanksq     ; Clear memory where sequences will be stored
@Main   lda #147        ; Clear screen
        jsr chrout
        lda #23
        sta 53272       ; switch to lower case char set
        lda #13
        jsr chrout
        ldy #30         ; 30 chars
        ldx #0
@MenuL1 lda Menu1,x     ; "Commodore 64 RC car controller"
        jsr chrout
        inx
        dey
        bne @MenuL1
        lda #13
        jsr chrout
        jsr chrout
        ldy #30         ; 30 chars
        ldx #0
@MenuL2 lda Menu2,x     ; "By Steve Smit     October 2021"
        jsr chrout
        inx
        dey
        bne @MenuL2
        lda #13
        jsr chrout
        jsr chrout
        ldy #12         ; 12 chars
        ldx #0
@MenuL3 lda Menu3,x     ; "Function Key"
        jsr chrout
        inx
        dey
        bne @MenuL3
        lda #13
        jsr chrout
        jsr chrout
        ldy #37         ; 37 chars
        ldx #0
@FuncL1 lda Func1,x     ; "F1   Operate RC car without recording"
        jsr chrout
        inx
        dey
        bne @FuncL1
        lda #13
        jsr chrout
        ldy #34         ; 34 chars
        ldx #0
@FuncL2 lda Func2,x     ; "F3   Operate RC car with recording"
        jsr chrout
        inx
        dey
        bne @FuncL2
        lda #13
        jsr chrout
        ldy #31         ; 31 chars
        ldx #0
@FuncL3 lda Func3,x     ; "F5   Menu of recorded sequences"
        jsr chrout
        inx
        dey
        bne @FuncL3
        lda #13
        jsr chrout
        ldy #9         ; 9 chars
        ldx #0
@FuncL4 lda Func4,x    ; "F7   Exit"
        jsr chrout
        inx
        dey
        bne @FuncL4
@input1 jsr getin
        beq @input1
        cmp #133        ; test for F1
        bne @next1      ; If not, test for F3
        jsr PlayRC      ; Call subroutine PlayRC
        jmp @Main       ; Back to main menu
@next1  cmp #134        ; test for F3
        bne @next2      ; if not, test for F5
        jsr PlayRec     ; Call subrountine PlayRec
        jmp @Main
@next2  cmp #135        ; test for F5
        bne @next3      ; if not, test for F5
        jsr RecBack     ; Call subrountine RecBack
        jmp @Main
@next3  cmp #136        ; test for F7
        beq @ending     ; if so, jump to end
        jmp @Main
@ending lda #13
        jsr chrout
        ldy #9          ; Length of Good Bye!
        ldx #0
@gbloop lda GoodB,x
        jsr chrout
        inx
        dey
        bne @gbloop
        rts

; Play with the RC car without recording the sequence
; Note: need to only send the command when there is a change to
; the direction of the joystick, i.e. not continuously if held in one
; position

PlayRC  lda #147        ; Better clear the 
        jsr chrout      ; screen first
        lda #255
        sta LstPos      ; We will start with an assumed joystick centred
        clc
        ldx #2          ; place cursor 2 lines down
        ldy #4          ; and 4 from left side
        jsr plot
        ldy #32
        ldx #5
@F1head lda Func1,x     ; Write "Operate RC car without recording"
        jsr chrout
        inx
        dey
        bne @F1head
        clc
        ldx #4          ; place cursor 2 lines down
        ldy #9          ; and 4 from left side
        jsr plot
        ldy #22
        ldx #0
@JoyLp  lda JoyPort,x   ; Write "Use Joystick in Port 1"
        jsr chrout
        inx
        dey
        bne @joyLp
        clc
        ldx #6          ; place cursor 4 lines down
        ldy #11         ; and 11 in from side
        jsr plot
        ldx #0
        ldy #18
@firex  lda FireXT,x
        jsr chrout
        inx
        dey
        bne @firex
        clc             ; position cursor in middle of screen
        ldy #19
        ldx #12
        jsr plot
        lda #"O"        ; Let's start with a O in the middle
        jsr chrout
@joyML  clc             ; position cursor in middle of screen
        ldy #19
        ldx #12
        jsr plot
        lda joy1        ; read Joystick in port 1
        sta w_Var       ; save a copy
        and #%00010000  ; mask out the 4th bit
        bne @cont1
@clrkb  jsr getin       ; lets clear the keyboard buffer
        bne @clrkb
@loopj  lda joy1
        and #%00010000  ; mask out the 4th bit
        beq @loopj      ; loop until fire button released
        jsr smldly
        jmp @ending
@cont1  lda w_Var
        cmp LstPos      ; First let's see if anything has changed
        bne @cont2      ; goto cont2 if there is a change
        jmp @joyML
@cont2  lda w_Var
        cmp #255        ; nothing pressed yet?
        bne @next1
        lda w_Var
        sta LstPos
        ldx #3
        stx X_Var
        lda pointr,x    ; show a "O" in the middle of screen
        jsr chrout
        jsr SndByt      ; As joystick has moved, send the new 'command'
        jmp @joyML      ; jump back until something happens on the joystick
@next1  lda w_Var
        cmp #254        ; test for Forward
        bne @next2
        lda w_Var
        sta LstPos
        ldx #4          ; command for forward is 4
        stx X_Var
        lda pointr,x    ; show a "^" in the middle of screen
        jsr chrout
        jsr SndByt      ; call Send Byte via RS232 sub-routine
        jmp @joyML
@next2  lda w_Var
        cmp #253        ; test for Back
        bne @next3
        lda w_Var
        sta LstPos
        ldx #5          ; command for backwards is 5
        stx X_Var
        lda pointr,x    ; show a "v" in the middle of screen
        jsr chrout
        jsr SndByt      ; call Send Byte via RS232 sub-routine
        jmp @joyML
@next3  lda w_Var
        cmp #251        ; test for Left
        bne @next4
        lda w_Var
        sta LstPos
        ldx #1          ; command for Left is 1
        stx X_Var
        lda pointr,x    ; show a "<" in the middle of screen
        jsr chrout
        jsr SndByt      ; call Send Byte via RS232 sub-routine
        jmp @joyML
@next4  lda w_Var
        cmp #247        ; test for Right
        bne @next5
        lda w_Var
        sta LstPos
        ldx #2          ; command for Right is 2
        stx X_Var
        lda pointr,x    ; show a ">" in the middle of screen
        jsr chrout
        jsr SndByt      ; call Send Byte via RS232 sub-routine
        jmp @joyML
@next5  lda w_Var
        cmp #250        ; test for Forward & Left
        bne @next6
        lda w_Var
        sta LstPos
        ldx #9          ; command for forward&Left is 9
        stx X_Var
        lda pointr,x    ; show a Left/Up angle in the middle of the screen
        jsr chrout
        jsr SndByt      ; call Send Byte via RS232 sub-routine
        jmp @joyML
@next6  lda w_Var
        cmp #246        ; test for Forward & Right
        bne @next7
        lda w_Var
        sta LstPos
        ldx #6          ; command for Forward&Right is 6
        stx X_Var
        lda pointr,x    ; show a Right/Up angle in the middle of the screen
        jsr chrout
        jsr SndByt      ; call Send Byte via RS232 sub-routine
        jmp @joyML
@next7  lda w_Var
        cmp #249        ; test for Back & Left
        bne @next8
        lda w_Var
        sta LstPos
        ldx #8          ; command for Back&Left is 8
        stx X_Var
        lda pointr,x    ; show a Down/Left angle in the middle of the screen
        jsr chrout
        jsr SndByt      ; call Send Byte via RS232 sub-routine
        jmp @joyML
@next8  lda w_Var
        cmp #245        ; test for Back & Right
        bne @next9
        lda w_Var
        sta LstPos
        ldx #7          ; command for Back&Right is 7
        stx X_Var
        lda pointr,x    ; show a Down/Right angle in the middle of the screen
        jsr chrout
        jsr SndByt      ; call Send Byte via RS232 sub-routine
        jmp @joyML
@next9  nop             ; test for anything else?
        jmp @joyML
@ending lda #3          ; just in case the fire button was pressed
        sta X_Var       ; when the RC car was sent a direction to go in
        jsr SndByt      ; send the RC car the centre/off command
@endlp  lda joy1        ; before returning to the main Menu
        cmp #255        ; wait until the fire button is off again
        bne @endlp      ; loop back until joystick in centre position
        rts        

; Using RC car with recording of sequence
; Also allows one to playback what has just been recorded
; And record the sequence to a file
; Note: Joystick fire button, once pressed needs to be released
; before being considered again for 'stop' recording

PlayRec lda #147        ; Better clear the 
        jsr chrout      ; screen first
        lda #255
        sta LstPos      ; We will start with an assumed joystick centred
        lda #0
        sta RecFlg      ; Turn off the recording on flag
        sta SeqPos      ; Number of commands (0-255)
        clc
        ldx #2          ; place cursor 2 lines down
        ldy #6          ; and 6 from left side
        jsr plot
        ldy #29
        ldx #5
@F3head lda Func2,x     ; Write "Operate RC car with recording"
        jsr chrout
        inx
        dey
        bne @F3head
        clc
        ldx #4          ; place cursor 4 lines down
        ldy #9          ; and 4 from left side
        jsr plot
        ldy #22
        ldx #0
@JoyLp  lda JoyPort,x   ; Write "Use Joystick in Port 1"
        jsr chrout
        inx
        dey
        bne @joyLp
        clc
        ldx #6          ; place cursor 6 lines down
        ldy #0          ; and hard against LHS
        jsr plot
        ldy #39
        ldx #0
@firex  lda FireST,x    ; "Pressing Fire will start/stop recording"
        jsr chrout
        inx
        dey
        bne @firex
        clc
        ldx #18         ; place cursor 18 lines down
        ldy #9          ; and 9 in from side
        jsr plot
        ldy #18
        ldx #0
@RcLpT  lda RecTxt,x    ; "O Record indicator"
        jsr chrout
        inx
        dey
        bne @RcLpT
        clc
        ldx #21         ; place cursor 22 lines down
        ldy #15         ; and 15 in from side
        jsr plot
        ldy #9          ; 9 chars
        ldx #0
@FuncL4 lda Func4,x     ; "F7 = Exit"
        jsr chrout
        inx
        dey
        bne @FuncL4
        clc             ; position cursor in middle of screen
        ldy #19
        ldx #12
        jsr plot
        lda #"O"        ; Lets start with a O in the middle
        jsr chrout
@joyML  clc             ; position cursor in middle of screen
        ldy #19
        ldx #12
        jsr plot
        jsr getin       ; check for keyboard entry
        beq @noF7
        cmp #136        ; was F7 pressed?
        bne @noF7
        lda RecFlg      ; Does recoding need to end?
        bne @termR      ; If not zero, need to terminate recording
        jmp @ending
@termR  jsr StopR       ; This will stop recording
        jmp @ending
@noF7   lda joy1        ; read Joystick in port 1
        sta w_Var       ; save a copy
        and #%00010000  ; mask out the 4th bit
        bne @cont1
@clrkb  jsr getin       ; lets clear the keyboard buffer
        bne @clrkb
@loopj  lda joy1
        and #%00010000  ; mask out the 4th bit
        beq @loopj      ; loop until fire button released
        lda RecFlg      ; RecFlg checking if recording stopping or
        beq @cont2      ; Starting, or
        lda SeqPos      ; If we are still at SeqPos 0 then 
        beq @cont1      ; Let's keep going (i.e. ignore stop recording)
        jsr StopR       ; Call stop recording subroutine
        jsr Replay      ; Offer user opportunity to play back before saving
        lda RecFlg      ; Did user want to replay
        bne @cont       ; a non-zero means yes, they did want to save
        clc             ; Need to wipe away the 'Replay sequence ...' text
        ldx #23         ; place cursor 23 lines down
        ldy #1          ; and 1 in from side
        jsr plot        
        ldx #38         ; a nearly full line of spaces
        lda #" "
@loop1  jsr chrout
        dex
        bne @loop1
@cont   jsr SaveRC      ; call the subroutine to get filename & save sequence
        jmp @ending     ; After saving a sequence, lets return to main menu
@cont2  jsr StartR      ; Call Sub routine to start recoding
        jmp @joyML
@cont1  lda w_Var
        cmp LstPos      ; First let's see if anything has changed
        bne @cont3      ; goto cont3 if there is a change
        jmp @joyML
@cont3  lda w_Var
        cmp #255        ; nothing pressed yet?
        bne @next1
        lda w_Var
        sta LstPos
        ldx #3
        stx X_Var
        lda pointr,x    ; show a "O" in the middle of screen
        jsr chrout
        lda RecFlg
        bne @send1
        jsr SndByt      ; send byte without recording
        jmp @joyML
@send1  jsr SndBytR     ; Joystick moved, send new 'command' and record too
        jmp @joyML      ; jump back until something happens on the joystick
@next1  lda w_Var
        cmp #254        ; test for Forward
        bne @next2
        lda w_Var
        sta LstPos
        ldx #4          ; command for forward is 4
        stx X_Var
        lda pointr,x    ; show a "^" in the middle of screen
        jsr chrout
        lda RecFlg
        bne @send2
        jsr SndByt      ; send byte without recording
        jmp @joyML    
@send2  jsr SndBytR     ; send byte with recording
        jmp @joyML
@next2  lda w_Var
        cmp #253        ; test for Back
        bne @next3
        lda w_Var
        sta LstPos
        ldx #5          ; command for backwards is 5
        stx X_Var
        lda pointr,x    ; show a "v" in the middle of screen
        jsr chrout
        lda RecFlg
        bne @send3
        jsr SndByt      ; send byte without recording
        jmp @joyML    
@send3  jsr SndBytR     ; Joystick moved, send new 'command' and record too
        jmp @joyML
@next3  lda w_Var
        cmp #251        ; test for Left
        bne @next4
        lda w_Var
        sta LstPos
        ldx #1          ; command for Left is 1
        stx X_Var
        lda pointr,x    ; show a "<" in the middle of screen
        jsr chrout
        lda RecFlg
        bne @send4
        jsr SndByt      ; send byte without recording
        jmp @joyML    
@send4  jsr SndBytR     ; Joystick moved, send new 'command' and record too
        jmp @joyML
@next4  lda w_Var
        cmp #247        ; test for Right
        bne @next5
        lda w_Var
        sta LstPos
        ldx #2          ; command for Right is 2
        stx X_Var
        lda pointr,x    ; show a ">" in the middle of screen
        jsr chrout
        lda RecFlg
        bne @send5
        jsr SndByt      ; send byte without recording
        jmp @joyML    
@send5  jsr SndBytR     ; Joystick moved, send new 'command' and record too
        jmp @joyML
@next5  lda w_Var
        cmp #250        ; test for Forward & Left
        bne @next6
        lda w_Var
        sta LstPos
        ldx #9          ; command for forward&Left is 9
        stx X_Var
        lda pointr,x    ; show a Left/Up angle the middle of screen
        jsr chrout
        lda RecFlg
        bne @send6
        jsr SndByt      ; send byte without recording
        jmp @joyML    
@send6  jsr SndBytR     ; Joystick moved, send new 'command' and record too
        jmp @joyML
@next6  lda w_Var
        cmp #246        ; test for Forward & Right
        bne @next7
        lda w_Var
        sta LstPos
        ldx #6          ; command for Forward&Right is 6
        stx X_Var
        lda pointr,x    ; show a Right/Up in the middle of screen
        jsr chrout
        lda RecFlg
        bne @send7
        jsr SndByt      ; send byte without recording
        jmp @joyML    
@send7  jsr SndBytR     ; Joystick moved, send new 'command' and record too
        jmp @joyML
@next7  lda w_Var
        cmp #249        ; test for Back & Left
        bne @next8
        lda w_Var
        sta LstPos
        ldx #8          ; command for Back&Left is 8
        stx X_Var
        lda pointr,x    ; show a Back/Left angle in the middle of screen
        jsr chrout
        lda RecFlg
        bne @send8
        jsr SndByt      ; send byte without recording
        jmp @joyML    
@send8  jsr SndBytR     ; Joystick moved, send new 'command' and record too
        jmp @joyML
@next8  lda w_Var
        cmp #245        ; test for Back & Right
        bne @next9
        lda w_Var
        sta LstPos
        ldx #7          ; command for Back&Right is 7
        stx X_Var
        lda pointr,x    ; show a Down/Right angle in the middle of screen
        jsr chrout
        lda RecFlg
        bne @send9
        jsr SndByt      ; send byte without recording
        jmp @joyML    
@send9  jsr SndBytR     ; Joystick moved, send new 'command' and record too
        jmp @joyML
@next9  nop             ; test for anything else?
        jmp @joyML
@ending rts             ; back to menu screen

; Selecting from pre-recorded sequences and playing them back

RecBack lda #147        ; Clear the screen
        jsr chrout
        ldy #14       
        ldx #0
@loop   lda rddirT,x     ; prints "Disk Directory"
        jsr chrout
        inx
        dey
        bne @loop
        jsr dir1        ; Load the directory
        jsr disdir      ; Now display up to 10 sequences
        jsr SelSeq      ; Jump to subroutine to select sequence
        jsr NoYellw     ; remove yellow of selected Seq
        jsr LoadSeq     ; After selecting the sequence to play, load it
        jsr PlayBck     ; This routine knows a sequence is in mem
; @loop1  jsr getin
;         beq @loop1
        rts             ; code for reading the disk for seq 

; Play Back routine
; Used after RecBack has been used to select a sequence and
; Its loaded into memory at $4000 with SeqLgth containing 
; the number of sequences (each being 3 bytes long) 2 bytes are the
; lo byte hi bytes of the number of Jiffies before the command
; the command being the last of the 3 bytes per sequence

PlayBck lda #147        ; Clear the screen
        jsr chrout
        lda #13
        jsr chrout
        lda #0
        sta SeqPos
        ldy #30         ; 30 chars
        ldx #0
@MenuL1 lda Menu1,x     ; "Commodore 64 RC car controller"
        jsr chrout
        inx
        dey
        bne @MenuL1
        lda #13
        jsr chrout
        jsr chrout
        ldy #30         ; 30 chars
        ldx #0
@MenuL2 lda Menu2,x     ; "By Steve Smit     October 2021"
        jsr chrout
        inx
        dey
        bne @MenuL2
        clc             ; position cursor in middle of screen
        ldy #19
        ldx #12
        jsr plot
        lda #"O"        ; Let's start with a O in the middle
        jsr chrout
@joyML  clc             ; position cursor in middle of screen
        ldy #19
        ldx #12
        jsr plot
        clc
        ldx #23
        ldy #0
        jsr plot
        ldy #39
        ldx #0
@loop1  lda WaitSP,x    ; Print "Press Space Bar to play loaded sequence"
        jsr chrout
        inx
        dey
        bne @loop1
@loop2  jsr getin
        cmp #" "
        bne @loop2
        lda #0
        sta j_Var
        lda #$40
        sta j_Var+1
        lda #3          ; First, let's send a 'centre' command
        sta X_Var       ; to the RC car
        jsr SndByt
        jsr Reset       ; now reset the timer
@PlyLp  clc             ; position cursor in middle of screen
        ldy #19
        ldx #12
        jsr plot
        lda SeqPos      ; to read the next sequence bytes
        ldx #3          ; we need to multiply by 3 the current SeqPos
        jsr multi       
        stx i_Var       ; Lo Byte of multiplication
        sta i_Var+1     ; Hi Byte of multiplication
        jsr Addit       ; k_Var = $4000 + SeqPos * 3
        ldy #1          ; Starting with the lo byte of the jiffies
@loop3  lda (k_Var),y   ; Let's read the number of Jiffies to delay
        cmp $a2         ; compare with the lo jiffy count
        bne @loop3      ; If lo byte doesn't match go back until it does
        ldy #0
        lda (k_Var),y   ; now let's check the hi byte of jiffies
        cmp $a1         ; the hi byte is at $A1 in the C64 memory
        bne @loop3      ; go back if both the hi and lo bytes don't match
        ldy #2
        lda (k_Var),y   ; OK lets read the command we need to send
        sta X_Var       ; to send to the RC car
        tax
        lda pointr,x    ; show the current direction symbol centre screen
        jsr chrout
        jsr SndByt      ; Send the command to the RC car
        lda SeqPos      ; have we done the last command?
        cmp SeqLgth
        beq @ending     ; yes we have
        inc SeqPos      ; Incriment the Sequence Position variable
        jsr Reset       ; reset the timer
        jmp @PlyLp      ; go back and do the next 'command'
@ending clc             ; position cursor in middle of screen
        ldy #19
        ldx #12
        jsr plot
        lda #"O"        ; Lets end with a O in the middle
        jsr chrout
        clc
        ldx #23
        ldy #0
        jsr plot        ; move to last line on screen
        ldx #39
        lda #" "
@clrln  jsr chrout
        dex
        bne @clrln
        clc
        ldx #23
        ldy #1
        jsr plot        ; move to last line on screen
        ldy #19
        ldx #0
@loop4  lda PlyAgn,x    ; Print "Play it again? Y/N:"
        jsr chrout
        inx
        dey
        bne @loop4
@ynresp jsr getin
        beq @ynresp
        cmp #"y"
        bne @cont1
        lda #0
        sta SeqPos
        jmp @joyML
@cont1  cmp #"n"
        bne @ynresp
        lda #0
        sta RecFlg
        rts

; DisDir Display Directory of 'sequences' 
; First call DIR1 which (if current drive exists and reads fine) will
; Populate the number of seqs on that disk and the array of seq names
; This routine draws the box with correct drive number and sequences shown

disdir  ldx #23         ; Now to build the box to show the listing
@loop3  dex
        lda tabl1,x     ; Using values in mem for top row of box
        sta screen+16,x
        txa
        bne @loop3      
        ldx #23
@loop4  dex
        lda tablh,x     ; Using values in mem for 2nd row of box
        sta screen+56,x
        txa
        bne @loop4      
        ldx #23
@loop5  dex
        lda tabl3,x     ; Using values in mem for 3rd row of box
        sta screen+96,x
        txa
        bne @loop5             
        lda #<$488      ; Let's use i_Var
        sta i_Var       ; to hold the start screen position
        lda #>$488     
        sta i_Var+1     
        ldx #10         ; let's do 10 rows down the screen
@loop7  ldy #23
@loop6  dey
        lda tabl2,y
        sta (i_Var),y
        tya
        bne @loop6
        lda #40         ; Now to add 40 to i_Var
        sta j_Var       
        lda #0
        sta j_Var+1
        jsr Addit
        lda k_Var
        sta i_Var
        lda k_Var+1
        sta i_Var+1
        dex
        bne @loop7
        ldy #23
        ldx #0
@loop10 lda tabl4,x     ; Using values in mem for text at bottom of table
        sta screen+536,x
        inx
        dey
        bne @loop10
        lda Seqs        ; How many Sequences did the DIR1 subroutine find?
        bne @lstSeq
        jsr noSeqs      ; If Seq = 0 then there are no Seqs!
        jmp @end  
@lstSeq lda #0          ; Let's start at top of list
        sta SeqPntr     ; A pointer to current Seq no. from current disk
        sta SeqBoxP     ; Set Seq within Box Position to top most
        lda #3          ; 3 lines down is where the Seq list starts
        sta m_Var       ; m_Var will keep our vertical position for cursor
        lda #<SeqFNS    ; Let's use k_Var to store the    
        sta k_Var       ; position in memory where Seq filename
        lda #>SeqFNS    ; text strings are held
        sta k_Var+1
        lda #0
        sta a_Var       ; Start a counter for which Seq we're up to
        dec b_Var       ; for our maths below, b_Var needs to be reduced by 1
        clc             ; Using Plot to set the 1st Seq filename position
        ldx m_Var       ; 3rd line down (top line is 0)
        ldy #17         ; Start at 17 positions over from left hand side
        jsr plot        ; move the cursor here
        ldy #0          ; starting at 1st char of Seq filename
        ldx SeqFNL      ; x contains length of filename
@loop11 dex
        lda (k_Var),y
        jsr chrout      ; 'print' the value of the character 
        iny
        txa
        bne @loop11
        clc
        lda a_Var       ; next position cursor for printing the block size
        adc #3
        tax
        ldy #36         ; 36th column from left
        jsr plot        
        lda a_Var
        rol             ; multiply this by 2 (this won't get to more than 200)
        tay
        iny             ; start by reading hi byte 
        lda SeqBLK,y
        dey             ; decrement y so we can read the low byte
        ldx SeqBLK,y    ; So high byte is in Acc and lo byte in X
        jsr $bdcd       ; print basic line number
        lda a_Var
        clc
        adc #1          ; Since we started at 0, we need to inc before compare
        cmp Seqs        ; have we written all the sequences yet?
        beq @main       ; yes we have, go to main 'select one' routine
        lda a_Var       ; Also, we only load up to 10 Seqs
        cmp #9          ; This is 9, because 0 is the first Seq
        beq @main
        inc a_Var       ; not at end, or 10th line, so add one to our counter
        inc m_Var       ; m_Var is also moved down one line
        clc
        lda #16         ; Add 16 to our SeqFNS pointer (k_Var)
        adc k_Var
        sta k_Var
        lda #0
        adc k_Var+1
        sta k_Var+1
        clc
        ldx m_Var       ; For new 'plot' cursor position
        ldy #17         ; Still 17th position from left side
        jsr plot
        ldx a_Var
        lda SeqFNL,x
        tax
        ldy #0
        jmp @loop11
@main   lda #$89        ; Set k_Var to first colour line position
        sta k_Var
        lda #$d8        ; Now high byte
        sta k_Var+1
        ldx #7          ; Set colour to Yellow
        jsr ColBoxL     ; Make the first Seq Yellow
@end    rts

; This subroutine reads the disk directory and fills arrays
; for all files that are SEQ (i.e. Tablature files)

dir1    lda DirFlag     ; First, let's see if the Directory of Seqs is already
        beq @RdDir      ; If 0 then we haven't read the directory yet
        rts 
@RdDir  lda #1          ; Length of filename "$"
        ldx #<dirname
        ldy #>dirname
        jsr setnam      ; Call setname
        lda #5          ; Logical Number = 5
        ;ldx $ba         ; $ba Address in memory holding current drive number
        ;bne @skip
        ldx #$08        ; default to device number 8
@skip   ldy #$00        ; secondary address 0 (required for dir reading!)
        jsr setlfs      ; call SETLFS
        jsr open        ; call OPEN (open the directory)
        ; bcs @err1
        jmp @cont1      ; quit if OPEN failed, jump ahead if not
@err1   jmp error
@cont1  lda #0          ; Set a counter for where in memory we are up to
        sta b_Var       ; Stores vertical lines (if 0=no Seqs) 
        lda #<SeqFNS    ; Address for where directory filenames will be stored
        sta m_Var       ; First low-byte
        lda #>SeqFNS    ; then hi-byte
        sta m_Var+1
        ldx #5          ; filenumber 5
        jsr chkin       ; call CHKIN
        ldy #6
@skip6  jsr getbyte     ; get a byte from dir and ignore it
        dey
        bne @skip6
@char1  jsr getbyte     ; read first name of disk line, but discard
        bne @char1      ; continue until end of line
        ldy #2          ; skip 2 bytes of the next line
@char3  jsr getbyte
        dey
        bne @char3
        lda b_Var       ; Get the current count of Seqs
        cmp #101        ; 100 Seqs on a 'disk' will be our maximum
        beq error       ; Trigger an error if at 100 (Note: 0 - 99 = 100)
        clc
        lda b_Var
        rol             ; multiply this by 2
        tay
        jsr getbyte     ; get low byte of basic line number (Block size)
        sta SeqBLK,y    ; Store this at SeqBlk array position 1
        iny
        jsr getbyte     ; get high byte of basic line number (Block size)
        sta SeqBLK,y    ; Store this at SeqBlk array position 2
@char4  jsr getbyte     ; read bytes past start of line until we hit "
        beq @lstend     ; If we hit an EOL here, we are at the end of file!
        cmp #34         ; or have we hit the " character?
        bne @char4
        ldy #0          ; From here is the filename text
@char5  jsr getbyte     ; now reading past the "
        tax
        cmp #34         ; Are we at the end "  for the file name yet? 
        beq @endln      ; if byte = 0 we are end of a line
        txa
        sta (m_Var),y   ; store character at address in m_Var offset by y
        iny
        jmp @char5
@endln  lda b_Var       ; b_Var = which Seq we're dealing with 
        tax
        tya             ; y contains lines read so far
        sta SeqFNL,x    ; stores the string length in Seq FNL array
@char6  jsr getbyte     ; read chars after 2nd "
        beq @endln2     ; if we encounter an EOL then jump ahead
        cmp #83         ; Have we encountered an "S"?
        beq @over1
        bne @char6      ; continue until end of line
@endln2 ldy #2          ; Here we've encountered an eol but file was not SEQ
        jmp @char3
@over1  inc b_Var       ; Here we have a file extention of "S" (i.e. SEQ) 
        lda #16         ; After inc Line, A * X = A (hi Byte) X reg (lo Byte)
        sta i_Var
        lda #0
        sta i_Var+1
        lda m_Var
        sta j_Var
        lda m_Var+1
        sta j_Var+1
        jsr addit       ; k_Var = i_Var + j_Var
        lda k_Var
        sta m_Var
        lda k_Var+1
        sta m_Var+1
@char7  jsr getbyte     ; read characters past the "S" in SEQ
        bne @char7
        ldy #2          ; No. of bytes to ignore at next directory line 
        jmp @char3
@lstend lda b_Var       ; save the number of Seqs here
        sta Seqs
error   lda #1          ; Now that the Seq directory has been read
        sta DirFlag     ; set the flag  
        lda #5          ; filenumber 5
        jsr close       ; call CLOSE
        jsr clrchn      ; call CLRCHN
        rts

; Get a byte from the disk directory subroutine
; Note, Getbyte uses the x register, so save x before calling if needed

getbyte jsr readst      ; call READST (read status byte)
        ; bne error       ; Not 0 then error (most likely 5, device not found)
        jsr chrin       ; call CHRIN (read byte from directory) ends with rts
        rts

; No Seqs subroutine

noSeqs  ; brk             ; Advise user, there are no Seqs!
        rts             ; Make sure to leave any current Seq data as it was

; TabUp  Used when scrolling down the list off the bottom by one
; This subroutine first copies the screen memory for lines from the seq 
; directory dialogue box from lines 2 to 10 up a line
; Then write in the text for seq at SeqPntr to bottom line in box 

TabUp   ldx #21
@loop   lda screen+176,x      ; Starting from right to left, copy from 2nd line
        sta screen+136,x      ; and copy to line 1
        lda screen+216,x      ; Now line 3
        sta screen+176,x      ; to line 2, and so on
        lda screen+256,x
        sta screen+216,x
        lda screen+296,x
        sta screen+256,x
        lda screen+336,x
        sta screen+296,x
        lda screen+376,x
        sta screen+336,x
        lda screen+416,x
        sta screen+376,x
        lda screen+456,x
        sta screen+416,x
        lda screen+496,x
        sta screen+456,x
        dex
        bne @loop
        lda SeqPntr             ; which seq filename to write to this line
        ldx #16
        jsr multi               ; multiply by 16
        stx i_Var
        sta i_Var+1
        lda #<SeqFNS            ; now to add to the address of seq filenames
        sta j_Var
        lda #>SeqFNS
        sta j_Var+1
        jsr Addit               ; k_Var = i_Var + j_Var
        clc
        ldx #12                 ; Now position the cursor 13 lines down
        ldy #17                 ; and 17 chars over from the left
        jsr plot
        ldx SeqPntr
        lda SeqFNL,x            ; Get the text length for this seq
        tax
        ldy #0
@loop2  lda (k_Var),y           ; read the text
        jsr chrout              ; write it to the table line
        iny                     ; increment offset
        dex                     ; decrement counter
        bne @loop2
        sty a_Var
        cld
        sec
        lda #16
        sbc a_Var               ; How many spaces do we need to pad out
        tax
        lda #32                 ; Space character
@loop3  jsr chrout
        dex
        bne @loop3
        clc
        ldx #12
        ldy #36         ; 36th column from left
        jsr plot        
        lda SeqPntr
        rol             ; multiply this by 2 (this won't get to more than 200)
        tay
        iny             ; start by reading hi byte 
        lda SeqBLK,y
        dey             ; decrement y so we can read the low byte
        ldx SeqBLK,y    ; So high byte is in Acc and lo byte in X
        jsr $bdcd       ; print basic line number
        lda #<$d9f1     ; Location in Colour Ram area
        sta k_Var
        lda #>$d9f1
        sta k_Var+1
        ldx #7
        jsr ColBoxL
        rts

; TabDwn  Used when scrolling up the list to the top and go one higher

TabDwn  ldx #21
@loop   lda screen+456,x        ; Starting from right to left, copy 9th line
        sta screen+496,x        ; to line 10
        lda screen+416,x        ; Now line 8
        sta screen+456,x        ; to line 9, and so on
        lda screen+376,x
        sta screen+416,x
        lda screen+336,x
        sta screen+376,x
        lda screen+296,x
        sta screen+336,x
        lda screen+256,x
        sta screen+296,x
        lda screen+216,x
        sta screen+256,x
        lda screen+176,x
        sta screen+216,x
        lda screen+136,x
        sta screen+176,x
        dex                     
        bne @loop
        lda SeqPntr     ; which seq filename to write to this line
        ldx #16
        jsr multi       ; multiply by 16
        stx i_Var
        sta i_Var+1
        lda #<SeqFNS    ; now to add to the address of seq filenames
        sta j_Var
        lda #>SeqFNS
        sta j_Var+1
        jsr Addit       ; k_Var = i_Var + j_Var
        clc
        ldx #3          ; Now position the cursor 13 lines down
        ldy #17         ; and 17 chars over from the left
        jsr plot
        ldx SeqPntr
        lda SeqFNL,x    ; Get the text length for this seq
        tax
        ldy #0
@loop2  lda (k_Var),y   ; read the text
        jsr chrout      ; write it to the table line
        iny             ; increment offset
        dex             ; decrement counter
        bne @loop2
        sty a_Var
        cld
        sec
        lda #16
        sbc a_Var       ; How many spaces do we need to pad out
        tax
        lda #32         ; Space character
@loop3  jsr chrout
        dex
        bne @loop3
        clc
        ldx #3
        ldy #36         ; 36th column from left
        jsr plot        
        lda SeqPntr
        rol             ; multiply this by 2 (this won't get to more than 200)
        tay
        iny             ; start by reading hi byte 
        lda SeqBLK,y
        dey             ; decrement y so we can read the low byte
        ldx SeqBLK,y    ; So high byte is in Acc and lo byte in X
        jsr $bdcd       ; print basic line number
        lda #<$d889
        sta k_Var
        lda #>$d889
        sta k_Var+1
        ldx #7
        jsr ColBoxL
        rts

; Select a sequence from the Load dialogue box routine
; Returns what's needed for a successful load of a seq into memory

SelSeq  lda #14         ; 14 is standard colour
        sta chrclr      ; sets the character/cursor colour to standard blue
@loop1  jsr getin       ; Call Kernal GETIN
        beq @loop1      ; 0 = no keys yet, go back until key hit
        cmp #17         ; test for Cursor Down key pressed
        bne @next1      ; 17=Down, 145=Up, 157=Left, 29=Right
        inc SeqPntr     ; A pointer to current Seq no. from current disk
        lda Seqs
        cmp SeqPntr
        bne @over1
        dec SeqPntr
        jmp @loop1      ; If we're at the last seq, don't inc and loop back
@over1  lda SeqPntr
        cmp #100
        bne @over2
        dec SeqPntr
        jmp @loop1
@over2  inc SeqBoxP     ; Set Seq within Box Position to top most
        lda SeqBoxP
        cmp #10         ; Test if we are at the bottom of Dir dialogue box
        bne @over3      ; We're not at the bottom, jump head
        dec SeqBoxP     ; SeqBoxP can only be between 0 and 9!
        jsr TabUp       ; Move the table of Seqs up a line (10 to 2)
        jmp @loop1      ; Routine will also write SeqPntr text to last line
@over3  jsr DirLnC
        jmp @loop1
@next1  cmp #145        ; Up cursor 
        bne @next4
        lda SeqPntr
        beq @loop1      ; If SeqPntr is 0 then we can't go up
        dec SeqPntr
        lda SeqBoxP     ; Note: if Seqs>10 then SeqBoxP could be out of sync
        bne @over4      ; If SeqBoxP is above 0, we can decrement this too
        jsr TabDwn      ; Move the table of Seqs down a line (1 to 9)
        jmp @loop1      ; Routine will also write SeqPntr text to top line
@over4  dec SeqBoxP
        jsr DirLnC
        jmp @loop1
@next4  cmp #13         ; only return if CR is pressed
        beq @end
        jmp @loop1
@end    rts

; Routine that sets the specified SeqBoxP line to Yellow 
; It will also make the line above (if applicable) and line below
; (also if applicable) into Light Blue

DirLnC  lda SeqBoxP     ; First let's set i_Var to actual colour position
        ldx #40         ; Take SeqBoxP x 40 then add it to $8d89
        jsr multi       
        stx j_Var       ; put lo-byte result of Multiplication into i_Var
        sta j_Var+1     ; High byte result of Multi
        lda #$89        ; low byte
        sta i_Var
        lda #$d8        ; hi byte
        sta i_var+1
        jsr Addit       ; k_Var result = i_Var + j_Var
        ldx #7
        jsr ColBoxL
        lda SeqBoxP     
        bne @cont1      ; If not 0, jump to @cont1
        jsr LnAft       ; Increment k_Var by 40
        ldx #14
        jsr ColBoxL
        rts
@cont1  lda SeqBoxP
        cmp #9          ; Are we are bottom line (10th) or position 9?
        beq @AbOnly     ; If we are Bottom, Blue only above
        jsr LnB4        ; Go back & make line before blue
        ldx #14
        jsr ColBoxL
        jsr LnAft
        jsr LnAft       ; Then do line below in Blue
        ldx #14
        jsr ColBoxL
        rts  
@AbOnly jsr LnB4       
        ldx #14
        jsr ColBoxL
        rts

; Subroutine to colour the box line
; Call with x reg set to colour = 7 for Yellow, or = 14 for Light Blue
; make sure k_Var contains line position in Colour Ram applicable

ColBoxL ldy #16
@loop1  dey             ; Offset is 0 to 15
        txa
        sta (k_Var),y ; 
        tya             ; Have we done this 16 times yet?
        bne @loop1      ; only if Y=0, otherwise loop1
        clc
        lda k_Var
        adc #17         ; Add 17 to also colour the Size number
        sta j_Var
        lda k_Var+1
        adc #0
        sta j_var+1
        ldy #4
@loop2  dey             ; Offset is 0 to 3
        txa
        sta (j_Var),y   ; 
        tya             ; Have we done this 4 times yet?
        bne @loop2      ; only if Y=0, otherwise loop2
        rts

; LnAft Line After, adds 40 to k_Var

LnAft   clc
        lda #40
        adc k_Var
        sta k_Var
        lda #0
        adc k_Var+1
        sta k_Var+1
        rts

; LnB4 Line Before, subtracts 40 from k_Var

LnB4    cld             ; Clear decimal flag
        sec             ; Set the carry flag
        lda k_Var       ; Load LSB of first number
        sbc #40       
        sta k_Var 
        lda k_Var+1
        sbc #0
        sta k_Var+1
        rts 

; Loads the Seq selected from LoadSeq which called DIR1 and SelSeq before
; getting here, so SeqPntr has the value we need to read the filename
; as well as getting the filename text length
; then populates memory from $4000 as well as calculate the SeqLength
; Which will be needed for any subsequent saves if changes are made

LoadSeq lda #147        ; Clear the screen
        jsr chrout      
        clc
        ldx #2
        ldy #2
        jsr plot
        ldy #10
        ldx #0
@ldngLP lda ldngTX,x    ; Write "Loading..."
        jsr chrout
        inx
        dey
        bne @ldngLP
        lda SeqPntr     ; which Seq filename to write to this line
        ldx #16
        jsr multi       ; multiply by 16
        stx i_Var
        sta i_Var+1
        lda #<SeqFNS    ; now to add to the address of Seq filenames
        sta j_Var
        lda #>SeqFNS
        sta j_Var+1
        jsr Addit       ; k_Var = i_Var + j_Var
        ldx SeqPntr     ; Offset to filename length
        lda SeqFNL,x    ; Set to filename length to this
        sta filnaml
        tax             ; load x reg with filename length 
        ldy #0          ; Setup a loop to read the filename
@loop12 lda (k_Var),y   ; in memory at $4000 + SeqPntr * 16
        sta filetxt,y   ; store the characters in filetxt memory
        iny             ; increment x offset
        dex             ; decrement filename length character counter
        bne @loop12     ; if not at end of filename loop until we are
        ldx k_Var       ; k_Var contains address of filename text
        ldy k_Var+1
        lda filnaml
        jsr setnam      ; Call setname
;        ldx $BA         ; read current drive number
;        bne @cont1      ; if Current drive is 0, then we'll force to 8
        ldx #8
;        stx $BA 
@cont1  lda #5          ; Logical Number = 5
;        ldx $BA         ; default to device number 8
        ldy #2          ; secondary address 2 (needed for SEQ files)
        jsr setlfs      ; call SETLFS
        jsr open        ; call OPEN (open the directory)
        bcs @error
        ldx #5          ; filenumber 5
        jsr chkin       ; call CHKIN
        lda #<SeqMEM    ; Address for where Seq data is to be stored from
        sta w_Var       ; First low-byte
        lda #>SeqMEM    ; then hi-byte
        sta w_Var+1
        ldy #0
@loop   jsr readst      ; call READST (read status byte)
        bne @eof        ; either EOF or read error
        jsr chrin       ; call CHRIN (get a byte from file)
        sta (w_Var),Y   ; write byte to memory
        inc w_Var
        bne @skip2      ; If w_Var has become 0, then we need to inc hi-byte 
        inc w_Var+1
@skip2  jmp @loop       ; next byte
@eof    and #$40        ; end of file?
        beq @error
        nop             ; Not sure what needs to be here if akk <> 0
@error  lda w_Var       ; SeqLgth = (w_Var - $4000) / 3
        sta i_Var       ; First, let us subtract $4000 from w_Var value
        lda w_Var+1     ; Subtract k_Var = i_Var - j_Var
        sta i_Var+1
        lda #$0         ; now to load j_Var with $4000
        sta j_Var
        lda #$40
        jsr SubTrt      ; k_Var now contains w_Var - $4000
        lda k_Var       ; So to divide, we need i_Var containing result
        sta i_Var       ; of subtraction above
        lda k_Var+1
        sta i_Var+1     ; OK, now lets divide by 3
        lda #$03
        sta j_Var
        lda #$0
        sta j_Var+1
        jsr divide      ; First i_Var = i_Var / j_Var
        lda i_Var
        sta SeqLgth
;        lda k_Var+1
;        sta SeqLgth+1   ; SeqLength should now be Seq length in 'notes'
        lda #5          ; filenumber 5
        jsr close       ; call CLOSE
        jsr clrchn      ; call CLRCHN
        rts

; Remove yellow after tablature directory box used

NoYellw lda #$88        ; Low Byte of colour memory to clean up
        sta i_Var
        lda #$d8
        sta i_Var+1
        ldy #22
        ldx #10
@start  lda #14         ; colour of Light Blue
@loop   sta (i_Var),y   ; Goes from right to left, but gets the job done
        dey
        bne @loop       ; lets do this 21 positions across current line
        clc
        lda #40
        adc i_Var       ; add 40 to the low-byte in i_Var
        sta i_Var       ; store result
        lda #0
        adc i_Var+1
        sta i_Var+1     ; same for hi-byte 
        ldy #22
        dex             ; Have we done this 10 times yet? 
        bne @start      ; Done, all blue where some yellow used to be
        lda #32         ; Now to clean top of tab lines 2 and 9
        ldx #22
@loop2  sta screen+99,x
        sta screen+379,x
        dex
        bne @loop2
        lda #14         ; make where the arrows were not yellow
        sta colour+64   ; Location of D for Drive 
        sta colour+586  ; location of Up arrow
        sta colour+592  ; down arrow
        rts             

; FixLns Fix the lines that drawing the directory selection box distroyed

fixlns  rts             ; I should not need this code. Remove when confirmed

; Start recording a new sequence

StartR  lda #10         ; Light Red colour
        sta 56025       ; Colour RAM screen location for Record on
        jsr Reset       ; OK, reset the timer now
        jsr smldly      ; just to also clean off any bounce
        lda #1
        sta RecFlg      ; Set the flag that indicates we are recording
        rts

; Stop recording the current sequence

StopR   lda X_Var       ; If the last 'command' sent to the RC car
        cmp #3          ; was a 3, we don't need to send this again
        beq @cont1
        lda #3          ; just in case the fire button was pressed
        sta X_Var       ; when the RC car was sent a direction to go in
        jsr SndBytR     ; send the RC car the centre/off command
@cont1  jsr smldly      ; Just to be safe,
        jsr smldly      ; after a small delay
        jsr smldly
        lda #0          ; Turn off the recording indicator
        sta RecFlg
        lda #14         ; Light Blue colour for char
        sta 56025
        rts

; Used when joystick is used for avoiding bounce

smldly  ldy #5
@loop2  ldx #250        ; small delay (approx 7.5 msec)
@loop1  dex
        bne @loop1
        dey
        bne @loop2
        rts

; Reset the time
; Used to force the clock back to 0 so I can count the jiffies
; Note: Some conjecture if jiffies on a PAL C64 is 50 per second or 60
;       Books suggest it's always 60, but on a wiki site it says it's tied
;       to the video refresh, hence would be 50 on a PAL machine

Reset   lda #0
        tax
        tay
        jsr settim
        rts

; Send Byte X without recording
; Sub-routine to send a byte via RS232

SndByt  ldx #$02        ; Set device
        jsr chkout      ; as output
        lda X_Var       ; Command to be sent to RC car
        jsr chrout      ; send the byte
        ldx #3          ; The screen
        jsr chkout
        rts

; Send Byte X with recording
; Sub-routine to send a byte via RS232

SndBytR lda SeqPos      ; What position are we at
        ldx #3          ; this needs to be multiplied by 3
        jsr multi       ; Result acc = Hi Byte, x = Lo byte
        stx k_Var       ; store in Lo byte
        clc
        adc #$40
        sta k_Var+1     ; Hi byte order
        ldy #0          ; initial offset from where array is pointing
        lda $a1         ; High Byte of Jiffies since last Reset
        sta (k_Var),y   ; Store in the RC array ($4000 + SeqPos*3)
        iny
        lda $a2         ; Low Byte of Jiffies
        sta (k_Var),y 
        iny
        lda X_Var       ; load the command byte to be sent and stored
        sta (k_Var),y
        jsr SndByt
        inc SeqPos
        jsr Reset       ; reset the jiffy clock timer
        rts

; Replay routine
; This routine plays back the current sequence in memory
; Sequence begins at $4000 and goes to $4000 + SeqPos * 3
; Starts by sending a 3 to ensure car is in idle
; The waits the 2 byte delay saved in memory in jiffies
; Then sends the byte next in memory, etc.
; Last byte is always a 3 due to Stop Recording putting it there

Replay  clc
        ldx #23
        ldy #1
        jsr plot        ; move to last line on screen
        ldy #35
        ldx #0
@loop1  lda RePlyT,x    ; Print "Replay sequence bedore saving? Y/N:"
        jsr chrout
        inx
        dey
        bne @loop1
@yesno  jsr getin
        beq @yesno      ; wait until user presses a key
        cmp #"y"        ; did the user press a Y ?
        beq @replyy     ; replay yes
        cmp #"n"        ; We only need to save, no need to replay now
        bne @yesno      ; If user didn't press either y or n, go back        
        lda #0          ; This confirms to do a save 
        sta RecFlg
        rts             ; Retun to PlayRec for saving & back to main menu
@replyy clc
        ldx #23
        ldy #7
        jsr plot
        ldy #30
        ldx #0
@loop2  lda RplyOn,x    ; Print "Replaying now          "
        jsr chrout
        inx
        dey
        bne @loop2
        lda SeqPos      ; Let's use SeqPos to count to SeqLgth
        sta SeqLgth
        lda #0
        sta SeqPos
        sta j_Var
        lda #$40
        sta j_Var+1
        lda #3          ; First, let's send a 'centre' command
        sta X_Var       ; to the RC car
        jsr SndByt
        jsr Reset       ; now reset the timer
@PlyLp  clc             ; position cursor in middle of screen
        ldy #19
        ldx #12
        jsr plot
        lda SeqPos      ; to read the next sequence bytes
        ldx #3          ; we need to multiply by 3 the current SeqPos
        jsr multi       
        stx i_Var       ; Lo Byte of multiplication
        sta i_Var+1     ; Hi Byte of multiplication
        jsr Addit       ; k_Var = $4000 (j_Var) + SeqPos * 3 (i_Var)
        ldy #1          ; Starting with the lo byte of the jiffies
@loop3  lda (k_Var),y   ; Let's read the number of Jiffies to delay
        cmp $a2         ; compare with the lo jiffy count
        bne @loop3      ; If lo byte doesn't match go back until it does
        ldy #0
        lda (k_Var),y   ; now let's check the hi byte of jiffies
        cmp $a1         ; the hi byte is at $A1 in the C64 memory
        bne @loop3      ; go back if both the hi and lo bytes don't match
        ldy #2
        lda (k_Var),y   ; OK lets read the command we need to send
        sta X_Var       ; to send to the RC car
        tax
        lda pointr,x    ; show the current direction symbol centre screen
        jsr chrout
        jsr SndByt      ; Send the command to the RC car
        lda SeqPos      ; have we done the last command?
        cmp SeqLgth
        beq @ending     ; yes we have
        inc SeqPos      ; Incriment the Sequence Position variable
        jsr Reset       ; reset the timer
        jmp @PlyLp      ; go back and do the next 'command'
@ending clc             ; position cursor in middle of screen
        ldy #19
        ldx #12
        jsr plot
        lda #"O"        ; Let's start with a O in the middle
        jsr chrout
        clc
        ldx #23
        ldy #1
        jsr plot        ; move to last line on screen
        ldy #24
        ldx #0
@loop4  lda SaveQT,x    ; Print "Save this sequence? Y/N:"
        jsr chrout
        inx
        dey
        bne @loop4
@ynresp jsr getin
        beq @ynresp
        cmp #"y"
        bne @cont1
        lda #1
        sta RecFlg
        rts
@cont1  cmp #"n"
        bne @ynresp
        lda #0
        sta RecFlg
        sta SeqLgth
        sta SeqPos
        clc
        ldx #23
        ldy #1
        jsr plot        ; move to last line on screen
        ldx #26
        lda #" "        ; wipe away the text as we're not saving this Seq
@loop5  jsr chrout
        dex
        bne @loop5
        rts

; Routine to fill $4000 to $7fff with a blank sequence
; For each command to the RC car, there are 3 bytes
; The first byte is the MSB of the Jiffy clock count
; The second byte is the LSB of the Jiffy clock count
; The 3rd byte is the command sent via RS232 to the RC car

Blanksq lda #0          ; This is normally done prior to calling Blanksg
        sta i_Var       ; Store lo byte of $7f00
        lda #$7f        ; Now the high byte
        sta i_Var+1     ; in 2nd byte 
@start  ldy #$0         ; Using Y as an offset and decrementing (is faster)
@loop   dey
        lda #0          ; Since we are counting backwards, we start with
        sta (i_Var),y   ; The last byte in the sequence (see header notes)
        tya             ; by transfering the Y value to A we can test
        bne @loop       ; to see if we have decrimented to 0 yet, if not loop
        lda #$40        ; Now to test if we have reached
        cmp i_Var+1     ; our final bank of 255
        beq @end        ; if so, branch to end
        dec i_Var+1     ; if not decrement hi byte and
        jmp @start      ; jump back to start to continue to next 256 byte bank
@end    rts

; Addition
; 
; k_Var result = i_Var + j_Var
;

Addit   clc             ; clear carry
        lda i_Var 
        adc j_Var 
        sta k_Var       ; store sum of LSBs
        lda i_Var+1
        adc j_Var+1      ; add the MSBs using carry from
        sta k_Var+1      ; the previous calculation
        rts

; Substraction sub-routine
;
; k_Var Result = i_Var - j_Var
;
; Test BMI Branch if Negative to see if result is negative
; If the 2 values are the same, the result will be 0, obviously
; Use BEQ to test this

SubTrt  cld             ; Clear decimal flag
        sec             ; Set the carry flag
        lda i_Var       ; Load LSB of first number
        sbc j_Var       
        sta k_Var 
        lda i_Var+1
        sbc j_Var+1
        sta k_Var+1
        rts             ; Return from subroutine

; Multiplication
;
; Acc * X Reg
;
; Result in Acc (hi-byte) & X Reg (lo-byte)
;
; Uses i_Var during calculation (i.e. contents are distroyed)

multi   cpx #$00
        beq @end5
        dex
        stx @modi+1
        lsr
        sta i_Var
        lda #$00
        ldx #$08
@loop7  bcc @skip1
@modi   adc #$00
@skip1  ror
        ror i_Var
        dex
        bne @loop7
        ldx i_Var
        rts
@end5   txa
        rts

; Divide sub-routine 
; 
;                 i_Var  Dividend
; i_Var Result =  -----            + Remainder m_Var
;                 j_Var  Divisor

divide  lda #0          ; preset remainder to 0
        sta m_Var
        sta m_Var+1
        ldx #16         ; repeat for each bit: ...
divloop asl i_Var       ; dividend lb & hb*2, msb -> Carry
        rol i_Var+1  
        rol m_Var       ; remainder lb & hb * 2 + msb from carry
        rol m_Var+1
        lda m_Var
        sec
        sbc j_Var       ; substract divisor to see if it fits in
        tay             ; lb result -> Y, for we may need it later
        lda m_Var+1
        sbc j_Var+1
        bcc skip        ; if carry=0 then divisor didn't fit in yet
        sta m_Var+1     ; else save substraction result as new remainder,
        sty m_Var    
        inc i_Var       ; and INCrement result cause divisor fit in 1 times
skip    dex
        bne divloop     
        rts

; Save a recorded sequence
; This routine prompts the user for a filename (no error checking yet)
; Then saves the sequence just recorded

SaveRC  clc             ; Clear Carry flag = Set cursor position
        ldy #1          ; Cursor X position
        ldx #23         ; Cursor Y position
        jsr plot        ; Move cursor to initial 'Filename?:' position
        ldy #35
        ldx #0
@loop2  lda filen,x     ; Print "Filename?:  " at line 23 and 1 in from side
        jsr chrout
        inx
        dey
        bne @loop2
        clc
        ldx #23
        ldy #11
        jsr plot        ; position cursor for filename entry
        jsr getflnm     ; Get filename
        lda filnaml     ; check if any filename actually provided
        bne @cont1      ; if we got a filename let's continue
        jmp SaveRC      ; let's re-prompt for a filename
@cont1  ldy #0
        ldx filnaml     ; Read filnaml which will have the filename length
@loop3  lda fnseqx,y    ; Add the text ",s,w" to end of filnaml
        sta filetxt,x
        inx
        iny
        cpy #4
        bne @loop3      ; Have we added all the characters yet?
        clc
        lda filnaml
        adc #4          ; Accumulator should now contain filnaml+4
        ldx #<filetxt   ; Address in memory holding filename text
        ldy #>filetxt
        jsr setnam      ; Kernal call to set filename
        lda SeqPos
        ldx #3
        jsr multi
        stx i_Var 
        sta i_Var+1
        lda #$01        ; Now to add $4001
        sta j_Var       ; I need to add $4001 becuase the routine below
        lda #$40        ; For saving does an inc after saving each byte 
        sta j_Var+1     ; and therefore stops one byte short otherwise
        jsr Addit       ; Add $4000 to Seq Length * 4, result in k_Var
        lda #$05        ; file number 5
        ldx #$08        ; default to device 8
        ldy #$02        ; secondary address 2
        jsr setlfs      ; call SETLFS
        clc
        jsr open        ; call OPEN
        bcs error2      ; if carry set, the file could not be opened
        ldx #$05        ; filenumber 5
        jsr chkout      ; call CHKOUT (file 5 now used as output)
        lda #$00        ; set j_Var to start address of where in mem file
        sta j_Var       ; file data starts from (being 2 bytes after $4000)
        lda #$40        ; so ignore the 2 bytes that are the load address
        sta j_var+1
        ldy #$00
@loop4  jsr readst      ; call READST (read status byte)
        bne werror      ; write error
        lda (j_Var),Y   ; get byte from memory
        jsr chrout      ; call CHROUT (write byte to file)
        inc j_var
        bne @skip4
        inc j_Var+1
@skip4  lda j_Var
        cmp k_Var
        lda j_Var+1
        sbc k_Var+1
        bcc @loop4      ; next byte
close3  lda #$05        ; filenumber 5
        jsr close       ; call CLOSE
        jsr clrchn      ; call CLRCHN
        lda #0          ; since Seq is now saved
        sta RecFlg      ; reset the RecFlg
        sta DirFlag     ; Ensure the flag to read the directory is reset 
endis   rts

error1  ; Akkumulator contains BASIC error code
        ; most likely errors:
        ; A = $05 (DEVICE NOT PRESENT)
        ;... error handling for open errors ...
        jmp close3   ; even if OPEN failed, the file has to be closed

rderror ; for further information, the drive error channel has to be read
        ;... error handling for read errors ...
        jmp close3

error2  ; Akkumulator contains BASIC error code
        ; most likely errors:
        ; A = $05 (DEVICE NOT PRESENT)
        ; ... error handling for open errors ...
        jmp close3    ; even if OPEN failed, the file has to be closed

werror  ; for further information, the drive error channel has to be read
        ; ... error handling for write errors ...
        jmp close3

; Get file name
; stores filename text at filetxt = $3f6c up to 18 characters
; will need to support backspace to delete back to fix file name error
; stores filename length in filnaml = $c90a

getflnm lda #0          ; Use filnaml to store filename length
        sta filnaml     ; starting at 0
        sta BLNSW       ; make sure cursor is flashing
@loop   jsr chrin       ; read keyboard buffer
        beq @loop       ; loop if no character entered
        cmp #13         ; Has a CR been pressed
        beq @end        ; If so go end
        cmp #160        ; check if fire button char
        beq @loop
        cmp #148        ; check if a backspace (del) has been pressed
        bne @cont       ; if not then jmp ahead to add character to filename
        lda filnaml
        beq @loop       ; if filename length is 0 then we can't backspace
        dec filnaml
        jmp @loop
@cont   ldx filnaml     ; load x as offset for storing filename
        sta filetxt,x   ; Store each charater at filetxt
        inc filnaml     ; Increment filnaml for each character stored 
        jmp @loop       ; return back to get more char or a CR
@end    lda #1          ; Flag to turn the cursor blink back off
        sta BLNSW       ; Turn off the flashing cursor
        rts

; Print Number right justified for up to 3 digit numbers
; Note: This allows numbers from 0 to 999. Numbers above 255 need 2 bytes
; load j_Var with number to be printed at current location
; Note: k_Var is used to replace j_Var
;       also, i_Var is also used and contents distroyed
; uses x and y registers too

prnum   lda j_Var       ; copy the current value of j_Var into k_Var
        sta k_Var       ; because the write up to a 3 digit number
        lda j_Var+1     ; kills the contents of j_Var
        sta k_Var+1
        lda #0          ; null delimiter for print
        tax
        pha    
prnum2  lda #0          ;   divide var[x] by 10
        sta i_Var+1     ; clr BCD
        lda #16
        sta i_Var       ; {>} = loop counter
prdiv1  asl j_Var       ; var[x] is gradually replaced
        rol j_Var+1     ;   with the quotient
        rol i_Var+1     ; BCD result is gradually replaced
        lda i_Var+1     ;   with the remainder
        sec
        sbc #10         ; partial BCD >= 10 ?
        bcc prdiv2
        sta i_Var+1     ;   yes: update the partial result
        inc j_Var       ;   set low bit in partial quotient
prdiv2  dec i_Var
        bne prdiv1      ; loop 16 times
        lda i_Var+1
        ora #"0"        ;   convert BCD result to ASCII
        pha             ;   stack digits in ascending
        inx
        lda j_Var       ;     order ('0' for zero)
        ora j_Var+1
        bne prnum2      ; } until var[x] is 0
        pla
prnum3  tay             ; temp store Acc in Y
        cpx #3
        beq print3      ; print 3 digit no. (i.e. no leading space)
        cpx #2
        beq print2      
        lda #" "
        jsr chrout
        jsr chrout
        tya 
        jmp prnum4
print2  lda #" "
        jsr chrout
        tya
        jmp prnum4      
print3  tya
prnum4  jsr chrout      ; print digits in descending
        pla             ;   order until delimiter is
        bne prnum4      ;   encountered
        lda k_Var       ; copy the original value of j_Var back
        sta j_Var       ; before returning so j_Var is restored
        lda k_Var+1      
        sta j_Var+1 
        rts

Menu1   text "Commodore 64 RC car controller" ; 
Menu2   text "By Steve Smit     October 2021"
Menu3   text "Function Key"
Func1   text "F1 ",$3d," Operate RC car without recording"
Func2   text "F3 ",$3d," Operate RC car with recording"
Func3   text "F5 ",$3d," Menu of recorded sequences"
Func4   text "F7 ",$3d," Exit"
JoyPort text "Use Joystick in Port 1"
FireXT  text "Press Fire to exit"
FireST  text "Pressing Fire will start/stop recording"
RecTxt  text "O Record indicator"
GoodB   text "Good Bye!"
ReplyT  text "Replay sequence before saving? Y/N:" ; 35 chars long
SaveQT  text "Save this sequence? Y/N:"  ; 24 characters long
RplyOn  text "ing now                       "
WaitSP  text "Press Space Bar to play loaded sequence"
PlyAgn  text "Play it again? Y/N:"
filen   text "Filename?:                         "       ; 35 chars long
fnseqx  text ",s,w"             ; 4 chars Filename SEQ extension for save
rddirT  text "Disk Directory"
dirname text "$"                ; filename used to access directory
pointr  text "O<>O^v",174,189,173,176
ldngTX  text "Loading..."
tabl1   byte 112,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,114,64,64,64,64,110
tablh   byte 93,83
        text 'equences       '
        byte 93,83 
        text 'ize'
        byte 93
tabl3   byte 107,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,91,64,64,64,64,115
tablb   byte 93,32,32,32,32,32,32,32,85,16,158,32,68
        text 'own'
        byte 28,93,32,32,32,32,93
tabl2   byte 93,96,96,96,96,96,32,32,32,32,32,32,32,32,32,32,32,93,32,32,32,32,93
tabl4   byte 109,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,113,64,64,64,64,125
RSPAR   byte %00001000, %00000000   ; sets RS232 to 1200 baud
