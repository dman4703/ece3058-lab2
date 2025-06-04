## **Pipelined Processor**

Go ahead and [download](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/assignment.zip) the assignment.

## **Required Tools for this lab[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#required-tools-for-this-lab)**

1. If you've Linux or Windows (WSL), then it is recommended to use [iverilog](https://github.gatech.edu/pages/ECE3058/website/resources/iverilog/iverilog) with [GTKwave or Scansion](https://github.gatech.edu/pages/ECE3058/website/resources/VCD/vcd/)

# **Lab Assignment 2 (*100 points total*)[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#lab-assignment-2-100-points-total)**

## **Problem Description[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#problem-description)**

After you've built the computer for your friend from last lab, he keeps complaining that its too slow. You decide to help him again. In order to speedup the clock rate, you'll need to modify your datapath to the pipeline design you learned in class. Luckily for you, someone else has already provided an outline for the datapath but with several bugs and essential missing components required for pipelining to work efficently. You're task is to add in these missing pieces.

The mermaid figure below is a high-level view of the current pipeline implementation from the given **system verilog** code. It should be very similiar to the one presented in class. Please note that many wires/connections are missing.

```
graph TD
    %% Instruction Fetch Module
    subgraph IF["InstructionFetch_Module"]
        PC["PC"]
        IM["Instruction<br/>Memory"]
        FM["Fetch Module"]
        PC --> IM
        FM --> PC
    end
    
    %% Instruction Decode Module
    subgraph ID["InstructionDecode_Module"]
        RF["32x32 Register File"]
        DM["Decode Module"]
        SC["Stall Controller"]
        RF --> DM
        DM --> RF
    end
    
    %% Instruction Execute Module
    subgraph IE["InstructionExecute_Module"]
        ALU["ALU Unit"]
        COMP["Comparator"]
        FCM["Foward Controller Module"]
        OPA["Operand Mux A"]
        OPB["Operand Mux B"]
        FCM --> OPA
        FCM --> OPB
        OPA --> ALU
        OPB --> COMP
    end
    
    %% Memory Module
    subgraph MEM["Memory_Module"]
        DM_MEM["Data Memory"]
        LSU["LSU Unit"]
        DM_MEM --> LSU
        LSU --> DM_MEM
    end
    
    %% WriteBack Module
    subgraph WB["WriteBack_Module"]
        WBM["Writeback Module"]
    end
    
    %% inter‑stage pipeline registers
    FD["IF/ID Latch"]
    DE["ID/EX Latch"]
    EM["EX/MEM Latch"]
    MW["MEM/WB Latch"]
    
    %% connections
    IM --> FD
    PC --> FD

    FD --> DM

    DE --> OPA
    DE --> OPB
    ALU --> EM
    COMP --> EM

    EM --> OPA
    EM --> OPB
    EM --> LSU

    LSU --> MW

    MW --> WBM

    WBM --> OPA
    WBM --> OPB
```

### Processor Specifications[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#processor-specifications)

The pipeline for our application will implement 6 instructions of the RV32I ISA. The specifications are detailed below.

1. The microarchiecture will need to implement the following instructions of the RV32I: `ADD`, `ADDI`, `SUB` `LW`, `SLT`, and `JAL` 

2. There are two forwarding lines to forward the ALU result from the MEM and WB back to the EX stage based on `PipelineHighLevelView.pptx`.  
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

In this lab, you will perform the following tasks:

### Design Task[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#design-task)

Similar to the previous lab, create a diagram to identify the connections between modules. Make sure to include all of the modules in `Core.sv` and indicate the connections between the modules. Highlight the location of the Stall Controller and the Forward Controller. The mermaid diagram shown below can help you get started with conceptualizing the design.

```
graph TD
    %% Instruction Fetch Module
    subgraph IF["InstructionFetch_Module"]
        PC["PC"]
        IM["Instruction<br/>Memory"]
        FM["Fetch Module"]
        PC --> IM
        FM --> PC
    end
    
    %% Instruction Decode Module
    subgraph ID["InstructionDecode_Module"]
        RF["32x32 Register File"]
        DM["Decode Module"]
        SC["Stall Controller"]
        RF --> DM
        DM --> RF
    end
    
    %% Instruction Execute Module
    subgraph IE["InstructionExecute_Module"]
        ALU["ALU Unit"]
        COMP["Comparator"]
        FCM["Foward Controller Module"]
        OPA["Operand Mux A"]
        OPB["Operand Mux B"]
        FCM --> OPA
        FCM --> OPB
        OPA --> ALU
        OPB --> COMP
    end
    
    %% Memory Module
    subgraph MEM["Memory_Module"]
        DM_MEM["Data Memory"]
        LSU["LSU Unit"]
        DM_MEM --> LSU
        LSU --> DM_MEM
    end
    
    %% WriteBack Module
    subgraph WB["WriteBack_Module"]
        WBM["Writeback Module"]
    end
    
    %% inter‑stage pipeline registers
    FD["IF/ID Latch"]
    DE["ID/EX Latch"]
    EM["EX/MEM Latch"]
    MW["MEM/WB Latch"]
    
    %% connections
    IM --> FD
    PC --> FD

    FD --> DM

    DE --> OPA
    DE --> OPB
    ALU --> EM
    COMP --> EM

    EM --> OPA
    EM --> OPB
    EM --> LSU

    LSU --> MW

    MW --> WBM

    WBM --> OPA
    WBM --> OPB
```

