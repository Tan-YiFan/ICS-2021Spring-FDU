//  Package: fetch_pkg
//
`ifndef __FETCH_PKG_SV
`define __FETCH_PKG_SV


`include "common.sv"
package fetch_pkg;
    import common::*;
    //  Group: Typedefs
    typedef struct packed {
        word_t pcplus4;
        word_t raw_instr;
    } fetch_data_t;
    

    //  Group: Parameters
    

    
endpackage: fetch_pkg



`endif