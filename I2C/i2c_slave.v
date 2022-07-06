`timescale 10ns / 1ps

module i2c_slave(
	inout sda,
	inout scl
	);
	
	parameter ADDRESS = 7'b1010101;
	
	parameter READ_ADDR = 0;
	parameter ADDR_ACKNOWLEDGE = 1;
	parameter READ_DATA = 2;
	parameter WRITE_DATA = 3;
	parameter DATA_ACKNOWLEDGE = 4;
	
	reg [7:0] addr;
	reg [2:0] counter;
	reg [2:0] state = 0;
	reg [7:0] data_in = 0;
	reg [7:0] data_out = 8'b11001100;
	reg sda_out = 0;
	reg sda_in = 0;
	reg start = 0;
	reg write_enable = 0;
	
	//whether to send data from SDA line or not.
	assign sda = (write_enable == 1) ? sda_out : 'bz;
	
	//checking for the start condition and initiating the transfer of data conditions
	always @(negedge sda) begin
		if ((start == 0) && (scl == 1)) begin
			start <= 1;	
			counter <= 7;
		end
	end
	
	//Counters and other signals are changed here.
	//Reading the input address so to findout which slave is the Master Talking to.
	always @(posedge sda) begin
		if ((start == 1) && (scl == 1)) begin
			state <= READ_ADDR;
			start <= 0;
			write_enable <= 0;
		end
	end
	
	//Begin the Data Transfer: Receive or Send
	always @(posedge scl) begin
		if (start == 1) begin
			case(state)
				READ_ADDR: begin
					addr[counter] <= sda;
					if(counter == 0) state <= ADDR_ACKNOWLEDGE;
					else counter <= counter - 1;					
				end
				
				//Depening on the LSB bit we come to know whether the Master is trying to send data or receive data
				ADDR_ACKNOWLEDGE: begin
					if(addr[7:1] == ADDRESS) begin
						counter <= 7;
						if(addr[0] == 0) begin 
							state <= READ_DATA;
						end
						else state <= WRITE_DATA;
					end
				end
				
				//If reading the Data is work, state changed to READ_DATA
				READ_DATA: begin
					data_in[counter] <= sda;
					if(counter == 0) begin
						state <= DATA_ACKNOWLEDGE;
					end else counter <= counter - 1;
				end
				
				DATA_ACKNOWLEDGE: begin
					state <= READ_ADDR;					
				end
				
				//If Writing the Data is work, state changed to WRITE_DATA
				WRITE_DATA: begin
					if(counter == 0) state <= READ_ADDR;
					else counter <= counter - 1;		
				end
				
			endcase
		end
	end
	
	
	//Actual Data trnsfer takes place here
	always @(negedge scl) begin
		case(state)
			
			READ_ADDR: begin
				write_enable <= 0;			
			end
			
			ADDR_ACKNOWLEDGE: begin
				sda_out <= 0;
				write_enable <= 1;	
			end
			
			READ_DATA: begin
				write_enable <= 0;
			end
			
			WRITE_DATA: begin
				sda_out <= data_out[counter];
				write_enable <= 1;
			end
			
			DATA_ACKNOWLEDGE: begin
				sda_out <= 0;
				write_enable <= 1;
			end
		endcase
	end
	
endmodule