Consider the following instructions on a pipelined processor. Explain why the add will have an issue and what possible solutions could be used to solve the issue.

|  | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| lw $2, 0 | F | D | E | M | WB |  |  |  |  |  |  |  |  |  |
| lw $3, 0x4 |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| add $1, $2, $3 |  |  |  |  |  |  |  |  |  |  |  |  |  |  |

### Code Task[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#code-task)

1. Add support for the load-to-use stall. For example, if a `lw` instruction produces data used by an immediately following instruction, one stall cycle should be included between the `lw` and the immediately following instruction.  
2. Currently the processor does not stall when the instruction following the load depends on it. The logic that needs to be repaired to add load-to-use stall is in the file `Stall_Control.sv`. Add support for writeback stalls. This is detailed in the 2nd specification above. For example, if an add instruction writes data back to the register file addr. in the same CLK cycle that another instr. is in the *Decode* and reading the same register file addr. then you need to stall for one cycle to allow the data to be written back to the register file so that on the next CLK cycle, the correct value can be read.  
3. Implement data forwarding to the EX stage. There is a blank module called `FWD_CONT.sv` already created for you and instantiated within `Core.sv`. Feel free to modify the input/output ports if required in your implementation. Just how you checked for hazards in the `Stall_Control.sv` file, you will check for hazards and forward the correct value from EX/MEM or MEM/WB stage to the execute unit.  
4. Implement flushing in the pipeline. Note specification 4 above. Thus, the fetch stage will keep fetching instructions through `PC + 4` until the jump condition is resolved. Flushing out will mean clearing out the relevant (before branch resolution) registers.

**Functionally all the processor should still be generating correct logic after all the changes to implementing stalling, forwarding, and flushing.**

Build test cases by combining intructions to test out stalling, forwarding, and flushing. Some example functions are included in the following section.

# **Testing and Debugging[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#testing-and-debugging)**

To help you debug as well as better understand the tasks of lab 2, we've provided the waveforms for some of the tests that are running in Gradescope. Their names below correspond to the test names you see in Gradescope. You are NOT REQUIRED to match these waveforms. They are only here to help you as a guide to debug the test cases and show what the proper execution of the test cases should be in order to pass. The waveforms may even contain irrelevant wires and signals, but ultimately the most important considerations for our cases are the register and memory values as these are what ensure functional correctness and the proper implementation of the 5 stage in-order pipeline. Your goal shouldn't be to try to match them bit by bit but rather make sure you understand what instructions are suppose to output. You should use the emulator form Lab0 to make sure you understand what's going on first and see what is outputted to memory and RF at every cycle and try to understand how you can obtain that rather than just diving directly in to match the waveforms because chances are you're not going to match every signal.

* Functional. [here](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/Functional.vcd)
```
0x00000000  
0xfec10493    
0x00c58533   
0x00002403   
0x40618a33   
0x01392ab3    
0x014005ef 
```
   
