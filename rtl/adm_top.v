module adm_top(
    input clk_in,
    input reset,
    input VP,VN,
    output [15:0] cpu_output,
    output UART_txd
);

wire clk;
wire [31:0] adc_sample;
wire ip_buf_wr;
wire locked;
wire async_reset = reset | (~locked);
reg [1:0] reset_sync;
wire [31:0] cpu_output_internal;
wire dac_strobe;

always @(posedge clk or posedge async_reset) begin
    if(async_reset) begin
        reset_sync <= 2'b11;
    end else begin
        reset_sync <= {reset_sync[0],1'b0};
    end
end

wire sys_reset = reset_sync[1];

cpu adm_cpu_unit(
    .clk(clk),
    .reset(sys_reset),
    .adc_sample(adc_sample),
    .cpu_output(cpu_output_internal),
    .ip_buf_wr(ip_buf_wr),
    .dac_strobe(dac_strobe)
);

mmcm adm_mmcm_unit(
    .clk_in(clk_in),
    .reset(reset),
    .clk100(clk),
    .LOCKED(locked)
);

xadc_wrapper adm_xadc_wrapper_unit(
    .clk(clk),
    .reset(sys_reset),
    .vp(VP),
    .vn(VN),
    .adc_sample(adc_sample),
    .ip_buf_wr(ip_buf_wr)
);

wire tx_busy, tx_send;
wire [7:0] tx_data;
wire capturing, draining;

uart_tx #(
    .CLK_FREQ(100_000_000),
    .BAUD_RATE(115200)
) u_uart_tx (
    .clk(clk), .rst(sys_reset),
    .send(tx_send), .data(tx_data),
    .busy(tx_busy), .tx(UART_txd)
);

capture_buffer #(
    .BUFFER_DEPTH(4096),
    .ADDR_WIDTH(12)
) u_capture (
    .clk(clk), .rst(sys_reset),
    .sample_tick (dac_strobe),           // dac_strobe IS our sample_tick
    .cpu_output  (cpu_output_internal[11:0]),
    .uart_send(tx_send), .uart_data(tx_data), .uart_busy(tx_busy),
    .capturing(capturing), .draining(draining)
);

assign cpu_output = cpu_output_internal[15:0];

endmodule
