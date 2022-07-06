`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   14:48:37 02/09/2022
// Design Name:   BAUD_GEN
// Module Name:   C:/Users/SWARUP/Desktop/Acads/EEE F376 DOP/Verilog Files/DOP/baudtb.v
// Project Name:  DOP
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: BAUD_GEN
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module baudtb;

	// Inputs
	reg Clock;

	// Outputs
	wire RX_Clock;
	wire TX_Clock;

	// Instantiate the Unit Under Test (UUT)
	BAUD_GEN uut (
		.Clock(Clock), 
		.RX_Clock(RX_Clock), 
		.TX_Clock(TX_Clock)
	);
	
	initial begin
	Clock = 0;
		forever #1 Clock = !Clock;
		end
endmodule

