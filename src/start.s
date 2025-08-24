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

.segment "HEADER"

.byte "NES"
.byte $1a
.byte $01 ; PRG ROM
.byte $01 ; CHR ROM
.byte %00000000 ; mapper + mirorring
.byte $00
.byte $00
.byte %00000001
.byte $00
.byte $00, $01, $00, $00, $00

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

        TXA

        JMP MAIN
.endproc

.segment "CHARS"
.incbin "chr.chr"

.segment "VECTORS"
.word NMI
.word RESET
.word IRQ
