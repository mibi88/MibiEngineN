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

.export MAIN

.segment "ZEROPAGE"

countdown:      .res 1

.segment "BSS"

.segment "TEXT"

.include "nmi.inc"
.include "std.inc"
.include "nes.inc"
.include "ppu.inc"
.include "tile_update.inc"
.include "sprites.inc"
.include "map_data.inc"

.proc MAIN
        LDA #$80
        STA $2000

        JSR PPU_INIT

        LDA #%10000000
        STA ppu_ctrl
        STA PPUCTRL
        LDA #%00000000
        STA ppu_mask

        LDX #>PALETTE
        LDA #<PALETTE
        JSR LOAD_PALETTE

        LDX #$20
        LDA #$00
        JSR SET_PPU_ADDR

        LDX #>TITLE_NAM
        LDA #<TITLE_NAM
        JSR LOAD_RLE

        LDX #$00
        LDA #$00
        JSR SET_PPU_ADDR

        LDX #>TILES
        LDA #<TILES
        JSR LOAD_RLE

        LDA #%00011110
        STA ppu_mask
        LDA #%10001000
        STA ppu_ctrl

        JSR INIT_SPRITES
        JSR LOAD_MAP_USAGE
        JSR LOAD_TILE_USAGE

    LOOP:
        LDA nmi
        BEQ LOOP
        LDA #$00
        STA nmi

        LDX countdown
        CPX #$08
        BNE SKIP

        JSR MOVE_SPRITES
        LDX #$00
        JMP UPDATE

    SKIP:
        INX
    UPDATE:
        STX countdown
        JSR UPDATE_SPRITES
        JSR SPRITE_COLLISION

        JSR FIND_EMPTY

        JMP LOOP
.endproc

PALETTE:
    .byte $03, $30, $16, $36
    .byte $03, $30, $16, $36
    .byte $03, $30, $16, $36
    .byte $03, $30, $16, $36

    .byte $03, $30, $16, $36
    .byte $03, $30, $16, $36
    .byte $03, $30, $16, $36
    .byte $03, $30, $16, $36

TITLE_NAM:
    .incbin "data/title.nam.rle"

TILES:
    .incbin "data/chr.chr.rle"
