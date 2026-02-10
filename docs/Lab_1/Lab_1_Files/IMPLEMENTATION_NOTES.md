# Lab 1 Implementation Notes

## Overview
This directory contains the implementation of an AXI Stream Matrix Multiplication Coprocessor as described in the Lab 1 assignment.

## Files Modified/Created

### 1. matrix_multiply.v
**Status**: Fully implemented

This module performs matrix multiplication with fixed-point division by 256.

**Implementation Details**:
- **State Machine**: 5 states (IDLE, READ_A_B, ACCUMULATE, WRITE_RES, DONE_STATE)
- **Algorithm**: For each row in matrix A:
  - Perform dot product with matrix B by iterating through columns
  - Accumulate partial products in a 16-bit accumulator
  - Divide by 256 by taking upper 8 bits of the 16-bit result
  - Write result to RES RAM
- **Parameterized**: Works with any m×n matrix A and n×1 matrix B

**Key Features**:
- Synchronous RAM reads (1 cycle latency)
- Pipelined operation: READ_A_B state requests data, ACCUMULATE state processes it
- Proper handling of matrix dimensions through parameters

### 2. myip_v1_0.v
**Status**: Fully implemented

Top-level AXI Stream coprocessor module that interfaces with the matrix_multiply unit and RAMs.

**Implementation Details**:
- **State Machine**: 4 states (Idle, Read_Inputs, Compute, Write_Outputs)
- **Read_Inputs State**: 
  - Receives 12 words via S_AXIS interface
  - First 8 words stored in A_RAM (2×4 matrix)
  - Next 4 words stored in B_RAM (4×1 matrix)
- **Compute State**:
  - Asserts Start signal to matrix_multiply unit
  - Waits for Done signal
  - Prepares for output by initiating first RES_RAM read
- **Write_Outputs State**:
  - Reads results from RES_RAM (synchronous read)
  - Outputs 2 words via M_AXIS interface
  - Properly handles M_AXIS_TREADY handshake

**Key Features**:
- Proper AXI Stream protocol implementation
- Synchronous RAM access with proper timing
- Ready to handle continuous operation (can accept new inputs after completing)

### 3. memory_RAM.v
**Status**: No changes required

Standard single-port synchronous RAM implementation provided by the instructor.

### 4. tb_myip_v1_0.v
**Status**: Updated parameters

**Changes**:
- NUMBER_OF_INPUT_WORDS: 4 → 12 (8 for A + 4 for B)
- NUMBER_OF_OUTPUT_WORDS: 4 → 2 (2 for RES)

### 5. test_input.mem
**Status**: Updated with matrix multiplication test vectors

**Test Case 1**:
- Matrix A: [[10, 20, 30, 40], [50, 60, 70, 80]]
- Matrix B: [[10], [20], [30], [40]]

**Test Case 2**:
- Matrix A: [[20, 30, 40, 50], [60, 70, 80, 127]]
- Matrix B: [[20], [30], [40], [50]]

### 6. test_result_expected.mem
**Status**: Updated with expected results

**Expected Results**:
- Test Case 1: [0x0B, 0x1B] = [11, 27]
- Test Case 2: [0x15, 0x32] = [21, 50]

**Calculations**:
- Result[0] = (A[0,:]·B) / 256
- Result[1] = (A[1,:]·B) / 256

## Matrix Dimensions
- **A**: 2 × 4 matrix (m=2, n=4)
- **B**: 4 × 1 matrix (n=4)
- **RES**: 2 × 1 matrix (m=2)

These dimensions are parameterized and can be easily changed by modifying the depth_bits parameters in myip_v1_0.v.

## Performance
For the current implementation (m=2, n=4):
- **Input Phase**: 12 cycles (receiving A and B)
- **Computation Phase**: ~18 cycles per row (2 cycles per multiply-accumulate × 4 + overhead) × 2 rows ≈ 36 cycles
- **Output Phase**: 3 cycles (1 wait + 2 outputs)
- **Total**: ~51 cycles per matrix multiplication

## Synthesis Considerations
- All RAMs will synthesize to Block RAM or Distributed RAM depending on size
- No asynchronous reads (good for timing)
- State machines use one-hot encoding (specified in myip_v1_0.v)
- All arithmetic operations are synthesizable
- Division by 256 is implemented as bit selection (no division hardware required)

## Testing Instructions
1. Add all .v files and .mem files to a Vivado project
2. Set tb_myip_v1_0.v as the simulation top module
3. Run behavioral simulation
4. Check for "Test Passed" message in console
5. Run synthesis to verify resource usage
6. Run post-synthesis functional simulation

## Design Decisions
1. **Separate A and B RAMs**: Clearer design, easier to debug
2. **Synchronous RAM reads**: Better timing performance, follows Xilinx best practices
3. **State-based matrix multiply**: Modular design, easier to verify and test
4. **Pipeline depth**: 2-cycle read-compute pipeline balances performance and complexity
5. **Fixed-point arithmetic**: Uses 0.8 format with implicit scale factor of 256

## Future Enhancements
- Add support for variable matrix dimensions (runtime configuration)
- Pipeline the matrix multiplication for higher throughput
- Add error checking and status reporting
- Support for larger matrices using burst transfers
