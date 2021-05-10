`include "common.svh"

module DCache #(
    parameter LINE_SIZE = 64,
    parameter SET_NUM = 4,
    parameter ASSOCIATIVITY = 4
)(
    input logic clk, resetn,

    input  dbus_req_t  dreq,
    output dbus_resp_t dresp,
    output cbus_req_t  dcreq,
    input  cbus_resp_t dcresp
);
    /**
     * TODO (Lab3) your code here :)
     */

    localparam OFFSET_LEN = $clog2(LINE_SIZE) + 3;
    localparam OFFSET_LEN_WORD = OFFSET_LEN - 2;
    localparam SET_LEN = $clog2(SET_NUM);
    localparam TAG_LEN = 32 - OFFSET_LEN - SET_LEN;
    localparam POSITION_LEN = $clog2(ASSOCIATIVITY);
    localparam WORDS_IN_LINE = LINE >> 2;
    
    localparam type state_t = enum i2 {INIT, FETCH, WRITEBACK};
    localparam type index_t = logic[SET_LEN-1:0];
    localparam type tag_t = logic[TAG_LEN-1:0];
    localparam type position_t = logic[POSITION_LEN-1:0];
    localparam type aligned_offset_t = logic[OFFSET_LEN_WORD-1:0];
    localparam type offset_t = logic[OFFSET_LEN-1:0];
    localparam type meta_t = struct packed {
        logic valid;
        logic dirty;
        tag_t tag;
    };
    localparam type meta_set_t = meta_t [ASSOCIATIVITY-1:0];
    localparam type cache_line_t = word_t [WORDS_IN_LINE-1:0];
    localparam type cache_set_t = cache_line_t[SET_NUM-1:0];
    localparam type divided_addr_t = struct packed {
        tag_t tag;
        index_t index;
        aligned_offset_t offset;
        i2 zeros;
    };

    meta_set_t [SET_NUM-1:0] meta;
    cache_set_t [SET_NUM-1:0] data;
    state_t state, state_nxt;

    divided_addr_t divided_input;
    assign divided_input = divided_addr_t'(dreq.addr);

    meta_set_t meta_set_chosen;
    assign meta_set_chosen = meta[divided_input.index];

    cache_set_t data_chosen;
    assign data_chosen = data[divided_input.index];

    i1 hit;
    index_t hit_set_id;
    always_comb begin : get_hit_status
        hit = '0;
        hit_set_id = '0;
        for (int i = 0; i < ASSOCIATIVITY; i++) begin
            if (meta_set_chosen[i].tag == divided_input.tag && 
                meta_set_chosen[i].valid) begin
                    hit = 1'b1;
                    hit_set_id = index_t'(i);
                break;
            end
        end
    end
    
    offset_t counter, counter_nxt;
    always_comb begin : generate_outputs
        state_nxt = state;
        counter_nxt = counter;
        dresp = '0;
        dcreq = '0;
        unique case(state)
            INIT: begin
                if (dreq.valid) begin
                    if (~hit) begin
                        
                    end else begin
                        dresp.addr_ok = '1;
                        dresp.data_ok = '1;
                        dresp.data = data_chosen[divided_input.offset];
                    end
                end
            end
            READ: begin
                dcreq.valid = 1'b1;
                dcreq.size = dreq.size;
                dcreq.addr = {divided_input.tag, divided_input.index, counter, 2'b00};

                dcreq.len = MLEN16;
                if (dcresp.ready) begin
                    counter_nxt = counter + 4;
                end
                if (dcresp.last) begin
                    state_nxt = INIT;
                end
            end
            WRITE: begin
                dcreq.valid = 1'b1;
                dcreq.is_write = 1'b1;
                dcreq.size = MSIZE4;
                dcreq.addr = {divided_input.tag, divided_input.index, counter, 2'b00};
                dcreq.strobe = '1;
                dcreq.data = data_chosen[??];
                dcreq.len = MLEN16;

                if (dcresp.ready) begin
                    counter_nxt = counter + 4;
                end
                if (dcresp.last) begin
                    state_nxt = READ;
                end
            end
            default: begin
                
            end
        endcase
    end
    

    always_ff @(posedge clk) begin
        if (~resetn) begin
            state <= state_t'('0);
            counter <= '0;
        end else begin
            state <= state_nxt;
            counter <= counter_nxt;
        end
    end
    
`if 0
    // remove following lines when you start
    assign {dresp, dcreq} = '0;
    `UNUSED_OK({clk, resetn, dreq, dcresp});
`endif
endmodule
