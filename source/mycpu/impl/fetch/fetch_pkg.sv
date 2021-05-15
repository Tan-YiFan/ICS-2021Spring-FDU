//  Package: fetch_pkg
//
`include "mycpu/pkg.svh"
package fetch_pkg;
    import common::*;
    //  Group: Typedefs
    typedef struct packed {
        word_t pcplus4;
        word_t raw_instr;
    } fetch_data_t;
    

    //  Group: Parameters
    

    
endpackage: fetch_pkg
