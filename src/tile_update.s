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

.include "tile_update.inc"
.include "map_data.inc"
.include "ppu.inc"
.include "std.inc"
.include "nes.inc"

.segment "ZEROPAGE"

spr_stack_idx:  .res 1

tile_idx:       .res 1
new_tile_idx:   .res 1

tmp:            .res 1
tmp2:           .res 1

tmptile:        .res 16

.segment "BSS"

sprite_tile_hi: .res UPDATE_STACK_SZ
sprite_tile_lo: .res UPDATE_STACK_SZ
sprite_tgt_hi:  .res UPDATE_STACK_SZ
sprite_tgt_lo:  .res UPDATE_STACK_SZ
sprite_fine_x:  .res UPDATE_STACK_SZ
sprite_fine_y:  .res UPDATE_STACK_SZ
sprite_idx:     .res UPDATE_STACK_SZ

.segment "TEXT"

RETURN:
    RTS

.proc UPDATE_TILES
        LDX spr_stack_idx
        CPX #UPDATE_STACK_SZ
        BCS RETURN

    LOOP:
        LDA sprite_tile_hi, X
        STA PPUADDR
        LDA sprite_tile_lo, X
        STA PPUADDR

        LDA #$00
        STA tmp2

        LDA PPUDATA
        LDA PPUDATA

        ASL
        ROL tmp2
        ASL
        ROL tmp2
        ASL
        ROL tmp2
        ASL
        ROL tmp2
        SEC
        ADC sprite_fine_y, X
        STA tmp
        LDA tmp2
        ADC #$00
        STA tmp2

        LDA tmp2
        STA PPUADDR
        LDA tmp
        STA PPUADDR

        LDY PPUDATA
        LDY PPUDATA

        LDA tmp
        CLC
        ADC #$08
        STA tmp
        LDA tmp2
        ADC #$00
        STA PPUADDR
        LDA tmp
        STA PPUADDR

        LDA PPUDATA
        LDA PPUDATA
        STA tmp
        TYA
        ORA tmp
        AND sprite_fine_x, X
        BNE COLLISION
        JMP NO_COLLISION

    COLLISION:

.if 0
        LDA sprite_tgt_hi, X
        STA PPUADDR
        LDA sprite_tgt_lo, X
        STA PPUADDR

        LDY PPUDATA
        LDY PPUDATA
        STY tile_idx

        LDA TILE_USAGE, Y
        BNE ALLOC
        LDA tile_usage, Y
        CPY #64
        BCC NO_ALLOC
        JMP FILL

    ALLOC:

        LDY empty_tiles
        CPY #TILE_STACK_SZ
        BCC OK
        JMP CONTINUE
    OK:

        LDA empty_tile_idx, Y
        INY
        STY empty_tiles

        STA new_tile_idx

        LDA sprite_tgt_hi, X
        STA PPUADDR
        LDA sprite_tgt_lo, X
        STA PPUADDR
        LDA new_tile_idx
        STA PPUDATA

    TILE_COPY:
        LDA tile_idx
        STA tmp2
        LDA #$00
        LDY #$10

        ASL tmp2
        ROL
        ASL tmp2
        ROL
        ASL tmp2
        ROL
        ASL tmp2
        ROL

        STA PPUADDR
        LDA tmp2
        STA PPUADDR

        LDA PPUDATA

    READ_LOOP:
        LDA PPUDATA
        STA tmptile, Y

        DEY
        BNE READ_LOOP

    WRITE_DATA:
        LDA new_tile_idx
        STA tmp2
        LDA #$00
        LDY #$10

        ASL tmp2
        ROL
        ASL tmp2
        ROL
        ASL tmp2
        ROL
        ASL tmp2
        ROL

        STA PPUADDR
        LDA tmp2
        STA PPUADDR

    WRITE_LOOP:
        LDA tmptile, Y
        STA PPUDATA

        DEY
        BNE WRITE_LOOP

        LDY tile_idx
        LDA tile_usage, Y
        LDY new_tile_idx
        STA tile_usage, Y

        JMP SET_PIXEL
.endif
    NO_ALLOC:

        

    SET_PIXEL:
        LDY tile_idx
        LDA tile_usage, Y
        CLC
        ADC #$01
        STA tile_usage, Y
        JMP RESET_POS

    FILL:
        LDA sprite_tgt_hi, X
        STA PPUADDR
        LDA sprite_tgt_lo, X
        STA PPUADDR
        LDA #FULL_TILE
        STA PPUDATA

    RESET_POS:
        LDY sprite_idx
        LDA #$00
        STA sprites, Y
        JSR RAND
        STA sprites+3, Y

    NO_COLLISION:

    CONTINUE:
        ; Mark it as not being on the stack anymore.
        LDY sprite_idx, X
        LDA #$00
        STA sprites+2, Y

        INC spr_stack_idx

        INX
        CPX #UPDATE_STACK_SZ
        BEQ BREAK
        JMP LOOP

    BREAK:
        RTS
.endproc
