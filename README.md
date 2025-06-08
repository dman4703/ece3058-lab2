## **Required Tools for this lab[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#required-tools-for-this-lab)**

1. If you've Linux or Windows (WSL), then it is recommended to use [iverilog](https://github.gatech.edu/pages/ECE3058/website/resources/iverilog/iverilog) with [GTKwave or Scansion](https://github.gatech.edu/pages/ECE3058/website/resources/VCD/vcd/)

# **Lab Assignment 2 (*100 points total*)[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#lab-assignment-2-100-points-total)**

## **Problem Description[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#problem-description)**

After you've built the computer for your friend from last lab, he keeps complaining that its too slow. You decide to help him again. In order to speedup the clock rate, you'll need to modify your datapath to the pipeline design you learned in class. Luckily for you, someone else has already provided an outline for the datapath but with several bugs and essential missing components required for pipelining to work efficently. You're task is to add in these missing pieces.

The mermaid figure below is a high-level view of the current pipeline implementation from the given **system verilog** code. It should be very similiar to the one presented in class.

```
flowchart TD
 subgraph IF["InstructionFetch_Module"]
        PC["PC"]
        IM["Instruction Memory"]
        FM["Fetch Module"]
  end
 subgraph ID["InstructionDecode_Module"]
        RF["32x32 Register File"]
        DM["Decode Module"]
        SC["Stall Controller"]
  end
 subgraph IE["InstructionExecute_Module"]
        ALU["ALU Unit"]
        COMP["Comparator"]
        FCM["Foward Controller Module"]
        OPA["Operand Mux A"]
        OPB["Operand Mux B"]
  end
 subgraph MEM["Memory_Module"]
        DM_MEM["Data Memory"]
        LSU["LSU Unit"]
  end
 subgraph WB["WriteBack_Module"]
        WBM["Writeback Module"]
  end
    PC --> IM & FD["IF/ID Latch"]
    FM --> PC
    RF --> DM
    DM --> RF & DE["ID/EX Latch"] & FM & PC
    FCM --> OPA & OPB
    OPA --> ALU
    OPB --> COMP
    DM_MEM --> LSU & MW["MEM/WB Latch"]
    LSU --> DM_MEM & MW
    IM --> FD
    FD --> DM & SC
    SC --> DE & PC & FD
    DE --> OPA & OPB & ALU & COMP & LSU
    ALU --> EM["EX/MEM Latch"] & FM & PC
    COMP --> EM & FM & PC
    EM --> LSU & DM_MEM & OPA & OPB & FCM
    MW --> WBM & FCM
    WBM --> RF & OPA & OPB & FCM
```

### Processor Specifications[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#processor-specifications)

The pipeline for our application will implement 6 instructions of the RV32I ISA. The specifications are detailed below.

1. The microarchiecture will need to implement the following instructions of the RV32I: `ADD`, `ADDI`, `SUB` `LW`, `SLT`, and `JAL` 

2. There are two forwarding lines to forward the ALU result from the MEM and WB back to the EX stage based on the diagram shown above.  
3. Jumps are resolved in the *Execute Stage*. Even though the jump instruction is known in the decode stage, the jump address calculations rely on the ALU to compute.  
4. Writebacks writes and RegisterFile reads cannot occur in the same cycle. In other words, if we writeback data to $3, then only on the next *CLK cycle* can we read the updated value of the register file. Note that you cannot just forward the results of WB to EX because the dependant instruction is in the Decode stage and not the Execute. The forwarding lines are only directed to the EX stage. For example, with the two forwarding lines:

|  | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| add $2, $2, $3 | F | D | E | M | WB |  |  |  |  |  |  |  |  |  |
| add $3, $4, $5 |  | F | D | E | M | WB |  |  |  |  |  |  |  |  |
| add $1, $2, $3 |  |  | F | D | E | M | WB |  |  |  |  |  |  |  |
| add $1, $2, $3 |  |  |  | F | D | D | E | M | WB |  |  |  |  |  |

> **Warning** <br>
> Grading will be based on both functionality and performance. Your implementation must not only execute application logic (assembly instr.) properly but also be the most efficient pipeline that can be designed based on the constraints given above. Your implementation will be compared against the TAs solution as a baseline in the autograder for both accuracy and speed. Points will be deducted if the execution logic (appropriate values in RF and MEM updated on approrpiate cycles) of your implementation based on the above specifications does not match the TAs' solutions.

## **Your Tasks[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#your-tasks)**

First click [here](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/assignment.zip) to download the lab. Change into the rtl directory and run `make` to generate the `Core_Simulation.vcd`, and then open it. Make sure you're able to view a waveform and that everything works properly so far without any edits. You should not get any errors during compilation. The current processor should implement all the 6 instructions given in the specifications correctly if there are no data dependencies. In fact if you submit it right now to Gradescope, you will pass the functionality test and get a free 5 points. In the tasks below you will modify the processor so that it supports data dependencies.

In this lab, you will perform the following task:

### Code Task[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#code-task)

