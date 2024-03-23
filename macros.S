# A macro to call a function external to a .S file.
# It assumes there is a dword in the .text section
# with a _addr suffix, filled in with the needed
# address by the linker.
.MACRO excall register, prefix, suffix=_addr
    la \register, \prefix\suffix
    ld \register, 0(\register)
    jalr \register
.ENDM

