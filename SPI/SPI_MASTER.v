

module SPI_Master
  #(parameter SPI_MODE = 3,
    parameter CLKS_PER_HALF_BIT = 2)
  (
   // Control/Data Signals,
   input        reset,     // FPGA Reset
   input        Clk,       // FPGA Clock
   
   // TX (MOSI) Signals
   input [7:0]  TX_Byte,        // Byte to transmit on MOSI
   input        TX_DataValid,          // Data Valid Pulse with TX_Byte
   output reg   TX_Ready,       // Transmit Ready for next byte
   
   // RX (MISO) Signals
   output reg       RX_DataValid,     // Data Valid pulse (1 clock cycle)
   output reg [7:0] o_RX_Byte,   // Byte received on MISO

   // SPI Interface
   output reg SPI_Clk,         //SPI Clock
   input      SPI_MISO,
   output reg SPI_MOSI
   );

  // SPI Interface (All Runs at SPI Clock Domain)
  wire CPOL;     // Clock polarity
  wire CPHA;     // Clock phase

  reg [$clog2(CLKS_PER_HALF_BIT*2)-1:0] r_SPI_Clk_Count;
  reg r_SPI_Clk;
  reg [4:0] r_SPI_Clk_Edges;
  reg Leading_Edge;
  reg Trailing_Edge;
  reg       r_TX_DataValid;
  reg [7:0] r_TX_Byte;

  reg [2:0] r_RX_Bit_Count;
  reg [2:0] r_TX_Bit_Count;

  // CPOL: Clock Polarity
  // CPOL=0 means clock idles at 0, leading edge is rising edge.
  // CPOL=1 means clock idles at 1, leading edge is falling edge.
  assign CPOL  = (SPI_MODE == 2) | (SPI_MODE == 3);

  // CPHA: Clock Phase
  // CPHA=0 means the "out" side changes the data on trailing edge of clock
  //              the "in" side captures data on leading edge of clock
  // CPHA=1 means the "out" side changes the data on leading edge of clock
  //              the "in" side captures data on the trailing edge of clock
  assign CPHA  = (SPI_MODE == 1) | (SPI_MODE == 3);



  // Purpose: Generate SPI Clock correct number of times when DV pulse comes
  always @(posedge Clk or negedge reset)
  begin
    if (~reset)
    begin
      TX_Ready      <= 1'b0;
      r_SPI_Clk_Edges <= 0;
      Leading_Edge  <= 1'b0;
      Trailing_Edge <= 1'b0;
      r_SPI_Clk       <= CPOL; // assign default state to idle state
      r_SPI_Clk_Count <= 0;
    end
    else
    begin
			// Default assignments
			Leading_Edge  <= 1'b0;
			Trailing_Edge <= 1'b0;
			
			//additional one
			//TX_Ready <= 1'b1;
			
			if (TX_DataValid)
				begin
				  TX_Ready      <= 1'b0;
				  r_SPI_Clk_Edges = 16;  // Total # edges in one byte ALWAYS 16
				end
			
			if (r_SPI_Clk_Edges > 0)
				begin
				  TX_Ready <= 1'b0;
				  
				  if (r_SPI_Clk_Count == CLKS_PER_HALF_BIT*2-1)
					  begin
						 r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1'b1;
						 Trailing_Edge <= 1'b1;
						 r_SPI_Clk_Count <= 0;
						 r_SPI_Clk       <= ~r_SPI_Clk;
					  end
				  else if (r_SPI_Clk_Count == CLKS_PER_HALF_BIT-1)
					  begin
						 r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1'b1;
						 Leading_Edge  <= 1'b1;
						 r_SPI_Clk_Count <= r_SPI_Clk_Count + 1'b1;
						 r_SPI_Clk       <= ~r_SPI_Clk;
					  end
				  else
					  begin
						 r_SPI_Clk_Count <= r_SPI_Clk_Count + 1'b1;
					  end
				end  
			else
				begin
				  TX_Ready <= 1'b1;
				end
     
    end
  end


  // Purpose: Register TX_Byte when Data Valid is pulsed.
  // Keeps local storage of byte in case higher level module changes the data
  always @(posedge Clk or negedge reset)
  begin
    if (~reset)
    begin
      r_TX_Byte <= 8'h00;
      r_TX_DataValid   <= 1'b0;
    end
    else
      begin
        r_TX_DataValid <= TX_DataValid; // 1 clock cycle delay
        if (TX_DataValid)
        begin
          r_TX_Byte <= TX_Byte;
        end
      end
  end


  // Purpose: Generate MOSI data
  // Works with both CPHA=0 and CPHA=1
  always @(posedge Clk or negedge reset)
  begin
    if (~reset)
    begin
      SPI_MOSI     <= 1'b0;
      r_TX_Bit_Count <= 3'b111; // send MSb first
    end
    else
    begin
      // If ready is high, reset bit counts to default
      if (TX_Ready)
      begin
        r_TX_Bit_Count <= 3'b111;
      end
      // Catch the case where we start transaction and CPHA = 0
      else if (r_TX_DataValid & ~CPHA)
      begin
        SPI_MOSI     <= r_TX_Byte[3'b111];
        r_TX_Bit_Count <= 3'b110;
      end
      else if ((Leading_Edge & CPHA) | (Trailing_Edge & ~CPHA))
      begin
        r_TX_Bit_Count <= r_TX_Bit_Count - 1'b1;
        SPI_MOSI     <= r_TX_Byte[r_TX_Bit_Count];
      end
    end
  end


  // Purpose: Read in MISO data.
  always @(posedge Clk or negedge reset)
  begin
    if (~reset)
    begin
      o_RX_Byte      <= 8'h00;
      RX_DataValid        <= 1'b0;
      r_RX_Bit_Count <= 3'b111;
    end
    else
    begin

      // Default Assignments
      RX_DataValid   <= 1'b0;

      if (TX_Ready) // Check if ready is high, if so reset bit count to default
      begin
        r_RX_Bit_Count <= 3'b111;
      end
      else if ((Leading_Edge & ~CPHA) | (Trailing_Edge & CPHA))
      begin
        o_RX_Byte[r_RX_Bit_Count] <= SPI_MISO;  // Sample data
        r_RX_Bit_Count            <= r_RX_Bit_Count - 1'b1;
        if (r_RX_Bit_Count == 3'b000)
        begin
          RX_DataValid   <= 1'b1;   // Byte done, pulse Data Valid
        end
      end
    end
  end
  
  
  // Purpose: Add clock delay to signals for alignment.
  always @(posedge Clk or negedge reset)
  begin
    if (~reset)
    begin
      SPI_Clk  <= CPOL;
    end
    else
      begin
        SPI_Clk <= r_SPI_Clk;
      end
  end
endmodule
