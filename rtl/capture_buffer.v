module capture_buffer #(
    parameter BUFFER_DEPTH = 4096,
    parameter ADDR_WIDTH   = 12
)(
    input  wire        clk,
    input  wire        rst,

    input  wire        sample_tick,
    input  wire [11:0] cpu_output,

    output reg         uart_send,
    output reg  [7:0]  uart_data,
    input  wire        uart_busy,

    output reg         capturing,
    output reg         draining
);

    localparam [7:0] SYNC0 = 8'hAA, SYNC1 = 8'h55, SYNC2 = 8'hAA, SYNC3 = 8'h55;

    localparam S_IDLE     = 0,
               S_CAPTURE  = 1,
               S_SYNC0    = 2,
               S_SYNC1    = 3,
               S_SYNC2    = 4,
               S_SYNC3    = 5,
               S_DRAIN_HI = 6,
               S_DRAIN_LO = 7,
               S_WAIT     = 8;

    reg [3:0]              state;        // widened to fit 9 states
    reg [3:0]              return_state;
    reg [ADDR_WIDTH-1:0]    wr_addr;
    reg [ADDR_WIDTH-1:0]    rd_addr;
    reg [15:0]              mem [0:BUFFER_DEPTH-1];
    reg [15:0]              rd_word;

    reg                      mem_we;
    reg [ADDR_WIDTH-1:0]     mem_wr_addr;
    reg [15:0]               mem_wr_data;
    reg [ADDR_WIDTH-1:0]     mem_rd_addr_next;

    always @(posedge clk) begin
        if (mem_we)
            mem[mem_wr_addr] <= mem_wr_data;
        rd_word <= mem[mem_rd_addr_next];
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= S_CAPTURE;
            capturing <= 1'b1;
            draining  <= 1'b0;
            uart_send <= 1'b0;
            wr_addr   <= 0;
            rd_addr   <= 0;
            mem_we    <= 1'b0;
        end else begin
            uart_send <= 1'b0;
            mem_we    <= 1'b0;

            case (state)
                S_CAPTURE: begin
                    if (sample_tick) begin
                        mem_we      <= 1'b1;
                        mem_wr_addr <= wr_addr;
                        mem_wr_data <= {4'b0000, cpu_output};
                        if (wr_addr == BUFFER_DEPTH - 1) begin
                            capturing        <= 1'b0;
                            draining         <= 1'b1;
                            rd_addr          <= 0;
                            mem_rd_addr_next <= 0;
                            state            <= S_SYNC0;
                        end else begin
                            wr_addr <= wr_addr + 1'b1;
                        end
                    end
                end

                S_SYNC0: begin
                    uart_data    <= SYNC0;
                    uart_send    <= 1'b1;
                    return_state <= S_SYNC1;
                    state        <= S_WAIT;
                end
                
                S_SYNC1: begin
                    uart_data    <= SYNC1;
                    uart_send    <= 1'b1;
                    return_state <= S_SYNC2;
                    state        <= S_WAIT;
                end
                
                S_SYNC2: begin
                    uart_data    <= SYNC2;
                    uart_send    <= 1'b1;
                    return_state <= S_SYNC3;
                    state        <= S_WAIT;
                end
                
                S_SYNC3: begin
                    uart_data    <= SYNC3;
                    uart_send    <= 1'b1;
                    return_state <= S_DRAIN_HI;
                    state        <= S_WAIT;
                end

                S_DRAIN_HI: begin
                    uart_data    <= rd_word[15:8];
                    uart_send    <= 1'b1;
                    return_state <= S_DRAIN_LO;
                    state        <= S_WAIT;
                end

                S_DRAIN_LO: begin
                    uart_data <= rd_word[7:0];
                    uart_send <= 1'b1;
                    if (rd_addr == BUFFER_DEPTH - 1) begin
                        return_state <= S_CAPTURE;
                    end else begin
                        return_state <= S_DRAIN_HI;
                    end
                    state <= S_WAIT;
                end

                S_WAIT: begin
                    if (!uart_busy && !uart_send) begin
                        if (return_state == S_DRAIN_HI) begin
                            rd_addr          <= rd_addr + 1'b1;
                            mem_rd_addr_next <= rd_addr + 1'b1;
                        end
                        if (return_state == S_CAPTURE) begin
                            draining  <= 1'b0;
                            capturing <= 1'b1;
                            wr_addr   <= 0;
                        end
                        state <= return_state;
                    end
                end
            endcase
        end
    end

endmodule
