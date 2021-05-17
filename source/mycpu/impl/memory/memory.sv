`include "mycpu/interface.svh"
module memory
	import common::*;
	import memory_pkg::*; (
	output mem_read_req mread,
	output mem_write_req mwrite/* verilator split_var */,
	input word_t rd,
	mreg_intf.memory mreg,
	wreg_intf.memory wreg,
	forward_intf.memory forward,
	hazard_intf.memory hazard,
	exception_intf.memory exception,
	input logic[5:0] ext_int
);
	logic invalid_addr;
	always_comb begin
		invalid_addr = '0;
		unique case(mreg.dataE.instr.ctl.mem_type)
			MEM_LH, MEM_LHU, MEM_SH: invalid_addr = mreg.dataE.aluout[0];
			MEM_LW, MEM_SW: invalid_addr = |mreg.dataE.aluout[1:0];
			default: begin
				invalid_addr = '0;
			end
		endcase
	end
	
	assign mread.valid = mreg.dataE.instr.ctl.memread & ~invalid_addr;
	assign mread.addr = mreg.dataE.aluout;
	assign mread.size = mreg.dataE.instr.ctl.mem_size;
	
	assign mwrite.valid = mreg.dataE.instr.ctl.memwrite & ~invalid_addr;
	assign mwrite.addr = mreg.dataE.aluout;
	// assign mwrite.data = 
	writedata writedata(
		.addr(mwrite.addr[1:0]), 
		._wd(mreg.dataE.writedata), 
		.mem_type(mreg.dataE.instr.ctl.mem_type), 
		.wd(mwrite.data),
		.strobe(mwrite.strobe)
	);
	assign mwrite.size = mreg.dataE.instr.ctl.mem_size;

	memory_data_t dataM;
	assign dataM.instr = mreg.dataE.instr;
	assign dataM.rd = rd;
	assign dataM.aluout = mreg.dataE.aluout;
	assign dataM.writereg = mreg.dataE.writereg;
	assign dataM.hi = mreg.dataE.hi;
	assign dataM.lo = mreg.dataE.lo;
	assign dataM.pcplus4 = mreg.dataE.pcplus4;
	
	assign wreg.dataM_new = dataM;

	assign forward.dataM = dataM;
	assign hazard.dataM = dataM;

	assign exception.instr = mreg.dataE.exception_instr;
	assign exception.ri = mreg.dataE.exception_ri;
	assign exception.ov = mreg.dataE.exception_of;
	assign exception.sys = mreg.dataE.instr.ctl.is_sys;
	assign exception.bp = mreg.dataE.instr.ctl.is_bp;
	assign exception.store = invalid_addr & mreg.dataE.instr.ctl.memwrite;
	assign exception.load = invalid_addr & mreg.dataE.instr.ctl.memread;
	assign exception.interrupt_info = ({ext_int, 2'b00} | {exception.timer_interrupt, 7'b00} |
					mreg.dataE.cp0_cause.IP) & mreg.dataE.cp0_status.IM;
	assign exception.in_delay_slot = mreg.dataE.in_delay_slot;
	assign exception.pc = mreg.dataE.pcplus4 - 4;
	assign exception.badvaddr = invalid_addr ? mreg.dataE.aluout : exception.pc;
	assign exception.cp0_status = mreg.dataE.cp0_status;
	assign exception.cp0_cause = mreg.dataE.cp0_cause;
	assign exception.is_eret = mreg.dataE.instr.ctl.is_eret;
endmodule
