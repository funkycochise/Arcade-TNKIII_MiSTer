//TNKIIICore_Front_sync.sv
//Author: @RndMnkIII
//Date: 25/05/2022
`default_nettype none
`timescale 1ns/1ps


module TNKIIICore_Front_sync(
    input  wire VIDEO_RSTn,
    input wire clk,
    input wire CK1,
    //Side SRAM address selector V/C
    input wire V_C,
    //B address
    input wire FRONT_VIDEO_CSn,
    input wire [10:0] VA,
    input wire [7:0] VD_in,
    output logic [7:0] VD_out,
    //hps_io rom interface
	input wire         [24:0] ioctl_addr,
	input wire         [7:0] ioctl_data,
	input wire               ioctl_wr,
    //A address
    input wire VCKn,
    //front SRAM control
    input wire VRD,
    input wire VDG,
    input wire VOE,
    input wire VWE,
    //clocking
    input wire [4:0] FH,
    input wire [8:0] FV,
    input wire LC,
    input wire VLK,
    input wire FCK,
    input wire H3,
    input wire LD,
    input wire CK0,
    //front data output
    output logic [7:0] FD,
    output logic [8:0] FL_Y
);
    logic [7:0] D0_in, D1_in, D2_in, D3_in;
    logic [7:0] Q0, Q1, Q2, Q3;
    logic [7:0] D0_out, D1_out, D2_out, D3_out;
    logic [7:0] Dreg0, Dreg1, Dreg2, Dreg3;

    logic F1B3, F1B2, F1B1, F1B0;
    ttl_74139_nodly b2_cpu_pcb(.Enable_bar(FRONT_VIDEO_CSn), .A_2D(VA[1:0]), .Y_2D({F1B3, F1B2, F1B1, F1B0}));
    
    //bus multiplexers between video data common bus and front SRAM ICs.
    logic F2_EN; //F10 LS32 UnitA
    logic F3_EN; //F10 LS32 UnitB
    logic F4_EN; //F10 LS32 UnitC
    logic F5_EN; //F10 LS32 UnitD

    assign F2_EN =~(F1B0 | VDG);
    assign F3_EN =~(F1B1 | VDG);
    assign F4_EN =~(F1B2 | VDG);
    assign F5_EN =~(F1B3 | VDG);

    assign D0_in = (F2_EN && VRD) ? VD_in : 8'hFF;
    assign D1_in = (F3_EN && VRD) ? VD_in : 8'hFF;
    assign D2_in = (F4_EN && VRD) ? VD_in : 8'hFF;
    assign D3_in = (F5_EN && VRD) ? VD_in : 8'hFF;

    // DIR=L B->A, DIR=H A->B
    // A (VD) -> B(Dx)
    logic [10:0] A;
    logic B3CSn, B2CSn, B1CSn, B0CSn;
    logic d2_dummy;
    ttl_74157 #(.DELAY_RISE(0), .DELAY_FALL(0)) d5 (.Enable_bar(1'b0), .Select(V_C), .A_2D({F1B3,VCKn,F1B2,VCKn,F1B1,VCKn,F1B0,VCKn}), .Y({B3CSn, B2CSn, B1CSn, B0CSn}));

    ttl_74157 #(.DELAY_RISE(0), .DELAY_FALL(0)) d2 (.Enable_bar(1'b0), .Select(V_C), .A_2D({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,VA[10],1'b0}), .Y({d2_dummy, A[10:8]}));

    ttl_74157 #(.DELAY_RISE(0), .DELAY_FALL(0)) d3 (.Enable_bar(1'b0), .Select(V_C), .A_2D({VA[9],1'b0,VA[8],1'b0,VA[7],FH[4],VA[6],FH[3]}), .Y(A[7:4]));

    ttl_74157 #(.DELAY_RISE(0), .DELAY_FALL(0)) d4 (.Enable_bar(1'b0), .Select(V_C), .A_2D({VA[5],FH[2],VA[4],FH[1],VA[3],FH[0],VA[2],H3}), .Y(A[3:0]));

    //--- HM6116P-3 2Kx8 300ns SRAM x 4 ICs, only used 512bytes per IC ---

    //TNKIII only uses VA[10:0] 2Kbytes FRONT RAM space
    SRAM_dual_sync #(.ADDR_WIDTH(9)) h2_byte0
    (
        .ADDR0({VA[10:2]}), 
        .clk0(clk), 
        .cen0(~F1B0), 
        .we0(~VWE), 
        .DATA0(D0_in), 
        .Q0(Q0),
        .ADDR1({3'b000,FH[4:0],H3}), 
        .clk1(clk), 
        .cen1(~VCKn), 
        .we1(1'b0), 
        .DATA1(8'hff),
        .Q1(Dreg0)
    );

    SRAM_dual_sync #(.ADDR_WIDTH(9)) h3_byte1
    (
        .ADDR0({VA[10:2]}), 
        .clk0(clk), 
        .cen0(~F1B1), 
        .we0(~VWE), 
        .DATA0(D1_in), 
        .Q0(Q1),
        .ADDR1({3'b000,FH[4:0],H3}), 
        .clk1(clk), 
        .cen1(~VCKn), 
        .we1(1'b0), 
        .DATA1(8'hff),
        .Q1(Dreg1)
    );


    SRAM_dual_sync #(.ADDR_WIDTH(9)) h5_byte2
    (
        .ADDR0({VA[10:2]}), 
        .clk0(clk), 
        .cen0(~F1B2), 
        .we0(~VWE), 
        .DATA0(D2_in), 
        .Q0(Q2),
        .ADDR1({3'b000,FH[4:0],H3}), 
        .clk1(clk), 
        .cen1(~VCKn), 
        .we1(1'b0), 
        .DATA1(8'hff),
        .Q1(Dreg2)
    );

    SRAM_dual_sync #(.ADDR_WIDTH(9)) h6_byte3
    (
        .ADDR0({VA[10:2]}), 
        .clk0(clk), 
        .cen0(~F1B3), 
        .we0(~VWE), 
        .DATA0(D3_in), 
        .Q0(Q3),
        .ADDR1({3'b000,FH[4:0],H3}), 
        .clk1(clk), 
        .cen1(~VCKn), 
        .we1(1'b0), 
        .DATA1(8'hff),
        .Q1(Dreg3)
    );

    assign D0_out = (!VOE) ? Q0 : 8'hff;
    assign D1_out = (!VOE) ? Q1 : 8'hff;
    assign D2_out = (!VOE) ? Q2 : 8'hff;
    assign D3_out = (!VOE) ? Q3 : 8'hff; 

    assign VD_out = ( (!VRD && F2_EN) ? D0_out : (
                      (!VRD && F3_EN) ? D1_out : (
                      (!VRD && F4_EN) ? D2_out : (
                      (!VRD && F5_EN) ? D3_out : 8'hff
                    ))));

    logic [7:0] G2_Q;
    //Sprite X offset
    ttl_74273_sync g2(.RESETn(VIDEO_RSTn), .CLRn(1'b1), .Clk(clk), .Cen(VLK), .D(Dreg0), .Q(G2_Q));
    logic [7:0] Tile_num;
    //Sprite Tile Number
    ttl_74273_sync g3(.RESETn(VIDEO_RSTn), .CLRn(1'b1), .Clk(clk), .Cen(VLK), .D(Dreg1), .Q(Tile_num));
    logic [7:0] Y_offset;
    //Sprite Y offset
    ttl_74273_sync g4(.RESETn(VIDEO_RSTn), .CLRn(1'b1), .Clk(clk), .Cen(VLK), .D(Dreg2), .Q(Y_offset));
    logic [7:0] G5_Q;
    //Sprite attributes
    ttl_74273_sync g5(.RESETn(VIDEO_RSTn), .CLRn(1'b1), .Clk(clk), .Cen(VLK), .D(Dreg3), .Q(G5_Q));
    
    logic [3:0] Spr_color_bank;
    logic X_offset_MSB;
    logic Spr_bank; //TNKIII only 512 tiles
    logic Spr_XFlip; //TNKIII
    logic Y_offset_MSB;

    assign  Spr_XFlip = G5_Q[5];
    assign  X_offset_MSB = ~G5_Q[4];


    logic [7:0] X_offset;
    genvar i;
    generate
        for(i=0; i<8; i++) begin : x_offset_gen
            assign X_offset[i] = ~G2_Q[i];
        end
    endgenerate

    //TNKIII SPECIFIC
    ttl_74174_sync N7
    (
        .Reset_n(VIDEO_RSTn),
        .Clk(clk),
        .Cen(FCK),
        .Clr_n(1'b1),
        .D({G5_Q[7:6],G5_Q[3:0]}),
        .Q({FL_Y[8],Spr_bank,Spr_color_bank})
    );

    ttl_74273_sync f6(.RESETn(VIDEO_RSTn), .CLRn(1'b1), .Clk(clk), .Cen(FCK), .D(Y_offset), .Q(FL_Y[7:0]));

    logic [7:0] G7_Q;
    ttl_74273_sync g7(.RESETn(VIDEO_RSTn), .CLRn(1'b1), .Clk(clk), .Cen(FCK), .D(Tile_num), .Q(G7_Q));

    logic e7_D;
    logic e5_cout;
    logic [3:0] e5_sum;

    assign e7_D = FV[8] ^ X_offset_MSB;

    logic e7_C;
    assign e7_C = e7_D ^ e5_cout;

    logic e4_cout;
    ttl_74283_nodly e5 (.A(FV[7:4]), .B(X_offset[7:4]), .C_in(e4_cout),  .Sum(e5_sum), .C_out(e5_cout));

    logic [3:0] e4_sum;
    ttl_74283_nodly e4 (.A(FV[3:0]), .B(X_offset[3:0]), .C_in(1'b1), .Sum(e4_sum), .C_out(e4_cout));

    //Sprite X flip, TNKIII
    logic [3:0] e4_flip;
    generate
        for(i=0; i<4; i++) begin : x_flip_gen
            assign e4_flip[i] = e4_sum[i] ^ Spr_XFlip;
        end
    endgenerate

    logic e6_B;
    assign e6_B = &e5_sum;
    logic e8_C;
    ////////////Hack: insert one clock cycle delay to e7_C,e6_B
    reg e7_Cr, e6_Br;
    always @(posedge clk) begin
        e7_Cr    <= e7_C;
        e6_Br    <= e6_B;
    end
    assign e8_C = ~(e7_Cr & e6_Br);

    logic [4:0] E8_Q;
    logic E8_dummy;

    ttl_74174_sync E8
    (
        .Reset_n(VIDEO_RSTn),
        .Clk(clk),
        .Cen(FCK),
        .Clr_n(1'b1),
        .D({e8_C,e4_flip,1'b1}),
        .Q({E8_Q,E8_dummy})
    );

    logic [1:0] M6_dum;

    ttl_74174_sync M6
    (
        .Reset_n(VIDEO_RSTn),
        .Clk(clk),
        .Cen(LC),
        .Clr_n(1'b1),
        .D({2'b11,Spr_color_bank}),
        .Q({M6_dum,FD[6:3]})
    );
    assign FD[7] = 1'b0;

    //MBM27256-25 250ns 32Kx8x3 FRONT ROMS ---
    wire P7_H7_cs = (ioctl_addr >= 25'h50_000) & (ioctl_addr < 25'h54_000);
	wire P8_F7_cs  = (ioctl_addr >= 25'h60_000) & (ioctl_addr < 25'h64_000); 
	wire P9_E7_cs  = (ioctl_addr >= 25'h70_000) & (ioctl_addr < 25'h74_000);

    logic [7:0] H7_D, H7_Dout; //On PCB pulled to Vcc with 4.7Kx8 RA7
    eprom_16K P7_H7
    (
        .ADDR({Spr_bank,G7_Q,E8_Q[3:0],FCK}),
        .CLK(clk),
        .DATA(H7_Dout),
        .ADDR_DL(ioctl_addr),
        .CLK_DL(clk),
        .DATA_IN(ioctl_data),
        .CS_DL(P7_H7_cs),
        .WR(ioctl_wr)
    );

    assign H7_D = (!E8_Q[4]) ? H7_Dout : 8'hFF;

    logic [7:0] F7_D, F7_Dout; //On PCB pulled to Vcc with 4.7Kx8 RA6
    eprom_16K P8_F7
    (
        .ADDR({Spr_bank,G7_Q,E8_Q[3:0],FCK}),
        .CLK(clk),
        .DATA(F7_Dout),
        .ADDR_DL(ioctl_addr),
        .CLK_DL(clk),
        .DATA_IN(ioctl_data),
        .CS_DL(P8_F7_cs),
        .WR(ioctl_wr)
    );
    assign F7_D = (!E8_Q[4]) ? F7_Dout : 8'hFF;

    logic [7:0] E7_D,E7_Dout; //On PCB pulled to Vcc with 4.7Kx8 RA5
    eprom_16K P9_E7
    (
        .ADDR({Spr_bank,G7_Q,E8_Q[3:0],FCK}),
        .CLK(clk),
        .DATA(E7_Dout),
        .ADDR_DL(ioctl_addr),
        .CLK_DL(clk),
        .DATA_IN(ioctl_data),
        .CS_DL(P9_E7_cs),
        .WR(ioctl_wr)
    );
    assign E7_D = (!E8_Q[4]) ? E7_Dout : 8'hFF;

//    logic LD_reg;
//    always @(posedge clk) begin
//       LD_reg <= LD; 
//    end
    PLSO_shift g10 (.RESETn(VIDEO_RSTn), .CLK(clk), .CEN(~CK0), .LOADn(LD), .SI(1'b1), .D(H7_D), .SO(FD[0])); //Hack CLK should be CK0
    PLSO_shift g9  (.RESETn(VIDEO_RSTn), .CLK(clk), .CEN(~CK0), .LOADn(LD), .SI(1'b1), .D(F7_D),  .SO(FD[1])); //Hack CLK should be CK0
    PLSO_shift g8  (.RESETn(VIDEO_RSTn), .CLK(clk), .CEN(~CK0), .LOADn(LD), .SI(1'b1), .D(E7_D),  .SO(FD[2])); //Hack CLK should be CK0
endmodule

module PLSO_shift (RESETn, CLK, CEN, LOADn, SI, D, SO); 
    input wire RESETn, CLK, CEN, SI, LOADn; 
    input wire [7:0] D; 
    output wire SO;

    reg [7:0] tmp; 
    reg last_cen;

    always @(posedge CLK) 
    begin 
        if (!RESETn) begin
            tmp <= 0;
            last_cen = 1'b1;
        end
        else begin
            last_cen <= CEN;

            if (CEN && !last_cen) begin
                if (!LOADn) tmp <= D; 
                else        tmp <= {tmp[6:0], SI};
            end 
        end
    end 

    assign SO = tmp[7]; 
endmodule 
