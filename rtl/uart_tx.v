// Simple 8N1 UART transmitter
// CLK_FREQ  : input clock frequency in Hz (Boolean board = 100_000_000)
// BAUD_RATE : desired baud rate, e.g. 115200
module uart_tx #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire        send,      // pulse high for 1 cycle to start sending 'data'
    input  wire [7:0]  data,
    output reg         busy,      // high while a byte is being shifted out
    output reg         tx         // connect to UART_txd pin
);

    localparam integer BIT_PERIOD = CLK_FREQ / BAUD_RATE;

    reg [3:0]  bit_index;
    reg [15:0] clk_count;
    reg [9:0]  shift_reg;   // start bit + 8 data bits + stop bit

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            busy      <= 1'b0;
            tx        <= 1'b1;   // idle high
            clk_count <= 0;
            bit_index <= 0;
        end else begin
            if (!busy) begin
                tx <= 1'b1;
                if (send) begin
                    shift_reg <= {1'b1, data, 1'b0}; // stop, data[7:0], start
                    busy      <= 1'b1;
                    clk_count <= 0;
                    bit_index <= 0;
                end
            end else begin
                if (clk_count == BIT_PERIOD - 1) begin
                    clk_count <= 0;
                    tx        <= shift_reg[0];
                    shift_reg <= shift_reg >> 1;
                    if (bit_index == 4'd9) begin
                        busy      <= 1'b0;
                        bit_index <= 0;
                    end else begin
                        bit_index <= bit_index + 1'b1;
                    end
                end else begin
                    clk_count <= clk_count + 1'b1;
                end
            end
        end
    end

endmodule