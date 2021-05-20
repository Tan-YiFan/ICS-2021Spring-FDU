`ifndef __TRANSLATION_PKG_SV
`define __TRANSLATION_PKG_SV

`include "common.sv"
`include "cp0_pkg.sv"
package translation_pkg;

import common::*;
import cp0_pkg::*;
typedef struct packed {
	logic is_tlbwi;
	cp0_entryhi_t entryhi;
	cp0_entrylo_t entrylo0, entrylo1;
	cp0_index_t index;
} tu_op_req_t;
    
typedef struct packed {
	cp0_entryhi_t entryhi;
	cp0_entrylo_t entrylo0, entrylo1;
	cp0_index_t index;
	logic i_tlb_invalid; // && req
	logic i_tlb_modified; // && is store
	logic d_tlb_invalid; // && req
	logic d_tlb_modified; // && is store
	logic i_tlb_refill;
	logic d_tlb_refill;
	logic i_mapped;
	logic d_mapped;
} tu_op_resp_t;

parameter TLB_ENTRIES = 2 ** TLB_INDEX;

typedef logic[$clog2(TLB_ENTRIES)-1:0] tlb_addr_t;

typedef struct packed {
	logic [18:0] vpn2;
	logic [7:0] asid;
	logic G;
	logic [19:0] pfn0, pfn1;
	logic [2:0] C0, C1;
	logic V0, V1, D0, D1;
} tlb_entry_t;

typedef tlb_entry_t[TLB_ENTRIES-1:0] tlb_table_t;
typedef struct packed {
	logic valid;
	tlb_addr_t addr;
	tlb_entry_t data;
} tlbwrite_t;

typedef struct packed {
	word_t paddr;
	logic hit, dirty, valid;
	tlb_addr_t tlb_addr;
	logic [2:0] cache_flag;
} tlblut_resp_t;

typedef struct packed {
	logic  req;
	word_t vaddr;
} tu_addr_req_t;

typedef struct packed {
	logic  is_uncached;
	word_t paddr;
} tu_addr_resp_t;
endpackage
`endif
