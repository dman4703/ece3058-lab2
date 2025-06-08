//***********************************************************
// ECE 3058 Architecture Concurrency and Energy in Computation
//
// RISCV Processor System Verilog Behavioral Model
//
// School of Electrical & Computer Engineering
// Georgia Institute of Technology
// Atlanta, GA 30332
//
//  Module:     core_tb
//  Functionality:
//      Forward Controller for a 5 Stage RISCV Processor
//
//***********************************************************

import CORE_PKG::*;

module FWD_Control (
  input logic reset, 

  input [6:0] id_instr_opcode_ip, // ID/EX pipeline buffer opcode

  input write_back_mux_selector EX_MEM_wb_mux_ip,
  input write_back_mux_selector MEM_WB_wb_mux_ip,

  input logic [4:0] EX_MEM_dest_ip, //EX/MEM Dest Register
  input logic [4:0] MEM_WB_dest_ip, //MEM/WB Dest Register
  input logic [4:0] ID_dest_rs1_ip, //Rs from decode stage
  input logic [4:0] ID_dest_rs2_ip, //Rt from decode stage

  output forward_mux_code fa_mux_op, //select lines for forwarding muxes (Rs)
  output forward_mux_code fb_mux_op  //select lines for forwarding muxes (Rt)
);

  logic EX_MEM_RegWrite_en;
  logic MEM_WB_RegWrite_en;

  assign EX_MEM_RegWrite_en = (EX_MEM_wb_mux_ip == NO_WRITEBACK) ? 1'b0 : 1'b1;
  assign MEM_WB_RegWrite_en = (MEM_WB_wb_mux_ip == NO_WRITEBACK) ? 1'b0 : 1'b1;

  always @(*) begin
    fa_mux_op = ORIGINAL_SELECT;
    fb_mux_op = ORIGINAL_SELECT;

    case (id_instr_opcode_ip)

      /**
        EX Hazard
        if (EX/MEM.RegWrite and (EX/MEM.RegisterRd != 0) and (EX/MEM.RegisterRd = ID/EX.Register.Rs1)) { 
          FwdA --> EX/MEM 
        }
        if (EX/MEM.RegWrite and (EX/MEM.RegisterRd != 0) and (EX/MEM.RegisterRd = ID/EX.Register.Rs2)) { 
          FwdB --> EX/MEM 
        }

        MEM hazard
        if (MEM/WB.RegWrite and (MEM/WB.RegisterRD != 0) and (MEM/WB.RegisterRD = ID/EX.RegisterRs1)) {
          Fwd A --> MEM/WB
        }
        if (MEM/WB.RegWrite and (MEM/WB.RegisterRD != 0) and (MEM/WB.RegisterRD = ID/EX.RegisterRs2)) {
          Fwd B --> MEM/WB
        }
      */

      OPCODE_OP: begin // Register-Register ALU operation

        /**
        * Task 2
        * 
        * Here you will need to check for hazards and decide if and what you will forward 
        * For Register Register instructions, what registers are relevant for you to check 
        */
        // you need to consider two main cases:
        // case 1: you need to assign something to the fa_mux (corresponds to rs1), which gets results from either the execution stage or writeback stage.
        // case 2: you need to do something with fb_mux (corresponds to rs2), which gets results from the execution stage or writeback stage.
      end

      OPCODE_OPIMM: begin // Register Immediate 

        /**
        * Task 2
        * 
        * Here you will need to check for hazards and decide if and what you will forward 
        * For Register Register instructions, what registers are relevant for you to check
        */
        // one main case to consider:
        // case 1: you need to assign something to the fa_mux (corresponds to rs1), which gets results from either the execution stage or writeback stage.
        
      end

    endcase

  end
endmodule