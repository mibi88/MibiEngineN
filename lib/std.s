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

.include "std.inc"

.segment "ZEROPAGE"

ptr:            .res 2

seed:           .res 1
randtmp:        .res 1

.segment "TEXT"

.proc STRLEN
        STA ptr
        STX ptr+1

        LDY #$00

    LOOP:
        INY
        LDA (ptr), Y
        BNE LOOP

    DONE:
        RTS
.endproc

.proc HTOA
        STY ptr
        STX ptr+1

        LDY #$00

        TAX

        ; Get the high nibble
        LSR
        LSR
        LSR
        LSR

        CLC
        ADC #$30

        ; Check if it should be a letter
        CMP #$3A
        BCC NOT_ALPHA2

        ; Make it a letter
        ADC #($41-$3A-1)
    NOT_ALPHA2:

        STA (ptr), Y
        INY

        ; Get the low nibble
        TXA

        AND #$0F

        CLC
        ADC #$30

        ; Check if it should be a letter
        CMP #$3A
        BCC NOT_ALPHA

        ; Make it a letter
        ADC #($41-$3A-1)
    NOT_ALPHA:

        STA (ptr), Y
        INY

        ; Make the string NUL-terminated.
        LDA #$00
        STA (ptr), Y

        RTS
.endproc

.proc RAND
        STX randtmp
        LDX seed
        LDA RAND_DATA, X
        INX
        STX seed
        LDX randtmp

        RTS
.endproc

RAND_DATA:
    .incbin "rand.bin"
