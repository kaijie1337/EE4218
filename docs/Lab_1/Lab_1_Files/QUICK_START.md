# Quick Start Guide - Lab 1 Matrix Multiplication Coprocessor

## Overview
This implementation provides a complete AXI Stream matrix multiplication coprocessor that computes RES = (A × B) / 256 for matrices:
- A: 2×4 matrix (8-bit elements)
- B: 4×1 matrix (8-bit elements)
- RES: 2×1 matrix (8-bit elements)

## Files to Use

### Verilog Implementation
If you prefer Verilog, use these files:
- `myip_v1_0.v` - Top-level AXI Stream coprocessor
- `matrix_multiply.v` - Matrix multiplication unit
- `memory_RAM.v` - RAM module (no changes needed)
- `tb_myip_v1_0.v` - Self-checking testbench
- `test_input.mem` - Test input vectors
- `test_result_expected.mem` - Expected output vectors

### VHDL Implementation
If you prefer VHDL:
- The VHDL files (`.vhd`) are provided but **NOT IMPLEMENTED**
- You can mix Verilog and VHDL (e.g., use Verilog modules with VHDL testbench)
- For this assignment, the Verilog files are complete and ready to use

## Quick Test in Vivado

### Step 1: Create Project
```
1. Open Vivado
2. Create New Project → RTL Project
3. Do not add sources yet
```

### Step 2: Add Files
```
1. Add Design Sources:
   - myip_v1_0.v
   - matrix_multiply.v
   - memory_RAM.v

2. Add Simulation Sources:
   - tb_myip_v1_0.v (set as top)
   - test_input.mem (will be recognized as Memory File)
   - test_result_expected.mem (will be recognized as Memory File)
```

### Step 3: Run Behavioral Simulation
```
1. Click "Run Simulation" → "Run Behavioral Simulation"
2. Wait for simulation to complete
3. Check console output for "Test Passed" message
4. Examine waveforms to verify operation
```

### Step 4: Run Synthesis
```
1. Click "Run Synthesis"
2. Check synthesis report for:
   - Resource usage (LUTs, FFs, BRAMs)
   - No critical warnings
   - Timing estimates
3. Review "Detailed RTL Component Info" to see inferred components
```

### Step 5: Run Post-Synthesis Simulation
```
1. Click "Run Simulation" → "Run Post-Synthesis Functional Simulation"
2. Verify "Test Passed" message
3. This confirms the design works after synthesis
```

## Expected Behavior

### Test Case 1
**Input:**
- A = [[10, 20, 30, 40], [50, 60, 70, 80]]
- B = [[10], [20], [30], [40]]

**Output:**
- RES[0] = 11 (0x0B)
- RES[1] = 27 (0x1B)

### Test Case 2
**Input:**
- A = [[20, 30, 40, 50], [60, 70, 80, 127]]
- B = [[20], [30], [40], [50]]

**Output:**
- RES[0] = 21 (0x15)
- RES[1] = 50 (0x32)

## Waveform Signals to Monitor

### Top-Level (myip_v1_0)
- `state` - Current state of FSM (Idle=8, Read_Inputs=4, Compute=2, Write_Outputs=1)
- `S_AXIS_TVALID`, `S_AXIS_TREADY`, `S_AXIS_TDATA` - Input interface
- `M_AXIS_TVALID`, `M_AXIS_TREADY`, `M_AXIS_TDATA` - Output interface
- `Start`, `Done` - Control signals to/from matrix_multiply
- `read_counter`, `write_counter` - Progress counters

### Matrix Multiply Unit
- `state` - FSM state
- `a_addr`, `b_addr`, `res_addr` - RAM addresses
- `k_counter` - Dot product iteration counter
- `accumulator` - Partial sum accumulator
- `A_read_data_out`, `B_read_data_out` - Data from RAMs

### RAMs
- `A_RAM/RAM` - Contents of A matrix
- `B_RAM/RAM` - Contents of B matrix
- `RES_RAM/RAM` - Contents of result matrix

## Common Issues and Solutions

### Issue: Test Failed
**Possible Causes:**
1. Incorrect test vectors
2. Wrong matrix dimensions in parameters
3. Timing issue with synchronous reads

**Debug Steps:**
1. Check waveforms around the failure point
2. Verify RAM contents after Read_Inputs state
3. Check accumulator values during computation
4. Verify RES_RAM contents before Write_Outputs

### Issue: Simulation Hangs
**Possible Causes:**
1. State machine stuck in a state
2. Handshake deadlock (TVALID/TREADY)

**Debug Steps:**
1. Check which state the FSM is stuck in
2. Verify Start/Done handshake
3. Check AXIS handshakes

### Issue: Synthesis Warnings
**Expected Warnings:**
- If using the original template without modifications, ~56 warnings about unused signals
- After implementation, should have minimal warnings

**Critical Warnings to Address:**
- Inferred latches (indicates incomplete case statements)
- Multi-driven nets (indicates signal assignment conflicts)
- Combinational loops

## Modifying for Different Matrix Sizes

To change matrix dimensions, modify these parameters in `myip_v1_0.v`:

```verilog
localparam A_depth_bits = 3;  // 2^3 = 8 elements in A
localparam B_depth_bits = 2;  // 2^2 = 4 elements in B  
localparam RES_depth_bits = 1; // 2^1 = 2 elements in RES

localparam NUMBER_OF_INPUT_WORDS = 12;  // 8 + 4
localparam NUMBER_OF_OUTPUT_WORDS = 2;   // 2
```

For example, for 4×8 matrix A and 8×1 matrix B:
```verilog
localparam A_depth_bits = 5;  // 2^5 = 32 elements (4×8)
localparam B_depth_bits = 3;  // 2^3 = 8 elements (8×1)
localparam RES_depth_bits = 2; // 2^2 = 4 elements (4×1)

localparam NUMBER_OF_INPUT_WORDS = 40;  // 32 + 8
localparam NUMBER_OF_OUTPUT_WORDS = 4;   // 4
```

Also update testbench parameters and test vectors accordingly.

## Performance Analysis

For m×n matrix A and n×1 matrix B:
- **Read Phase**: (m×n + n) cycles
- **Compute Phase**: m × (2n + 2) cycles (approximately)
- **Write Phase**: m + 1 cycles
- **Total**: ~m×(2n+3) + n + 1 cycles

For current implementation (m=2, n=4):
- Read: 12 cycles
- Compute: 2×10 = 20 cycles
- Write: 3 cycles
- **Total: ~35 cycles per operation**

## Tips for Demo

1. **Run both behavioral and post-synthesis simulations** - shows the design works in both cases
2. **Show waveforms** - especially state transitions and data flow
3. **Explain key decisions** - why separate RAMs, synchronous reads, etc.
4. **Show resource usage** - how many LUTs, FFs, BRAMs used
5. **Be ready to modify** - show how to change matrix dimensions

## Support

For detailed implementation notes, see `IMPLEMENTATION_NOTES.md`.
For assignment requirements, see `../1_Intro.md` and `../2_Design_Tips.md`.
