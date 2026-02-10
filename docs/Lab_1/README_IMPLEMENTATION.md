# Lab 1 - Matrix Multiplication Coprocessor Implementation

## What Was Implemented

This PR implements a complete AXI Stream Matrix Multiplication Coprocessor as specified in `docs/Lab_1/1_Intro.md`.

### Functionality
The coprocessor computes: **RES = (A × B) / 256**

Where:
- **A** is a 2×4 matrix (8-bit unsigned elements)
- **B** is a 4×1 matrix (8-bit unsigned elements)  
- **RES** is a 2×1 matrix (8-bit unsigned elements)

The design uses AXI Stream protocol for input/output and is parameterized to easily support different matrix dimensions.

## Files Modified

All files are in `docs/Lab_1/Lab_1_Files/`:

### Core Implementation (Verilog)
1. **myip_v1_0.v** - Top-level AXI Stream coprocessor with state machine
2. **matrix_multiply.v** - Matrix multiplication computation unit
3. **tb_myip_v1_0.v** - Self-checking testbench (parameters updated)
4. **test_input.mem** - Test input vectors (2 test cases)
5. **test_result_expected.mem** - Expected output vectors

### Documentation
- **QUICK_START.md** - Step-by-step guide to test in Vivado
- **IMPLEMENTATION_NOTES.md** - Detailed technical documentation

### Unchanged Files
- **memory_RAM.v** - RAM module (provided, no changes needed)
- **\*.vhd** files - VHDL templates (not implemented in this PR)

## Key Features

### Design Architecture
- **Modular Design**: Separate modules for top-level control, matrix multiply, and memory
- **State Machines**: 
  - Top-level: 4 states (Idle, Read_Inputs, Compute, Write_Outputs)
  - Matrix multiply: 5 states (IDLE, READ_A_B, ACCUMULATE, WRITE_RES, DONE_STATE)
- **Synchronous RAM Access**: Follows Xilinx best practices for timing
- **Parameterized**: Easy to modify for different matrix dimensions

### Implementation Details
- **Fixed-Point Arithmetic**: Uses 0.8 format with implicit scale factor of 256
- **Division by 256**: Implemented as bit selection (no divider hardware)
- **AXI Stream Protocol**: Full handshake support (TVALID, TREADY, TLAST)
- **Continuous Operation**: Can handle back-to-back matrix multiplications

### Test Vectors
Two test cases with manually verified results:

**Test Case 1:**
- A = [[10, 20, 30, 40], [50, 60, 70, 80]]
- B = [[10], [20], [30], [40]]
- Expected: RES = [11, 27]

**Test Case 2:**
- A = [[20, 30, 40, 50], [60, 70, 80, 127]]
- B = [[20], [30], [40], [50]]
- Expected: RES = [21, 50]

## How to Test

### Quick Test (Recommended)
See `docs/Lab_1/Lab_1_Files/QUICK_START.md` for detailed instructions.

### Summary Steps
1. **Create Vivado Project** and add the files
2. **Run Behavioral Simulation** - Should print "Test Passed"
3. **Run Synthesis** - Check resource usage and warnings
4. **Run Post-Synthesis Simulation** - Verify it still works

## Performance

For the current 2×4 × 4×1 matrix multiplication:
- **Total Cycles**: ~51 cycles per operation
  - Input: 12 cycles (receiving data)
  - Compute: ~36 cycles (matrix multiplication)
  - Output: 3 cycles (sending results)

## Design Decisions

1. **Separate A and B RAMs**: Clearer design, easier to debug and verify
2. **Synchronous Reads**: Better timing performance for synthesis
3. **State-Based Control**: Modular, maintainable, easy to verify
4. **Parameterized Dimensions**: Easy to scale to different matrix sizes

## Extensibility

The design can be easily modified for different matrix dimensions by changing parameters in `myip_v1_0.v`:

```verilog
localparam A_depth_bits = 3;     // log2(#elements in A)
localparam B_depth_bits = 2;     // log2(#elements in B)
localparam RES_depth_bits = 1;   // log2(#elements in RES)
```

## Next Steps

This implementation satisfies Assignment 1 requirements for Lab 1. Users should:

1. ✅ Test with behavioral simulation in Vivado
2. ✅ Verify synthesis with no critical warnings  
3. ✅ Run post-synthesis functional simulation
4. ✅ Analyze resource usage (LUTs, FFs, BRAMs)
5. ✅ Prepare demo for Week 5

The design is ready for integration into the complete system in Lab 3.

## References

- Assignment description: `docs/Lab_1/1_Intro.md`
- Design tips: `docs/Lab_1/2_Design_Tips.md`
- Quick start: `docs/Lab_1/Lab_1_Files/QUICK_START.md`
- Technical notes: `docs/Lab_1/Lab_1_Files/IMPLEMENTATION_NOTES.md`
