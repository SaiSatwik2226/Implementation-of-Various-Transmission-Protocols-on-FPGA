
`timescale 10ns / 1ps


module i2c_master(
	input wire clk,
	input wire reset,
	input wire [6:0] addr,
	input wire [7:0] data_in,
	input wire enable,
	input wire rw,

	output reg [7:0] data_out,
	output wire ready,

	inout i2c_sda,
	inout wire i2c_scl
	);

	parameter IDLE = 0;
	parameter START = 1;
	parameter ADDRESS = 2;
	parameter ADDR_ACKNOWLEDGE = 3;
	parameter WRITE_DATA = 4;
	parameter WRITE_ACKNOWLEDGE = 5;
	parameter READ_DATA = 6;
	parameter DATA_ACKNOWLEDGE = 7;
	parameter STOP = 8;
	
	parameter CLK_DIVIDER = 100; //for converting 100MHz clock to 1MHz if we are considering a speed of 1Mbps for i2c

	reg [3:0] state;
	reg [7:0] saved_addr;
	reg [7:0] saved_data;
	reg [2:0] counter;				//Counter for counting data or address bits
	reg [7:0] clk_counter = 0;	//Counter for counting FPGA clock
	reg write_enable;
	reg sda_out;
	reg i2c_scl_enable = 0;
	reg i2c_clk = 1;

	assign ready = ((reset == 0) && (state == IDLE)) ? 1 : 0;
	assign i2c_scl = (i2c_scl_enable == 0 ) ? 1 : i2c_clk;
	assign i2c_sda = (write_enable == 1) ? sda_out : 'bz;
	
	
	
	//Generating i2c clock
	always @(posedge clk) begin
		if (clk_counter == (CLK_DIVIDER/2) - 1) begin
			i2c_clk <= ~i2c_clk;
			clk_counter <= 0;
		end
		else clk_counter <= clk_counter + 1;
	end 
	
	
	//Generating i2c Clock Enable
	always @(negedge i2c_clk, posedge reset) begin
		if(reset == 1) begin
			i2c_scl_enable <= 0;
		end 
		else begin
			if ((state == IDLE) || (state == START) || (state == STOP)) begin
				i2c_scl_enable <= 0;
			end else begin
				i2c_scl_enable <= 1;
			end
		end
	
	end


	//Data Transfer
	always @(posedge i2c_clk, posedge reset) begin
		if(reset == 1) begin
			state <= IDLE;
		end		
		else begin
			case(state)
			
				IDLE: begin
					if (enable) begin
						state <= START;
						saved_addr <= {addr, rw};
						saved_data <= data_in;
					end
					else state <= IDLE;
				end

				START: begin
					counter <= 7;
					state <= ADDRESS;
				end

				ADDRESS: begin
					if (counter == 0) begin 
						state <= ADDR_ACKNOWLEDGE;
					end
					else counter <= counter - 1;
				end
				
				
				//Address Acknowledge
				ADDR_ACKNOWLEDGE: begin
					if (i2c_sda == 0) begin
						counter <= 7;
						if(saved_addr[0] == 0) state <= WRITE_DATA;
						else state <= READ_DATA;
					end else state <= STOP;
				end

				WRITE_DATA: begin
					if(counter == 0) begin
						state <= DATA_ACKNOWLEDGE;
					end else counter <= counter - 1;
				end
				
				DATA_ACKNOWLEDGE: begin
					if ((i2c_sda == 0) && (enable == 1)) state <= IDLE;
					else state <= STOP;
				end

				READ_DATA: begin
					data_out[counter] <= i2c_sda;
					if (counter == 0) state <= WRITE_ACKNOWLEDGE;
					else counter <= counter - 1;
				end
				
				WRITE_ACKNOWLEDGE: begin
					state <= STOP;
				end

				STOP: begin
					state <= IDLE;
				end
			endcase
		end
	end
	
	always @(negedge i2c_clk, posedge reset) begin
		if(reset == 1) begin
			write_enable <= 1;
			sda_out <= 1;
		end else begin
			case(state)
				
				START: begin
					write_enable <= 1;
					sda_out <= 0;
				end
				
				ADDRESS: begin
					sda_out <= saved_addr[counter];
				end
				
				ADDR_ACKNOWLEDGE: begin
					write_enable <= 0;
				end
				
				WRITE_DATA: begin 
					write_enable <= 1;
					sda_out <= saved_data[counter];
				end
				
				WRITE_ACKNOWLEDGE: begin
					write_enable <= 1;
					sda_out <= 0;
				end
				
				READ_DATA: begin
					write_enable <= 0;				
				end
				
				STOP: begin
					write_enable <= 1;
					sda_out <= 1;
				end
			endcase
		end
	end

endmodule