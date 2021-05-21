`ifndef __INTERFACE_SVH
`define __INTERFACE_SVH
`include "common.sv"
`include "decode_pkg.sv"
`include "execute_pkg.sv"
`include "fetch_pkg.sv"
`include "forward_pkg.sv"
`include "memory_pkg.sv"
`include "writeback_pkg.sv"
`include "cp0_pkg.sv"
`include "exception_pkg.sv"
`include "translation_pkg.sv"
import common::*;
interface pcselect_intf();
    	logic exception_valid, is_eret, branch_taken, is_jr,
	  is_jump;

    	word_t pcexception, pc_eret, pcbranch, pcjr,
	   pcjump, pcplus4;

    	modport pcselect(input exception_valid, is_eret, branch_taken,
			   is_jr, is_jump,
			   pcexception, pc_eret, pcbranch, pcjr,
			   pcjump, pcplus4);
    	modport fetch(output pcplus4);
    	modport decode(output pcjump, pcbranch, pcjr, branch_taken,
			  is_jr, is_jump);
	modport cp0(output exception_valid, is_eret, pcexception, pc_eret);
endinterface

interface freg_intf(output word_t pc);
    word_t pc_new;
    modport pcselect(output pc_new);
    modport freg(input pc_new, output pc);
    modport fetch(input pc);
endinterface

interface dreg_intf();
    // word_t pcplus4, pcplus4_new;
    import fetch_pkg::*;
    fetch_data_t dataF_new, dataF;
    modport fetch(output dataF_new);
    modport dreg(input dataF_new, output dataF);
    modport decode(input dataF);

endinterface

interface ereg_intf();
    import decode_pkg::*;
    decode_data_t dataD_new, dataD;
    modport decode(output dataD_new);
    modport ereg(input dataD_new, output dataD);
    modport execute(input dataD);

endinterface

interface mreg_intf();
    import execute_pkg::*;
    execute_data_t dataE_new, dataE;
    modport execute(output dataE_new);
    modport mreg(input dataE_new, output dataE);
    modport memory(input dataE);

endinterface

interface wreg_intf();
    import memory_pkg::*;
    memory_data_t dataM_new, dataM;
    modport memory(output dataM_new);
    modport wreg(input dataM_new, output dataM);
    modport writeback(input dataM);

endinterface

interface forward_intf();
    import forward_pkg::*;
    forward_t forwardAD;
    forward_t forwardBD;
    forward_t forwardAE;
    forward_t forwardBE;

    import decode_pkg::*;
    import execute_pkg::*;
    import memory_pkg::*;
    import writeback_pkg::*;
    /* verilator lint_off UNOPTFLAT */
    decode_data_t dataD;
    execute_data_t dataE;
    memory_data_t dataM;
    writeback_data_t dataW;
    /* verilator lint_on UNOPTFLAT */

    modport forward(output forwardAD, forwardBD, forwardAE, forwardBE,
		 input dataD, dataE, dataM, dataW);
    modport decode(input forwardAD, forwardBD, dataE, dataM, dataW,
		   output dataD);
    modport execute(input forwardAE, forwardBE, dataM, dataW,
		    output dataE);
    modport memory(output dataM);
    modport writeback(output dataW);

endinterface

interface regfile_intf(output creg_write_req rfwrite);
    creg_addr_t ra1, ra2;
    word_t src1, src2;
    modport regfile(input ra1, ra2, rfwrite, output src1, src2);
    modport decode(input src1, src2, output ra1, ra2);
    modport writeback(output rfwrite);
endinterface

interface hilo_intf();
    word_t hi, lo;
    hilo_write_req hi_req, lo_req;
    modport hilo(input hi_req, lo_req, output hi, lo);
    modport decode(input hi, lo);
    modport writeback(output hi_req, lo_req);
endinterface

interface hazard_intf(input logic i_data_ok, d_data_ok);
    import common::*;

    logic stallF, stallD, stallE, stallM,
		  flushD, flushE, flushM, flushW;

    import decode_pkg::*;
    import execute_pkg::*;
    import memory_pkg::*;
    import writeback_pkg::*;
    decode_data_t dataD;
    execute_data_t dataE;
    memory_data_t dataM;
    writeback_data_t dataW;
    logic mult_ok;
    logic exception_valid, is_eret;
    logic is_wait;

    modport hazard(output stallF, stallD, stallE, stallM,
			flushD, flushE, flushM, flushW,
		 input dataD, dataE, dataM, dataW, i_data_ok, d_data_ok, mult_ok, is_eret, exception_valid, is_wait);
    modport decode(output dataD, input stallD, flushD);
    modport execute(output dataE, mult_ok);
    modport memory(output dataM, is_wait);
    modport writeback(output dataW);
    modport exception(output is_eret, exception_valid);
endinterface

interface cp0_intf();
	import cp0_pkg::*;
	creg_addr_t ra;
	word_t rd;
	creg_write_req write;
	cp0_status_t cp0_status;
	cp0_cause_t cp0_cause;
    logic [2:0]sel;
    logic is_tlbp, is_tlbr;
	modport cp0(
	    input ra, write, sel, is_tlbp, is_tlbr,
	    output rd, cp0_status, cp0_cause
	);
	modport writeback(
	    output write
	);
	modport decode(
	    input rd, cp0_status, cp0_cause,
	    output ra, sel
	);
    modport memory(
        output is_tlbp, is_tlbr
    );
endinterface

interface exception_intf();
	import exception_pkg::*;
	import cp0_pkg::*;

	logic instr, ri, ov, sys, bp, store, load;
	logic [7:0] interrupt_info;
	exception_t exception_info;
	logic in_delay_slot;
	word_t pc, badvaddr;
	cp0_status_t cp0_status;
	cp0_cause_t cp0_cause;
    	logic is_eret;
	logic timer_interrupt;
    logic i_tlb_invalid; // && req
	logic i_tlb_modified; // && is store
	logic d_tlb_invalid; // && req
	logic d_tlb_modified; // && is store
	logic i_tlb_refill;
	logic d_tlb_refill;
    logic is_store;
	
	modport memory(
		input timer_interrupt, d_tlb_invalid, d_tlb_modified,
        d_tlb_refill,
		output instr, ri, ov, sys, bp, store, load, interrupt_info, in_delay_slot,
			pc, badvaddr, cp0_status, cp0_cause, is_eret,
            i_tlb_invalid, i_tlb_modified, i_tlb_refill, is_store
	);
	modport exception(
		input instr, ri, ov, sys, bp, store, load, interrupt_info, in_delay_slot,
			pc, badvaddr, cp0_status, cp0_cause, is_eret,
            i_tlb_invalid, i_tlb_modified,
            i_tlb_refill,
            d_tlb_invalid, d_tlb_modified,
            d_tlb_refill, is_store,
		output exception_info
	);
	modport cp0(
		input exception_info, is_eret,
		output timer_interrupt
	);
    modport mmu(
        output d_tlb_invalid, d_tlb_modified, d_tlb_refill,
        input is_store
    );

endinterface
`endif
