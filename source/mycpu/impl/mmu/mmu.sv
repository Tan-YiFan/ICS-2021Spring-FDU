`include "mycpu/interface.svh"
`include "common.svh"

module mmu
        import common::*;
        import translation_pkg::*;(
        input logic clk, resetn,
        input tu_op_req_t tu_op_req,
        output tu_op_resp_t tu_op_resp,

        input ibus_req_t ireq_virt,
        output dbus_req_t dreq_virt,
        output ibus_req_t ireq,
        output dbus_req_t dreq,
        exception_intf.mmu exception
);
        tu_addr_req_t  i_req,  d_req;
        tu_addr_resp_t i_resp, d_resp;
        translation translation_inst(
                .clk, .resetn,
                .op_req(tu_op_req), .op_resp(tu_op_resp),
                .k0_uncached(1'b1), .is_store(exception.is_store),
                .i_req, .i_resp,
                .d_req, .d_resp
        );

        assign i_req.vaddr = ireq_virt.addr;
        assign i_req.req = ireq_virt.valid;
        assign d_req.vaddr = dreq_virt.addr;
        assign d_req.req = dreq_virt.valid;

        assign ireq.addr = i_resp.paddr;
        assign ireq.valid = ireq_virt.valid & ~|{tu_op_resp.i_tlb_invalid,
                                        tu_op_resp.i_tlb_modified,
                                        tu_op_resp.i_tlb_refill};
        
        always_comb begin
                dreq = dreq_virt;
                dreq.addr = d_resp.paddr;
                dreq.valid = dreq_virt.valid & ~|{tu_op_resp.d_tlb_invalid,
                                        tu_op_resp.d_tlb_modified,
                                        tu_op_resp.d_tlb_refill};
        end
                                        
        assign exception.d_tlb_invalid = tu_op_resp.d_tlb_invalid;
        assign exception.d_tlb_refill = tu_op_resp.d_tlb_refill;
        assign exception.d_tlb_modified = tu_op_resp.d_tlb_modified;

endmodule
