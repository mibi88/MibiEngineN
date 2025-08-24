; MibiEngineN - A small engine (not really, it's more a template) to create
; NROM NES games in assembly.
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

.segment "ZEROPAGE"

nam_x:          .res 1
nam_y:          .res 1

nam_coarse_x:   .res 1
nam_coarse_y:   .res 1

scroll:         .res 1
direction:      .res 1

ppu_ctrl:       .res 1
ppu_mask:       .res 1

ppu_addr:       .res 2 ; Little endian for consistency with the 6502 code.

; Set it to 1 to update the palette
pal_update:     .res 1

; Set to 1 when a NMI occurs
nmi:            .res 1

.segment "BSS"

stripe_h:       .res 32 ; Horizontal stripe
stripe_v:       .res 30 ; Vertical stripe

status:         .res 32 ; Status bar

nam_buffer:     .res 256
pal_buffer:     .res $20

.segment "TEXT"

.proc PPU_INIT
        LDX #$00
        STX nam_x
        STX nam_y
        STX ppu_addr ; Set the low byte to $00

        STX ppu_ctrl
        STX ppu_mask

        STX nmi

        STX pal_update

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

        LDX #$00

    PAL_LOAD_LOOP:
        LDA pal_buffer, X
        STA PPUDATA
        INX
        CPX #$20
        BNE PAL_LOAD_LOOP

    PAL_LOAD_SKIP:

        ; Handle 4 way scrolling with status bar

        LDA scroll
        BEQ NAM_LOAD_SKIP

        INX

.if 0
        ; TODO: Allow copying data quickly when changing screen
        ; Load the target address
        LDA ppu_addr+1
        STA PPUADDR
        LDA ppu_addr
        STA PPUADDR
.endif

        ; Copy the nametable data over to the PPU

        ; TODO

    NAM_LOAD_SKIP:

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
