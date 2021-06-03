`include "mycpu/interface.svh"
module regfile 
    import common::*;(
    input logic clk, resetn,
    regfile_intf.regfile self
);
    word_t [CREG_NUM-1:1] regs, regs_nxt;

    always_ff @(posedge clk) begin
        if (~resetn) begin
            regs <= '0;
        end else begin
            regs <= regs_nxt;
        end
    end
    
    for (genvar i = 1; i < CREG_NUM; i++) begin
        always_comb begin
            regs_nxt[i] = regs[i];
            if (self.rfwrite.valid && 
                self.rfwrite.id == i) begin
                regs_nxt[i] = self.rfwrite.data;
            end
        end
    end
    
    assign self.src1 = (self.ra1 == '0) ? 32'b0 : regs[self.ra1];
    assign self.src2 = (self.ra2 == '0) ? 32'b0 : regs[self.ra2];
    assign self.original = (self.rfwrite.id == 0) ? 32'b0 : regs[self.rfwrite.id];
endmodule
