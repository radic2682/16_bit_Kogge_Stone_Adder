`timescale 1ns/100ps

module adder_16b (
    input [15:0] i_0,
    input [15:0] i_1,
    input i_c,
    output [15:0] o_s,
    output o_c
    );

    wire [15:0] g, p, GPG_g;
    wire mp_15to0;

    BPG     u000(.i0(i_0), .i1(i_1), .g(g), .p(p));
    GPG     u001(.g(g), .p(p), .c_in(i_c), .mg(GPG_g), .stage1_mp_15to0(mp_15to0));
    SUM     u002(.mg(GPG_g), .p(p), .c_in(i_c), .mp_15to0(mp_15to0), .s(o_s), .c_out(o_c));

endmodule


//---------------------------------------------------------------------------------
// Bitwise PG, Group PG, SUM
module BPG (
    input [15:0]    i0, i1,
    output [15:0]   g, p
    );

    genvar i;
    generate for (i = 0; i < 16; i = i + 1) begin
        AND_2I1O    u000 (.i0(i0[i]), .i1(i1[i]), .o(g[i]));
        XOR_2I1O    u001 (.i0(i0[i]), .i1(i1[i]), .o(p[i]));
    end
    endgenerate

endmodule

module GPG (
    input [15:0]    g, p,
    input           c_in,
    output [15:0]   mg,
    output stage1_mp_15to0
    );

    wire [15:0] stage4_mg;      wire [15:1] stage4_mp; // stage4 output
    wire [15:0] stage3_mg;      wire [15:3] stage3_mp; // stage3 output
    wire [15:0] stage2_mg;      wire [15:7] stage2_mp; // stage2 output
    wire [15:0] stage1_mg;                             // stage1 output

    // ***************** STAGE 4 *****************
    genvar i;
    generate for (i = 1; i < 16; i = i + 1) begin
        BLACK_CELL  u000(.g_ItoK(g[i]), .g_KtoJ(g[i-1]), .p_ItoK(p[i]), .p_KtoJ(p[i-1]), .mg(stage4_mg[i]), .mp(stage4_mp[i]));
    end
    endgenerate

    GREY_CELL   u001(.g_ItoK(g[0]), .g_KtoJ(c_in), .p_ItoK(p[0]), .mg(stage4_mg[0]));


    // ***************** STAGE 3 *****************
    generate for (i = 3; i < 16; i = i + 1) begin
        BLACK_CELL  u002(.g_ItoK(stage4_mg[i]), .g_KtoJ(stage4_mg[i-2]), .p_ItoK(stage4_mp[i]), .p_KtoJ(stage4_mp[i-2]), .mg(stage3_mg[i]), .mp(stage3_mp[i]));
    end
    endgenerate

    GREY_CELL   u003(.g_ItoK(stage4_mg[2]), .g_KtoJ(stage4_mg[0]), .p_ItoK(stage4_mp[2]), .mg(stage3_mg[2]));
    GREY_CELL   u004(.g_ItoK(stage4_mg[1]), .g_KtoJ(c_in), .p_ItoK(stage4_mp[1]), .mg(stage3_mg[1]));

    assign stage3_mg[0] = stage4_mg[0];


    // ***************** STAGE 2 *****************
    generate for (i = 7; i < 16; i = i + 1) begin
        BLACK_CELL  u005(.g_ItoK(stage3_mg[i]), .g_KtoJ(stage3_mg[i-4]), .p_ItoK(stage3_mp[i]), .p_KtoJ(stage3_mp[i-4]), .mg(stage2_mg[i]), .mp(stage2_mp[i]));
    end
    endgenerate

    GREY_CELL   u006(.g_ItoK(stage3_mg[6]), .g_KtoJ(stage3_mg[2]), .p_ItoK(stage3_mp[6]), .mg(stage2_mg[6]));
    GREY_CELL   u007(.g_ItoK(stage3_mg[5]), .g_KtoJ(stage3_mg[1]), .p_ItoK(stage3_mp[5]), .mg(stage2_mg[5]));
    GREY_CELL   u008(.g_ItoK(stage3_mg[4]), .g_KtoJ(stage3_mg[0]), .p_ItoK(stage3_mp[4]), .mg(stage2_mg[4]));
    GREY_CELL   u009(.g_ItoK(stage3_mg[3]), .g_KtoJ(c_in), .p_ItoK(stage3_mp[3]), .mg(stage2_mg[3]));

    assign stage2_mg[2:0] = stage3_mg[2:0];


    // ***************** STAGE 1 *****************
    BLACK_CELL  u010(.g_ItoK(stage2_mg[15]), .g_KtoJ(stage2_mg[7]), .p_ItoK(stage2_mp[15]), .p_KtoJ(stage2_mp[7]), .mg(stage1_mg[15]), .mp(stage1_mp_15to0));

    generate for (i = 8; i < 15; i = i + 1) begin
        GREY_CELL   u011(.g_ItoK(stage2_mg[i]), .g_KtoJ(stage2_mg[i-8]), .p_ItoK(stage2_mp[i]), .mg(stage1_mg[i]));
    end
    endgenerate
    
    GREY_CELL   u012(.g_ItoK(stage2_mg[7]), .g_KtoJ(c_in), .p_ItoK(stage2_mp[7]), .mg(stage1_mg[7]));

    assign stage1_mg[6:0] = stage2_mg[6:0];

    // ***************** Assign OUT *****************
    assign mg[15:0] = stage1_mg[15:0];

endmodule

module SUM (
    input [15:0]    mg,
    input [15:0]    p,
    input           c_in,
    input           mp_15to0,
    output [15:0]   s,
    output          c_out
    );

    XOR_2I1O     u000(.i0(c_in), .i1(p[0]), .o(s[0]));

    genvar i; generate
    for (i = 1; i < 16; i = i + 1) begin
        XOR_2I1O     u001(.i0(mg[i-1]), .i1(p[i]), .o(s[i]));
    end
    endgenerate

    GREY_CELL   u002(.g_ItoK(mg[15]), .g_KtoJ(c_in), .p_ItoK(mp_15to0), .mg(c_out));

endmodule



//---------------------------------------------------------------------------------
// Black Cell, Gray Cell

module BLACK_CELL (
    input           g_ItoK, g_KtoJ,
    input           p_ItoK, p_KtoJ,
    output          mg,
    output          mp
    );

    GREY_CELL   u000(.g_ItoK(g_ItoK), .g_KtoJ(g_KtoJ), .p_ItoK(p_ItoK), .mg(mg));
    AND_2I1O    u001(.i0(p_ItoK), .i1(p_KtoJ), .o(mp));

endmodule

module GREY_CELL (
    input           g_ItoK, g_KtoJ,
    input           p_ItoK,
    output          mg
    );

    wire w0;

    INV         u000(.i(g_ItoK), .o(inv_g));
    NAND_2I1O   u001(.i0(p_ItoK), .i1(g_KtoJ), .o(w0));
    NAND_2I1O   u002(.i0(inv_g), .i1(w0), .o(mg));

endmodule



//---------------------------------------------------------------------------------
// AND, XOR GATE

module AND_2I1O (
        input i0,
        input i1,
        output o
    );

    wire w0;

    NAND_2I1O   u000(.i0(i0), .i1(i1), .o(w0));
    INV         u001(.i(w0), .o(o));

endmodule

module XOR_2I1O (
        input i0,
        input i1,
        output o
    );

    wire w0, w1, w2;

    NAND_2I1O   u000(.i0(i0), .i1(i1), .o(w0));

    NAND_2I1O   u001(.i0(i0), .i1(w0), .o(w1));
    NAND_2I1O   u002(.i0(i1), .i1(w0), .o(w2));

    NAND_2I1O   u003(.i0(w1), .i1(w2), .o(o));

endmodule



///////////////////////////////////////////////////////////////////////////////////
// Don't modify the following primitive logic gates

module NAND_2I1O (i0, i1, o);
input i0;
input i1;
output o;

assign #(0.1, 0.2) o = ~(i0 & i1);

endmodule

module NAND_3I1O (i0, i1, i2, o);
input i0;
input i1;
input i2;
output o;

assign #(0.1, 0.3) o = ~(i0 & i1 & i2);

endmodule

module NAND_4I1O (i0, i1, i2, i3, o);
input i0;
input i1;
input i2;
input i3;
output o;

assign #(0.1, 0.4) o = ~(i0 & i1 & i2 & i3);

endmodule

module NOR_2I1O (i0, i1, o);
input i0;
input i1;
output o;

assign #(0.2, 0.1) o = ~(i0 | i1);

endmodule

module NOR_3I1O (i0, i1, i2, o);
input i0;
input i1;
input i2;
output o;

assign #(0.3, 0.1) o = ~(i0 | i1 | i2);

endmodule

module NOR_4I1O (i0, i1, i2, i3, o);
input i0;
input i1;
input i2;
input i3;
output o;

assign #(0.4, 0.1) o = ~(i0 | i1 | i2 | i3);

endmodule


module INV (i, o);
input i;
output o;

assign #(0.1, 0.1) o = ~i;

endmodule

