// I2C slave
module i2c_slave #(
    parameter ADR = 7'b1111111
    )(
    input wire clk,
    input wire rst,
    input wire scl,
    input wire sda_in,
    output reg sda_out = 1'bz,

    output reg wr = 0,
    input wire wr_en,
    input wire [7:0] wr_data,
    output reg rd = 0,
    output reg [7:0] rd_data,

    output wire [7:0] debug);

    parameter HIGH = 1'bz;
    parameter LOW = 1'b0;

    parameter READ    = 0;
    parameter WRITE   = 1;
    parameter STOP    = 0;
    parameter START   = 1;
    parameter ADDRESS = 0;
    parameter DATA    = 1;

    reg p_scl = 1;
    wire sig   = scl & ~p_scl;
    wire n_sig = ~scl & p_scl;

    reg p_sda = 1;
    wire d_sig  = sda_in & ~p_sda;
    wire nd_sig = ~sda_in & p_sda;

    reg cond = STOP;
    reg rw;
    reg seq;

    reg r_ack, s_ack;
    reg [3:0] count = 0;
    wire complete = count[3];

    assign debug = {count[2:0], r_ack, rd, rw, seq, cond};

    always @ (posedge clk) begin
        p_scl <= scl;
        p_sda <= sda_in;

        if (rst) cond <= STOP;

        if (cond == STOP) begin
            if (scl & nd_sig) begin // Start condition
                cond <= START;
                seq <= ADDRESS; // Address sequence
                rw <= READ;
                r_ack <= 0;
                s_ack <= 0;
                count <= 0;
                rd <= 0;
                sda_out <= HIGH;
            end
        end
        else begin

            if (scl & d_sig) begin // Stop condition
                cond <= STOP;
            end

            if (r_ack && n_sig) begin // Return ACK
                r_ack <= 0;
                sda_out <= HIGH;
                rd <= 0;
            end

            if (s_ack && sig) begin // Recieve ACK
                s_ack <= 0;
                wr <= 0;
            end

            if (rw == READ) begin // Recieve
                if (sig & !complete & !r_ack) begin // Recieve data
                    rd_data[3'b111 - count[2:0]] <= sda_in;
                    count <= count + 1;
                end

                if (n_sig & complete) begin

                    if (seq == ADDRESS) begin
                        if (rd_data[7:1] == ADR) begin
                            rw <= rd_data[0];
                            seq <= DATA;

                            if (rd_data[0] == WRITE & !wr_en) begin
                                sda_out <= HIGH;
                                cond <= STOP;
                            end
                            else begin
                                sda_out <= LOW;
                                r_ack <= 1;
                            end
                        end
                        else cond <= STOP;
                    end
                    else begin
                        r_ack <= 1;
                        sda_out <= LOW;
                        rd <= 1;
                    end

                    count <= 0;
                end
            end
            else begin // Send

                if (n_sig & !complete) begin // Send data
                    sda_out <= wr_data[3'b111 - count[2:0]] ? HIGH : LOW;
                    count <= count + 1;
                end

                if (n_sig & complete) begin
                    sda_out <= HIGH;
                    s_ack <= 1;
                    wr <= 1;
                    count <= 0;
                end
            end
        end

    end

endmodule
