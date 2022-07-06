`timescale 1ns/10ps

//`include "UART_TX.v"

module UART_TX_TB_using_RX ();

  // Testbench uses a 100 MHz clock
  // Want to interface to 115200 baud UART
  // 100000000 / 115200 = 868 Clocks Per Bit.
  parameter c_CLOCK_PERIOD_NS = 10;
  parameter c_CLKS_PER_BIT    = 868;
  parameter c_BIT_PERIOD      = 8680;
  
  reg Clock = 0;
  reg TX_Done_previous = 0;
  wire TX_Active, w_UART_Line;
  wire TX_Serial, TX_Done;
  reg [7:0] TX_Bytes = 0;
  wire [7:0] w_RX_Byte;

  UART_RX #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_RX_INST
     (.Clock(Clock),
	  .RX_Serial(w_UART_Line),
	  .RX_Done(RX_Done),
     .RX_Bytes(w_RX_Byte));
  
  UART_TX #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_TX_Inst
    (.Clock(Clock),
     .TX_Done_previous(TX_Done_previous),
     .TX_Bytes(TX_Bytes),
     .TX_Active(TX_Active),
     .TX_Serial(TX_Serial),
     .TX_Done(TX_Done)
     );

  // Keeps the UART Receive input high (default) when
  // UART transmitter is not active
  assign w_UART_Line = TX_Active ? TX_Serial : 1'b1;
    
  always
    #(c_CLOCK_PERIOD_NS/2) Clock <= !Clock;
  
  // Main Testing:
  initial
    begin
      // Tell UART to send a command (exercise TX)
      @(posedge Clock);
      TX_Done_previous   <= 1'b1;
      TX_Bytes <= 8'h37;
      @(posedge Clock);
      TX_Done_previous <= 1'b0;

      // Check that the correct command was received
      @(posedge RX_Done);
		//#90000
      if (w_RX_Byte == 8'h37)
        $display("Test Passed - Correct Byte Received");
      else
        $display("Test Failed - Incorrect Byte Received");
      $finish;
    end
endmodule
