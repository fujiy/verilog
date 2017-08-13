// main

`include "src/core.v"
`include "src/ram.v"
`include "src/seven_seg.v"

module cpu (clk, reset, btn, led, a, k);

    input  wire clk;
    input  wire reset;
    input  wire [3:0] btn;
    output wire [3:0] led;
    output wire [3:0] a;
    output wire [6:0] k;

    wire [15:0] addr;
    wire [7:0] w_data;
    wire [7:0] r_data;
    wire we;

    wire clock = btns[0];
    // wire clock = clk;

    assign led = ~leds;
    assign a   = ~as;
    assign k   = ~ks;

    wire [3:0] btns = ~btn;
    wire [3:0] leds = {we, clk, 2'h0};
    wire [3:0] as;
    wire [6:0] ks;

    wire [15:0] d = btns[1] ? {r_data, w_data} : addr;

    Core Core(.clk(clock), .reset(reset),
              .AB(addr), .DI(r_data), .DO(w_data), .WE(we));

    RAM #(.AddrWidth(16)) RAM (
        .clk(clock), .addr(addr), .wdata(w_data), .we(we), .data(r_data));

    SevenSeg4d SevenSeg(clk, d, as, ks);

endmodule
