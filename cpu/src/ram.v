
module RAM(clk, addr, wdata, we, data);
	parameter DataWidth = 8;
	parameter AddrWidth = 8;

	input clk;
	input [AddrWidth-1:0] addr;  // address bus
	input [DataWidth-1:0] wdata; // write data
	input we;                    // write enable
	output [DataWidth-1:0] data; // read data

	reg [AddrWidth-1:0] addr_buf = 0;
	reg [DataWidth-1:0] ram [2**AddrWidth-1:0];

	assign data = ram[addr_buf];

	always@(posedge clk) begin
		addr_buf = addr;
		if(we) begin
			ram[addr_buf] = wdata;
		end
	end

    initial begin
        $readmemh("ram.hex", ram);
    end
endmodule
