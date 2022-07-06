// CLKS_PER_BIT = (Frequency of Clock)/(Frequency of UART)
// Example: 100 MHz Clock, 115200 baud UART
// (100000000)/(115200) = 868

module UART_RX
  #(parameter CLKS_PER_BIT = 868) //100000000/115200
  (
   input        		Clock,
   input        		RX_Serial,
   //output reg	 		RX_Done_Out,
	output reg	 		RX_Done,
   //output reg	[7:0] RX_Bytes_Out
	output reg	[7:0] RX_Bytes
   );
   
  parameter RX_START_BIT = 2'b00;
  parameter RX_DATA_BITS = 2'b01;
  parameter RX_STOP_BIT  = 2'b10;
  
  reg [9:0]     r_Clock_Count = 0;
  reg [2:0]     r_Bit_Index   = 0; //8 bits total
  reg [1:0]     state     = 0;
  //reg				 RX_Done;
  //reg [7:0] 	 RX_Bytes;
  
 
  // Purpose: Control RX state machine
  always @(posedge Clock)
  begin
    case (state)
      RX_START_BIT :
        begin
			 if (RX_Serial == 1'b0)
          begin
				if (r_Clock_Count == (CLKS_PER_BIT-1)/2)
            begin
              r_Clock_Count <= 0;  // reset counter, found the middle
              state     <= RX_DATA_BITS;
            end
            else
				begin
				  r_Clock_Count <= r_Clock_Count + 1;
				  state     <= RX_START_BIT;
			   end
          end
          else
          begin
            r_Clock_Count <= 0;
            state     <= RX_START_BIT;
          end
        end // case: RX_START_BIT
      
      
      // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
      RX_DATA_BITS :
        begin
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            state     <= RX_DATA_BITS;
          end
          else
          begin
            r_Clock_Count          <= 0;
            RX_Bytes[r_Bit_Index] <= RX_Serial;
            
            // Check if we have received all bits
            if (r_Bit_Index < 7)
            begin
              r_Bit_Index <= r_Bit_Index + 1;
              state   <= RX_DATA_BITS;
            end
            else
            begin
              r_Bit_Index <= 0;
              state   <= RX_STOP_BIT;
            end
          end
        end // case: RX_DATA_BITS
      
      
      // Receive Stop bit.  Stop bit = 1
      RX_STOP_BIT :
        begin
          // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
     	    state     <= RX_STOP_BIT;
          end
          else
          begin
       	    RX_Done       <= 1'b1;
				 r_Clock_Count <= 0;
				 state     <= RX_START_BIT;
          end
        end // case: RX_STOP_BIT
      
      default :
        state <= RX_START_BIT;
    endcase
  end    
  
//assign RX_Done_Out   = RX_Done;
//assign RX_Bytes_Out = RX_Bytes;
  
endmodule // UART_RX
