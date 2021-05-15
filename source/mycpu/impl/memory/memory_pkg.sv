//  Package: memory_pkg
//
`include "mycpu/pkg.svh"
package memory_pkg;
    import common::*;
    import decode_pkg::*;
    //  Group: Parameters
    

    //  Group: Typedefs
    typedef struct packed {
        decoded_instr_t instr;
        word_t rd;
        word_t aluout;
        creg_addr_t writereg;
        word_t hi, lo;
        word_t pcplus4;
    } memory_data_t;
    

    
endpackage: memory_pkg
