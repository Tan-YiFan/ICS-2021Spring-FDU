`include "mycpu/interface.svh"
module multiplier_top 
    import common::*;(
    input logic clk, resetn,
    input word_t a, b,
    output word_t hi, lo,
    input logic is_signed,
    input logic valid
);

    word_t A, B;
    dword_t P;
    // mult_gen_0 mult_gen_0(.CLK(clk), .A, .B, .P);
    multiplier multiplier_inst(.a(A), .b(B), .c(P), .clk, .resetn, .valid);
    assign A = (is_signed & a[31]) ? -a:a;
    assign B = (is_signed & b[31]) ? -b:b;
    assign {hi, lo} = (is_signed & (a[31] ^ b[31])) ? -P:P;

endmodule

