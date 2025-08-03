module DSP_TOP(
  A, B, BCIN, BCOUT, C, D, carryin, M, clk, opmode, P, PCIN, PCOUT,
  carryout, carryoutF, RSTA, RSTB, RSTC, RSTD, RSTM, RSTCARRYIN,
  RSTOPMODE, RSTP, CEA, CEB, CEC, CECARRYIN, CED, CEM, CEP, CEOPMODE
);

  input RSTA, RSTB, RSTC, RSTD, RSTM, RSTCARRYIN, RSTOPMODE, RSTP;
  input CEA, CEB, CEC, CECARRYIN, CED, CEM, CEP, CEOPMODE;
  input [17:0] A, B, D, BCIN;
  input [47:0] C;
  input clk, carryin;
  input [7:0] opmode;
  input [47:0] PCIN;

  output reg [35:0] M;
  output reg [47:0] P, PCOUT;
  output reg carryout, carryoutF;
  output reg [17:0] BCOUT;

  parameter A0REG = 0, A1REG = 1, B0REG = 0, B1REG = 1;
  parameter CREG = 1, DREG = 1, MREG = 1, PREG = 1;
  parameter CARRYINREG = 1, CARRYOUTREG = 1, OPMODEREG = 1;
  parameter CARRYINSEL = "OPMODE[5]";
  parameter B_INPUT = "DIRECT";
  parameter RSTTYPE = "SYNC";

  reg [17:0] A_out, A_out2, D_out, B_out, B_out2, B_out3, B2;
  reg [47:0] out_mux_x, out_mux_z;
  reg CIN, COUT;
  reg [47:0] post_adder_out;
  reg [7:0] opmode_out;
  reg Carry_Cascade_out;
  reg [47:0] C_out;
  reg [35:0] M_out, M_out_mult;

  wire [17:0] A1_out, A1_out2, D1_out, B1_out, B1_out3;
  wire CIN1, carryout1;
  wire [35:0] M1_out;
  wire [47:0] P1, C1_out;
  wire [7:0] opmode1;

  pipeline #(8) m0 (.reset(RSTOPMODE), .clk(clk), .enable(CEOPMODE), .Q(opmode1), .D(opmode));
  pipeline m1 (.reset(RSTA), .clk(clk), .enable(CEA), .Q(A1_out), .D(A));
  pipeline m2 (.reset(RSTA), .clk(clk), .enable(CEA), .Q(A1_out2), .D(A_out));
  pipeline m3 (.reset(RSTD), .clk(clk), .enable(CED), .Q(D1_out), .D(D));
  pipeline m4 (.reset(RSTB), .clk(clk), .enable(CEB), .Q(B1_out), .D(B2));
  pipeline m5 (.reset(RSTB), .clk(clk), .enable(CEB), .Q(B1_out3), .D(B_out2));
  pipeline #(36) m6 (.reset(RSTM), .clk(clk), .enable(CEM), .Q(M1_out), .D(M_out_mult));
  pipeline #(48) m7 (.reset(RSTC), .clk(clk), .enable(CEC), .Q(C1_out), .D(C));
  pipeline #(1) m8 (.reset(RSTCARRYIN), .clk(clk), .enable(CECARRYIN), .Q(CIN1), .D(Carry_Cascade_out));
  pipeline #(1) m9 (.reset(RSTCARRYIN), .clk(clk), .enable(CECARRYIN), .Q(carryout1), .D(COUT));
  pipeline #(48) m10 (.reset(RSTP), .clk(clk), .enable(CEP), .Q(P1), .D(post_adder_out));

  always @(*) begin
    opmode_out = OPMODEREG ? opmode1 : opmode;
    A_out  = A0REG ? A1_out : A;
    A_out2 = A1REG ? A1_out2 : A_out;
    D_out  = DREG ? D1_out : D;

    case (B_INPUT)
      "DIRECT":  B2 = B;
      "CASCADE": B2 = BCIN;
      default:   B2 = 0;
    endcase

    B_out = B0REG ? B1_out : B2;

    if (opmode_out[4] == 1) begin
      case (opmode_out[6])
        1'b0: B_out2 = D_out + B_out;
        1'b1: B_out2 = D_out - B_out;
      endcase
    end else begin
      B_out2 = B_out;
    end

    B_out3 = B1REG ? B1_out3 : B_out2;
    BCOUT = B_out3;
    M_out_mult = B_out3 * A_out2;
    M_out = MREG ? M1_out : M_out_mult;
    M = ~(~M_out);

    case (opmode_out[1:0])
      2'b00: out_mux_x = 0;
      2'b01: out_mux_x = { {12{M_out[35]}}, M_out };
      2'b10: out_mux_x = P1;
      2'b11: out_mux_x = {D_out[11:0], A, B};
    endcase

    C_out = CREG ? C1_out : C;

    case (opmode_out[3:2])
      2'b00: out_mux_z = 0;
      2'b01: out_mux_z = PCIN;
      2'b10: out_mux_z = P1;
      2'b11: out_mux_z = C_out;
    endcase

    Carry_Cascade_out = (CARRYINSEL == "OPMODE[5]") ? opmode_out[5] : (CARRYINSEL == "CARRYIN") ? carryin : 0;
    CIN = CARRYINREG ? CIN1 : Carry_Cascade_out;

    if (opmode_out[7])
      {COUT, post_adder_out} = out_mux_z - (out_mux_x + CIN);
    else
      {COUT, post_adder_out} = out_mux_z + out_mux_x;

    carryout = CARRYOUTREG ? carryout1 : COUT;
    carryoutF = carryout;
    P = PREG ? P1 : post_adder_out;
    PCOUT = P;
  end

endmodule
