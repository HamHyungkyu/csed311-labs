// Title         : vending_machine.v
// Author      : Jae-Eon Jo (Jojaeeon@postech.ac.kr) 
//					   Dongup Kwon (nankdu7@postech.ac.kr) (2015.03.30)

`include "vending_machine_def.v"

module vending_machine (

	clk,							// Clock signal
	reset_n,						// Reset signal (active-low)
	
	i_input_coin,				// coin is inserted.
	i_select_item,				// item is selected.
	i_trigger_return,			// change-return is triggered 
	
	o_available_item,			// Sign of the item availability
	o_output_item,			// Sign of the item withdrawal
	o_return_coin				// Sign of the coin return
);

	// Ports Declaration
	// Do not modify the module interface
	input clk;
	input reset_n;
	
	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0] i_select_item;
	input i_trigger_return;
		
	output [`kNumItems-1:0] o_available_item;
	output [`kNumItems-1:0] o_output_item;
	output [`kNumCoins-1:0] o_return_coin;
 
	// Normally, every output is register,
	//   so that it can provide stable value to the outside.
	reg [`kNumItems-1:0] o_available_item;
	reg [`kNumItems-1:0] o_output_item;
	reg [`kNumCoins-1:0] o_return_coin;
	
	// Net constant values (prefix kk & CamelCase)
	// Please refer the wikepedia webpate to know the CamelCase practive of writing.
	// http://en.wikipedia.org/wiki/CamelCase
	// Do not modify the values.
	wire [31:0] kkItemPrice [`kNumItems-1:0];	// Price of each item
	wire [31:0] kkCoinValue [`kNumCoins-1:0];	// Value of each coin
	assign kkItemPrice[0] = 400;
	assign kkItemPrice[1] = 500;
	assign kkItemPrice[2] = 1000;
	assign kkItemPrice[3] = 2000;
	assign kkCoinValue[0] = 100;
	assign kkCoinValue[1] = 500;
	assign kkCoinValue[2] = 1000;


	// NOTE: integer will never be used other than special usages.
	// Only used for loop iteration.
	// You may add more integer variables for loop iteration.
	integer i, j, k;

	// Internal states. You may add your own net & reg variables.
	reg [`kTotalBits-1:0] current_total;
	
	// Next internal states. You may add your own net and reg variables.
	reg [`kTotalBits-1:0] current_total_nxt;
	
	// Variables. You may add more your own registers.
	reg [`kTotalBits-1:0] input_total, output_total, return_total;
	reg [31:0] waitTime;

	// initiate values
	initial begin
		waitTime <= `kWaitTime;
		current_total <= 0;
		current_total_nxt <= 0;
		input_total <= 0;
		output_total <= 0;
		return_total <= 0;
		o_available_item <= 4'b0000;
		o_output_item <= 4'b0000;
		o_return_coin <= 3'b000;
	end

	
	// Combinational logic for the next states
	always @(*) begin
		if(i_input_coin) begin
			case(i_input_coin) 
				3'b001: begin current_total_nxt = current_total + kkCoinValue[0]; input_total = kkCoinValue[0]; end
				3'b010: begin current_total_nxt = current_total + kkCoinValue[1]; input_total = kkCoinValue[1]; end
				3'b100: begin current_total_nxt = current_total +  kkCoinValue[2]; input_total = kkCoinValue[2]; end
			endcase
		end
		if(i_select_item) begin
			case(i_select_item) 
				4'b0001: if(current_total >= kkItemPrice[0]) begin current_total_nxt = current_total - kkItemPrice[0]; output_total=kkItemPrice[0]; end
				4'b0010: if(current_total >= kkItemPrice[1]) begin current_total_nxt = current_total - kkItemPrice[1]; output_total=kkItemPrice[1]; end
				4'b0100: if(current_total >= kkItemPrice[2]) begin current_total_nxt = current_total - kkItemPrice[2]; output_total=kkItemPrice[2]; end
				4'b1000: if(current_total >= kkItemPrice[3]) begin current_total_nxt = current_total - kkItemPrice[3]; output_total=kkItemPrice[3]; end
			endcase
		end
		if(return_total) begin
			if(current_total >= kkCoinValue [2]) begin current_total_nxt = current_total - kkCoinValue[2]; end
			else if(current_total >= kkCoinValue [1]) begin current_total_nxt = current_total - kkCoinValue[1]; end
			else if(current_total >= kkCoinValue [0]) begin current_total_nxt = current_total - kkCoinValue[0]; end
			else begin return_total = 0;end
		end
	end

	
	
	// Combinational logic for the outputs
	always @(*) begin
		
		if(current_total >= kkItemPrice[3]) begin o_available_item = 4'b1111; end
		else if(current_total >= kkItemPrice[2]) begin o_available_item = 4'b0111; end
		else if(current_total >= kkItemPrice[1]) begin o_available_item = 4'b0011; end
		else if(current_total >= kkItemPrice[0]) begin o_available_item = 4'b0001; end	
		else o_available_item = 4'b0000; 

		if(output_total == kkItemPrice[0]) begin o_output_item = 4'b0001; end
		else if(output_total == kkItemPrice[1]) begin o_output_item = 4'b0010; end
		else if(output_total == kkItemPrice[2]) begin o_output_item = 4'b0100; end
		else if(output_total == kkItemPrice[3]) begin o_output_item = 4'b1000; end
		else o_output_item = 4'b0000;
		
		if(return_total) begin
			if(current_total >= kkCoinValue [2]) begin o_return_coin = 3'b100; end
			else if(current_total >= kkCoinValue [1]) begin o_return_coin = 3'b010; end
			else if(current_total >= kkCoinValue [0]) begin o_return_coin = 3'b001; end
			else begin o_return_coin = 3'b000; end
		end
	end
 
	
	
	// Sequential circuit to reset or update the states
	always @(posedge clk) begin

		if (!reset_n) begin
			waitTime <= `kWaitTime;
			current_total <= 0;
			current_total_nxt <= 0;
			input_total <= 0;
			output_total <= 0;
			return_total <= 0;
			o_available_item <= 4'b0000;
			o_output_item <= 4'b0000;
			o_return_coin <= 3'b000;
		end
		else begin
			if(i_input_coin || i_select_item  || return_total) begin
				current_total <= current_total_nxt;
				waitTime <= `kWaitTime;
			end
			else if(waitTime == 0 || i_trigger_return) begin
				return_total <= 1;
			end
			else begin
				waitTime <= waitTime - 1;
			end
		end
	end

endmodule
