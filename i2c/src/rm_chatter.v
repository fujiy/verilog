// Remove chattering
module rm_chatter #(
    parameter N = 1
    ) (
    input wire clk,
    input wire [N-1:0] in,
    output reg [N-1:0] out
    );

    reg [15:0] count = 0;

    always @ (posedge clk) begin
        count <= count + 1;

        if (count == 0) begin
            out <= in;
        end
    end

endmodule
