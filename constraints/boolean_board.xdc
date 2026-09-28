# ============================================================
# BOOLEAN BOARD CONSTRAINTS
# Device: xc7s50csga324-1
# Project: ADM CPU with XADC VAUX0 Input
# ============================================================

# ------------------------------------------------------------
# 1. CLOCK DEFINITIONS
# ------------------------------------------------------------
# Input 100 MHz oscillator on pin F14
create_clock -period 10.000 -name clk_in [get_ports clk_in]

# MMCM output clk100 (derived from clk_in)
create_generated_clock -name clk -source [get_ports clk_in] -divide_by 10 -multiply_by 10 [get_pins adm_mmcm_unit/mmcmuut/CLKOUT0]

# ------------------------------------------------------------
# 2. CLOCK PIN (Physical constraint)
# ------------------------------------------------------------
set_property PACKAGE_PIN F14 [get_ports clk_in]
set_property IOSTANDARD LVCMOS33 [get_ports clk_in]

# ------------------------------------------------------------
# 3. RESET (Slide Switch SW0)
# ------------------------------------------------------------
set_property PACKAGE_PIN V2 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

# ------------------------------------------------------------
# 4. 16 ONBOARD LEDs (cpu_output[15:0])
# ------------------------------------------------------------
set_property PACKAGE_PIN G1 [get_ports {cpu_output[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpu_output[0]}]
set_property PACKAGE_PIN G2 [get_ports {cpu_output[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpu_output[1]}]
set_property PACKAGE_PIN F1 [get_ports {cpu_output[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpu_output[2]}]
set_property PACKAGE_PIN F2 [get_ports {cpu_output[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpu_output[3]}]
set_property PACKAGE_PIN E1 [get_ports {cpu_output[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpu_output[4]}]
set_property PACKAGE_PIN E2 [get_ports {cpu_output[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpu_output[5]}]
set_property PACKAGE_PIN E3 [get_ports {cpu_output[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpu_output[6]}]
set_property PACKAGE_PIN E5 [get_ports {cpu_output[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpu_output[7]}]
set_property PACKAGE_PIN E6 [get_ports {cpu_output[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpu_output[8]}]
set_property PACKAGE_PIN C3 [get_ports {cpu_output[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpu_output[9]}]
set_property PACKAGE_PIN B2 [get_ports {cpu_output[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpu_output[10]}]
set_property PACKAGE_PIN A2 [get_ports {cpu_output[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpu_output[11]}]
set_property PACKAGE_PIN B3 [get_ports {cpu_output[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpu_output[12]}]
set_property PACKAGE_PIN A3 [get_ports {cpu_output[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpu_output[13]}]
set_property PACKAGE_PIN B4 [get_ports {cpu_output[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpu_output[14]}]
set_property PACKAGE_PIN A4 [get_ports {cpu_output[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpu_output[15]}]

# ------------------------------------------------------------
# 5. XADC ANALOG INPUT (Vaux0, via PMOD JA pin 1)
# ------------------------------------------------------------
# JA1_P -> B13 (IO_L1P_T0_AD0P_15)
# JA1_N -> A13 (IO_L1N_T0_AD0N_15)
# Bank 15 VCCO is hardwired to 3.3V on the Boolean board PCB,
# so we must explicitly set LVCMOS33 here to override Vivado's
# default LVCMOS18 inference for XADC auxiliary pins.
# The XADC primitive connection (VAUXP/VAUXN) takes precedence
# for actual analog routing -- IOSTANDARD here only controls
# the I/O buffer standard to satisfy the DRC bank voltage check.
set_property IOSTANDARD LVCMOS33 [get_ports VP]
set_property PACKAGE_PIN B13 [get_ports VP]
set_property PACKAGE_PIN A13 [get_ports VN]
set_property IOSTANDARD LVCMOS33 [get_ports VN]

# ------------------------------------------------------------
# 6. DEBUG CORE (ILA)
# ------------------------------------------------------------


set_property -dict {PACKAGE_PIN U11 IOSTANDARD LVCMOS33} [get_ports UART_txd]



create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list adm_mmcm_unit/clkfb_buf]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 32 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {adm_cpu_unit/ex2_mem_alu_result[0]} {adm_cpu_unit/ex2_mem_alu_result[1]} {adm_cpu_unit/ex2_mem_alu_result[2]} {adm_cpu_unit/ex2_mem_alu_result[3]} {adm_cpu_unit/ex2_mem_alu_result[4]} {adm_cpu_unit/ex2_mem_alu_result[5]} {adm_cpu_unit/ex2_mem_alu_result[6]} {adm_cpu_unit/ex2_mem_alu_result[7]} {adm_cpu_unit/ex2_mem_alu_result[8]} {adm_cpu_unit/ex2_mem_alu_result[9]} {adm_cpu_unit/ex2_mem_alu_result[10]} {adm_cpu_unit/ex2_mem_alu_result[11]} {adm_cpu_unit/ex2_mem_alu_result[12]} {adm_cpu_unit/ex2_mem_alu_result[13]} {adm_cpu_unit/ex2_mem_alu_result[14]} {adm_cpu_unit/ex2_mem_alu_result[15]} {adm_cpu_unit/ex2_mem_alu_result[16]} {adm_cpu_unit/ex2_mem_alu_result[17]} {adm_cpu_unit/ex2_mem_alu_result[18]} {adm_cpu_unit/ex2_mem_alu_result[19]} {adm_cpu_unit/ex2_mem_alu_result[20]} {adm_cpu_unit/ex2_mem_alu_result[21]} {adm_cpu_unit/ex2_mem_alu_result[22]} {adm_cpu_unit/ex2_mem_alu_result[23]} {adm_cpu_unit/ex2_mem_alu_result[24]} {adm_cpu_unit/ex2_mem_alu_result[25]} {adm_cpu_unit/ex2_mem_alu_result[26]} {adm_cpu_unit/ex2_mem_alu_result[27]} {adm_cpu_unit/ex2_mem_alu_result[28]} {adm_cpu_unit/ex2_mem_alu_result[29]} {adm_cpu_unit/ex2_mem_alu_result[30]} {adm_cpu_unit/ex2_mem_alu_result[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 32 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {adm_cpu_unit/adc_sample[0]} {adm_cpu_unit/adc_sample[1]} {adm_cpu_unit/adc_sample[2]} {adm_cpu_unit/adc_sample[3]} {adm_cpu_unit/adc_sample[4]} {adm_cpu_unit/adc_sample[5]} {adm_cpu_unit/adc_sample[6]} {adm_cpu_unit/adc_sample[7]} {adm_cpu_unit/adc_sample[8]} {adm_cpu_unit/adc_sample[9]} {adm_cpu_unit/adc_sample[10]} {adm_cpu_unit/adc_sample[11]} {adm_cpu_unit/adc_sample[12]} {adm_cpu_unit/adc_sample[13]} {adm_cpu_unit/adc_sample[14]} {adm_cpu_unit/adc_sample[15]} {adm_cpu_unit/adc_sample[16]} {adm_cpu_unit/adc_sample[17]} {adm_cpu_unit/adc_sample[18]} {adm_cpu_unit/adc_sample[19]} {adm_cpu_unit/adc_sample[20]} {adm_cpu_unit/adc_sample[21]} {adm_cpu_unit/adc_sample[22]} {adm_cpu_unit/adc_sample[23]} {adm_cpu_unit/adc_sample[24]} {adm_cpu_unit/adc_sample[25]} {adm_cpu_unit/adc_sample[26]} {adm_cpu_unit/adc_sample[27]} {adm_cpu_unit/adc_sample[28]} {adm_cpu_unit/adc_sample[29]} {adm_cpu_unit/adc_sample[30]} {adm_cpu_unit/adc_sample[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 32 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {adm_cpu_unit/addr_ip_buf[0]} {adm_cpu_unit/addr_ip_buf[1]} {adm_cpu_unit/addr_ip_buf[2]} {adm_cpu_unit/addr_ip_buf[3]} {adm_cpu_unit/addr_ip_buf[4]} {adm_cpu_unit/addr_ip_buf[5]} {adm_cpu_unit/addr_ip_buf[6]} {adm_cpu_unit/addr_ip_buf[7]} {adm_cpu_unit/addr_ip_buf[8]} {adm_cpu_unit/addr_ip_buf[9]} {adm_cpu_unit/addr_ip_buf[10]} {adm_cpu_unit/addr_ip_buf[11]} {adm_cpu_unit/addr_ip_buf[12]} {adm_cpu_unit/addr_ip_buf[13]} {adm_cpu_unit/addr_ip_buf[14]} {adm_cpu_unit/addr_ip_buf[15]} {adm_cpu_unit/addr_ip_buf[16]} {adm_cpu_unit/addr_ip_buf[17]} {adm_cpu_unit/addr_ip_buf[18]} {adm_cpu_unit/addr_ip_buf[19]} {adm_cpu_unit/addr_ip_buf[20]} {adm_cpu_unit/addr_ip_buf[21]} {adm_cpu_unit/addr_ip_buf[22]} {adm_cpu_unit/addr_ip_buf[23]} {adm_cpu_unit/addr_ip_buf[24]} {adm_cpu_unit/addr_ip_buf[25]} {adm_cpu_unit/addr_ip_buf[26]} {adm_cpu_unit/addr_ip_buf[27]} {adm_cpu_unit/addr_ip_buf[28]} {adm_cpu_unit/addr_ip_buf[29]} {adm_cpu_unit/addr_ip_buf[30]} {adm_cpu_unit/addr_ip_buf[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 5 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {adm_cpu_unit/ex1_ex2_rd[0]} {adm_cpu_unit/ex1_ex2_rd[1]} {adm_cpu_unit/ex1_ex2_rd[2]} {adm_cpu_unit/ex1_ex2_rd[3]} {adm_cpu_unit/ex1_ex2_rd[4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 32 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {adm_cpu_unit/ex2_mem_rd2[0]} {adm_cpu_unit/ex2_mem_rd2[1]} {adm_cpu_unit/ex2_mem_rd2[2]} {adm_cpu_unit/ex2_mem_rd2[3]} {adm_cpu_unit/ex2_mem_rd2[4]} {adm_cpu_unit/ex2_mem_rd2[5]} {adm_cpu_unit/ex2_mem_rd2[6]} {adm_cpu_unit/ex2_mem_rd2[7]} {adm_cpu_unit/ex2_mem_rd2[8]} {adm_cpu_unit/ex2_mem_rd2[9]} {adm_cpu_unit/ex2_mem_rd2[10]} {adm_cpu_unit/ex2_mem_rd2[11]} {adm_cpu_unit/ex2_mem_rd2[12]} {adm_cpu_unit/ex2_mem_rd2[13]} {adm_cpu_unit/ex2_mem_rd2[14]} {adm_cpu_unit/ex2_mem_rd2[15]} {adm_cpu_unit/ex2_mem_rd2[16]} {adm_cpu_unit/ex2_mem_rd2[17]} {adm_cpu_unit/ex2_mem_rd2[18]} {adm_cpu_unit/ex2_mem_rd2[19]} {adm_cpu_unit/ex2_mem_rd2[20]} {adm_cpu_unit/ex2_mem_rd2[21]} {adm_cpu_unit/ex2_mem_rd2[22]} {adm_cpu_unit/ex2_mem_rd2[23]} {adm_cpu_unit/ex2_mem_rd2[24]} {adm_cpu_unit/ex2_mem_rd2[25]} {adm_cpu_unit/ex2_mem_rd2[26]} {adm_cpu_unit/ex2_mem_rd2[27]} {adm_cpu_unit/ex2_mem_rd2[28]} {adm_cpu_unit/ex2_mem_rd2[29]} {adm_cpu_unit/ex2_mem_rd2[30]} {adm_cpu_unit/ex2_mem_rd2[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 5 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {adm_cpu_unit/id_ex1_rd[0]} {adm_cpu_unit/id_ex1_rd[1]} {adm_cpu_unit/id_ex1_rd[2]} {adm_cpu_unit/id_ex1_rd[3]} {adm_cpu_unit/id_ex1_rd[4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 32 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {adm_cpu_unit/mem_data[0]} {adm_cpu_unit/mem_data[1]} {adm_cpu_unit/mem_data[2]} {adm_cpu_unit/mem_data[3]} {adm_cpu_unit/mem_data[4]} {adm_cpu_unit/mem_data[5]} {adm_cpu_unit/mem_data[6]} {adm_cpu_unit/mem_data[7]} {adm_cpu_unit/mem_data[8]} {adm_cpu_unit/mem_data[9]} {adm_cpu_unit/mem_data[10]} {adm_cpu_unit/mem_data[11]} {adm_cpu_unit/mem_data[12]} {adm_cpu_unit/mem_data[13]} {adm_cpu_unit/mem_data[14]} {adm_cpu_unit/mem_data[15]} {adm_cpu_unit/mem_data[16]} {adm_cpu_unit/mem_data[17]} {adm_cpu_unit/mem_data[18]} {adm_cpu_unit/mem_data[19]} {adm_cpu_unit/mem_data[20]} {adm_cpu_unit/mem_data[21]} {adm_cpu_unit/mem_data[22]} {adm_cpu_unit/mem_data[23]} {adm_cpu_unit/mem_data[24]} {adm_cpu_unit/mem_data[25]} {adm_cpu_unit/mem_data[26]} {adm_cpu_unit/mem_data[27]} {adm_cpu_unit/mem_data[28]} {adm_cpu_unit/mem_data[29]} {adm_cpu_unit/mem_data[30]} {adm_cpu_unit/mem_data[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 32 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {adm_cpu_unit/if_id_inst[0]} {adm_cpu_unit/if_id_inst[1]} {adm_cpu_unit/if_id_inst[2]} {adm_cpu_unit/if_id_inst[3]} {adm_cpu_unit/if_id_inst[4]} {adm_cpu_unit/if_id_inst[5]} {adm_cpu_unit/if_id_inst[6]} {adm_cpu_unit/if_id_inst[7]} {adm_cpu_unit/if_id_inst[8]} {adm_cpu_unit/if_id_inst[9]} {adm_cpu_unit/if_id_inst[10]} {adm_cpu_unit/if_id_inst[11]} {adm_cpu_unit/if_id_inst[12]} {adm_cpu_unit/if_id_inst[13]} {adm_cpu_unit/if_id_inst[14]} {adm_cpu_unit/if_id_inst[15]} {adm_cpu_unit/if_id_inst[16]} {adm_cpu_unit/if_id_inst[17]} {adm_cpu_unit/if_id_inst[18]} {adm_cpu_unit/if_id_inst[19]} {adm_cpu_unit/if_id_inst[20]} {adm_cpu_unit/if_id_inst[21]} {adm_cpu_unit/if_id_inst[22]} {adm_cpu_unit/if_id_inst[23]} {adm_cpu_unit/if_id_inst[24]} {adm_cpu_unit/if_id_inst[25]} {adm_cpu_unit/if_id_inst[26]} {adm_cpu_unit/if_id_inst[27]} {adm_cpu_unit/if_id_inst[28]} {adm_cpu_unit/if_id_inst[29]} {adm_cpu_unit/if_id_inst[30]} {adm_cpu_unit/if_id_inst[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 32 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {adm_cpu_unit/pc[0]} {adm_cpu_unit/pc[1]} {adm_cpu_unit/pc[2]} {adm_cpu_unit/pc[3]} {adm_cpu_unit/pc[4]} {adm_cpu_unit/pc[5]} {adm_cpu_unit/pc[6]} {adm_cpu_unit/pc[7]} {adm_cpu_unit/pc[8]} {adm_cpu_unit/pc[9]} {adm_cpu_unit/pc[10]} {adm_cpu_unit/pc[11]} {adm_cpu_unit/pc[12]} {adm_cpu_unit/pc[13]} {adm_cpu_unit/pc[14]} {adm_cpu_unit/pc[15]} {adm_cpu_unit/pc[16]} {adm_cpu_unit/pc[17]} {adm_cpu_unit/pc[18]} {adm_cpu_unit/pc[19]} {adm_cpu_unit/pc[20]} {adm_cpu_unit/pc[21]} {adm_cpu_unit/pc[22]} {adm_cpu_unit/pc[23]} {adm_cpu_unit/pc[24]} {adm_cpu_unit/pc[25]} {adm_cpu_unit/pc[26]} {adm_cpu_unit/pc[27]} {adm_cpu_unit/pc[28]} {adm_cpu_unit/pc[29]} {adm_cpu_unit/pc[30]} {adm_cpu_unit/pc[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 32 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {adm_xadc_wrapper_unit/adc_sample[0]} {adm_xadc_wrapper_unit/adc_sample[1]} {adm_xadc_wrapper_unit/adc_sample[2]} {adm_xadc_wrapper_unit/adc_sample[3]} {adm_xadc_wrapper_unit/adc_sample[4]} {adm_xadc_wrapper_unit/adc_sample[5]} {adm_xadc_wrapper_unit/adc_sample[6]} {adm_xadc_wrapper_unit/adc_sample[7]} {adm_xadc_wrapper_unit/adc_sample[8]} {adm_xadc_wrapper_unit/adc_sample[9]} {adm_xadc_wrapper_unit/adc_sample[10]} {adm_xadc_wrapper_unit/adc_sample[11]} {adm_xadc_wrapper_unit/adc_sample[12]} {adm_xadc_wrapper_unit/adc_sample[13]} {adm_xadc_wrapper_unit/adc_sample[14]} {adm_xadc_wrapper_unit/adc_sample[15]} {adm_xadc_wrapper_unit/adc_sample[16]} {adm_xadc_wrapper_unit/adc_sample[17]} {adm_xadc_wrapper_unit/adc_sample[18]} {adm_xadc_wrapper_unit/adc_sample[19]} {adm_xadc_wrapper_unit/adc_sample[20]} {adm_xadc_wrapper_unit/adc_sample[21]} {adm_xadc_wrapper_unit/adc_sample[22]} {adm_xadc_wrapper_unit/adc_sample[23]} {adm_xadc_wrapper_unit/adc_sample[24]} {adm_xadc_wrapper_unit/adc_sample[25]} {adm_xadc_wrapper_unit/adc_sample[26]} {adm_xadc_wrapper_unit/adc_sample[27]} {adm_xadc_wrapper_unit/adc_sample[28]} {adm_xadc_wrapper_unit/adc_sample[29]} {adm_xadc_wrapper_unit/adc_sample[30]} {adm_xadc_wrapper_unit/adc_sample[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list adm_cpu_unit/adc_stall]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list adm_cpu_unit/ex1_ex2_mem_r]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list adm_cpu_unit/ex2_mem_mem_r]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list adm_cpu_unit/ex2_mem_mem_w]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list adm_cpu_unit/id_ex1_mem_r]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list adm_cpu_unit/ip_buf_wr]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 1 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list adm_cpu_unit/load_use_hazard]]
create_debug_core u_ila_1 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_1]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_1]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_1]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_1]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
set_property port_width 1 [get_debug_ports u_ila_1/clk]
connect_debug_port u_ila_1/clk [get_nets [list clk_BUFG]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
set_property port_width 16 [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list {adm_xadc_wrapper_unit/DO[0]} {adm_xadc_wrapper_unit/DO[1]} {adm_xadc_wrapper_unit/DO[2]} {adm_xadc_wrapper_unit/DO[3]} {adm_xadc_wrapper_unit/DO[4]} {adm_xadc_wrapper_unit/DO[5]} {adm_xadc_wrapper_unit/DO[6]} {adm_xadc_wrapper_unit/DO[7]} {adm_xadc_wrapper_unit/DO[8]} {adm_xadc_wrapper_unit/DO[9]} {adm_xadc_wrapper_unit/DO[10]} {adm_xadc_wrapper_unit/DO[11]} {adm_xadc_wrapper_unit/DO[12]} {adm_xadc_wrapper_unit/DO[13]} {adm_xadc_wrapper_unit/DO[14]} {adm_xadc_wrapper_unit/DO[15]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
set_property port_width 5 [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list {adm_xadc_wrapper_unit/channel[0]} {adm_xadc_wrapper_unit/channel[1]} {adm_xadc_wrapper_unit/channel[2]} {adm_xadc_wrapper_unit/channel[3]} {adm_xadc_wrapper_unit/channel[4]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
set_property port_width 26 [get_debug_ports u_ila_1/probe2]
connect_debug_port u_ila_1/probe2 [get_nets [list {adm_xadc_wrapper_unit/period_cnt[0]} {adm_xadc_wrapper_unit/period_cnt[1]} {adm_xadc_wrapper_unit/period_cnt[2]} {adm_xadc_wrapper_unit/period_cnt[3]} {adm_xadc_wrapper_unit/period_cnt[4]} {adm_xadc_wrapper_unit/period_cnt[5]} {adm_xadc_wrapper_unit/period_cnt[6]} {adm_xadc_wrapper_unit/period_cnt[7]} {adm_xadc_wrapper_unit/period_cnt[8]} {adm_xadc_wrapper_unit/period_cnt[9]} {adm_xadc_wrapper_unit/period_cnt[10]} {adm_xadc_wrapper_unit/period_cnt[11]} {adm_xadc_wrapper_unit/period_cnt[12]} {adm_xadc_wrapper_unit/period_cnt[13]} {adm_xadc_wrapper_unit/period_cnt[14]} {adm_xadc_wrapper_unit/period_cnt[15]} {adm_xadc_wrapper_unit/period_cnt[16]} {adm_xadc_wrapper_unit/period_cnt[17]} {adm_xadc_wrapper_unit/period_cnt[18]} {adm_xadc_wrapper_unit/period_cnt[19]} {adm_xadc_wrapper_unit/period_cnt[20]} {adm_xadc_wrapper_unit/period_cnt[21]} {adm_xadc_wrapper_unit/period_cnt[22]} {adm_xadc_wrapper_unit/period_cnt[23]} {adm_xadc_wrapper_unit/period_cnt[24]} {adm_xadc_wrapper_unit/period_cnt[25]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
set_property port_width 1 [get_debug_ports u_ila_1/probe3]
connect_debug_port u_ila_1/probe3 [get_nets [list adm_xadc_wrapper_unit/conv_pending]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
set_property port_width 1 [get_debug_ports u_ila_1/probe4]
connect_debug_port u_ila_1/probe4 [get_nets [list adm_cpu_unit/dac_strobe]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe5]
set_property port_width 1 [get_debug_ports u_ila_1/probe5]
connect_debug_port u_ila_1/probe5 [get_nets [list adm_xadc_wrapper_unit/den_reg]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe6]
set_property port_width 1 [get_debug_ports u_ila_1/probe6]
connect_debug_port u_ila_1/probe6 [get_nets [list adm_xadc_wrapper_unit/drdy]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_BUFG]
