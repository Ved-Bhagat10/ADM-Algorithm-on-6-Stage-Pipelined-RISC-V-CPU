
# Register map
#   x1  input pointer          x8   current sample
#   x2  output pointer         x9   error = sample - integrator
#   x4  integrator             x10  sign(error)
#   x5  step size              x11  sign(prev_error)
#   x6  prev_error             x15  scratch / compare result
#   x14 MIN_STEP               x16  MAX_STEP
#   x19 OUT_MAX (4095)

# ---------------- init ----------------
        addi  x1,  x0, 0          # [0]  0x00000093  input pointer  (set to real base externally)
        addi  x2,  x0, 0          # [1]  0x00000113  output pointer (set to real base externally)
        addi  x14, x0, 1          # [2]  0x00100713  MIN_STEP
        addi  x16, x0, 16         # [3]  0x01000813  MAX_STEP
        addi  x19, x0, 2047       # [4]  0x7FF00993  OUT_MAX build 1/3
        slli  x19, x19, 1         # [5]  0x00199993  OUT_MAX build 2/3 -> 4094
        addi  x19, x19, 1         # [6]  0x00198993  OUT_MAX build 3/3 -> 4095 (12-bit range)
        lui   x4,  0x1            # [7]  0x00001237  x4 = 4096
        addi  x4,  x4, -2048      # [8]  0x80020213  integrator = 2048 (mid-range)
        addi  x6,  x0, 0          # [9]  0x00000313  prev_error = 0
        add   x5,  x14, x0        # [10] 0x000702B3  step = MIN_STEP

# ---------------- main loop ----------------
LOOP:
        lw    x8,  0(x1)          # [11] 0x0000A403  sample = MEM[input_ptr]
        sub   x9,  x8, x4         # [12] 0x404404B3  error = sample - integrator
        slt   x10, x9, x0         # [13] 0x0004A533  sign(error)
        slt   x11, x6, x0         # [14] 0x000325B3  sign(prev_error)
        xor   x15, x10, x11       # [15] 0x00B547B3  nonzero -> sign reversal
        bne   x15, x0, DECREASE   # [16] 0x00079863

# ---- same sign: step = step + (step >> 1)  (x1.5) ----
        srli  x15, x5, 1          # [17] 0x0012D793
        add   x5,  x5, x15        # [18] 0x00F282B3
        jal   x0,  CLAMP_STEP     # [19] 0x0080006F

# ---- sign reversal: step = step >> 1  (x0.5) ----
DECREASE:
        srli  x5,  x5, 1          # [20] 0x0012D293

# ---- clamp step to [MIN_STEP, MAX_STEP] ----
CLAMP_STEP:
        slt   x15, x5, x14        # [21] 0x00E2A7B3  step < MIN_STEP ?
        bne   x15, x0, SET_MIN_STEP   # [22] 0x00079863
        slt   x15, x16, x5        # [23] 0x005827B3  MAX_STEP < step ?
        bne   x15, x0, SET_MAX_STEP   # [24] 0x00079863
        jal   x0,  APPLY          # [25] 0x0100006F

SET_MIN_STEP:
        add   x5,  x14, x0        # [26] 0x000702B3
        jal   x0,  APPLY          # [27] 0x0080006F

SET_MAX_STEP:
        add   x5,  x16, x0        # [28] 0x000802B3

# ---- update integrator ----
APPLY:
        beq   x9,  x0, STORE      # [29] 0x02048A63  error == 0 -> integrator unchanged
        beq   x10, x0, UPDATE_POS # [30] 0x00050663  error > 0
        sub   x4,  x4, x5         # [31] 0x40520233  error < 0: integrator -= step
        jal   x0,  CLAMP_OUTPUT   # [32] 0x0080006F

UPDATE_POS:
        add   x4,  x4, x5         # [33] 0x00520233  integrator += step

# ---- clamp integrator to [0, OUT_MAX] ----
CLAMP_OUTPUT:
        slt   x15, x19, x4        # [34] 0x0049A7B3  OUT_MAX < integrator ?
        bne   x15, x0, SET_MAX_OUT    # [35] 0x00079863
        slt   x15, x4, x0         # [36] 0x000227B3  integrator < 0 ?
        bne   x15, x0, SET_MIN_OUT    # [37] 0x00079863
        jal   x0,  STORE          # [38] 0x0100006F

SET_MAX_OUT:
        add   x4,  x19, x0        # [39] 0x00098233
        jal   x0,  STORE          # [40] 0x0080006F

SET_MIN_OUT:
        addi  x4,  x0, 0          # [41] 0x00000213

# ---- output and housekeeping ----
STORE:
        sw    x4,  0(x2)          # [42] 0x00412023  drives cpu_output + dac_strobe
        add   x6,  x9, x0         # [43] 0x00048333  prev_error = error
        addi  x1,  x1, 4          # [44] 0x00408093  input_ptr  += 4
        addi  x2,  x2, 4          # [45] 0x00410113  output_ptr += 4
        jal   x0,  LOOP           # [46] 0xF75FF06F