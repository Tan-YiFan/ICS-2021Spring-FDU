`ifndef __FORWARD_PKG_SV
`define __FORWARD_PKG_SV


`include "common.sv"
package forward_pkg;
    import common::*;
    typedef enum logic [1:0] {
        NOFORWARD,
        FORWARDM,
        FORWARDW
    } forward_t;
    
endpackage



`endif