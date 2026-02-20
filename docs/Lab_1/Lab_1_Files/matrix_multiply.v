`timescale 1ns / 1ps

/* 
----------------------------------------------------------------------------------
--	(c) Rajesh C Panicker, NUS
--  Description : Template for the Matrix Multiply unit for the AXI Stream Coprocessor
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post a modified version of this on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept the responsibility to ensure that your implementation does not violate any intellectual property of any entity.
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course EE4218 at the National University of Singapore);
--		(vi) retain this notice in this file or any files derived from this.
----------------------------------------------------------------------------------
*/

// those outputs which are assigned in an always block of matrix_multiply shoud be changes to reg (such as output reg Done).

module matrix_multiply
	#(	parameter width = 8, 			// width is the number of bits per location
		parameter A_depth_bits = 3, 	// depth is the number of locations (2^number of address bits)
		parameter B_depth_bits = 2, 
		parameter RES_depth_bits = 1,
		parameter m = 2,					// number of rows in A
		parameter n = 4					// number of columns in A and number of rows in B
	) 
	(
		input clk,										
		input Start,									// myip_v1_0 -> matrix_multiply_0.
		output reg Done = 0,									// matrix_multiply_0 -> myip_v1_0. Possibly reg.
		
		output reg A_read_en = 0,  								// matrix_multiply_0 -> A_RAM. Possibly reg.
		output reg [A_depth_bits-1:0] A_read_address = 0, 		// matrix_multiply_0 -> A_RAM. Possibly reg.
		input [width-1:0] A_read_data_out,				// A_RAM -> matrix_multiply_0.
		
		output reg B_read_en = 0, 								// matrix_multiply_0 -> B_RAM. Possibly reg.
		output reg [B_depth_bits-1:0] B_read_address = 0, 		// matrix_multiply_0 -> B_RAM. Possibly reg.
		input [width-1:0] B_read_data_out,				// B_RAM -> matrix_multiply_0.
		
		output reg RES_write_en = 0, 							// matrix_multiply_0 -> RES_RAM. Possibly reg.
		output reg [RES_depth_bits-1:0] RES_write_address = 0, 	// matrix_multiply_0 -> RES_RAM. Possibly reg.
		output reg [width-1:0] RES_write_data_in = 0			// matrix_multiply_0 -> RES_RAM. Possibly reg.
	);
	
	// implement the logic to read A_RAM, read B_RAM, do the multiplication and write the results to RES_RAM
	// Note: A_RAM and B_RAM are to be read synchronously. Read the wiki for more details.

	localparam IDLE = 0, READ = 1, CALCULATE = 2, WRITE = 3; // you can change these states as appropriate.
	reg [1:0] state = IDLE; // you can change the number of bits as appropriate.
	reg [1:0] next_state = IDLE;

	reg Start_prev = 0; // to store the previous value of Start. You can change this as appropriate.
	reg [width-1:0] A_data = 0; // to store the data read from A_RAM. You can change this as appropriate.
	reg [width-1:0] B_data = 0; // to store the data read from B_RAM. You can change this as appropriate.
	reg [2*width-1:0] RES_data [0:2**RES_depth_bits-1]; // RES_data stores 2**RES_depth_bits-1 results of 2*width bits to avoid overflow
	integer i;

	// no. of bits for row and column counters. If m or n is 1, default to 1 bit to represent the counter
	localparam integer ROW_CNT_W = (m > 1) ? $clog2(m) : 1;
	localparam integer COL_CNT_W = (n > 1) ? $clog2(n) : 1;
	// counters for rows and columns
	reg [ROW_CNT_W-1:0] row_counter = 0;
	reg [COL_CNT_W-1:0] col_counter = 0;

	// start debouncing, only start the multiplication when Start goes from 0 to 1 and not on every cycle when Start is 1.
	wire start_pulse = Start && !Start_prev;
	// checks if current multiplication is the last one
	wire last_mul = (row_counter == m - 1) && (col_counter == n - 1);
	// checks if current write is the last one
	wire last_write = (RES_write_address == m - 1);

	// Combinational logic for next state and output generation
	always @(*) begin
		// next-state logic only
		next_state = state;
		case (state)
			// Wait for Start to go high. Then move to READ
			IDLE: begin
				if (start_pulse) begin
					next_state = READ;
				end
			end

			// Read RAM A and B synchronously. Then move to CALCULATE
			READ: begin
				next_state = CALCULATE;
			end

			// Stay in READ-CALCULATE loop till all multiplications for the current row are done. Then move to WRITE.
			CALCULATE: begin
				if (last_mul) begin
					next_state = WRITE;
				end else begin
					next_state = READ;
				end
			end

			// Stay in WRITE till all results are written to RES_RAM. Then move to IDLE.
			WRITE: begin
				if (last_write) begin
					next_state = IDLE;
				end
			end

			default: next_state = IDLE;
		endcase
	end

	always @(posedge clk) begin
		// register state and defaults
		state <= next_state;
		Start_prev <= Start;

		A_read_en <= 0;
		B_read_en <= 0;
		RES_write_en <= 0;

		case (state)
			IDLE: begin
				Done <= 1'b0;
				if (start_pulse) begin // initialize all the registers and counters at the start of multiplication before READ state
					A_read_address <= 0;
					B_read_address <= 0;
					RES_write_address <= 0;
					row_counter <= 0;
					col_counter <= 0;
					for (i = 0; i < m; i = i + 1) begin // initialize the RES_data registers to 0 at the start of multiplication
						RES_data[i] <= 0;
					end
				end
			end

			READ: begin
				// set read enables and addresses for A_RAM and B_RAM
				A_read_en <= 1;
				B_read_en <= 1;
				A_read_address <= A_read_address + 1;
				B_read_address <= col_counter;
			end

			CALCULATE: begin
				// since read enables and addresses are set in the previous READ state, directly use the read data outputs from A_RAM and B_RAM for multiplication and accumulation.
				// read data directly from inputs A_read_data_out and B_read_data_out and do the multiplication and accumulation in RES_data registers.
				RES_data[row_counter] <= RES_data[row_counter] + ((A_read_data_out * B_read_data_out) >> 8); // divide by 256 using right shift by 8 bits
				if (!last_mul) begin
					if (col_counter == n - 1) row_counter <= row_counter + 1'b1; // move on to the next row after finishing all columns of the current row
					col_counter <= col_counter + 1; // moves on to next element in row (next column) then automatically wraps around to 0 when it reaches last element in row (last column or n-1)
				end
			end

			WRITE: begin
				RES_write_en <= 1'b1;
				RES_write_data_in <= RES_data[RES_write_address];
				RES_write_address <= RES_write_address + 1'b1;
				if (last_write) begin
					Done <= 1'b1;
					Start_prev <= 0; 
				end
			end

			default: begin
				state <= IDLE;
			end
		endcase
	end

endmodule


