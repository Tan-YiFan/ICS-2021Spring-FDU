`include "common.svh"
module DirectTrans #(
	parameter type req_t = cbus_req_t,
	parameter type resp_t = cbus_resp_t
)(
	input  req_t  treq,
	output resp_t tresp,
	output req_t  oreq,
	input  resp_t oresp
);
	always_comb begin
		oreq = treq;
		unique case(treq.addr[31:28])
			4'h8, 4'ha: oreq.addr = {4'b0, treq.addr[27:0]};
			4'h9, 4'hb: oreq.addr = {4'b1, treq.addr[27:0]};
			default: oreq.addr = treq.addr;
		endcase
	end

	assign tresp = oresp;
endmodule
