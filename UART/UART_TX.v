// CLKS_PER_BIT = (Frequency of Clock)/(Frequency of UART)
// Example: 100 MHz Clock, 115200 baud UART
// (100000000)/(115200) = 868
 
module UART_TX 
  #(parameter CLKS_PER_BIT = 868) //100000000/115200
  (
   input       Clock,
   input       TX_Done_previous,
   input [7:0] TX_Bytes, 
   output 		TX_Active,
   output reg  TX_Serial,
   output 		TX_Done
   );
 
  parameter IDLE         = 2'b00;
  parameter TX_START_BIT = 2'b01;
  parameter TX_DATA_BITS = 2'b10;
  parameter TX_STOP_BIT  = 2'b11;
  
  reg [1:0] state     = 0;
  reg [9:0] r_Clock_Count = 0;
  reg [2:0] r_Bit_Index   = 0; //8 bits
  reg [7:0] TX_Data     = 0;
  reg       r_TX_Done     = 0;
  reg       r_TX_Active   = 0;
    
  always @(posedge Clock)
  begin
    case (state)
      IDLE :
        begin
          TX_Serial   <= 1'b1;         // Drive Line High for Idle
          r_TX_Done     <= 1'b0;
          r_Clock_Count <= 0;
          r_Bit_Index   <= 0;
          
          if (TX_Done_previous == 1'b1)
          begin
            r_TX_Active <= 1'b1;
            TX_Data   <= TX_Bytes;
            state   <= TX_START_BIT;
          end
          else
            state <= IDLE;
        end // case: IDLE
      
      
      // Send out Start Bit. Start bit = 0
      TX_START_BIT :
        begin
          TX_Serial <= 1'b0;
          
          // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            state     <= TX_START_BIT;
          end
          else
          begin
            r_Clock_Count <= 0;
            state     <= TX_DATA_BITS;
          end
        end // case: TX_START_BIT
      
      
      // Wait CLKS_PER_BIT-1 clock cycles for data bits to finish         
      TX_DATA_BITS :
        begin
          TX_Serial <= TX_Data[r_Bit_Index];
          
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            state     <= TX_DATA_BITS;
          end
          else
          begin
            r_Clock_Count <= 0;
            
            // Check if we have sent out all bits
            if (r_Bit_Index < 7)
            begin
              r_Bit_Index <= r_Bit_Index + 1;
              state   <= TX_DATA_BITS;
            end
            else
            begin
              r_Bit_Index <= 0;
              state   <= TX_STOP_BIT;
            end
          end 
        end // case: TX_DATA_BITS
      
      
      // Send out Stop bit.  Stop bit = 1
      TX_STOP_BIT :
        begin
          TX_Serial <= 1'b1;
          
          // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            state     <= TX_STOP_BIT;
          end
          else
          begin
            r_TX_Done     <= 1'b1;
				//TX_Done <= 1'b1;
            r_Clock_Count <= 0;
            //state     <= TX_START_BIT; //original
				state		<= IDLE;
            r_TX_Active   <= 1'b0;
				//TX_Active   <= 1'b0;
          end 
        end // case: TX_STOP_BIT    
      
      default :
        state <= IDLE;
      
    endcase
  end
  
  assign TX_Active = r_TX_Active;
  assign TX_Done   = r_TX_Done;
  
endmodule
