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

.include "region.inc"
.include "ppu.inc"

.segment "HEADER"

.byte "NES"
.byte $1a
.byte $01 ; PRG ROM
.byte $00 ; CHR ROM
.byte %00000000 ; mapper + mirorring
.byte $00
.byte $00
.byte %00000001 ; TV system: PAL
.byte %00110001 ; Bus conflicts, no PRG ram, compatible with both PAL and NTSC
.byte $07 ; CHR-RAM shift count in the lower nibble, i.e.,
          ; 64<<shift_count bytes.
.byte $01, $00, $00, $00

.segment "STARTUP"

.import MAIN
.import NMI
.import IRQ

.proc RESET
        SEI
        CLD

        ; Disable APU IRQ
        LDX #$40
        STX $4017

        LDX #$FF
        TXS

        INX

        STX $2000
        STX $2001

        STX $4010

        BIT $2002

    WAIT_VBLANK1:
        BIT $2002
        BPL WAIT_VBLANK1

        TXA

    CLRMEM:
        STA $0000, X
        STA $0100, X

        STA $0300, X
        STA $0400, X
        STA $0500, X
        STA $0600, X
        STA $0700, X
        INX
        BNE CLRMEM

        LDA #$FF

    CLRSPRITES:
        STA $0200, X
        INX
        BNE CLRSPRITES

    WAIT_VBLANK2:
        BIT $2002
        BPL WAIT_VBLANK2

        ; Checking TV System as described in
        ; https://forums.nesdev.org/viewtopic.php?p=163258#p163258
        LDX #$00
        LDY #$00
    XLOOP:
        INX
        BNE SKIPY ; Branch if X != 0
        INY
    SKIPY:
        ; Check for vblank
        BIT PPUSTATUS ; Waiting for VBLANK.
        BPL XLOOP
        ; Adapt speed to the region
        CPY #$09
        BEQ IS_NTSC
        CPY #$13
        BEQ IS_NTSC
        ; PAL
        LDA #PAL
    IS_NTSC:
        ; NTSC
        LDA #NTSC

        JMP MAIN
.endproc

.segment "VECTORS"
.word NMI
.word RESET
.word IRQ
