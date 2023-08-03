`timescale 1ns/100ps

module adder_16b (
    input [15:0] i_0,
    input [15:0] i_1,
    input i_c,

    output [15:0] o_s,
    output o_c
    );

    wire [15:0] w_G, w_P, w_GG;
    wire w_PP_15to0;

    BPG     u000(.i_A(i_0), .i_B(i_1), .o_G(w_G), .o_P(w_P));
    GPG     u001(.i_G(w_G), .i_P(w_P), .i_CIN(i_c), .o_GG(w_GG), .o_PP_15to0(w_PP_15to0));
    SUM     u002(.i_GG(w_GG), .i_P(w_P), .i_PP_15to_0(w_PP_15to0), .i_CIN(i_c), .o_S(o_s), .o_COUT(o_c));

endmodule


//---------------------------------------------------------------------------------
// Bitwise PG, Group PG, SUM

module BPG (
    input [15:0]    i_A, i_B,

    output [15:0]   o_G, o_P
    );

    genvar i;
    generate for (i = 0; i < 16; i = i + 1) begin
        GEN_PROP_CELL   u000(.i_A(i_A[i]), .i_B(i_B[i]), .o_G(o_G[i]), .o_P(o_P[i]));
    end endgenerate

endmodule

module GPG (
    input [15:0]    i_G, i_P,
    input           i_CIN,

    output [15:0]   o_GG,
    output          o_PP_15to0
    );

    wire [16:0] w_GG_S0 = {i_G[15:0], i_CIN};
    wire [16:1] w_PP_S0 = i_P[15:0];
    wire [16:0] w_GG_S1;
    wire [16:4] w_PP_S1;
    wire [16:0] w_GG_S2;


    // STAGE 1
    assign w_GG_S1[0] = w_GG_S0[0];
    GRAY_CELL   u000(.i_Ga(w_GG_S0[1]), .i_Pa(w_PP_S0[1]), .i_Gb(w_GG_S0[0]), .o_Y(w_GG_S1[1]));
    HVAL_G_3I   u001(.i_Ga(w_GG_S0[2]), .i_Pa(w_PP_S0[2]), .i_Gb(w_GG_S0[1]), .i_Pb(w_PP_S0[1]), .i_Gc(w_GG_S0[0]), .o_Ga2c(w_GG_S1[2]));
    HVAL_G_4I   u002(.i_Ga(w_GG_S0[3]), .i_Pa(w_PP_S0[3]), .i_Gb(w_GG_S0[2]), .i_Pb(w_PP_S0[2]), .i_Gc(w_GG_S0[1]), .i_Pc(w_PP_S0[1]), .i_Gd(w_GG_S0[0]), .o_Ga2d(w_GG_S1[3]));

    genvar i;
    generate for (i = 4; i < 17; i = i + 1) begin
        HVAL_B_4I   u003(.i_Ga(w_GG_S0[i]), .i_Pa(w_PP_S0[i]), .i_Gb(w_GG_S0[i-1]), .i_Pb(w_PP_S0[i-1]), .i_Gc(w_GG_S0[i-2]), .i_Pc(w_PP_S0[i-2]), .i_Gd(w_GG_S0[i-3]), .i_Pd(w_PP_S0[i-3]), .o_Ga2d(w_GG_S1[i]), .o_Pa2d(w_PP_S1[i]));
    end endgenerate

    // STAGE 2
    assign w_GG_S2[3:0] = w_GG_S1[3:0];

    generate for (i = 4; i < 8; i = i + 1) begin
        GRAY_CELL   u004(.i_Ga(w_GG_S1[i]), .i_Pa(w_PP_S1[i]), .i_Gb(w_GG_S1[i-4]), .o_Y(w_GG_S2[i]));
        HVAL_G_3I   u005(.i_Ga(w_GG_S1[i+4]), .i_Pa(w_PP_S1[i+4]), .i_Gb(w_GG_S1[i]), .i_Pb(w_PP_S1[i]), .i_Gc(w_GG_S1[i-4]), .o_Ga2c(w_GG_S2[i+4]));
        HVAL_G_4I   u006(.i_Ga(w_GG_S1[i+8]), .i_Pa(w_PP_S1[i+8]), .i_Gb(w_GG_S1[i+4]), .i_Pb(w_PP_S1[i+4]), .i_Gc(w_GG_S1[i]), .i_Pc(w_PP_S1[i]), .i_Gd(w_GG_S1[i-4]), .o_Ga2d(w_GG_S2[i+8]));
    end endgenerate

    HVAL_B_4I   u007(.i_Ga(w_GG_S1[16]), .i_Pa(w_PP_S1[16]), .i_Gb(w_GG_S1[12]), .i_Pb(w_PP_S1[12]), .i_Gc(w_GG_S1[8]), .i_Pc(w_PP_S1[8]), .i_Gd(w_GG_S1[4]),.i_Pd(w_PP_S1[4]), .o_Ga2d(w_GG_S2[13]), .o_Pa2d(o_PP_15to0));

    // Assign Output
    assign o_GG[15:0] = w_GG_S2[16:1];

endmodule

module SUM (
    input [15:0]    i_GG,
    input [15:0]    i_P,
    input           i_PP_15to_0,
    input           i_CIN,

    output [15:0]   o_S,
    output          o_COUT
    );
    
    wire [15:0] new_GG = {i_GG[14:0], i_CIN};

    genvar i;
    generate for (i = 0; i < 16; i = i + 1) begin
       XOR_2I1O u000(.i0(i_P[i]), .i1(new_GG[i]), .o(o_S[i]));
    end endgenerate

    GRAY_CELL   u001(.i_Ga(i_GG[15]), .i_Pa(i_PP_15to_0), .i_Gb(i_CIN), .o_Y(o_COUT));

endmodule



//---------------------------------------------------------------------------------
// Cell : Gray, generate & Propagate, 3-higher valency Gray & Black, 4-higher valency Gray & Black

module GRAY_CELL (
        input i_Ga, i_Pa,
        input i_Gb,

        output o_Y
    );

    wire w0, w1;

    INV         u000(.i(i_Ga), .o(w0));
    NAND_2I1O   u001(.i0(i_Pa), .i1(i_Gb), .o(w1));
    NAND_2I1O   u002(.i0(w0), .i1(w1), .o(o_Y));

endmodule

module GEN_PROP_CELL (
        input i_A,
        input i_B,

        output o_G,
        output o_P
    );

    wire w0, w1, w2;

    NAND_2I1O   u000(.i0(i_A), .i1(i_B), .o(w0));

    NAND_2I1O   u001(.i0(i_A), .i1(w0), .o(w1));
    NAND_2I1O   u002(.i0(i_B), .i1(w0), .o(w2));

    NAND_2I1O   u003(.i0(w1), .i1(w2), .o(o_G));

    INV         u004(.i(w0), .o(o_P));

endmodule

module HVAL_G_3I (
        input i_Ga, i_Pa,
        input i_Gb, i_Pb,
        input i_Gc,

        output o_Ga2c
    );

    wire w0, w1, w2;

    NAND_3I1O   u000(.i0(i_Pa), .i1(i_Pb), .i2(i_Gc), .o(w0));
    NAND_2I1O   u001(.i0(i_Pa), .i1(i_Gb), .o(w1));
    INV         u002(.i(i_Ga), .o(w2));

    NOR_3I1O    u003(.i0(w0), .i1(w1), .i2(w2), .o(o_Ga2c));

endmodule

module HVAL_G_4I (
        input i_Ga, i_Pa,
        input i_Gb, i_Pb,
        input i_Gc, i_Pc,
        input i_Gd,

        output o_Ga2d
    );

    wire w0, w1, w2, w3;

    NAND_4I1O   u000(.i0(i_Pa), .i1(i_Pb), .i2(i_Pc), .i3(i_Gd), .o(w0));
    NAND_3I1O   u001(.i0(i_Pa), .i1(i_Pb), .i2(i_Gc), .o(w1));
    NAND_2I1O   u002(.i0(i_Pa), .i1(i_Gb), .o(w2));
    INV         u003(.i(i_Ga), .o(w3));

    NOR_4I1O    u004(.i0(w0), .i1(w1), .i2(w2), .i3(w3), .o(o_Ga2d));

endmodule

module HVAL_B_3I (
        input i_Ga, i_Pa,
        input i_Gb, i_Pb,
        input i_Gc, i_Pc,

        output o_Ga2c, o_Pa2c
    );

    wire w0;

    HVAL_G_3I   u000(.i_Ga(i_Ga), .i_Pa(i_Pa), .i_Gb(i_Gb), .i_Pb(i_Pb), .i_Gc(i_Gc), .o_Ga2c(o_Ga2c));

    NAND_3I1O   u001(.i0(i_Pa), .i1(i_Pb), .i2(i_Pc), .o(w0));
    INV         u002(.i(w0), .o(o_Pa2c));

endmodule

module HVAL_B_4I (
        input i_Ga, i_Pa,
        input i_Gb, i_Pb,
        input i_Gc, i_Pc,
        input i_Gd, i_Pd,

        output o_Ga2d, o_Pa2d
    );

    wire w0;

    HVAL_G_4I   u000(.i_Ga(i_Ga), .i_Pa(i_Pa), .i_Gb(i_Gb), .i_Pb(i_Pb), .i_Gc(i_Gc), .i_Pc(i_Pc), .i_Gd(i_Gd), .o_Ga2d(o_Ga2d));

    NAND_4I1O   u001(.i0(i_Pa), .i1(i_Pb), .i2(i_Pc), .i3(i_Pd), .o(w0));
    INV         u002(.i(w0), .o(o_Pa2d));

endmodule


//---------------------------------------------------------------------------------
// XOR GATE

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

