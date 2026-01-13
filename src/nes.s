; Small demo for christmas 2025.
;
; Copyright (c) 2025 Mibi88.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;
; 1. Redistributions of source code must retain the above copyright notice,
; this list of conditions and the following disclaimer.
;
; 2. Redistributions in binary form must reproduce the above copyright notice,
; this list of conditions and the following disclaimer in the documentation
; and/or other materials provided with the distribution.
;
; 3. Neither the name of the copyright holder nor the names of its
; contributors may be used to endorse or promote products derived from this
; software without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
; POSSIBILITY OF SUCH DAMAGE.

.include "nes.inc"

.include "std.inc"
.include "nmi.inc"

.segment "ZEROPAGE"

max:            .res 1
tmp_y:          .res 1

ctrl1:          .res 1
ctrl2:          .res 1

sprite_rot:     .res 1

.segment "BSS"

; A page containing the sprites that is then copied to $0200, rotated by
; sprite_rotation to make sprites flicker when there are more than 8 sprites
; on a scanline.
sprites: .res $100

.segment "TEXT"

CTRL1 = $4016

.proc READ_CTRL1
        LDA #$01
        STA CTRL1
        STA ctrl1
        LSR
        STA CTRL1

    LOOP:
        LDA CTRL1
        LSR
        ROL ctrl1
        BCC LOOP

        RTS
.endproc

CTRL2 = $4017

.proc READ_CTRL2
        LDA #$01
        STA CTRL2
        STA ctrl2
        LSR
        STA CTRL2

    LOOP:
        LDA CTRL2
        LSR
        ROL ctrl2
        BCC LOOP

        RTS
.endproc

.proc LOAD_PALETTE
        STA ptr
        STX ptr+1

        LDY #$00
    LOOP:
        LDA (ptr), Y
        STA pal_buffer, Y
        INY
        CPY #$20
        BNE LOOP

        LDA #01
        STA pal_update

        RTS
.endproc

.proc SET_PPU_ADDR
        ; Wait for all the bytes of the buffer to be loaded before changing the
        ; target address.
    WAIT:
        LDY nam_cur
        BNE WAIT

        STA ppu_addr
        STX ppu_addr+1

        RTS
.endproc

.proc LOAD_RLE
        STA ptr
        STX ptr+1

        LDY #$00

    LOAD_LOOP:
        LDA (ptr), Y
        BEQ END
    LOAD_LOOP_SKIP_LOAD:
        STA max
        INY
        LDA (ptr), Y

        STY tmp_y
        LDX #$00
    BUFFER_WRITE_LOOP:

        LDY nam_max
    WAIT_ON_LIMIT:
        CPY nam_cur
        BEQ WAIT_ON_LIMIT

        LDY nam_cur
        STA nam_buffer, Y
        INC nam_cur

        INX
        CPX max
        BNE BUFFER_WRITE_LOOP

    BUFFER_WRITE_LOOP_END:

        LDY tmp_y
        INY
        BNE LOAD_LOOP

        ; Y wrapped to 0

        INC ptr+1
        ; If the next tile should be repeated 0 times, we exit the loop. I'm
        ; using it to mark the end of the nametable.
        LDA (ptr), Y
        BNE LOAD_LOOP_SKIP_LOAD

    END:
        RTS
.endproc

.proc UPDATE_SPRITES
        LDX sprite_rot
        LDY #$00

    LOOP:
        LDA sprites, X
        STA $0200, Y
        INX
        INY
        BNE LOOP

        ; Rotate the sprite data by 8 sprites next time
        LDA sprite_rot
        CLC
        ADC #4
        STA sprite_rot

        RTS
.endproc