1. Add support for the load-to-use stall. For example, if a `lw` instruction produces data used by an immediately following instruction, one stall cycle should be included between the `lw` and the immediately following instruction.  
2. Currently the processor does not stall when the instruction following the load depends on it. The logic that needs to be repaired to add load-to-use stall is in the file `Stall_Control.sv`. Add support for writeback stalls. This is detailed in the 2nd specification above. For example, if an add instruction writes data back to the register file addr. in the same CLK cycle that another instr. is in the *Decode* and reading the same register file addr. then you need to stall for one cycle to allow the data to be written back to the register file so that on the next CLK cycle, the correct value can be read.  
3. Implement data forwarding to the EX stage. There is a blank module called `FWD_CONT.sv` already created for you and instantiated within `Core.sv`. Feel free to modify the input/output ports if required in your implementation. Just how you checked for hazards in the `Stall_Control.sv` file, you will check for hazards and forward the correct value from EX/MEM or MEM/WB stage to the execute unit. Tips:
    
    - In `FWD_Control.sv`:
        - In `OPCODE_OP`, you need to consider two main cases:
            1. you need to assign something to the `fa_mux` (corresponds to rs1), which gets results from either the execution stage or writeback stage.
            2. you need to do something with fb_mux (corresponds to rs2), which gets results from the execution stage or writeback stage.
        - `OPCODE_OPIMM` section will check practically the same conditions, but only one case:
            1. you need to assign something to the `fa_mux` (corresponds to rs1), which gets results from either the execution stage or writeback stage.
    
    - Here are the fowarding conditions for reference:
        ```
        // EX Hazard
        if (EX/MEM.RegWrite and (EX/MEM.RegisterRd != 0) and (EX/MEM.RegisterRd = ID/EX.Register.Rs1)) { 
            FwdA --> EX/MEM 
        }
        if (EX/MEM.RegWrite and (EX/MEM.RegisterRd != 0) and (EX/MEM.RegisterRd = ID/EX.Register.Rs2)) { 
            FwdB --> EX/MEM 
        }

        // MEM hazard
        if (MEM/WB.RegWrite and (MEM/WB.RegisterRD != 0) and (MEM/WB.RegisterRD = ID/EX.RegisterRs1)) {
            Fwd A --> MEM/WB
        }
        if (MEM/WB.RegWrite and (MEM/WB.RegisterRD != 0) and (MEM/WB.RegisterRD = ID/EX.RegisterRs2)) {
            Fwd B --> MEM/WB
        }
        ```

    - In `EX_Stage.sv`, `fa_mux_ip` and `fb_mux_ip` could be assigned to:
        ```
        typedef enum logic [2:0] {
        ORIGINAL_SELECT = 3'b000, 
        EX_RESULT_SELECT = 3'b001,
        MEM_RESULT_SELECT = 3'b010, 
        WB_RESULT_SELECT = 3'b011,
        MEM_DATA_EX_SELECT = 3'b100, forwarded 
        MEM_DATA_WB_SELECT = 3'b101
        } forward_mux_code;
        ```
        - You will want to consider the cases when `fa_mux_ip` is `EX_RESULT_SELECT`, `MEM_RESULT_SELECT`, and `WB_RESULT_SELECT`. In each of these scenarios, we want to assign something to `alu_operand_a`; something like `EX_RESULT_SELECT: alu_operand_a = ?`. Hint: what you can assign to operand a would be related to `input logic [31:0] fw_wb_data` (data from the forward controller) OR it would be related to `output logic [31:0] alu_result_op` (data that is being routed back to the execution stage).
        - The same advice applies to `fb_mux_ip`, except now we are assigning `alu_operand_b`

4. Implement flushing in the pipeline. Note specification 4 above. Thus, the fetch stage will keep fetching instructions through `PC + 4` until the jump condition is resolved. Flushing out will mean clearing out the relevant (before branch resolution) registers.

**Functionally all the processor should still be generating correct logic after all the changes to implementing stalling, forwarding, and flushing.**

Build test cases by combining intructions to test out stalling, forwarding, and flushing. Some example functions are included in the following section.

# **Testing and Debugging[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#testing-and-debugging)**

To help you debug as well as better understand the tasks of lab 2, we've provided the waveforms for some of the tests that are running in Gradescope. Their names below correspond to the test names you see in Gradescope. You are NOT REQUIRED to match these waveforms. They are only here to help you as a guide to debug the test cases and show what the proper execution of the test cases should be in order to pass. The waveforms may even contain irrelevant wires and signals, but ultimately the most important considerations for our cases are the register and memory values as these are what ensure functional correctness and the proper implementation of the 5 stage in-order pipeline. Your goal shouldn't be to try to match them bit by bit but rather make sure you understand what instructions are suppose to output. You should use the emulator form Lab0 to make sure you understand what's going on first and see what is outputted to memory and RF at every cycle and try to understand how you can obtain that rather than just diving directly in to match the waveforms because chances are you're not going to match every signal.

