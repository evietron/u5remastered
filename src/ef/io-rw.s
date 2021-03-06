; ----------------------------------------------------------------------------
; Copyright 2019 Drunella
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;     http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
; ----------------------------------------------------------------------------

.include "easyflash.i"

.export get_crunched_byte
.export load_prg
.export load_block
.export save_prg_byte
.export erase_prg

.export load_destination_high
.export load_destination_low

.export save_source_low
.export save_source_high

;.import temporary_accumulator

temporary_accumulator = $fb


.segment "IO_CODE2"

    ; --------------------------------------------------------------------
    ; must preserve stat, X, Y
    ; return value in A
    get_crunched_byte:
        php

        ; process, bank in and memory
        lda #$07
        sta $01
        lda #EASYFLASH_LED | EASYFLASH_16K
        sta EASYFLASH_CONTROL ; jsr SetMemConfiguration
        ; read byte
        jsr EAPIReadFlashInc
        sta temporary_accumulator
        ; bank out and memory
        lda #EASYFLASH_KILL
        sta EASYFLASH_CONTROL ; jsr SetMemConfiguration
        lda #$06
        sta $01

        lda temporary_accumulator
        plp        
        rts


    ; --------------------------------------------------------------------
    ; high address byte is set in load_destination_high
    ; low address byte is set in load_destination_low (usually 0)
    ; eapi ptr set
    ; eapi bank set
    ; eapi size not set
    load_block:
        ; set length to 256
        lda #$00
        tax
        ldy #$01
        jsr EAPISetLen

        jmp data_loader


    ; --------------------------------------------------------------------
    ; address is loaded as 1. and 2. byte
    ; eapi ptr set
    ; eapi bank set
    ; eapi size set
    load_prg:
        ; bank in
        lda #$07
        sta $01
        lda #EASYFLASH_LED | EASYFLASH_16K
        sta EASYFLASH_CONTROL ; jsr SetMemConfiguration

        ; read address
        jsr EAPIReadFlashInc
        sta load_destination_low
        jsr EAPIReadFlashInc
        sta load_destination_high

        ; no jmp data_loader as directly below


    ; --------------------------------------------------------------------
    ; loads data to destination
    data_loader:
        ; bank in and memory
        lda #$07
        sta $01
        lda #EASYFLASH_LED | EASYFLASH_16K
        sta EASYFLASH_CONTROL ; jsr SetMemConfiguration

        ; read byte
        jsr EAPIReadFlashInc
        sta temporary_accumulator

        ; bank out and memory
        lda #$06
        sta $01
        lda #EASYFLASH_KILL
        sta EASYFLASH_CONTROL ; jsr SetMemConfiguration

        ; if C set last byte read
        bcs data_loader_finish   

        ; write byte to destination
        lda temporary_accumulator
    load_destination_low = load_destination + 1
    load_destination_high = load_destination + 2
    load_destination:
        sta $ffff
        inc load_destination_low
        bne :+
        inc load_destination_high
    :   bne data_loader

    data_loader_finish:
        jsr $0129  ; sound on
        clc        ; indicate success
        rts


    ; --------------------------------------------------------------------
    ; reads data and writes to flash
    save_prg_byte:
        ; bank out and memory
        lda #$06
        sta $01
        lda #EASYFLASH_KILL
        sta EASYFLASH_CONTROL ; jsr SetMemConfiguration

        ; read byte
    save_source_low = save_source + 1
    save_source_high = save_source + 2
    save_source:
        lda $ffff ; will be modified by code
        sta temporary_accumulator

        ; bank in and memory
        lda #$07
        sta $01
        lda #EASYFLASH_LED | EASYFLASH_16K
        sta EASYFLASH_CONTROL ; jsr SetMemConfiguration

        ; inc address
        inc save_source_low
        bne :+
        inc save_source_high
    
        ; and write to flash
    :   lda temporary_accumulator
        jmp EAPIWriteFlashInc
        ; no rts


    ; --------------------------------------------------------------------
    ; erase_prg
    ; erases the file that fe,ff points to
    ; can only be used for files in low ram
    ; parameters
    ;    fe,ff: address of directory entry
    erase_prg:
        lda #efs_directory::flags
        clc
        adc $fe
        tax        ; low address in x
        lda #$00
        adc $ff
        tay        ; high address in y
        lda #$00
        jmp EAPIWriteFlash ; erase flag of file
        ; no rts
