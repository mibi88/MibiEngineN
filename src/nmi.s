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

.export NMI

.include "ppu.inc"
.include "nmi.inc"
.include "tile_update.inc"

.segment "ZEROPAGE"

nam_cur:        .res 1 ; The cursor in the nametable buffer (initialized to $FF
                       ; and decremented for each byte.
nam_max:        .res 1 ; The maximum number of bytes that can be loaded at once

nam_x:          .res 1
nam_y:          .res 1

ppu_ctrl:       .res 1
ppu_mask:       .res 1

ppu_addr:       .res 2 ; Little endian for consistency with the 6502 code.

; Set it to 1 to update the palette
pal_update:     .res 1

; Set to 1 when a NMI occurs
nmi:            .res 1

.segment "BSS"

nam_buffer:     .res 256
pal_buffer:     .res $20

.segment "TEXT"

.proc PPU_INIT
        ; TODO: Tweak this limit once the NMI handler is finished
        LDA #$40
        STA nam_max

        LDX #$00
        STX nam_x
        STX nam_y
        STX ppu_addr ; Set the low byte to $00

        STX ppu_ctrl
        STX ppu_mask

        STX nmi

        STX pal_update

        DEX
        STX nam_cur

        LDA #$20
        STA ppu_addr+1

        RTS
.endproc

.proc NMI
        PHA
        TXA
        PHA
        TYA
        PHA

        ; Make sure w is cleared
        BIT PPUSTATUS

        ; Perform OAM DMA
        LDA #$02
        STA OAMDMA

        LDA #$01
        STA nmi

        ; Disable rendering

        LDA #$00
        STA PPUCTRL
        STA PPUMASK

        ; PALETTE LOADING CODE

        LDA pal_update
        BEQ PAL_LOAD_SKIP

        ; Load the target address
        LDA #$3F
        STA PPUADDR
        LDA #$00
        STA PPUADDR

        ; Load the palette

        LDX #($100-$20)

    PAL_LOAD_LOOP:
        LDA pal_buffer-($100-$20), X
        STA PPUDATA
        INX
        BNE PAL_LOAD_LOOP

        STX pal_update

    PAL_LOAD_SKIP:

        ; NAMETABLE LOADING CODE

        LDX nam_cur
        BEQ NAM_LOAD_SKIP

        LDX #$00

        ; Load the target address
        LDA ppu_addr+1
        STA PPUADDR
        LDA ppu_addr
        STA PPUADDR

        ; Copy the nametable data over to the PPU

    NAM_LOAD_LOOP:
        LDA nam_buffer, X
        STA PPUDATA
        INX
        CPX nam_cur
        BNE NAM_LOAD_LOOP

        LDA nam_cur
        CLC
        ADC ppu_addr
        STA ppu_addr
        LDA ppu_addr+1
        ADC #$00
        STA ppu_addr+1

        LDA #$00
        STA nam_cur
        BEQ END ; Branch always taken.

        ; Do not edit tiles if nametable data was already loaded, as it may
        ; take too many cycles.
    NAM_LOAD_SKIP:
        JSR UPDATE_TILES

    END:
        ; Write to PPUCTRL and PPUMASK

        LDA ppu_ctrl
        ; Keep one from setting the slave bit.
        AND #%10111111
        STA PPUCTRL
        LDA ppu_mask
        STA PPUMASK

        ; Set the scrolling

        LDA nam_x
        STA PPUSCROLL
        LDA nam_y
        STA PPUSCROLL

        PLA
        TAY
        PLA
        TAX
        PLA

        RTI
.endproc