* Task 3 Simple. [here](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/Task3_Simple.vcd)
```
nop # (0x00000000)
nop # (0x00000000)
nop # (0x00000000)
add x1, x2, x3
add x1, x2, x1
add x1, x1, x2
add x1, x9, x1
add x2, x9, x1
nop # (0x00000000)
add x2, x9, x2
sub x1, x9, x6
add x1, x6, x9
sub x2, x15, x1
nop # (0x00000000)
```

* Task 3 General. [here](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/Task3_General.vcd)
```
nop # (0x00000000)
addi x8, x0, -5
add x8, x0, x5
sub x9, x6, x8
lw x9, 0(x0)
add x9, x9, x8
sub x9, x9, x8
add x12, x9, x8
slt x11, x8, x9
sub x2, x0, x11
```

* Task 3 Complex [here](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/Task3_Long.vcd)
```
nop # (0x00000000)
nop # (0x00000000)
nop # (0x00000000)
add x2, x2, x2
add x2, x2, x2
add x2, x2, x2
add x2, x2, x2
add x2, x2, x2
add x2, x2, x2
add x2, x2, x2
add x2, x2, x2
add x2, x2, x2
add x2, x2, x2
add x16, x16, x16
nop # (0x00000000)
add x16, x16, x16
nop # (0x00000000)
add x16, x16, x16
nop # (0x00000000)
nop # (0x00000000)
add x16, x16, x16
sub x14, x2, x16
sub x12, x14, x16
nop # (0x00000000)
sub x12, x14, x16
sub x9, x12, x16
add x3, x9, x2
lw x9, 0(x0)
add x4, x9, x3
sub x4, x9, x3
addi x2, x2, -20
lw x1, 4(x0)    
```

# **Template Modifications[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#template-modifications)**

You are free to modify the given template as desired. However our autograders do drive custom instruction streams and read corresponding outputs to check for correctness so we HIGHLY recommend working off of the given template. If you do make major changes (restructuring wholes files NOT adding a couple of wires), below is the list of verilog wires, modules, and filenames that we ask you do not modify. Please also make sure your processor still follows the specifications detailed above and is based on the architecture given in class. We also ask that you do not rename any of the file names for our autograder purposes.

* `data_RAM` in `DRAM.sv ` 
* `instr_RAM` in `Instr_Mem.sv`
* `Register_File.sv`  
* `DFlipFlop.sv`  
* `Register Module` in `ID_Stage.sv`  
* `Instruction Memory Module` in `IF_Stage.sv`  
* `DRAM Module` in `Core.sv`

### **Coding Task Submission[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#coding-task-submission)**

To clarify: 1\. First implement stalling for the task 1\. and 2\. and verify that it is working properly. 2\. Once stalling works implment forwarding. Verify forwarding is working by seeing only one stall in the case with a lw RAW. This is the case where the data is only avaliable after memory stage (you want to implement stalling first in order to verify that data is not being taken incorrectly in any case) 3\. Implement flushing and verify functionality

**All Tests on Gradescope assume that forwarding is working to the extent of the specification. Even the first test that tests load-to-use stalls assumes that forwarding is working to some extent**

For submission, please submit your tarball to Gradescope under the Lab2 Pipelining Assignment. To generate the tarball:

* If you're using the files in the regular assignment directory, simply just run `make submit` on your terminal where the Makefile is located (same as running make to generate your waveform). 

you'll end up with a file titled ece3058\_lab2\_submission.tar.gz that you will submit to Gradescope.

Make sure you add comments for the changes. Do NOT submit different RTL directories for the different tasks

For guidance/issues with running Make or bash scripts to debug or generate zip files for lab submission, follow the link [here](https://github.gatech.edu/pages/ECE3058/website/resources/compiling/compiling/)

## **A Hint on Verilog[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#a-hint-on-verilog)**

In Verilog there are two different comparison operators. They have distinct purposes and behaviors:

1. `==` (Double Equal):  
2. The `==` operator is used for simple equality comparison.  
3. It compares two values for equality without considering the "unknown" (x or z) values.  
4. If both operands have the same value (0 or 1), it returns true. If they are different, it returns false.

Example: `a \== b; // Returns true if 'a' and 'b' are both 0 or both 1\.`

1. `===` (Triple Equal):  
2. The `===` operator is used for "case equality" comparison.  
3. It compares two values while considering "unknown" (x or z) values as well.  
4. It returns true if the two values are identical, even if they contain "unknown" values. It returns false if they differ in any way, including the presence of "unknown" values.

Example: `a === b; // Returns true if 'a' and 'b' are identical, including 'x' and 'z' values.`

In summary, the Double Equal is a simple equality comparison operator that only considers 0 and 1, while the Triple Equal is used for case equality and considers "unknown" values in the comparison.

In Lab 2, `EX_reg` sometimes has a high impedance value. You needed to take this into account while you designed your stall controller. Note that there are other ways to do this, but the `===` is a simple built-in function that could have been used to achieve this check.

For more see [ChipVerify](https://www.chipverify.com/verilog/verilog-operators) for additional explination.

