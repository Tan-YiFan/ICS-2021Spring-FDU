`include "mycpu/interface.svh"
module execute 
    import common::*;
    import execute_pkg::*;
    import forward_pkg::*;(
    input logic clk, resetn,
    ereg_intf.execute ereg,
    mreg_intf.execute mreg,
    forward_intf.execute forward,
    hazard_intf.execute hazard
);
    
    logic exception_of;
    word_t aluout;
    word_t alusrca, alusrcb, writedata;
    always_comb begin : forwardAE
        unique case(forward.forwardAE)
            FORWARDM: begin
                alusrca = forward.dataM.aluout;
            end
            default: begin
                alusrca = ereg.dataD.rd1;
            end
        endcase
    end : forwardAE
    always_comb begin : forwardBE
        unique case(forward.forwardBE)
            FORWARDM: begin
                writedata = forward.dataM.aluout;
            end
            default: begin
                writedata = ereg.dataD.rd2;
            end
        endcase
    end : forwardBE
    assign alusrcb = ereg.dataD.instr.ctl.alusrc == REGB ? 
                     writedata : ereg.dataD.instr.imm;
    alu alu_inst (
        .a(~ereg.dataD.instr.ctl.shamt_valid ? alusrca : ereg.dataD.instr.imm),
        .b(alusrcb),
        .c(aluout),
        .alufunc(ereg.dataD.instr.ctl.alufunc),
        .exception_of
    );
    word_t hi, lo;
    multicycle multicycle_inst (
        .clk, .resetn,
        .a(alusrca),
        .b(alusrcb),
        .is_multdiv(ereg.dataD.instr.ctl.is_multdiv),
        .flushE(1'b0),
        .multicycle_type(ereg.dataD.instr.ctl.multicycle_type),
        .hi,
        .lo,
        .ok(hazard.mult_ok)
    );
    execute_data_t dataE /* verilator split_var */;
    // assign dataE.instr = ereg.dataD.instr;
    always_comb begin
        dataE.instr = ereg.dataD.instr;
        if ((dataE.instr.ctl.is_movn && alusrcb == '0) || 
        (dataE.instr.ctl.is_movz && alusrcb != '0)) begin
            dataE.instr.ctl.regwrite = '0;
        end
    end
    
    assign dataE.exception_instr = ereg.dataD.exception_instr;
    assign dataE.exception_ri = ereg.dataD.instr.exception_ri;
    assign dataE.exception_of = exception_of;
    assign dataE.exception_cpu = ereg.dataD.instr.exception_cpu;
    assign dataE.aluout = (ereg.dataD.instr.ctl.is_link) ? (ereg.dataD.pcplus4 + 4) : (
        ereg.dataD.instr.ctl.is_mul ? lo : aluout
    );
    assign dataE.writereg = ereg.dataD.instr.dest;
    assign dataE.writedata = writedata;
    always_comb begin
        unique case(ereg.dataD.instr.ctl.multicycle_type)
            M_MADD, M_MADDU: {dataE.hi, dataE.lo} = {ereg.dataD.hi, ereg.dataD.lo} + {hi, lo};
            M_MSUB, M_MSUBU: {dataE.hi, dataE.lo} = {ereg.dataD.hi, ereg.dataD.lo} - {hi, lo};
            default: begin
                {dataE.hi, dataE.lo} = {hi, lo};
            end
        endcase
    end
    
    // assign dataE.hi = hi;
    // assign dataE.lo = lo;
    assign dataE.pcplus4 = ereg.dataD.pcplus4;
    assign dataE.in_delay_slot = ereg.dataD.in_delay_slot;
    assign dataE.cp0_cause = ereg.dataD.cp0_cause;
    assign dataE.cp0_status = ereg.dataD.cp0_status;
    assign dataE.i_tlb_invalid = ereg.dataD.i_tlb_invalid;
    assign dataE.i_tlb_modified = ereg.dataD.i_tlb_modified;
    assign dataE.i_tlb_refill = ereg.dataD.i_tlb_refill;
    logic tr;
    assign dataE.exception_tr = tr;
    always_comb begin
        tr = '0;
        if (ereg.dataD.instr.ctl.is_trap) begin
            unique case(ereg.dataD.instr.ctl.trap_type)
                TRAP_TEQ: tr = alusrca == alusrcb;
                TRAP_TNE: tr = alusrca != alusrcb;
                TRAP_TLT: tr = signed'(alusrca) < signed'(alusrcb);
                TRAP_TLTU: tr = alusrca < alusrcb;
                TRAP_TGE: tr = signed'(alusrca) > signed'(alusrcb);
                TRAP_TGEU: tr = alusrca > alusrcb;
                default: begin
                    
                end
            endcase
        end
    end
    
    assign mreg.dataE_new = dataE;

    assign hazard.dataE = dataE;
    assign forward.dataE = dataE;
endmodule
