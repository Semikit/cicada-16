
.section name="syslib_table" vaddr=0xE000 size=256
	.word empty_data_entry ; default font data
	.word empty_data_entry ; sine wave table
	.word empty_data_entry ; note frequency table
	.word empty_data_entry ; default APU waves
	.word empty_data_entry ; APU percussion presets
	.word empty_func_entry ; initDefaultFont
.section_end

.section name="syslib_data" vaddr=0xE100 size=3840
empty_data_entry:
	.word 0xEEEE
empty_func_entry:
	LDI R0, 0x1111
	RETI
.section_end
