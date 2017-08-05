`include "src/seven_seg_4d.v"

module seven_seg (a0, a1, a2, a3, k0, k1, k2, k3, k4, k5, k6, clk, btn);
    input clk;
    input btn;
    output a0, a1, a2, a3;
    output k0, k1, k2, k3, k4, k5, k6;

    wire [3:0] a;
    wire [6:0] d;

    reg [26:0] clock = 0;
    reg [15:0] count = 0;

    assign {a3, a2, a1, a0} = ~a;
    assign {k0, k1, k2, k3, k4, k5, k6} = ~d;

    seven_seg_4d seven_seg_4d(clock[14], count, a, d);

    always @ (posedge(clk)) begin
        clock <= clock + 1;
    end

    always @ (posedge(clock[19])) begin
        if (btn == 0) begin
            count <= count + 1;
        end
    end
endmodule
