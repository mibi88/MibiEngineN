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

.include "sprites.inc"

.include "nes.inc"
.include "std.inc"
.include "map_data.inc"
.include "tile_update.inc"

.segment "ZEROPAGE"

coarse_x:       .res 1
fine_x:         .res 1

coarse_y:       .res 1
fine_y:         .res 1
tmp_x:          .res 1

tile_x:         .res 1
tile_y:         .res 1

tmp:            .res 1

.segment "TEXT"

.proc INIT_SPRITES
        LDX #$00

    LOOP:
        JSR RAND
        STA sprites, X
        JSR RAND
        STA sprites+3, X

        TXA
        CLC
        ADC #$04
        TAX
        BNE LOOP

    INIT_STACK:
        LDA #UPDATE_STACK_SZ
        STA spr_stack_idx

        RTS
.endproc

.proc MOVE_SPRITES
        LDX #$00

    LOOP:
        INC sprites, X

        LDY sprites+3, X
        JSR RAND
        AND #$03
        BEQ CONTINUE
        CMP #$01
        BEQ MOVE_RIGHT

    MOVE_LEFT:
        DEY
        TYA
        STA sprites+3, X
        JMP CONTINUE

    MOVE_RIGHT:
        INY
        TYA
        STA sprites+3, X

    CONTINUE:

        JSR RAND
        AND #$03
        BNE SKIP

        INC sprites, X

    SKIP:

        TXA
        CLC
        ADC #$04
        TAX
        BNE LOOP

        INC seed

        RTS
.endproc

RETURN:
    RTS

.proc SPRITE_COLLISION
        LDX #$00

    LOOP:
        LDY spr_stack_idx
        BEQ RETURN ; The stack is full

        ; I'm writing 4 to the sprite flags to mark them as being processed, as
        ; the third bit is unused.
        LDA sprites+2, X
        BEQ OK
        STX tmp_x
        JMP ALREADY_ON_STACK
    OK:

        LDA sprites, X
        CMP #240
        BCS COLLISION
        AND #7^$FF

        ; Leave fine Y bits away and divide.
        LSR

        ; Coarse Y is already divided by 8 and multiplied back by 4 to get the
        ; tile position.
        STA coarse_y

        LDA sprites+3, X

        LSR
        LSR
        LSR
        ; A now contains the tile number.
        STA tile_x

        LSR
        LSR
        LSR
        ; A now contains the byte number in the mask

        ; Coarse X is in A.
        CLC
        ADC coarse_y

        ; The index of the byte to read from the mask is in coarse_x.
        STA coarse_x

        LDA tile_x
        AND #$07
        STA fine_x

        LDY coarse_x

        LDA map_usage, Y
        LDX fine_x
        BEQ SHIFT_END
    SHIFT_LOOP:
        LSR
        DEX
        BNE SHIFT_LOOP

    SHIFT_END:
        AND #$01
        BEQ EMPTY

        ; TODO: Add the pixel to the tile before resetting the position.
        LDX tmp_x
    COLLISION:

        LDA #$04
        STA sprites+2, X

        LDY spr_stack_idx
        ; Add it to the list of sprites to update.
        DEY
        STY spr_stack_idx

        TXA
        STA sprite_idx, Y

        LDA sprites, X
        SEC
        SBC #$01
        STA fine_y
        AND #$07
        STA sprite_fine_y, Y

        LDA #$00
        STA tmp
        LDA sprites, X
        AND #$07^$FF
        ASL
        ROL tmp
        ASL
        ROL tmp
        CLC
        ADC tile_x
        STA sprite_tile_lo, Y
        LDA tmp
        ADC #$20 ; The background is in the nametable at $2000.
        STA sprite_tile_hi, Y

        LDA #$00
        STA tmp
        LDA fine_y
        AND #$07^$FF
        ASL
        ROL tmp
        ASL
        ROL tmp
        CLC
        ADC tile_x
        STA sprite_tgt_lo, Y
        LDA tmp
        ADC #$20 ; The background is in the nametable at $2000.
        STA sprite_tgt_hi, Y

        LDA sprites+3, X
        AND #$07
        TAX
        LDA #$01
        CPX #$00
        BEQ NO_SHIFT

    FINE_X_SHIFT_LOOP:
        ASL

        DEX
        BNE FINE_X_SHIFT_LOOP

    NO_SHIFT:
        STA sprite_fine_x, Y

    ALREADY_ON_STACK:

    EMPTY:
        LDA tmp_x
        CLC
        ADC #$04
        STA tmp_x
        TAX
        BEQ END
        JMP LOOP

    END:
        RTS
.endproc
