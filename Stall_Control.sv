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
//      Stall Controller for a 5 Stage RISCV Processor
//
//***********************************************************
import CORE_PKG::*;

module Stall_Control (
  input logic reset, 

  input logic [6:0] ID_instr_opcode_ip,
  input logic [4:0] ID_src1_addr_ip,
  input logic [4:0] ID_src2_addr_ip,

  //The destination register from the different stages
  input logic [4:0] EX_reg_dest_ip,  // destination register from EX pipe
  input logic [4:0] LSU_reg_dest_ip,
  input logic [4:0] WB_reg_dest_ip,
  input logic WB_write_reg_en_ip,

  // The opcode of the current instr. in ID/EX
  input [6:0] EX_instr_opcode_ip,

  output logic stall_op
);

  always_comb begin
    stall_op = 1'b0;

    // Only need to check for hazards if not in reset
    //if (reset == 1'b0) begin

    case(ID_instr_opcode_ip) 

      OPCODE_OP: begin
        
        /**
        * Task 1
        * 
        * Here you will need to decide when to pull the stall control logic high. 
        * 
        * 1. Load to use stalls
        * 2. Stalls when reading and writing from Register File
        * For Register Register instructions, what registers are relevant
        */

        // make sure instr in EX is load, compare registers, stall for one cycle if necessary
        if ((EX_instr_opcode_ip == OPCODE_LOAD) 
            && ((EX_reg_dest_ip == ID_src1_addr_ip) 
            || (EX_reg_dest_ip == ID_src2_addr_ip)) 
            && (EX_reg_dest_ip != 5'd0)) begin
          stall_op = 1'b1;
        end

        // Stall if W stage is writing to a reg that D is trying to read (in same cycle)
        if ((WB_write_reg_en_ip == 1'b1)
            && (WB_reg_dest_ip != 5'd0)
            && ((WB_reg_dest_ip == ID_src1_addr_ip)
            || (WB_reg_dest_ip == ID_src2_addr_ip))) begin
          stall_op = 1'b1;
        end

      end

      OPCODE_OPIMM: begin

        /**
        * Task 1
        * 
        * Here you will need to decide when to pull the stall control logic high. 
        * 
        * 1. Load to use stalls
        * 2. Stalls when reading and writing from Register File
        * For Register Immedite instructions, what registers are relevant
        */

        // only rs1 is relevant
        if ((EX_instr_opcode_ip == OPCODE_LOAD) 
            && (EX_reg_dest_ip == ID_src1_addr_ip) 
            && (EX_reg_dest_ip != 5'd0)) begin
          stall_op = 1'b1;
        end

        // Check for WB stall when D is reading reg that the W stage writes
        if ((WB_write_reg_en_ip == 1'b1)
            && (WB_reg_dest_ip != 5'd0)
            && (WB_reg_dest_ip == ID_src1_addr_ip)) begin
          stall_op = 1'b1;
        end
      end

      OPCODE_LOAD: begin
        // Ld instruc read rs1 for the base address; check hazards same wat as imm instruc
        if ((EX_instr_opcode_ip == OPCODE_LOAD)
            && (EX_reg_dest_ip == ID_src1_addr_ip)
            && (EX_reg_dest_ip != 5'd0)) begin
          stall_op = 1'b1;
        end

        if ((WB_write_reg_en_ip == 1'b1)
            && (WB_reg_dest_ip != 5'd0)
            && (WB_reg_dest_ip == ID_src1_addr_ip)) begin
          stall_op = 1'b1;
        end
      end

      OPCODE_JALR: begin
        // JALR reads rs1 for the base address; check hazards same way as immediate instructions
        if ((EX_instr_opcode_ip == OPCODE_LOAD)
            && (EX_reg_dest_ip == ID_src1_addr_ip)
            && (EX_reg_dest_ip != 5'd0)) begin
          stall_op = 1'b1;
        end

        if ((WB_write_reg_en_ip == 1'b1)
            && (WB_reg_dest_ip != 5'd0)
            && (WB_reg_dest_ip == ID_src1_addr_ip)) begin
          stall_op = 1'b1;
        end
      end

      default: begin
        stall_op = 1'b0;
      end
    endcase
  end

endmodule
