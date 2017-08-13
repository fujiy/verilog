`include "src/alu.v"

module Core (clk, reset, AB, DI, DO, WE);

    input  wire clk;        // clock
    input  wire reset;      // reset signal
    output wire [15:0] AB; // address bus
    input  wire [7:0] DI;  // data in
    output wire [7:0] DO;  // data out
    output wire WE;        // write enable

    // registers ---------------------------------------------------------------

    reg [7:0]  AX; // accumulator
    reg [7:0]  DX; // data register
    reg [3:0]  IX; // index register
    reg [14:0] SB; // stack base pointer
    reg [7:0]  SP; // stack offset pointer
    reg [14:0] IP; // instruction pointer

    reg CF; // carry flag
    reg ZF; // zero flag
    reg NF; // nagative flag
    reg VF; // overflow flag

    // wires -------------------------------------------------------------------

    wire [3:0] SX = {VF, NF, ZF, CF}; // status register
    wire [7:0] M = DI; // memory

    // control -----------------------------------------------------------------

    reg AS; // address select state (program/data)
    // wire AS = clk; // address select state (data/program)

    always @ (negedge clk or posedge reset) begin
        if (reset) AS <= 0;
        else       AS <= ~AS;
    end

    wire i_clk = clk & AS;  // fetch instruction
    wire r_clk = clk & ~AS; // update register

    assign AB[15] = AS;
    assign AB[14:0] = AS ? SB + stack_a : IP;
    assign WE = AS && stack_w;

    // instruction -------------------------------------------------------------

    reg [7:0] I; // instruction

    always @ (posedge i_clk) begin
        I <= DI;
    end

    wire halt_sig         = I == 8'b00000001;   // halt

    wire leave_sig        = I == 8'b00000010;   // leave

    wire return_sig       = I == 8'b00000011;   // return

    wire flag_sig         = I[7:1] == 7'b0000010; // carry flag
    wire flag_d           = I[0];               // clear/set

    wire arith_sig        = I[7:3] == 5'b00001; // useing ALU
    wire arith_bi         = I[0];     // DX/memory
    wire [1:0] arith_op   = I[2:1];   // ALU opcode

    wire mov_sig          = I[7:3] == 5'b00010; // mov/load/store
    wire mov_to_ax        = mov_sig && ~I[2] && ~I[0];  // to AX
    wire mov_to_dx        = mov_sig && ~I[2] && I[0]; // to DX
    wire mov_to_m         = mov_sig && I[2];           // to memory
    wire [1:0] mov_from   = I[2:1] == 2'b00 ? {1'b0, ~I[0]} // from AX/DX
                          : I[2:1] == 2'b01 ? 2'b10         // from memory
                          :                   I[0];         // from AX/DX
    wire [7:0] mov_data   = mov_from == 2'b00 ? AX
                          : mov_from == 2'b01 ? DX
                          :                     M;

    wire branch_sig       = I[7:3] == 5'b00011; // branch
    wire [1:0] branch_f   = I[2:1];             // target flag (CF, ZF, NF, VF)
    wire branch_c         = ~I[0];              // condition
    wire branch           = branch_sig &&
                             SX[branch_f] == branch_c; // weather branch

    wire index_sig        = I[7:5] == 3'b001;   // update ix
    wire [4:0] index_d    = I[4:0];             // data

    wire enter_sig        = I[7:5] == 3'b010;   // enter
    wire [4:0] enter_size = I[4:0];             // local memory size

    wire jump_sig         = I[7:5] == 3'b011;   // jump
    wire [4:0] jump_a     = I[4:0];             // relative address

    wire im_sig           = I[7:6] == 2'b10;    // load immidiate
    wire im_lh            = I[5];               // lower/higher
    wire im_to_ax         = im_sig && ~I[0];    // to AX
    wire im_to_dx         = im_sig && I[0];     // to DX
    wire [3:0] im_d       = I[4:1];             // 4bit immidiate
    wire [7:0] im_data    = im_lh ? {im_d, I[0] ? DX : AX}
                                  : {4'h0, im_d};

    wire call_sig         = I[7:6] == 2'b11;    // call
    wire [4:0] call_a     = I[4:0];             // relative address

    // register wiring ---------------------------------------------------------

    always @ (posedge r_clk or posedge reset) begin

        if (reset) begin
            AX <= 0;
            DX <= 0;
            IX <= 0;
            SB <= 0;
            SP <= 0;
            IP <= 0;
            CF <= 0;
            ZF <= 0;
            NF <= 0;
            VF <= 0;
        end
        else begin
            // AX
            if      (arith_sig) AX <= alu_o;
            else if (mov_to_ax) AX <= mov_data;
            else if (im_to_ax)  AX <= im_data;

            // DX
            if      (mov_to_dx) DX <= mov_data;
            else if (im_to_dx)  DX <= im_data;

            // IX
            if (index_sig) IX <= index_d;

            // SX
            if (arith_sig) begin
                CF <= alu_cf;
                ZF <= alu_zf;
                NF <= alu_nf;
                VF <= alu_vf;
            end
            else if (flag_sig) CF <= flag_d;

            // SB
            if      (enter_sig) SB <= SB + SP;
            else if (leave_sig) SB <= SB - M;

            // SP
            if      (enter_sig) SP <= enter_size;
            else if (leave_sig) SP <= M;

            // IP
            if      (jump_sig)   IP <= IP + {{11{jump_a[4]}}, jump_a};
            else if (branch)     IP <= IP + 2;
            else if (call_sig)   IP <= IP + {call_a[4], call_a <<< 8};
            else if (return_sig) IP <= IP - {M[5], M[5:0] <<< 8};
            else                 IP <= IP + 1;
        end
    end

    // stack memory access -----------------------------------------------------

    reg [7:0] stack_a; // address
    reg [7:0] MX;      // write buffer
    wire stack_w = enter_sig || call_sig || mov_to_m; // is write mode

    always @ ( * ) begin
        // address
        if      (enter_sig || leave_sig)  stack_a <= 1;
        else if (call_sig  || return_sig) stack_a <= SP;
        else                              stack_a <= IX;

        // MX
        if      (mov_to_m)  MX <= mov_data;
        else if (enter_sig) MX <= SP;
        else if (call_sig)  MX <= call_a;
    end


    // ALU ---------------------------------------------------------------------

    wire alu_cf, alu_zf, alu_nf, alu_vf;
    wire [7:0] alu_o;
    wire [7:0] alu_bi = arith_bi ? M: DX;

    ALU ALU(.op(arith_op),
            .AI(AX), .BI(alu_bi), .CI(CF),
            .OUT(alu_o), .C(alu_cf), .Z(alu_zf), .N(alu_nf), .V(alu_vf));

endmodule