* Task 1 Simple. [here](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/Task1_Simple.vcd)
```
0x00000000   
0x00002483  
0x002480b3  
0x00402403  
0x006401b3
``` 
* Task 2 Simple. [here](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/Task2_Simple.vcd)
```
0x003100b3   
0x00418133   
0x005201b3  
0x00208233
```
* Task 2 Complex. [here](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/Task2_Complex.vcd)
```
0x00000000  
0x00000000  
0x00000000  
0x00002483  
0x00402403  
0x00002383  
0x00002083  
0x00000000  
0x00000000  
0x00402083  
0x00710133  
0x00402183  
0x01418233
``` 
* Task 3 Simple. [here](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/Task3_Simple.vcd)
```
0x00000000  
0x00000000  
0x00000000  
0x003100b3  
0x001100b3  
0x002080b3  
0x001480b3  
0x00148133  
0x00000000  
0x00248133  
0x406480b3  
0x009300b3  
0x40178133  
0x00000000
```
* Task 3 General. [here](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/Task3_General.vcd)
```
0x00000000  
0xffb00413  
0x00500433  
0x408304b3  
0x00002483  
0x008484b3  
0x408484b3  
0x00848633  
0x009425b3  
0x40b00133
```  
* Task 3 Complex [here](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/Task3_Long.vcd)
```
0x00000000      
0x00000000      
0x00000000      
0x00210133      
0x00210133      
0x00210133      
0x00210133      
0x00210133      
0x00210133      
0x00210133      
0x00210133      
0x00210133      
0x00210133      
0x01080833      
0x00000000      
0x01080833      
0x00000000      
0x01080833      
0x00000000      
0x00000000      
0x01080833      
0x41010733      
0x41070633      
0x00000000      
0x41070633      
0x410604b3      
0x002481b3      
0x00002483      
0x00348233      
0x40348233      
0xfec10113      
0x00402083    
```
* Task 4 Jal. [here](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/Task4_Jal.vcd)
```
0x00000000  
0x002282b3  
0x40760233  
0xff9ff56f  
0x405202b3  
0x00c20313
```
* Task 4 Jal Complex [here](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/Task4_Jal_Complex.vcd)
```
0x00000000   
0x00002783   
0x00178793   
0x0080056f   
0x00a182b3   
0x00a782b3   
0x004005ef   
0x0040066f   
0x00c582b3   
0x003282b3   
0x00c006ef   
0x003a8a33   
0xfd9ff76f   
0x00402683 
``` 
* Note: If you want to know what instructions are being executed for each test, you can decode the hexadecimal numbers. [https://luplab.gitlab.io/rvcodecjs/](https://luplab.gitlab.io/rvcodecjs/) is a good website that can encode/decode RISC-V instructions. E.g. `0x00c006ef \= jal x13, 12`

# **Template Modifications[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#template-modifications)**

You are free to modify the given template as desired. However our autograders do drive custom instruction streams and read corresponding outputs to check for correctness so we HIGHLY recommend working off of the given template. If you do make major changes (restructuring wholes files NOT adding a couple of wires), below is the list of verilog wires, modules, and filenames that we ask you do not modify. Please also make sure your processor still follows the specifications detailed above and is based on the architecture given in class. We also ask that you do not rename any of the file names for our autograder purposes.

* `data_RAM` in `DRAM.sv ` 
* `instr_RAM` in `Instr_Mem.sv`
* `Register_File.sv`  
* `DFlipFlop.sv`  
* `Register Module` in `ID_Stage.sv`  
* `Instruction Memory Module` in `IF_Stage.sv`  
* `DRAM Module` in `Core.sv`

## **Submission[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#submission)**

### **Design Task Submission[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#design-task-submission)**

For the [Design Task](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#design-task) you must submit a single PDF document to GradeScope. The PDF should include the design diagram you created based on the [verilog code for lab 2](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/assignment.zip). The PDF should also include the completed pipeline instruction VS time table found in the [Design Task](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#design-task) section.

### **Coding Task Submission[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#coding-task-submission)**

To clarify: 1\. First implement stalling for the task 1\. and 2\. and verify that it is working properly. 2\. Once stalling works implment forwarding. Verify forwarding is working by seeing only one stall in the case with a lw RAW. This is the case where the data is only avaliable after memory stage (you want to implement stalling first in order to verify that data is not being taken incorrectly in any case) 3\. Implement flushing and verify functionality

**All Tests on Gradescope assume that forwarding is working to the extent of the specification. Even the first test that tests load-to-use stalls assumes that forwarding is working to some extent**

For submission, please submit your tarball to Gradescope under the Lab2 Pipelining Assignment. To generate the tarball:

* If you're using the files in the regular assignment directory, simply just run `make submit` on your terminal where the Makefile is located (same as running make to generate your waveform). 

you'll end up with a file titled ece3058\_lab2\_submission.tar.gz that you will submit to Gradescope.

Make sure you add comments for the changes. Do NOT submit different RTL directories for the different tasks

For guidance/issues with running Make or bash scripts to debug or generate zip files for lab submission, follow the link [here](https://github.gatech.edu/pages/ECE3058/website/resources/compiling/compiling/)

## **Note about the Autograder[¶](https://github.gatech.edu/pages/ECE3058/website/labs/pipelined/pipelined/#note-about-the-autograder)**

The autograder does not try to match every signal bit for bit againsta reference based on the sample waveforms we've provided. The autograder only checks the RF and Mem after each cycle to make sure they are storing the correct values. The RF and Mem are what maintains the state of the execution at any given time and completely determines correctness. You should therefore be trying to match the memory and RF values.

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

Example: `a \=== b; // Returns true if 'a' and 'b' are identical, including 'x' and 'z' values.`

In summary, the Double Equal is a simple equality comparison operator that only considers 0 and 1, while the Triple Equal is used for case equality and considers "unknown" values in the comparison.

In Lab 2, `EX_reg` sometimes has a high impedance value. You needed to take this into account while you designed your stall controller. Note that there are other ways to do this, but the `===` is a simple built-in function that could have been used to achieve this check.

For more see [ChipVerify](https://www.chipverify.com/verilog/verilog-operators) for additional explination.

