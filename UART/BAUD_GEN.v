module BAUD_GEN(input wire Clock,
		     output wire RX_Clock,
		     output wire TX_Clock);

//if Clock 50 MHz

//parameter RX_ACC_MAX = 50000000 / (115200 * 16);

parameter RX_ACC_MAX = 868;//100000000 / 115200;
parameter TX_ACC_MAX = 868;//100000000 / 115200;
parameter RX_ACC_WIDTH = 6;//$clog2(RX_ACC_MAX);
parameter TX_ACC_WIDTH = 6;//$clog2(TX_ACC_MAX);

reg [RX_ACC_WIDTH - 1:0] rx_acc = 0;
reg [TX_ACC_WIDTH - 1:0] tx_acc = 0;

//reg [7:0] rx_acc = 0;
//reg [7:0] tx_acc = 0;


assign RX_Clock = (rx_acc >= (RX_ACC_MAX-1)/2); // divide by 2
assign TX_Clock = (tx_acc >= (TX_ACC_MAX-1)/2); // divide by 2

always @(posedge Clock) begin
	if(rx_acc == RX_ACC_MAX)
		rx_acc = 0;
	else
		rx_acc <= rx_acc + 6'b1;
end

always @(posedge Clock) begin
	if(tx_acc == TX_ACC_MAX)
		tx_acc = 0;
	else
		tx_acc <= tx_acc + 6'b1;
end

endmodule
