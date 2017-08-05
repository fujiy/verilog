// Main

`include "src/i2c_slave.v"
`include "src/seven_seg_4d.v"
`include "src/rm_chatter.v"
`include "src/fifo.v"
 
module i2c (
    input wire clk, rst,
    input wire scl,
    input wire sda_in,
    input wire b0, b1, b2, b3,
    output wire led0, led1,
    output wire sda_out,
    output wire a0, a1, a2, a3,
    output wire k0, k1, k2, k3, k4, k5, k6 );


    wire [3:0] as;
    wire [6:0] ks;
    wire [3:0] btn;
    assign {a3, a2, a1, a0} = ~as;
    assign {k0, k1, k2, k3, k4, k5, k6} = ~ks;
    reg [15:0] clock;

    reg [7:0] count = 0;
    reg [7:0] count1 = 0;

    assign sda_out = 1'bz;
    assign led0 = ~empty;
    assign led1 = ~full;

    reg [15:0] da = 16'hffff;
    reg [15:0] db = 16'hffff;

    wire [15:0] d = btn[0] ? {count1[3:0], count[3:0], debug} : {s_data, r_data};

    wire [7:0] debug;

    always @ (posedge wr) begin
        count1 <= count1 + 1;
    end

    always @ (posedge rd) begin
        count <= count + 1;
    end

    wire [7:0] s_data;
    wire [7:0] r_data;
    wire full, empty;
    wire rd, wr;

    fifo #(3) recieve_buffer(
        .rst(~rst),
        .wr(rd), .w_data(r_data), .rd(wr), .r_data(s_data),
        .full(full), .empty(empty));

    i2c_slave i2c_slave(
        .clk(clock[5]), .rst(~rst), .debug(debug),
        .scl(scl), .sda_in(sda_in), .sda_out(sda_out),
        .rd_data(r_data), .rd(rd), .wr_data(s_data + 8'h01), .wr(wr), .wr_en(~empty));

    seven_seg_4d seven_seg_4d(clock[15], d, as, ks);

    rm_chatter #(4) buttons (clk, {~b3, ~b2, ~b1, ~b0}, btn);

    always @ (posedge clk) begin
        clock <= clock + 1;
    end

endmodule
