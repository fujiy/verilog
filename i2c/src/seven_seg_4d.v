// 4 digit 7 segument LED
module seven_seg_4d (
    input wire clk,
    input wire [15:0] data,
    output wire [3:0] a,
    output wire [6:0] k);

    wire [3:0] s_data;
    reg [1:0] select;

    assign k = decoder_16(s_data);

    assign s_data = {data[{select, 2'b11}],
                     data[{select, 2'b10}],
                     data[{select, 2'b01}],
                     data[{select, 2'b00}]};

    assign a = decoder_2to4(select);

    always @ (posedge clk) begin
        select <= select + 1;
    end

    function [3:0] decoder_2to4(input [1:0] in);
        case (in)
            2'b00: decoder_2to4 = 4'b0001;
            2'b01: decoder_2to4 = 4'b0010;
            2'b10: decoder_2to4 = 4'b0100;
            2'b11: decoder_2to4 = 4'b1000;
        endcase
    endfunction

    function [6:0] decoder_16(input [3:0] in);
        case (in)
            4'h0:    decoder_16 = 7'b1111110;
            4'h1:    decoder_16 = 7'b0110000;
            4'h2:    decoder_16 = 7'b1101101;
            4'h3:    decoder_16 = 7'b1111001;
            4'h4:    decoder_16 = 7'b0110011;
            4'h5:    decoder_16 = 7'b1011011;
            4'h6:    decoder_16 = 7'b1011111;
            4'h7:    decoder_16 = 7'b1110000;
            4'h8:    decoder_16 = 7'b1111111;
            4'h9:    decoder_16 = 7'b1111011;
            4'ha:    decoder_16 = 7'b1110111;
            4'hb:    decoder_16 = 7'b0011111;
            4'hc:    decoder_16 = 7'b1001110;
            4'hd:    decoder_16 = 7'b0111101;
            4'he:    decoder_16 = 7'b1001111;
            4'hf:    decoder_16 = 7'b1000111;
            default: decoder_16 = 7'b0000000;
        endcase
    endfunction

endmodule
