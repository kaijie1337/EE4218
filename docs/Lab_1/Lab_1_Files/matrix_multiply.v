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
		parameter RES_depth_bits = 1
	) 
	(
		input clk,										
		input Start,									// myip_v1_0 -> matrix_multiply_0.
		output Done,									// matrix_multiply_0 -> myip_v1_0. Possibly reg.
		
		output A_read_en,  								// matrix_multiply_0 -> A_RAM. Possibly reg.
		output [A_depth_bits-1:0] A_read_address, 		// matrix_multiply_0 -> A_RAM. Possibly reg.
		input [width-1:0] A_read_data_out,				// A_RAM -> matrix_multiply_0.
		
		output B_read_en, 								// matrix_multiply_0 -> B_RAM. Possibly reg.
		output [B_depth_bits-1:0] B_read_address, 		// matrix_multiply_0 -> B_RAM. Possibly reg.
		input [width-1:0] B_read_data_out,				// B_RAM -> matrix_multiply_0.
		
		output RES_write_en, 							// matrix_multiply_0 -> RES_RAM. Possibly reg.
		output [RES_depth_bits-1:0] RES_write_address, 	// matrix_multiply_0 -> RES_RAM. Possibly reg.
		output [width-1:0] RES_write_data_in 			// matrix_multiply_0 -> RES_RAM. Possibly reg.
	);
	
	// implement the logic to read A_RAM, read B_RAM, do the multiplication and write the results to RES_RAM
	// Note: A_RAM and B_RAM are to be read synchronously. Read the wiki for more details.

	// Parameters for matrix dimensions
	// A is m x n matrix, B is n x 1 matrix, RES is m x 1 matrix
	// For assignment: m = 2, n = 4
	localparam m = 2**RES_depth_bits;  // number of rows in A (and RES)
	localparam n = 2**B_depth_bits;    // number of columns in A (and rows in B)
	
	// State machine for matrix multiplication
	localparam IDLE = 3'b000;
	localparam READ_A_B = 3'b001;
	localparam ACCUMULATE = 3'b010;
	localparam WRITE_RES = 3'b011;
	localparam DONE_STATE = 3'b100;
	
	reg [2:0] state, next_state;
	reg [A_depth_bits-1:0] a_addr;
	reg [B_depth_bits-1:0] b_addr;
	reg [RES_depth_bits-1:0] res_addr;
	reg [$clog2(n):0] k_counter;  // counter for dot product (0 to n-1)
	reg [width*2-1:0] accumulator;  // accumulator for partial sum (16 bits for 8-bit * 8-bit)
	reg a_rd_en, b_rd_en, res_wr_en;
	reg done_reg;
	
	// Output assignments
	assign A_read_en = a_rd_en;
	assign A_read_address = a_addr;
	assign B_read_en = b_rd_en;
	assign B_read_address = b_addr;
	assign RES_write_en = res_wr_en;
	assign RES_write_address = res_addr;
	assign RES_write_data_in = accumulator[width*2-1:width];  // divide by 256 (take upper 8 bits)
	assign Done = done_reg;
	
	// State machine
	always @(posedge clk) begin
		state <= next_state;
	end
	
	always @(*) begin
		next_state = state;
		case (state)
			IDLE: begin
				if (Start)
					next_state = READ_A_B;
			end
			READ_A_B: begin
				// Stay in this state for one cycle to get data from RAMs
				next_state = ACCUMULATE;
			end
			ACCUMULATE: begin
				if (k_counter == n-1)
					next_state = WRITE_RES;
				else
					next_state = READ_A_B;
			end
			WRITE_RES: begin
				if (res_addr == m-1)
					next_state = DONE_STATE;
				else
					next_state = READ_A_B;
			end
			DONE_STATE: begin
				next_state = IDLE;
			end
			default: next_state = IDLE;
		endcase
	end
	
	// Datapath
	always @(posedge clk) begin
		case (state)
			IDLE: begin
				a_addr <= 0;
				b_addr <= 0;
				res_addr <= 0;
				k_counter <= 0;
				accumulator <= 0;
				a_rd_en <= 0;
				b_rd_en <= 0;
				res_wr_en <= 0;
				done_reg <= 0;
			end
			READ_A_B: begin
				// Request read from A and B RAMs
				// A address: row * n + k (where row = res_addr, k = k_counter)
				// B address: k
				a_addr <= (res_addr << $clog2(n)) + k_counter;  // res_addr * n + k_counter
				b_addr <= k_counter;
				a_rd_en <= 1;
				b_rd_en <= 1;
				res_wr_en <= 0;
				done_reg <= 0;
			end
			ACCUMULATE: begin
				// Data from RAMs is now available, multiply and accumulate
				accumulator <= accumulator + (A_read_data_out * B_read_data_out);
				k_counter <= k_counter + 1;
				a_rd_en <= 0;
				b_rd_en <= 0;
				res_wr_en <= 0;
				done_reg <= 0;
			end
			WRITE_RES: begin
				// Write accumulated result to RES RAM
				res_wr_en <= 1;
				// accumulator already contains the result
				// Reset for next row
				k_counter <= 0;
				accumulator <= 0;
				res_addr <= res_addr + 1;
				a_rd_en <= 0;
				b_rd_en <= 0;
				done_reg <= 0;
			end
			DONE_STATE: begin
				// Assert done for one cycle
				done_reg <= 1;
				res_wr_en <= 0;
				a_rd_en <= 0;
				b_rd_en <= 0;
			end
		endcase
	end

endmodule


