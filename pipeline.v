module pipeline(D, clk, enable, reset, Q);
  parameter F = 18;
  input [F-1:0] D;
  input clk, enable, reset;
  output reg [F-1:0] Q;
  parameter RSTTYPE = "SYNC";

  generate
    if (RSTTYPE == "SYNC") begin
      always @(posedge clk) begin
        if (reset) Q <= 0;
        else if (enable) Q <= D;
      end
    end else begin
      always @(posedge clk or posedge reset) begin
        if (reset) Q <= 0;
        else if (enable) Q <= D;
      end
    end
  endgenerate
endmodule