<div>
    <image src="https://raw.githubusercontent.com/74HC138/system020/dev/images/logo_bb.png" alt="logo" style="width:15%;height:15%;display:block;margin-left:auto;margin-right:auto">
</div>

# ABI
## Parameters
Parameters are handed to functions on the stack. The first parameter is pushed on the stack first (forward).
## Return values
The return value of a function is returned in D0 and can thus only be 32bits in size. For bigger return values a structure pointer must either be supplied or returned to/by the function.
## Stack
The caller has to clean the parameters off the stack. The calle has to clean the data that it has pushed on the stack itself.
## Scratch registers
D0, D1, A0 and A1 are used as scratch registers. Any function can modify these without the need to restore them. When calling a function the data in those registers might be lost and has to be pushed on the stack or moved to safe registers (any registers other then the scratch registers). All other registers must be preserved.
## Interrupts
Interrupt handlers have to preserve all registers other then the status register as it is handled by the CPU itself.