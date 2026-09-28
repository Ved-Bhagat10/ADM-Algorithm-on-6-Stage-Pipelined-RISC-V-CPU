module mmcm(
    input clk_in,
    input reset,
    output clk100,
    output LOCKED
);

wire clkfb;
wire clkfb_buf;

MMCME2_BASE #(
    .CLKIN1_PERIOD(10.0),
    .CLKFBOUT_MULT_F(10.0),
    .DIVCLK_DIVIDE(1),
    .CLKOUT0_DIVIDE_F(10.0)
) mmcmuut (
    .CLKIN1(clk_in),
    .RST(reset),

    .CLKOUT0(clk100),

    .CLKFBOUT(clkfb),
    .CLKFBIN(clkfb_buf),

    .LOCKED(LOCKED),
    .PWRDWN(1'b0)
);

BUFG fb_buf (
    .I(clkfb),
    .O(clkfb_buf)
);

endmodule