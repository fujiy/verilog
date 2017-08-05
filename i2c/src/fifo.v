// Async FIFO
module fifo #(
    parameter A = 4, D = 8
    )(
    input wire rst,

    input wire wr,
    input wire [D-1:0] w_data,
    input wire rd,
    output wire [D-1:0] r_data,

    output wire empty,
    output wire full
    );

    reg [D-1:0] ram[0:2**A-1];
    reg [A-1:0] wp = 0;
    reg [A-1:0] rp = 0;

    assign r_data = ram[rp];

    // assign r_data = {wp, rp};

    assign empty = wp == rp;
    assign full  = wp + 1 == rp;

    always @ (posedge rd or posedge rst) begin
        if (rst) rp <= 0;
        else if (~empty) begin
            rp <= rp + 1;
        end
    end

    always @ (posedge wr or posedge rst) begin
        if (rst) wp <= 0;
        else if (~full) begin
            ram[wp] <= w_data;
            wp <= wp + 1;
        end
    end

endmodule
