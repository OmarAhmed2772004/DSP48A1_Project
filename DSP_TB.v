module DSP_TB();

  // Reset signals
  reg RSTA, RSTB, RSTC, RSTD, RSTM, RSTCARRYIN, RSTOPMODE, RSTP;
  // Enable signals
  reg CEA, CEB, CEC, CECARRYIN, CED, CEM, CEP, CEOPMODE;
  // Inputs
  reg [17:0] A, B, D, BCIN;
  reg [47:0] C, PCIN;
  reg clk, carryin;
  reg [7:0] opmode;
  // Outputs
  wire [35:0] M;
  wire [47:0] P, PCOUT;
  wire carryout, carryoutF;
  wire [17:0] BCOUT;

  DSP_TOP dut (
    A, B, BCIN, BCOUT, C, D, carryin, M, clk, opmode, P, PCIN, PCOUT,
    carryout, carryoutF, RSTA, RSTB, RSTC, RSTD, RSTM, RSTCARRYIN,
    RSTOPMODE, RSTP, CEA, CEB, CEC, CECARRYIN, CED, CEM, CEP, CEOPMODE
  );

  initial begin clk = 0; forever #1 clk = ~clk; end

  task display_values;
  begin
    $display("Time = %0t", $time);
    $display("Inputs: A=%0d, B=%0d, D=%0d, C=%0d, PCIN=%0d, carryin=%0b", A, B, D, C, PCIN, carryin);
    $display("OPMODE = %b", opmode);
    $display("Outputs: M=%0h, P=%0h, PCOUT=%0h, carryout=%0h, carryoutF=%0h, BCOUT=%0h", M, P, PCOUT, carryout, carryoutF, BCOUT);
  end
  endtask

  initial begin
    
    RSTA=1; RSTB=1; RSTC=1; RSTD=1; RSTM=1; RSTCARRYIN=1; RSTOPMODE=1; RSTP=1;
    CEA=1; CEB=1; CEC=1; CECARRYIN=1; CED=1; CEM=1; CEP=1; CEOPMODE=1;
    A=$random; B=$random; D=$random; C=$random; PCIN=$random; carryin=$random; opmode=8'b00000000;
    #5 @(negedge clk);
    display_values();
    if (M !== 0 || P !== 0 || PCOUT !== 0 || BCOUT !== 0 || carryout !== 0 || carryoutF !== 0)
      $display("Reset FAIL");
    else
      $display("Reset PASS
      -------------------------------------------------------------------------------");
      


    RSTA=0; RSTB=0; RSTC=0; RSTD=0; RSTM=0; RSTCARRYIN=0; RSTOPMODE=0; RSTP=0;

    // PATH 1: pre-sub, post-sub
    A=20; B=10; D=25; C=350; PCIN=0; carryin=0; BCIN=0; opmode=8'b11011101;
    #10 repeat(4) @(negedge clk);
    display_values();
    if (BCOUT === 18'hf && M === 36'h12c && P === 48'h32 && carryout == 0)
      $display("Path 1 PASS 
      -------------------------------------------------------------------------------");
    else
      $display("Path 1 FAIL");

    // PATH 2: pre-add, post-add
    A=20; B=10; D=25; C=350; PCIN=0; carryin=0; BCIN=0; opmode=8'b00010000;
    #10 repeat(4) @(negedge clk);
    display_values();
    if (BCOUT === 18'h23 && M === 36'h2bc && P === 0 && carryout == 0)
      $display("Path 2 PASS
      -------------------------------------------------------------------------------");
    else
      $display("Path 2 FAIL");

    // PATH 3: P feedback
    A=20; B=10; D=25; C=350; PCIN=0; carryin=0; BCIN=0; opmode=8'b00001010;
    #10 repeat(4) @(negedge clk);
    display_values();
    if (BCOUT === 18'ha && M === 36'hc8)
      $display("Path 3 PASS
      -------------------------------------------------------------------------------");
    else
      $display("Path 3 FAIL");

    // PATH 4: DAB concat + subtract
    A=5; B=6; D=25; C=350; PCIN=3000; carryin=0; BCIN=0; opmode=8'b10100111;
    #10 repeat(4) @(negedge clk);
    display_values();
    if (BCOUT === 18'd6 && M === 36'h1e && carryout == 1)
      $display("Path 4 PASS
      -------------------------------------------------------------------------------");
    else
      $display("Path 4 FAIL");

    $stop;
  end
endmodule
