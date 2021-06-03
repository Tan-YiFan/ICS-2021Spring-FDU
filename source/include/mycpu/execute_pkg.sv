//  Package: execute_pkg
//
`ifndef __EXECUTE_PKG_SV
`define __EXECUTE_PKG_SV

`include "common.sv"
`include "decode_pkg.sv"
`include "cp0_pkg.sv"
package execute_pkg;
    import common::*;
    import decode_pkg::*;
    import cp0_pkg::*;
    //  Group: Parameters
    

    //  Group: Typedefs
    typedef struct packed {
        decoded_instr_t instr;
        logic exception_instr, exception_ri, exception_of;
        word_t aluout;
        creg_addr_t writereg;
        word_t writedata;
        word_t hi, lo;
        word_t pcplus4;
        logic in_delay_slot;
        cp0_cause_t cp0_cause;
        cp0_status_t cp0_status;
        logic i_tlb_invalid;
        logic i_tlb_modified;
        logic i_tlb_refill;
        logic exception_cpu;
        logic exception_tr;
    } execute_data_t;
    

    
endpackage: execute_pkg



`endif