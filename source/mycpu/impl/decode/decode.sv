`include "mycpu/interface.svh"
module decode
    import common::*; 
    import decode_pkg::*;
    import forward_pkg::*;(
    input logic clk, resetn,
    pcselect_intf.decode pcselect,
    dreg_intf.decode dreg,
    ereg_intf.decode ereg,
    regfile_intf.decode regfile,
    forward_intf.decode forward,
    hazard_intf.decode hazard,
    hilo_intf.decode hilo,
    cp0_intf.decode cp0,
    input logic is_usermode
);
    decode_data_t dataD /* verilator split_var */;

    word_t raw_instr;
    assign raw_instr = dreg.dataF.raw_instr;
    decoded_instr_t instr;
    
    decoder decoder_inst(
        .raw_instr,
        .instr,
        .pcplus4(dreg.dataF.pcplus4),
        .is_usermode
    );

    logic in_delay_slot;
    always_ff @(posedge clk) begin
        if (~resetn | hazard.flushD) begin
            in_delay_slot <= '0;
        end else if (~hazard.stallD) begin
            in_delay_slot <= 
            instr.ctl.jump | instr.ctl.branch;
        end
    end
    
    logic branch_taken;
    word_t rd1, rd2;
    always_comb begin : forwardAD
        unique case(forward.forwardAD)
            FORWARDM: begin
                rd1 = forward.dataM.aluout;
            end
            FORWARDW: begin
                rd1 = forward.dataW.result;
            end
            default: begin
                rd1 = regfile.src1;
                if (instr.op == MFHI) begin
                    rd1 = hilo.hi;
                end
                if (instr.op == MFLO) begin
                    rd1 = hilo.lo;
                end
                if (instr.op == MFC0) begin
                    rd1 = cp0.rd;
                end
            end
        endcase
    end : forwardAD
    always_comb begin : forwardBD
        unique case(forward.forwardBD)
            FORWARDM: begin
                rd2 = forward.dataM.aluout;
            end
            FORWARDW: begin
                rd2 = forward.dataW.result;
            end
            default: begin
                rd2 = regfile.src2;
            end
        endcase
    end : forwardBD
    always_comb begin : branch
        branch_taken = '0;
        if (instr.ctl.branch) begin
            unique case(instr.ctl.branch_type)
                T_BEQ: begin
                    branch_taken = rd1 == rd2;
                end
                T_BNE: begin
                    branch_taken = rd1 != rd2;
                end
                T_BGEZ: begin
                    branch_taken = ~rd1[31];
                end 
                T_BLTZ: begin
                    branch_taken = rd1[31];
                end
                T_BGTZ: begin
                    branch_taken = ~rd1[31] && (rd1 != '0);
                end
                T_BLEZ: begin
                    branch_taken = rd1[31] || (rd1 == '0);
                end
                default: begin
                    branch_taken = '0;
                end
            endcase
        end
        
    end
    
    assign dataD.instr = instr;
    assign dataD.in_delay_slot = in_delay_slot;
    assign dataD.pcplus4 = dreg.dataF.pcplus4;
    assign dataD.rd1 = rd1;
    assign dataD.rd2 = rd2;
    assign dataD.exception_instr = dreg.dataF.exception_instr;
    assign dataD.exception_ri = dataD.instr.exception_ri;
    assign dataD.exception_cpu = dataD.instr.exception_cpu;
    assign dataD.cp0_status = cp0.cp0_status;
    assign dataD.cp0_cause = cp0.cp0_cause;
    assign dataD.hi = hilo.hi;
    assign dataD.lo = hilo.lo;

    assign ereg.dataD_new = dataD;

    assign pcselect.pcjump = {dreg.dataF.pcplus4[31:28], raw_instr[25:0], 2'b0};
    assign pcselect.pcjr = rd1;
    assign pcselect.pcbranch = dreg.dataF.pcplus4 + {{14{raw_instr[15]}}, raw_instr[15:0], 2'b00};
    assign pcselect.branch_taken = branch_taken;
    assign pcselect.is_jr = instr.ctl.jr;
    assign pcselect.is_jump = instr.ctl.jump;

    assign regfile.ra1 = instr.srca;
    assign regfile.ra2 = instr.srcb;

    assign forward.dataD = dataD;
    assign hazard.dataD = dataD;
    assign cp0.ra = raw_instr[15:11];
    assign cp0.sel = raw_instr[2:0];

    assign dataD.i_tlb_invalid = dreg.dataF.i_tlb_invalid;
    assign dataD.i_tlb_modified = dreg.dataF.i_tlb_modified;
    assign dataD.i_tlb_refill = dreg.dataF.i_tlb_refill;
endmodule
