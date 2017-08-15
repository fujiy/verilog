// main

`include "src/core.v"
`include "src/ram.v"
`include "src/seven_seg.v"
`include "src/rm_chatter.v"

module cpu (clk, reset, btn, led, a, k);

    input  wire clk;
    input  wire reset;
    input  wire [3:0] btn;
    output wire [3:0] led;
    output wire [3:0] a;
    output wire [6:0] k;

    wire rs = ~reset;
    wire [8:0] addr;
    wire [7:0] w_data;
    wire [7:0] r_data;
    wire we;

    wire clock = btns[0];
    // wire clock = clk;

    reg [15:0] led_clk;

    Core Core(.clk(clock), .reset(rs),
              .AB(addr), .DI(r_data), .DO(w_data), .WE(we));

    RAM #(.AddrWidth(9)) RAM (
        .clk(clock), .addr(addr), .wdata(w_data), .we(we), .data(r_data));

    assign led = ~leds;
    assign a   = ~as;
    assign k   = ~ks;

    wire [3:0] btns;
    wire [3:0] leds = {rs, clk, clock, we};
    wire [3:0] as;
    wire [6:0] ks;

    wire [15:0] d = btns[1] ? {r_data, w_data} : addr;

    always @ (posedge clk) begin
        led_clk <= led_clk + 1;
    end

    SevenSeg4d SevenSeg(led_clk[15], d, as, ks);
    rm_chatter #(4) buttons (clk, ~btn, btns);

endmodule
