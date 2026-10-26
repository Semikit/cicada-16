; ==============================================================================
; boot_audio.asm - Boot chime
; ==============================================================================
; A three-note arpeggio (C5, G5, C6) on the two pulse channels, started when
; the logo reaches its display position and keyed off when the exit fade
; begins. Audio ID 0x01 (silent) skips it; everything else plays the default
; chime (0xFF "random" currently resolves to the default as well).
;
; Pulse frequency: FREQ_REG = 65536 - 2097152 / (64 * f)
; ==============================================================================

.define CHIME_NOTE1_FREQ    0xFFC1      ; C5 (523 Hz)
.define CHIME_NOTE2_FREQ    0xFFD6      ; G5 (784 Hz)
.define CHIME_NOTE3_FREQ    0xFFE1      ; C6 (1047 Hz)
.define CHIME_ADSR_AD       0x04        ; attack 0 (fast), decay 4
.define CHIME_ADSR_SR       0xA6        ; sustain 10, release 6
.define CHIME_CTRL_ON       0xD0        ; KEY_ON, 50% duty, RETRIGGER
.define CHIME_CTRL_OFF      0x40        ; key off (release), 50% duty
.define CHIME_STEP_FRAMES   8           ; frames between notes
.define AUDIO_STEP_SILENT   0xFF
.define AUDIO_STEP_DONE     4

; ==============================================================================
; audio_init
; Configure the mixer and envelopes; decide whether to play at all.
; ==============================================================================
audio_init:
    LDI R0, 0
    ST.b (ANIM_AUDIO_TIMER), R0
    ST.b (ANIM_AUDIO_STEP), R0

    LD.b R0, (ANIM_AUDIO_ID)
    CMPI R0, AUDIO_SILENT_ID
    JRNZ ai_enable
    LDI R0, AUDIO_STEP_SILENT
    ST.b (ANIM_AUDIO_STEP), R0
    RET

ai_enable:
    LDI R0, CHIME_ADSR_AD
    ST.b (APU_CH0_ADSR_L), R0
    ST.b (APU_CH1_ADSR_L), R0
    LDI R0, CHIME_ADSR_SR
    ST.b (APU_CH0_ADSR_H), R0
    ST.b (APU_CH1_ADSR_H), R0

    LDI R0, 0xFF                    ; full volume, centre panning
    ST.b (APU_MIX_VOL), R0
    ST.b (APU_CH0_OUT), R0
    ST.b (APU_CH1_OUT), R0

    LDI R0, 0x83                    ; APU enable, channels 0 and 1
    ST.b (APU_MIX_CTRL), R0
    RET

; ==============================================================================
; audio_tick
; Called once per frame from animation_tick, after the phase logic.
; ==============================================================================
audio_tick:
    LD.b R0, (ANIM_AUDIO_STEP)
    CMPI R0, AUDIO_STEP_DONE
    JRNC at_done                    ; finished or silent

    ; key everything off as soon as the exit fade starts
    LD.b R1, (ANIM_PHASE)
    CMPI R1, PHASE_EXIT
    JRZ at_key_off

    CMPI R0, 0
    JRNZ at_running

    ; step 0: wait for the logo to settle (display phase), then note 1
    CMPI R1, PHASE_DISPLAY
    JRNZ at_done
    LDI R0, CHIME_NOTE1_FREQ
    ST (APU_CH0_FREQ_L), R0
    LDI R0, CHIME_CTRL_ON
    ST.b (APU_CH0_CTRL), R0
    LDI R0, 1
    JR at_next_step

at_running:
    LD.b R1, (ANIM_AUDIO_TIMER)
    DEC R1
    ST.b (ANIM_AUDIO_TIMER), R1
    JRNZ at_done

    CMPI R0, 1
    JRNZ at_step2
    LDI R0, CHIME_NOTE2_FREQ        ; step 1 -> note 2 on channel 1
    ST (APU_CH1_FREQ_L), R0
    LDI R0, CHIME_CTRL_ON
    ST.b (APU_CH1_CTRL), R0
    LDI R0, 2
    JR at_next_step

at_step2:
    CMPI R0, 2
    JRNZ at_done
    LDI R0, CHIME_NOTE3_FREQ        ; step 2 -> note 3 on channel 0 (retrigger)
    ST (APU_CH0_FREQ_L), R0
    LDI R0, CHIME_CTRL_ON
    ST.b (APU_CH0_CTRL), R0
    LDI R0, 3

at_next_step:
    ST.b (ANIM_AUDIO_STEP), R0
    LDI R0, CHIME_STEP_FRAMES
    ST.b (ANIM_AUDIO_TIMER), R0
    RET

at_key_off:
    LDI R0, CHIME_CTRL_OFF
    ST.b (APU_CH0_CTRL), R0
    ST.b (APU_CH1_CTRL), R0
    LDI R0, AUDIO_STEP_DONE
    ST.b (ANIM_AUDIO_STEP), R0
at_done:
    RET

; ==============================================================================
; audio_shutdown
; Silence the APU before handing off to the cartridge.
; ==============================================================================
audio_shutdown:
    LDI R0, 0
    ST.b (APU_CH0_CTRL), R0
    ST.b (APU_CH1_CTRL), R0
    ST.b (APU_MIX_CTRL), R0
    RET
