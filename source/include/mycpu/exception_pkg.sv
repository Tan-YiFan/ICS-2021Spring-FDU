`ifndef __EXCEPTION_PKG_SV
`define __EXCEPTION_PKG_SV

`include "common.sv"

package exception_pkg;
	import common::*;

parameter CODE_INT  = 5'h00;  // Interrupt
parameter CODE_MOD  = 5'h01;  // TLB modification exception
parameter CODE_TLBL = 5'h02;  // TLB exception (load or instruction fetch)
parameter CODE_TLBS = 5'h03;  // TLB exception (store)
parameter CODE_ADEL = 5'h04;  // Address exception (load or instruction fetch)
parameter CODE_ADES = 5'h05;  // Address exception (store)
parameter CODE_SYS  = 5'h08;  // Syscall
parameter CODE_BP   = 5'h09;  // Breakpoint
parameter CODE_RI   = 5'h0a;  // Reserved Instruction exception
parameter CODE_CPU  = 5'h0b;  // CoProcesser Unusable exception
parameter CODE_OV   = 5'h0c;  // OVerflow
parameter CODE_TR   = 5'h0d;  // TRap

typedef logic[4:0] exc_code_t;
typedef struct packed {
	logic valid;
	word_t location;
	word_t pc;
	logic in_delay_slot;
	exc_code_t code;
	word_t badvaddr;
} exception_t;

parameter EXC_ENTRY = 32'hbfc0_0380;

endpackage

`endif
