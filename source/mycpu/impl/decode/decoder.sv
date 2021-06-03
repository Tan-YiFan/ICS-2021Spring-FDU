`include "mycpu/interface.svh"
module decoder 
	import common::*;
	import decode_pkg::*;(
	input instr_t raw_instr,
	input word_t pcplus4,
	output decoded_instr_t instr,
	input logic is_usermode,
	input logic [3:0] cu
);
	localparam type raw_op_t = logic[5:0];
	localparam type raw_func_t = logic[5:0];

	raw_op_t raw_op;
	assign raw_op = raw_instr[31:26];

	raw_func_t raw_func;
	assign raw_func = raw_instr[5:0];
	creg_addr_t rs, rt, rd;
	assign rs = raw_instr[25:21];
	assign rt = raw_instr[20:16];
	assign rd = raw_instr[15:11];

	logic [15:0] imm;
	assign imm = raw_instr[15:0];

	control_t ctl;
	decoded_op_t op;
	assign instr.op = op;
	assign instr.ctl = ctl;
	assign instr.imm = 
	ctl.jump ? {pcplus4[31:28], raw_instr[25:0], 2'b0 }: 
	(ctl.shamt_valid ? {27'b0, raw_instr[10:6]} : 
	(ctl.zeroext ? {16'b0, raw_instr[15:0]} : 
	{{16{raw_instr[15]}}, raw_instr[15:0]}));
	logic exception_ri;
	logic exception_cpu;
	assign instr.exception_ri = exception_ri;
	assign instr.exception_cpu = exception_cpu;
	always_comb begin : control_signal
		exception_ri = '0;
		exception_cpu = '0;
		ctl = '0;
		op = decoded_op_t'(0);
		unique case(raw_op)
			OP_RT: begin
				unique case(raw_func)
					F_ADD: begin
						op = ADD;
						ctl.alufunc = ALU_ADD;
						ctl.regwrite = 1'b1;
					end
					F_ADDU: begin
						op = ADDU;
						ctl.alufunc = ALU_ADDU;
						ctl.regwrite = 1'b1;
					end
					F_SUB: begin
						op = SUB;
						ctl.alufunc = ALU_SUB;
						ctl.regwrite = 1'b1;
					end
					F_SUBU: begin
						op = SUBU;
						ctl.alufunc = ALU_SUBU;
						ctl.regwrite = 1'b1;
					end
					F_SLT: begin
						op = SLT;
						ctl.alufunc = ALU_SLT;
						ctl.regwrite = 1'b1;
					end
					F_SLTU: begin
						op = SLTU;
						ctl.alufunc = ALU_SLTU;
						ctl.regwrite = 1'b1;
					end
					F_DIV: begin
						op = DIV;
						ctl.hiwrite = 1'b1;
						ctl.lowrite = 1'b1;
						ctl.is_multdiv = 1'b1;
						ctl.multicycle_type = M_DIV;
					end
					F_DIVU: begin
						op = DIVU;
						ctl.hiwrite = 1'b1;
						ctl.lowrite = 1'b1;
						ctl.is_multdiv = 1'b1;
						ctl.multicycle_type = M_DIVU;
					end
					F_MULT: begin
						op = MULT;
						ctl.hiwrite = 1'b1;
						ctl.lowrite = 1'b1;
						ctl.is_multdiv = 1'b1;
						ctl.multicycle_type = M_MULT;
					end
					F_MULTU: begin
						op = MULTU;
						ctl.hiwrite = 1'b1;
						ctl.lowrite = 1'b1;
						ctl.is_multdiv = 1'b1;
						ctl.multicycle_type = M_MULTU;
					end
					F_AND: begin
						op = AND;
						ctl.alufunc = ALU_AND;
						ctl.regwrite = 1'b1;
					end
					F_NOR: begin
						op = NOR;
						ctl.alufunc = ALU_NOR;
						ctl.regwrite = 1'b1;
					end
					F_OR: begin
						op = OR;
						ctl.alufunc = ALU_OR;
						ctl.regwrite = 1'b1;
					end
					F_XOR: begin
						op = XOR;
						ctl.alufunc = ALU_XOR;
						ctl.regwrite = 1'b1;
					end
					F_SLLV: begin
						op = SLLV;
						ctl.alufunc = ALU_SLL;
						ctl.regwrite = 1'b1;
					end
					F_SLL: begin
						op = SLL;
						ctl.alufunc = ALU_SLL;
						ctl.regwrite = 1'b1;
						ctl.shamt_valid = 1'b1;
					end
					F_SRAV: begin
						op = SRAV;
						ctl.alufunc = ALU_SRA;
						ctl.regwrite = 1'b1;
					end
					F_SRA: begin
						op = SRA;
						ctl.alufunc = ALU_SRA;
						ctl.regwrite = 1'b1;
						ctl.shamt_valid = 1'b1;
					end
					F_SRLV: begin
						op = SRLV;
						ctl.alufunc = ALU_SRL;
						ctl.regwrite = 1'b1;
					end
					F_SRL: begin
						op = SRL;
						ctl.alufunc = ALU_SRL;
						ctl.regwrite = 1'b1;
						ctl.shamt_valid = 1'b1;
					end
					F_JR: begin
						op = JR;
						ctl.jump = 1'b1;
						ctl.jr = 1'b1;
						ctl.alufunc = ALU_PASSA;
					end
					F_JALR: begin
						op = JALR;
						ctl.jump = 1'b1;
						ctl.jr = 1'b1;
						ctl.regwrite = 1'b1;
						ctl.is_link = 'b1;
						ctl.alufunc = ALU_PASSA;
					end
					F_MFHI: begin
						op = MFHI;
						ctl.regwrite = 1'b1;
						ctl.alufunc = ALU_PASSA;
					end
					F_MFLO: begin
						op = MFLO;
						ctl.regwrite = 1'b1;
						ctl.alufunc = ALU_PASSA;
					end
					F_MTHI: begin
						op = MTHI;
						ctl.hiwrite = 1'b1;
						ctl.alufunc = ALU_PASSA;
					end
					F_MTLO: begin
						op = MTLO;
						ctl.lowrite = 1'b1;
						ctl.alufunc = ALU_PASSA;
					end
					F_BREAK: begin
						op = BREAK;
						ctl.alufunc = ALU_PASSA;
						ctl.is_bp = 1'b1;
					end
					F_SYSCALL: begin
						op = SYSCALL;
						ctl.alufunc = ALU_PASSA;
						ctl.is_sys = 1'b1;
					end
					F_MOVZ: begin
						op = MOVZ;
						ctl.regwrite = 1'b1;
						ctl.alufunc = ALU_PASSA;
						ctl.is_movz = 1'b1;
					end
					F_MOVN: begin
						op = MOVN;
						ctl.regwrite = 1'b1;
						ctl.alufunc = ALU_PASSA;
						ctl.is_movn = 1'b1;
					end
					F_SYNC: begin
						
					end
					F_TEQ: begin
						ctl.is_trap = 1'b1;
						ctl.trap_type = TRAP_TEQ;
					end
					F_TGE: begin
						ctl.is_trap = 1'b1;
						ctl.trap_type = TRAP_TGE;
					end
					F_TGEU: begin
						ctl.is_trap = 1'b1;
						ctl.trap_type = TRAP_TGEU;
					end
					F_TLT: begin
						ctl.is_trap = 1'b1;
						ctl.trap_type = TRAP_TLT;
					end
					F_TLTU: begin
						ctl.is_trap = 1'b1;
						ctl.trap_type = TRAP_TLTU;
					end
					F_TNE: begin
						ctl.is_trap = 1'b1;
						ctl.trap_type = TRAP_TNE;
					end
					default: begin
						exception_ri = 1'b1;
						op = RESERVED;
					end
				endcase
			end
			OP_ADDI: begin
				op = ADDI;
				ctl.alufunc = ALU_ADD;
				ctl.regwrite = 1'b1;
				ctl.alusrc = IMM;
			end
			OP_ADDIU: begin
				op = ADDIU;
				ctl.alufunc = ALU_ADDU;
				ctl.regwrite = 1'b1;
				ctl.alusrc = IMM;
			end
			OP_SLTI: begin
				op = SLTI;
				ctl.alufunc = ALU_SLT;
				ctl.regwrite = 1'b1;
				ctl.alusrc = IMM;
			end
			OP_SLTIU: begin
				op = SLTIU;
				ctl.alufunc = ALU_SLTU;
				ctl.regwrite = 1'b1;
				ctl.alusrc = IMM;
			end
			OP_ANDI: begin
				op = ANDI;
				ctl.alufunc = ALU_AND;
				ctl.regwrite = 1'b1;
				ctl.zeroext = 1'b1;
				ctl.alusrc = IMM;
			end
			OP_LUI: begin
				op = LUI;
				ctl.alufunc = ALU_LUI;
				ctl.regwrite = 1'b1;
				ctl.alusrc = IMM;
			end
			OP_ORI: begin
				op = ORI;
				ctl.alufunc = ALU_OR;
				ctl.regwrite = 1'b1;
				ctl.alusrc = IMM;
				ctl.zeroext = 1'b1;
			end
			OP_XORI: begin
				op = XORI;
				ctl.alufunc = ALU_XOR;
				ctl.regwrite = 1'b1;
				ctl.alusrc = IMM;
				ctl.zeroext = 1'b1;
			end
			OP_BEQ, OP_BEQL: begin
				op = BEQ;
				ctl.branch = 1'b1;
				ctl.branch_type = T_BEQ;
			end
			OP_BNE, OP_BNEL: begin
				op = BNE;
				ctl.branch = 1'b1;
				ctl.branch_type = T_BNE;
			end
			OP_REGIMM: begin
				unique case (raw_instr[20:16])
					B_BGEZ:  begin
						op = BGEZ;
						ctl.branch = 1'b1;
						ctl.branch_type = T_BGEZ;
					end  
					B_BLTZ: begin
						op = BLTZ;
						ctl.branch = 1'b1;
						ctl.branch_type = T_BLTZ;
					end   
					B_BGEZAL: begin
						op = BGEZAL;
						ctl.branch = 1'b1;
						ctl.regwrite = 1'b1;
						ctl.branch_type = T_BGEZ;
						ctl.is_link = 'b1;
					end 
					B_BLTZAL: begin
						op = BLTZAL;
						ctl.branch = 1'b1;
						ctl.regwrite = 1'b1;
						ctl.branch_type = T_BLTZ;
						ctl.is_link = 'b1;
					end
					F_TEQI: begin
						ctl.is_trap = 1'b1;
						ctl.alusrc = IMM;
						ctl.trap_type = TRAP_TEQ;
					end
					F_TGEI: begin
						ctl.is_trap = 1'b1;
						ctl.alusrc = IMM;
						ctl.trap_type = TRAP_TGE;
					end
					F_TGEIU: begin
						ctl.is_trap = 1'b1;
						ctl.alusrc = IMM;
						ctl.trap_type = TRAP_TGEU;
					end
					F_TLTI: begin
						ctl.is_trap = 1'b1;
						ctl.alusrc = IMM;
						ctl.trap_type = TRAP_TLT;
					end
					F_TLTIU: begin
						ctl.is_trap = 1'b1;
						ctl.alusrc = IMM;
						ctl.trap_type = TRAP_TLTU;
					end
					F_TNEI: begin
						ctl.is_trap = 1'b1;
						ctl.alusrc = IMM;
						ctl.trap_type = TRAP_TNE;
					end
					default: begin
						exception_ri = 1'b1;
						op = RESERVED;
					end
				endcase
			end
			OP_BGTZ: begin
				op = BGTZ;
				ctl.branch = 1'b1;
				ctl.branch_type = T_BGTZ;
			end
			OP_BLEZ: begin
				op = BLEZ;
				ctl.branch = 1'b1;
				ctl.branch_type = T_BLEZ;
			end
			OP_J: begin
				op = J;
				ctl.jump = 1'b1;
			end
			OP_JAL: begin
				op = JAL;
				ctl.jump = 1'b1;
				ctl.regwrite = 1'b1;
				ctl.is_link = 'b1;
			end
			OP_LB: begin
				op = LB;
				ctl.regwrite = 1'b1;
				ctl.memread = 1'b1;
				ctl.alusrc = IMM;
				ctl.mem_size = 2'b00;
				ctl.mem_type = MEM_LB;
			end
			OP_LBU: begin
				op = LBU;
				ctl.regwrite = 1'b1;
				ctl.memread = 1'b1;
				ctl.alusrc = IMM;
				ctl.mem_size = 2'b00;
				ctl.mem_type = MEM_LBU;
			end
			OP_LH: begin
				op = LH;
				ctl.regwrite = 1'b1;
				ctl.memread = 1'b1;
				ctl.alusrc = IMM;
				ctl.mem_size = 2'b01;
				ctl.mem_type = MEM_LH;
			end
			OP_LHU: begin
				op = LHU;
				ctl.regwrite = 1'b1;
				ctl.memread = 1'b1;
				ctl.alusrc = IMM;
				ctl.mem_size = 2'b01;
				ctl.mem_type = MEM_LHU;
			end
			OP_LW, OP_LL: begin
				op = LW;
				ctl.regwrite = 1'b1;
				ctl.memread = 1'b1;
				ctl.alusrc = IMM;
				ctl.mem_size = 2'b10;
				ctl.mem_type = MEM_LW;
			end
			OP_SB: begin
				op = SB;
				ctl.memwrite = 1'b1;
				ctl.alusrc = IMM;
				ctl.mem_size = 2'b00;
				ctl.mem_type = MEM_SB;
			end
			OP_SH: begin
				op = SH;
				ctl.memwrite = 1'b1;
				ctl.alusrc = IMM;
				ctl.mem_size = 2'b01;
				ctl.mem_type = MEM_SH;
			end
			OP_SW, OP_SC: begin
				op = SW;
				ctl.memwrite = 1'b1;
				ctl.alusrc = IMM;
				ctl.mem_size = 2'b10;
				ctl.mem_type = MEM_SW;
			end
			OP_MUL: begin
				unique case(raw_instr[5:0])
					M_MUL: begin
						op = MUL;
						ctl.is_multdiv = 1'b1;
						ctl.multicycle_type = M_MULT;
                                                ctl.is_mul = 1'b1;
                                                ctl.regwrite = 1'b1;
					end
					M_CLO: begin
						op = CLO;
						ctl.alufunc = ALU_CLO;
						ctl.regwrite = 1'b1;
					end
					M_CLZ: begin
						op = CLZ;
						ctl.alufunc = ALU_CLZ;
						ctl.regwrite = 1'b1;
					end
					M_ADD: begin
						op = MADD;
						ctl.is_multdiv = 1'b1;
						ctl.multicycle_type = M_MADD;
                                                ctl.is_mul = 1'b1;
						ctl.hiwrite = 1'b1;
						ctl.lowrite = 1'b1;
					end
					M_ADDU: begin
						op = MADDU;
						ctl.is_multdiv = 1'b1;
						ctl.multicycle_type = M_MADDU;
                                                ctl.is_mul = 1'b1;
						ctl.hiwrite = 1'b1;
						ctl.lowrite = 1'b1;
					end
					M_SUB: begin
						op = MSUB;
						ctl.is_multdiv = 1'b1;
						ctl.multicycle_type = M_MSUB;
                                                ctl.is_mul = 1'b1;
						ctl.hiwrite = 1'b1;
						ctl.lowrite = 1'b1;
					end
					M_SUBU: begin
						op = MSUBU;
						ctl.is_multdiv = 1'b1;
						ctl.multicycle_type = M_MSUBU;
                                                ctl.is_mul = 1'b1;
						ctl.hiwrite = 1'b1;
						ctl.lowrite = 1'b1;
					end
					default: begin
						exception_ri = 1'b1;
						op = RESERVED;
					end
				endcase
			end
			OP_PRIV: begin
				if (is_usermode && ~cu[0]) begin
					exception_cpu = '1;
					ctl.ce[0] = '1;
				end
				case (raw_instr[25:21])
					C_MFC0: begin
						op = MFC0;
						ctl.alufunc = ALU_PASSA;
						ctl.regwrite = 1'b1;
					end 
					C_MTC0: begin
						op = MTC0;
						ctl.cp0write = 1'b1;
						ctl.alufunc = ALU_PASSB;
					end
					default: begin
						case (raw_instr[5: 0])
							C_ERET: begin
								op = ERET;
								ctl.is_eret = 1'b1;
							end
							C_TLBP: begin
								op = TLBP;
								ctl.is_tlbp = 1'b1;
							end
							C_TLBR: begin
								op = TLBR;
								ctl.is_tlbr = 1'b1;
							end
							C_TLBWI: begin
								op = TLBWI;
								ctl.is_tlbwi = 1'b1;
							end
							C_WAIT: begin
								op = WAIT_EX;
								ctl.is_wait = 1'b1;
								
							end
							default: begin
								exception_ri = 1'b1;
								op = RESERVED;
							end
						endcase
					end
				endcase
			end
			OP_CACHE, OP_PREF: begin
				
			end
			OP_COP1: begin
				if ((raw_instr[25:21] == 5'b0 || raw_instr[25:21] == 5'b100) && raw_instr[10:0] == '0) begin
					exception_cpu = '1;
					ctl.ce[1] = 1'b1;
				end else if (raw_instr[5:0] == 6'b000010 || raw_instr[5:0] == 6'b000111 || raw_instr[5:1] == 5'b10110) begin
					exception_cpu = '1;
					ctl.ce[1] = 1'b1;
				end else begin
					exception_ri = 1'b1;
				end
				
			end
			OP_LWL: begin
				op = LWL;
				ctl.alusrc = IMM;
				ctl.mem_type = MEM_LWL;
				ctl.memread = 1'b1;
				ctl.regwrite = 1'b1;
				ctl.mem_size = 2'b10;
				ctl.unaligned_regwrite = 1'b1;
			end
			OP_LWR: begin
				op = LWR;
				ctl.alusrc = IMM;
				ctl.mem_type = MEM_LWR;
				ctl.memread = 1'b1;
				ctl.regwrite = 1'b1;
				ctl.mem_size = 2'b10;
				ctl.unaligned_regwrite = 1'b1;
			end
			OP_SWL: begin
				op = LWL;
				ctl.alusrc = IMM;
				ctl.mem_type = MEM_SWL;
				ctl.memwrite = 1'b1;
				ctl.mem_size = 2'b10;
			end
			OP_SWR: begin
				op = LWR;
				ctl.alusrc = IMM;
				ctl.mem_type = MEM_SWR;
				ctl.memwrite = 1'b1;
				ctl.mem_size = 2'b10;
			end
			default: begin
				exception_ri = 1'b1;
				op = RESERVED;
			end
		endcase
	end
	
	always_comb begin : srca
		instr.srca = rs;
		if (ctl.alufunc == ALU_PASSB) begin
			instr.srca = '0;
		end
		if (ctl.is_bp || ctl.is_sys || exception_ri) begin
			instr.srca = '0;
		end
	end

	always_comb begin : srcb
		instr.srcb = ctl.alusrc == REGB ? rt : '0;
		if (ctl.alufunc == ALU_PASSA) begin
			instr.srcb = '0;
		end
		if (ctl.memwrite | ctl.memread | ctl.is_movn | ctl.is_movz) begin
			instr.srcb = rt;
		end
		// if (ctl.cp0toreg) begin
		//     instr.srcb = rd;
		// end
		if (ctl.is_bp || ctl.is_sys || exception_ri) begin
			instr.srcb = '0;
		end
	end
	
	always_comb begin : dest
		instr.dest = (raw_op != OP_RT && raw_op != OP_MUL) ? rt : rd;
		if (ctl.jump | ctl.branch) begin
			instr.dest = 5'b11111;
		end
		if (ctl.cp0write) begin
			instr.dest = rd;
		end
	end
endmodule
