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
        logic tlb_refill;
        always_comb begin
                exception_valid = '1;
                exccode = '0;
                tlb_refill = '0;
                priority case (1'b1)
                        interrupt_valid : begin exccode = CODE_INT; tlb_refill = 1'b0;end
                        self.instr : begin exccode = CODE_ADEL;tlb_refill = 1'b0;end
                        self.i_tlb_invalid|self.i_tlb_modified|self.i_tlb_refill : begin exccode = CODE_TLBL;tlb_refill = self.i_tlb_refill;end
                        self.cpu: begin exccode = CODE_CPU;tlb_refill = 1'b0;end
                        self.ri: begin exccode = CODE_RI;tlb_refill = 1'b0;end
                        self.ov: begin exccode = CODE_OV;tlb_refill = 1'b0;end
                        self.bp: begin exccode = CODE_BP;tlb_refill = 1'b0;end
                        self.sys: begin exccode = CODE_SYS;tlb_refill = 1'b0;end
                        self.tr: begin exccode = CODE_TR;tlb_refill = 1'b0;end
                        self.load: begin exccode = CODE_ADEL;tlb_refill = 1'b0;end
                        self.store: begin exccode = CODE_ADES;tlb_refill = 1'b0;end
                        self.d_tlb_invalid|self.d_tlb_refill: begin 
                                exccode = self.is_store? CODE_TLBS : CODE_TLBL; tlb_refill = self.d_tlb_refill;
                        end
                        self.d_tlb_modified: begin exccode = CODE_MOD;tlb_refill = 1'b0;end
                        default: begin
                                exccode = '0;
                                exception_valid = '0;
                                tlb_refill = 1'b0;
                        end
                endcase
                /* if (interrupt_valid) begin
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
                end */
        end
        word_t exc_base;
        assign exc_base = self.cp0_status.BEV ? EXC_BASE_BEV1 : EXC_BASE_BEV0;
        word_t location;
        always_comb begin
                priority case(1'b1)
                        interrupt_valid & self.cp0_cause.IV: location = exc_base + OFFSET_INT;
                        tlb_refill & ~self.cp0_status.EXL: location = exc_base;
                        
                        default: location = exc_base + OFFSET_GENERAL;
                endcase
        end
        
        assign self.exception_info = '{
                valid : exception_valid,
                location: location, //tlb_refill ? REFILL_ENTRY : EXC_ENTRY,
                pc: self.pc,
                in_delay_slot: self.in_delay_slot,
                code: exccode,
                badvaddr: self.badvaddr,
                ce: self.ce
        };

        assign hazard.is_eret = self.is_eret;
        assign hazard.exception_valid = exception_valid;
endmodule
