; **************************************************************
; * Commodore 64 RC car control by Steve Smit - V 1.0  6/10/21 *
; * Project submitted to RetroChallenge 2021-10                *
; **************************************************************

;Constants
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
SeqMEM  = $4000         ; Where a sequence is to be stored in memory
SeqFNS  = $8000         ; Array of 100 16 bytes holding filename strings 
SeqFNL  = $8640         ; Array of 100 single bytes to store filename length
SeqBLK  = $86A4         ; Array of 100 two bytes holding size in blocks
TmpBuf  = $876D         ; Temp buffer-copy of bytes sent to RC car for diag


; Variables
TmpPly  = $05           ; Dec 5 - 2 byte address for testing Play 
i_Var   = $fb           ; 2 byte temporary variable ($fb and $fc)
j_Var   = $fd           ; Another 2 byte temporary variable ($fd and $fe)
k_Var   = $58           ; Another 2 byte temporary variable
m_Var   = $5a           ; Another 2 byte temporary variable
X_Var   = $61           ; 'X' is bytes sent to rc car
w_Var   = $ae           ; Another 2 byte temporary variable
SeqPos  = $64           ; Also 2 bytes for current sequence position
PreX    = $6c           ; Previous X position of the cursor
PreY    = $6d           ; Previous Y position of the cursor
CursorX = $6e           ; Current X position of the Cursor
CursorY = $70           ; Current X position of the Cursor
LastKey = $313          ; Last key pressed or mouse action
SeqLgth = $334          ; A 2 byte value, i.e. more than 256 steps (3 bytes/n)
DirFlag = $33a          ; Flag if current drive has had the song dir read
Modded  = $3ff          ; 0=no modificatoin, 1=sequence now modified
PauseA  = $c900         ; 16215 Holds contents of the Acc at debugging routine
SeqBoxP = $c901         ; A one bye var holding which line within box
SeqPntr = $c902         ; A pointer = Song no. from current disk
a_Var   = $c903         ; Temp 1 byte variable
b_Var   = $c904         ; another temp 1 byte variable
BytVar  = $c905         ; a single byte variable
Seqs    = $c906         ; One byte, holds number of sequences on current disk
filnaml = $c90a         ; 51466 Filename length
filetxt = $c90b         ; Memory to hold up to 20 charaters for filename

* = $2000

setup   lda #0          ; 
        sta Seqs        ; Also set the number of Seqs filenames in mem to 0
        sta SeqPntr     ; Set that we are pointing to the first Sequence
        sta DirFlag     ; Set Directory of Seqs flag=0, not yet read
        lda #2          ; Setup RS232 - Device # 2 = RS232
        ldx #<RSPAR     ; Low address for Baud rate of 1200 BPS
        ldy #>RSPAR     ; Command. 0 = Full Duplex 3 line
        jsr setnam
        lda #2          ; Using Logical Number 2 for all RS232 access
        tax
        ldy #0
        jsr setlfs      ; Open 2,2,RS232 at 1200 baud
        jsr open
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
; Should be easy, right?

PlayRC  lda #147        ; Better clear the 
        jsr chrout      ; screen first
        clc
        ldx #2          ; place cursor 2 lines down
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
        ldx #4          ; place cursor 4 lines down
        ldy #11         ; and 11 in from side
        jsr plot
        ldx #0
        ldy #18
@firex  lda FireXT,x
        jsr chrout
        inx
        dey
        bne @firex
@joyML  clc             ; position cursor in middle of screen
        ldy #19
        ldx #12
        jsr plot
        lda joy1        ; read Joystick in port 1
        sta i_Var       ; save a copy
        cmp #239        ; test for fire button
        bne @cont1
        jmp @ending
@cont1  lda i_Var
        cmp #255        ; nothing pressed yet?
        bne @next1
        lda #"O"        ; show a "O" in the middle of screen
        jsr chrout
        jmp @joyML
@next1  lda i_Var
        cmp #254        ; test for Forward
        bne @next2
        lda #"^"        ; need to select an appropriate char
        jsr chrout
        jmp @joyML
@next2  lda i_Var
        cmp #253        ; test for Back
        bne @next3
        lda #"v"        ; show a "v" in the middle of screen
        jsr chrout
        jmp @joyML
@next3  lda i_Var
        cmp #251        ; test for Left
        bne @next4
        lda #"<"        ; show a "<" in the middle of the screen
        jsr chrout
        jmp @joyML
@next4  lda i_Var
        cmp #247        ; test for Right
        bne @next5
        lda #">"        ; show a "<" in the middle of the screen
        jsr chrout
        jmp @joyML
@next5  lda i_Var
        cmp #250        ; test for Forward & Left
        bne @next6
        lda #176        ; show a Left/Up angle in the middle of the screen
        jsr chrout
        jmp @joyML
@next6  lda i_Var
        cmp #246        ; test for Forward & Right
        bne @next7
        lda #174        ; show a Right/Up angle in the middle of the screen
        jsr chrout
        jmp @joyML
@next7  lda i_Var
        cmp #249        ; test for Back & Left
        bne @next8
        lda #173        ; show a Down/Left angle in the middle of the screen
        jsr chrout
        jmp @joyML
@next8  lda i_Var
        cmp #245        ; test for Back & Right
        bne @next9
        lda #189        ; show a Down/Right angle in the middle of the screen
        jsr chrout
        jmp @joyML
@next9  nop             ; test for anything else?
        jmp @joyML
@ending rts        

; Using RC car with recording of sequence

PlayRec rts             ; code for using RC car w recording

; Selecting from pre-recorded sequences and playing them back

RecBack rts             ; code for reading the disk for seq 


Menu1   text "Commodore 64 RC car controller" ; 
Menu2   text "By Steve Smit     October 2021"
Menu3   text "Function Key"
Func1   text "F1 ",$3d," Operate RC car without recording"
Func2   text "F3 ",$3d," Operate RC car with recording"
Func3   text "F5 ",$3d," Menu of recorded sequences"
Func4   text "F7 ",$3d," Exit"
JoyPort text "Use Joystick in Port 1"
FireXT  text "Press Fire to exit"
GoodB   text "Good Bye!"
RSPAR   byte %00001000, %00000000
