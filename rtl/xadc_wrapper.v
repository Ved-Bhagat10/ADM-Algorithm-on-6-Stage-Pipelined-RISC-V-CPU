module xadc_wrapper(
    input clk,
    input reset,
    input vp, vn,            // now genuinely the Vaux0 differential pair
    (* mark_debug = "true" *)output reg [31:0] adc_sample,
    (* mark_debug = "true" *)output reg ip_buf_wr
);

    localparam [25:0] SAMPLE_PERIOD = 26'd100; // 100MHz/100 = 10MHz sample rate

    (* mark_debug = "true" *)reg [25:0] period_cnt;
    (* mark_debug = "true" *)reg        den_reg;
    (* mark_debug = "true" *)reg        conv_pending;
    (* mark_debug = "true" *)wire       drdy;
    (* mark_debug = "true" *)wire [15:0] DO;
    (* mark_debug = "true" *) wire [4:0] channel;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            period_cnt   <= 26'd0;
            den_reg      <= 1'b0;
            conv_pending <= 1'b0;
        end else begin
            den_reg <= 1'b0;
            if (conv_pending) begin
                if (drdy) conv_pending <= 1'b0;
            end else if (period_cnt == SAMPLE_PERIOD - 1) begin
                period_cnt   <= 26'd0;
                den_reg      <= 1'b1;
                conv_pending <= 1'b1;
            end else begin
                period_cnt <= period_cnt + 26'd1;
            end
        end
    end

    XADC #(
        .INIT_40(16'h0010), // config reg 0
        .INIT_41(16'h31A0), // config reg 1
        .INIT_42(16'h0400), // config reg 2
        .INIT_48(16'h0100), // Sequencer channel selection
        .INIT_49(16'h0000), // Sequencer channel selection
        .INIT_4A(16'h0000), // Sequencer Average selection
        .INIT_4B(16'h0000), // Sequencer Average selection
        .INIT_4C(16'h0000), // Sequencer Bipolar selection
        .INIT_4D(16'h0000), // Sequencer Bipolar selection
        .INIT_4E(16'h0000), // Sequencer Acq time selection
        .INIT_4F(16'h0000), // Sequencer Acq time selection
        .INIT_50(16'hB5ED), // Temp alarm trigger
        .INIT_51(16'h57E4), // Vccint upper alarm limit
        .INIT_52(16'hA147), // Vccaux upper alarm limit
        .INIT_53(16'hCA33),  // Temp alarm OT upper
        .INIT_54(16'hA93A), // Temp alarm reset
        .INIT_55(16'h52C6), // Vccint lower alarm limit
        .INIT_56(16'h9555), // Vccaux lower alarm limit
        .INIT_57(16'hAE4E),  // Temp alarm OT reset
        .INIT_58(16'h5999), // VCCBRAM upper alarm limit
        .INIT_5C(16'h5111),  //  VCCBRAM lower alarm limit
        .SIM_DEVICE("7SERIES"),
        .SIM_MONITOR_FILE("design.txt")
) uut (
        .DCLK   (clk),
        .RESET  (reset),
        .VP     (1'b0),      // dedicated VP/VN unused
        .VN     (1'b0),
        .DO     (DO),
        .DRDY   (drdy),
        .DEN    (den_reg),
        .DADDR  (7'h10),     // Vaux0 channel
        .DWE    (1'b0),
        .DI     (16'b0),
        .VAUXP  ({15'b0, vp}),
        .VAUXN  ({15'b0, vn}),
        .CHANNEL(channel)
    );

    // FIX: capture on drdy, not on the fixed timer. DEN only requests a
    // conversion when the timer expires; the actual result (DO) isn't
    // valid until drdy pulses some cycles later. Sampling on period_cnt
    // grabbed stale/garbage DO bits instead of the real conversion result
    // -- this is why the sine wave wouldn't show up correctly.
    always @(posedge clk or posedge reset) begin
    if (reset) begin
        adc_sample <= 32'd0;
        ip_buf_wr  <= 1'b0;
    end else if (drdy) begin
        adc_sample <= {20'b0,DO[11:0]};   // real XADC unipolar result, 12 bits
        ip_buf_wr  <= 1'b1;
    end else begin
        ip_buf_wr  <= 1'b0;
    end
end

endmodule
