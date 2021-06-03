`include "mycpu/interface.svh"
module readdata 
    import common::*;(
    input word_t _rd,
    output word_t rd,
    input logic[1:0] addr,
    input mem_t mem_type,
    input word_t original
);
    always_comb begin
        case (mem_type)
            MEM_LB: begin
                case (addr)
                    2'b00: rd = {{24{_rd[7]}}, _rd[7:0]};
                    2'b01: rd = {{24{_rd[15]}}, _rd[15:8]};
                    2'b10: rd = {{24{_rd[23]}}, _rd[23:16]};
                    2'b11: rd = {{24{_rd[31]}}, _rd[31:24]};
                    default: rd = _rd;
                endcase
            end
            MEM_LBU: begin
                case (addr)
                    2'b00: rd = {24'b0, _rd[7:0]};
                    2'b01: rd = {24'b0, _rd[15:8]};
                    2'b10: rd = {24'b0, _rd[23:16]};
                    2'b11: rd = {24'b0, _rd[31:24]};
                    default: rd = _rd;
                endcase
            end
            MEM_LH: begin
                case (addr[1])
                    1'b0: rd = {{16{_rd[15]}}, _rd[15:0]};
                    1'b1: rd = {{16{_rd[31]}}, _rd[31:16]};
                    default: begin
                        rd = _rd;
                    end
                endcase
            end
            MEM_LHU: begin
                case (addr[1])
                    1'b0: rd = {16'b0, _rd[15:0]};
                    1'b1: rd = {16'b0, _rd[31:16]};
                    default: begin
                        rd = _rd;
                    end
                endcase
            end
            MEM_LWL: begin
                unique case(addr)
                    2'b00: begin
                        rd = {_rd[7:0], original[23:0]};
                    end
                    2'b01: begin
                        rd = {_rd[15:0], original[15:0]};
                    end
                    2'b10: begin
                        rd = {_rd[23:0], original[7:0]};
                    end
                    2'b11: begin
                        rd = _rd;
                    end
                    default: begin
                        
                    end
                endcase
            end
            MEM_LWR: begin
                unique case(addr)
                    2'b00: begin
                        rd = _rd;
                    end
                    2'b01: begin
                        rd = {original[31:24], _rd[31:8]};
                    end
                    2'b10: begin
                        rd = {original[31:16], _rd[31:16]};
                    end
                    2'b11: begin
                        rd = {original[31:8], _rd[31:24]};
                    end
                    default: begin
                        
                    end
                endcase
            end
            default: begin
                rd = _rd;
            end
        endcase
    end
endmodule
