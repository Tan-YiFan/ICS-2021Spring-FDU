`include "mycpu/interface.svh"
module fetch 
    import common::*;
    import fetch_pkg::*;
    import translation_pkg::*;(
    pcselect_intf.fetch pcselect,
    freg_intf.fetch freg,
    dreg_intf.fetch dreg,
    input instr_t raw_instr,
    input tu_op_resp_t tu_op_resp
);
    word_t pc, pcplus4F;
    // word_t raw_instr;

    assign pcplus4F = pc + 32'b100;

    fetch_data_t dataF;
    assign dataF.pcplus4 = pcplus4F;
    assign dataF.raw_instr = raw_instr;
    assign pc = freg.pc;
    assign dreg.dataF_new = dataF;
    assign pcselect.pcplus4 = pcplus4F;
    assign dataF.exception_instr = |pc[1:0];
    assign dataF.i_tlb_invalid = tu_op_resp.i_tlb_invalid;
    assign dataF.i_tlb_modified = tu_op_resp.i_tlb_modified;
    assign dataF.i_tlb_refill = tu_op_resp.i_tlb_refill;
endmodule
