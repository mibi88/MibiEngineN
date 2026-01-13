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

.include "map_data.inc"

.segment "ZEROPAGE"

empty_tiles:    .res 1

.segment "BSS"

tile_usage:     .res 256
map_usage:      .res 32*30/8

empty_tile_idx: .res TILE_STACK_SZ

.segment "TEXT"

.proc LOAD_MAP_USAGE
        LDX #$00

    LOOP:
        LDA NAM_MASK, X
        STA map_usage, X

        INX
        CPX 32*30/8
        BNE LOOP

        RTS
.endproc

.proc LOAD_TILE_USAGE
        LDX #$FF

    LOOP:
        LDA TILE_USAGE, X
        STA tile_usage, X

        DEX
        BNE LOOP

        ; Initialize empty_tiles.
        LDA #TILE_STACK_SZ
        STA empty_tiles

        RTS
.endproc

.proc FIND_EMPTY
        ; NOTE: The first tile is skipped, as it is used in the original
        ; nametable data for empty tiles.

        LDA empty_tiles
        BEQ STACK_FULL
        LDX #63

    LOOP:
        LDA tile_usage, X
        BNE SKIP

        LDY empty_tiles
        DEY
        TXA
        STA empty_tile_idx+1, Y
        STY empty_tiles

    SKIP:
        DEX
        BNE LOOP

    STACK_FULL:
        RTS
.endproc

NAM_MASK:
    .incbin "data/title.nam.bin"

TILE_USAGE:
    ; Load only the data for the first page, as (obviously) only the first page
    ; is used in the nametable, and we don't need this data for the sprites.
    .incbin "data/chr.chr.bin", 0, $100
