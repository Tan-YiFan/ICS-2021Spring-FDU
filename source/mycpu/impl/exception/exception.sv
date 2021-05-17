`include "mycpu/interface.svh"
module exception
        import common::*;
        import exception_pkg::*;(
        exception_intf.exception self,
        hazard_intf.exception hazard
);
        logic interrupt_valid;
        assign interrupt_valid = (self.interrupt_info != 0) // request
                       & (self.cp0_status.IE)
                    //    & (~cp0.debug.DM)
                       & (~self.cp0_status.EXL)
                       & (~self.cp0_status.ERL);
        exc_code_t exccode;
        logic exception_valid;
        always_comb begin
                exception_valid = '0;
                exccode = '0;
                if (interrupt_valid) begin
                        exception_valid = 1'b1;
                        exccode = CODE_INT;
                end else if (self.instr) begin
                        exception_valid = 1'b1;
                        exccode = CODE_ADEL;
                end else if (self.ri) begin
                        exception_valid = 1'b1;
                        exccode = CODE_RI;
                end else if (self.ov) begin
                        exception_valid = 1'b1;
                        exccode = CODE_OV;
                end else if (self.sys) begin
                        exception_valid = 1'b1;
                        exccode = CODE_SYS;
                end else if (self.bp) begin
                        exception_valid = 1'b1;
                        exccode = CODE_BP;
                end else if (self.load) begin
                        exception_valid = 1'b1;
                        exccode = CODE_ADEL;
                end else if (self.store) begin
                        exception_valid = 1'b1;
                        exccode = CODE_ADES;
                end
        end
        assign self.exception_info = '{
                valid : exception_valid,
                location: EXC_ENTRY,
                pc: self.pc,
                in_delay_slot: self.in_delay_slot,
                code: exccode,
                badvaddr: self.badvaddr
        };

        assign hazard.is_eret = self.is_eret;
        assign hazard.exception_valid = exception_valid;
endmodule
