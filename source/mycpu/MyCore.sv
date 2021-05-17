`include "common.svh"
`include "mycpu/interface.svh"

module MyCore 
    import common::*;
    import fetch_pkg::*;
    import decode_pkg::*;
    import execute_pkg::*;
    import memory_pkg::*;
    import writeback_pkg::*;(
    input logic clk, resetn,

    output ibus_req_t  ireq,
    input  ibus_resp_t iresp,
    output dbus_req_t  dreq,
    input  dbus_resp_t dresp,
    input logic[5:0] ext_int
    /* verilator tracing_on */
);
    /**
     * TODO (Lab1) your code here :)
     */

/*     always_ff @(posedge clk)
    if (resetn) begin
        // AHA!
    end else begin
        // reset
        // NOTE: if resetn is X, it will be evaluated to false.
    end

    // remove following lines when you start
    assign ireq = '0;
    assign dreq = '0;
    `UNUSED_OK({iresp, dresp}); */
    /* assign ireq = '0;
    assign dreq = '0;
    `UNUSED_OK({iresp, dresp}); */
    word_t wb_pc/* verilator public_flat_rd */;
    mem_read_req mread;
    mem_write_req mwrite;
    creg_write_req rfwrite;
    creg_addr_t wb_id/* verilator public_flat_rd */;
    assign wb_id = rfwrite.id;
    word_t wb_value/* verilator public_flat_rd */;
    assign wb_value = rfwrite.data;
    logic wb_en/* verilator public_flat_rd */;
    assign wb_en = rfwrite.valid;
    assign ireq.valid = ~fetch.dataF.exception_instr;
    assign dreq.valid = mread.valid | mwrite.valid;
    assign dreq.size = msize_t'(mwrite.valid ? mwrite.size : mread.size);
    assign dreq.data = mwrite.data;
    assign dreq.strobe = mwrite.strobe;
    assign dreq.addr = mwrite.valid ? mwrite.addr : mread.addr;

    logic i_data_ok, d_data_ok;
    assign i_data_ok = iresp.data_ok | ~ireq.valid;
    assign d_data_ok = dresp.data_ok | ~dreq.valid;
    pcselect_intf pcselect_intf();
    freg_intf freg_intf(.pc(ireq.addr));
    dreg_intf dreg_intf();
    ereg_intf ereg_intf();
    mreg_intf mreg_intf();
    wreg_intf wreg_intf();
    regfile_intf regfile_intf(.rfwrite);
    hilo_intf hilo_intf();
    // cp0_intf cp0_intf();
    forward_intf forward_intf();
    hazard_intf hazard_intf(.i_data_ok, .d_data_ok);
    exception_intf exception_intf();
    cp0_intf cp0_intf();
    // exception_intf exception_intf(.ext_int);

    // instances
    pcselect pcselect(
        .self(pcselect_intf.pcselect),
        .freg(freg_intf.pcselect)
    );
    fetch fetch(
        .pcselect(pcselect_intf.fetch),
        .freg(freg_intf.fetch),
        .dreg(dreg_intf.fetch),
        .raw_instr(iresp.data)
    );
    decode decode(
        .clk, .resetn,
        .pcselect(pcselect_intf.decode),
        .dreg(dreg_intf.decode),
        .ereg(ereg_intf.decode),
        .forward(forward_intf.decode),
        .hazard(hazard_intf.decode),
        .regfile(regfile_intf.decode),
        .hilo(hilo_intf.decode),
        .cp0(cp0_intf.decode)
    );
    execute execute(
        .clk, .resetn,
        .ereg(ereg_intf.execute),
        .mreg(mreg_intf.execute),
        .forward(forward_intf.execute),
        .hazard(hazard_intf.execute)
    );
    memory memory(
        .mread, .mwrite, .rd(dresp.data),
        .mreg(mreg_intf.memory),
        .wreg(wreg_intf.memory),
        .forward(forward_intf.memory),
        .hazard(hazard_intf.memory),
        .exception(exception_intf.memory),
        .ext_int
    );
    writeback writeback(
        .wreg(wreg_intf.writeback),
        .regfile(regfile_intf.writeback),
        .hilo(hilo_intf.writeback),
        .hazard(hazard_intf.writeback),
        .forward(forward_intf.writeback),
        .cp0(cp0_intf.writeback),
        .pc(wb_pc)
    );
    hazard hazard (
        .self(hazard_intf.hazard)
    );
    forward forward(
        .self(forward_intf.forward)
    );
    regfile regfile (
        .clk,
        .self(regfile_intf.regfile)
    );

    hilo hilo (
        .clk,
        .self(hilo_intf.hilo)
    );

    exception exception(
        .self(exception_intf.exception),
        .hazard(hazard_intf.exception)
    );

    cp0 cp0(
        .clk, .resetn,
        .self(cp0_intf.cp0),
        .exception(exception_intf.cp0),
        .pcselect(pcselect_intf.cp0)
    );
    pipereg #(.T(word_t), .INIT(PCINIT)) freg(
        .clk, .resetn,
        .in(freg_intf.pc_new),
        .out(freg_intf.pc),
        .flush(1'b0),
        .en(~hazard_intf.stallF)
    );

    pipereg #(.T(fetch_data_t)) dreg (
        .clk, .resetn,
        .in(dreg_intf.dataF_new),
        .out(dreg_intf.dataF),
        .flush(hazard_intf.flushD),
        .en(~hazard_intf.stallD)
    );

    pipereg #(.T(decode_data_t)) ereg (
        .clk, .resetn,
        .in(ereg_intf.dataD_new),
        .out(ereg_intf.dataD),
        .flush(hazard_intf.flushE),
        .en(~hazard_intf.stallE)
    );

    pipereg #(.T(execute_data_t)) mreg (
        .clk, .resetn,
        .in(mreg_intf.dataE_new),
        .out(mreg_intf.dataE),
        .flush(hazard_intf.flushM),
        .en(~hazard_intf.stallM)
    );

    pipereg #(.T(memory_data_t)) wreg (
        .clk, .resetn,
        .in(wreg_intf.dataM_new),
        .out(wreg_intf.dataM),
        .flush(hazard_intf.flushW),
        .en(1'b1)
    );
endmodule
