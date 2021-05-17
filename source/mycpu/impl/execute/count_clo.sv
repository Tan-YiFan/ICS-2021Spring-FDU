`include "mycpu/interface.svh"
module count_clo
        import common::*; (
        input word_t in,
        output word_t out
);
        always_comb begin
                out = 32;
                for (int i = 31; i >= 0; i--) begin
                        if (~in[i]) begin
                                out = i;
                                break;
                        end
                end
        end
        
endmodule
