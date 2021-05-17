`include "mycpu/interface.svh"
module cp0 
        import common::*;
        import cp0_pkg::*;
        import exception_pkg::*;(
        input logic clk, resetn,
        cp0_intf.cp0 self,
        pcselect_intf.cp0 pcselect,
        exception_intf.cp0 exception
);
        cp0_regs_t cp0, cp0_nxt;

        logic count_switch;
        always_ff @(posedge clk) begin
                if (~resetn) begin
                        count_switch <= '0;
                end else begin
                        count_switch <= ~count_switch;
                end
        end
        exception_t exception_info;
        assign exception_info = exception.exception_info;
        always_comb begin
                cp0_nxt = cp0;
                cp0_nxt.count = cp0_nxt.count + {31'b0, count_switch};
                if (self.write.valid) begin
                        unique case(self.write.id)
                                5'd9: cp0_nxt.count = self.write.data;
                                5'd11: cp0_nxt.compare = self.write.data;
                                5'd12: begin
                                        cp0_nxt.status.IE = self.write.data[0];
                                        cp0_nxt.status.EXL = self.write.data[1];
                                        cp0_nxt.status.IM = self.write.data[15:8];
                                end
                                5'd13: begin
                                        cp0_nxt.cause.IP[1:0] = self.write.data[9:8];
                                end
                                5'd14: cp0_nxt.epc = self.write.data;
                                default: begin
                                        
                                end
                        endcase
                end
                
                if (exception_info.valid) begin
                        if (~cp0.status.EXL) begin
                                if (exception_info.in_delay_slot) begin
                                    cp0_nxt.cause.BD = 1'b1;
                                    cp0_nxt.epc = exception_info.pc - 32'd4;
                                end else begin
                                    cp0_nxt.cause.BD = 1'b0;
                                    cp0_nxt.epc = exception_info.pc;
                                end
                            end
                
                            cp0_nxt.cause.exccode = exception_info.code;
                
                            cp0_nxt.status.EXL = 1'b1;
                            if (exception_info.code == CODE_ADEL || exception_info.code == CODE_ADES) begin
                                cp0_nxt.badvaddr = exception_info.badvaddr;
                                if (timer_interrupt) begin
                                        cp0_nxt.cause.TI = '1;
                                end else begin
                                        cp0_nxt.cause.TI = '0;
                                end
                        end
                end
                if (exception.is_eret) begin
                        if (cp0.status.ERL) begin
                                cp0_nxt.status.ERL = 1'b0;
                        end else begin
                                cp0_nxt.status.EXL = 1'b0;
                        end
                end
        end
        
        always_ff @(posedge clk) begin
                if (~resetn) begin
                        cp0 <= '0;
                        cp0.status.BEV <= '1;
                        cp0.prid <= 32'h4220;
                        cp0.config_ <= 32'h80000080;
                        cp0.config_1 <= 32'b00_11111_000_101_111_000_101_011_0000000;
                end else begin
                        cp0 <= cp0_nxt;
                end
        end
        always_comb begin
                if (self.sel != '0) begin
                        self.rd = cp0.config_1;
                end else
                unique case(self.ra)
                        5'd0:   self.rd = cp0.index;
                        5'd1:   self.rd = cp0.random;
                        5'd2:   self.rd = cp0.entrylo0;
                        5'd3:   self.rd = cp0.entrylo1;
                        5'd4:   self.rd = cp0.context_;
                        5'd6:   self.rd = cp0.wired;
                        5'd8:   self.rd = cp0.badvaddr;
                        5'd9:   self.rd = cp0.count;
                        5'd10:  self.rd = cp0.entryhi;
                        5'd11:  self.rd = cp0.compare;
                        5'd12:  self.rd = cp0.status;
                        5'd13:  self.rd = cp0.cause;
                        5'd14:  self.rd = cp0.epc;
                        5'd15:  self.rd = cp0.prid;
                        5'd16:  self.rd = cp0.config_;
                        default: self.rd = '0;
                endcase
        end
        
        assign self.cp0_status = cp0.status;
        assign self.cp0_cause = cp0.cause;

        logic timer_interrupt;
        always_ff @(posedge clk) begin
                if (~resetn) begin
                        timer_interrupt <= '0;
                end else if (cp0.compare != '0 && cp0.compare == cp0.count) begin
                        timer_interrupt <= '1;
                end else if (self.write.valid && self.write.id == 5'd11) begin
                        timer_interrupt <= '0;
                end
        end
        
        assign exception.timer_interrupt = timer_interrupt;
        assign pcselect.exception_valid = exception_info.valid;
        assign pcselect.pc_eret = cp0.epc;
        assign pcselect.pcexception = exception_info.location;
        assign pcselect.is_eret = exception.is_eret;
        
endmodule
