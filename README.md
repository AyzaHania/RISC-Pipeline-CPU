# RISC Pipelined CPU

A 32-bit 5-stage pipelined RISC processor designed from RTL to physical layout using industry-standard Cadence EDA tools.

---

## Table of contents

1. [Project overview](#1-project-overview)
2. [Processor architecture](#2-processor-architecture)
3. [Pipeline stages](#3-pipeline-stages)
4. [Hazard handling](#4-hazard-handling)
5. [RTL flow](#5-rtl-flow)
6. [Synthesis flow](#6-synthesis-flow)
7. [Physical design flow](#7-physical-design-flow)
8. [Timing analysis](#8-timing-analysis)
9. [Results](#9-results)

---

## 1. Project overview

This project implements a 32-bit 5-stage pipelined RISC processor in Verilog HDL, verified through simulation, synthesized to a gate-level netlist, and taken through full physical design including placement, clock tree synthesis, and routing.

| Item | Detail |
|------|--------|
| Architecture | 32-bit MIPS-inspired RISC |
| Pipeline stages | 5 (IF, ID, EX, MEM, WB) |
| Hazard handling | Forwarding unit + hazard detection unit |
| Technology | 45 nm GPDK045 |
| Clock frequency | 142 MHz (7 ns period) |
| Core area | 150.31 × 147.06 µm |
| Total cells | 4,559 standard cells |
| Simulation tool | Cadence Xcelium + SimVision |
| Synthesis tool | Cadence Genus |
| Physical design tool | Cadence Innovus |

---

## 2. Processor architecture

### Instruction set

The CPU supports four instruction types using a MIPS-inspired 32-bit encoding.

| Opcode | Type | Example | Operation |
|--------|------|---------|-----------|
| `000000` | R-type | `ADD R3, R1, R2` | Register arithmetic/logic |
| `100011` | LOAD | `LW R1, 4(R2)` | Read from data memory |
| `101011` | STORE | `SW R1, 4(R2)` | Write to data memory |
| `000100` | BRANCH | `BEQ R1, R2, label` | Conditional PC jump |

### Instruction format

```
[31:26] opcode   — 6 bits  — instruction type
[25:21] rs1      — 5 bits  — source register 1
[20:16] rs2      — 5 bits  — source register 2
[15:11] rd       — 5 bits  — destination register
[10:0]  funct/imm — 11 bits — operation detail or immediate
```

### RTL modules

| File | Module | Description |
|------|--------|-------------|
| `alu.v` | `alu` | 32-bit combinational ALU — ADD, SUB, AND, OR, XOR |
| `alu_control.v` | `alu_control` | Translates `alu_op` + `funct` to 3-bit `alu_ctrl` |
| `register_file.v` | `register_file` | 32 × 32-bit registers, 2 read ports, 1 write port. R0 hardwired to 0 |
| `pc.v` | `pc` | 32-bit program counter with reset and `pc_write` stall input |
| `instruction_memory.v` | `instruction_memory` | Byte-addressed ROM, 64 bytes |
| `data_memory.v` | `data_memory` | Byte-addressed RAM — LOAD (combinational) / STORE (clocked) |
| `control_unit.v` | `control_unit` | Decodes opcode, generates 7 control signals |
| `sign_extension.v` | `sign_extend` | 16-bit → 32-bit sign extension using `{{16{in[15]}}, in}` |
| `mux.v` | `mux_alu_src`, `mux_mem_to_reg`, `mux_pc_src` | Three 2-to-1 MUXes for datapath selection |
| `pipeline_regs.v` | `if_id`, `id_ex`, `ex_mem`, `mem_wb` | Four pipeline registers between stages |
| `forwarding_unit.v` | `forwarding_unit` | Detects RAW hazards, sets `forwardA`/`forwardB` |
| `hazard_detection.v` | `hazard_detection` | Detects load-use hazards, asserts stall |
| `pipeline_cpu_top.v` | `pipeline_cpu_top` | Full pipelined CPU top-level |
| `cpu_core.v` | `cpu_core` | Synthesis-ready CPU with memory as external ports |

---

## 3. Pipeline stages

The processor uses a classic 5-stage pipeline. Each stage operates on a different instruction simultaneously, separated by pipeline registers that carry both data and control signals forward.

```
IF  →  [IF/ID]  →  ID  →  [ID/EX]  →  EX  →  [EX/MEM]  →  MEM  →  [MEM/WB]  →  WB
```

| Stage | Name | Hardware | What happens |
|-------|------|----------|--------------|
| IF | Instruction Fetch | PC, IMem | PC sends address to instruction memory. 32-bit instruction fetched. PC+4 computed. |
| ID | Instruction Decode | Control unit, Register file, Sign extender | Opcode decoded. 7 control signals generated. rs1 and rs2 read simultaneously. Immediate sign-extended. |
| EX | Execute | ALU control, ALU, MUX1 | ALU performs operation. Branch address computed. Zero flag produced. Forwarding MUXes select correct operands. |
| MEM | Memory Access | Data memory | LOAD reads from memory. STORE writes to memory. R-type instructions pass through idle. |
| WB | Write Back | MUX2, Register file | MUX2 selects ALU result or memory data. Result written to destination register. |

### Pipeline timing example

Four consecutive ADD instructions filling the pipeline:

```
        C1    C2    C3    C4    C5    C6    C7    C8
I1      IF    ID    EX    MEM   WB
I2            IF    ID    EX    MEM   WB
I3                  IF    ID    EX    MEM   WB
I4                        IF    ID    EX    MEM   WB
```

Once full (cycle 4 onward), one instruction completes every cycle — approximately 5× throughput improvement over single-cycle for long programs.

### Control signals

The control unit generates 7 signals from the 6-bit opcode:

| Signal | Width | Used in | Purpose |
|--------|-------|---------|---------|
| `reg_write` | 1 bit | WB | Write result to register file |
| `mem_read` | 1 bit | MEM | Read from data memory (LOAD) |
| `mem_write` | 1 bit | MEM | Write to data memory (STORE) |
| `mem_to_reg` | 1 bit | WB | Select ALU result or memory data |
| `alu_src` | 1 bit | EX | Select register or immediate as ALU B input |
| `branch` | 1 bit | MEM | Flag this as a branch instruction |
| `alu_op` | 2 bits | EX | Category hint to ALU control unit |

---

## 4. Hazard handling

### Data hazards — forwarding unit

When an instruction reads a register that a previous instruction has not yet written back, the forwarding unit routes the already-computed result directly to the ALU inputs, bypassing the register file.

```
forwardA / forwardB encoding:
  00 → use register file output (no hazard)
  01 → forward from MEM/WB stage (instruction 2 back)
  10 → forward from EX/MEM stage (immediately previous instruction)
```

Detection logic (for forwardA):

```verilog
if (exmem_reg_write && exmem_rd != 0 && exmem_rd == ex_rs1)
    forwardA = 2'b10;   // EX hazard — most recent value
else if (memwb_reg_write && memwb_rd != 0 && memwb_rd == ex_rs1)
    forwardA = 2'b01;   // MEM hazard
else
    forwardA = 2'b00;   // no hazard
```

This resolves RAW data hazards with **zero stall cycles**.

### Load-use hazard — hazard detection unit

A LOAD result is only available at the end of MEM stage. If the immediately following instruction needs it at the start of EX, forwarding cannot bridge the gap. One stall cycle is inserted.

Detection condition:

```verilog
if (idex_mem_read
    && idex_rd != 0
    && (idex_rd == ifid_rs1 || idex_rd == ifid_rs2))
    → HAZARD DETECTED
```

Three outputs on hazard:

| Signal | Value | Effect |
|--------|-------|--------|
| `stall` | 1 | Inserts NOP bubble into ID/EX |
| `pc_write` | 0 | Freezes PC — same instruction re-fetched |
| `ifid_write` | 0 | Freezes IF/ID — instruction in ID replayed |

After the 1-cycle stall, the forwarding unit routes the LOAD result from MEM/WB directly to the next instruction's ALU input.

### Control hazard — branch flush

Branch decisions are resolved at the MEM stage. Two instructions have already entered IF and ID by then. When `branch AND zero` is asserted, those two instructions are flushed (replaced with NOPs) and the PC redirects to the branch target.

```verilog
assign pc_src = mem_branch & mem_zero;
```

**Branch penalty: 2 cycles.**

### Hazard summary

| Situation | Handler | Stall cycles |
|-----------|---------|-------------|
| RAW data hazard (consecutive instructions) | Forwarding unit | 0 |
| Load-use hazard | Hazard detection + forwarding | 1 |
| Branch taken | Branch flush | 2 |
| Structural hazard (memory) | Harvard architecture (separate IMem/DMem) | 0 |

---

## 5. RTL flow

```
Write Verilog RTL
       ↓
Compile with Cadence Xcelium (xrun)
       ↓
Run testbench — check outputs
       ↓
View waveforms in Cadence SimVision
       ↓
Verify all test cases pass
```

### Simulation results

All modules verified individually and as a complete pipelined system:

| Test | Expected | Result |
|------|----------|--------|
| ADD R3, R1, R2 (R1=10, R2=20) | R3 = 30 | PASS |
| ADD R5, R3, R1 — forwarding from EX/MEM | R5 = 40 | PASS |
| ADD R7, R5, R3 — forwarding from EX/MEM | R7 = 70 | PASS |
| ADD R9, R7, R5 — forwarding from EX/MEM | R9 = 110 | PASS |
| Load-use stall — 1 bubble inserted | Correct value after stall | PASS |
| ALU zero flag for branch comparison | Zero = 1 when equal | PASS |

---

## 6. Synthesis flow

```
RTL (cpu_core.v)
       ↓
Load technology library — GPDK045 slow corner (125°C, 1.08 V)
       ↓
set_db library <path/slow_vdd1v2_basicCells.lib>
       ↓
read_hdl -sv <all RTL files>
       ↓
elaborate cpu_core
       ↓
create_clock -period <N> [get_ports clk]
       ↓
syn_generic   → technology-independent optimization
syn_map       → map to GPDK045 standard cells
syn_opt       → post-map timing optimization
       ↓
write_netlist → cpu_core_netlist.v
write_sdc     → constraints.sdc
```

> **Note on memory:** Synthesis tools cannot map Verilog arrays to standard cells. `cpu_core.v` exposes instruction and data memory as external ports, which is standard industry practice — memories are always handled by dedicated SRAM compilers.

### Clock period exploration

Synthesis was run at multiple clock periods to find the maximum timing-clean operating frequency:

| Clock period | Frequency | Synthesis WNS | Post-route status |
|-------------|-----------|--------------|-------------------|
| 10 ns | 100 MHz | +4318 ps | MET ✓ |
| 8 ns | 125 MHz | +2100 ps | MET ✓ |
| 7 ns | 142 MHz | +1621 ps | MET ✓ |
| 5 ns | 200 MHz | +568 ps | MET ✓ |
| 4 ns | 250 MHz | +397 ps | MET ✓ |
| 3 ns | 333 MHz | +23 ps | VIOLATED ✗ |

**7 ns selected as the optimal timing-clean operating point.** The 3 ns run violated post-route timing because the 23 ps synthesis slack was too small to absorb real wire delays (typically 200–300 ps after routing).

---

## 7. Physical design flow

```
Gate-level netlist + SDC constraints
       ↓
Floorplan — define chip boundary, power grid
       ↓
Placement — assign X/Y coordinates to 4,559 cells
       ↓
Clock Tree Synthesis (CTS) — balance clock to all flip-flops
       ↓
Routing — draw metal wires on 7 metal layers
       ↓
Post-route optimization — fix timing and DRC violations
       ↓
Sign-off: timeDesign postRoute + verify_drc
```

### Floorplan

```tcl
floorPlan -r 1.0 0.7 5.0 5.0 5.0 5.0
# aspect ratio 1.0 (square), core utilization 70%, 5 µm margins
```

| Parameter | Value |
|-----------|-------|
| Core width | 150.31 µm |
| Core height | 147.06 µm |
| Core utilization | 72.5% |
| Die fits within | 250 × 250 µm requirement ✓ |

### Clock tree synthesis results

| Metric | Value |
|--------|-------|
| Max clock latency | 0.086 ns |
| Min clock latency | 0.009 ns |
| Max clock skew | **0.014 ns (14 ps)** |
| Clock buffers inserted | ~3,806 |

14 ps skew across the entire chip — excellent CTS quality.

### Routing

| Metric | Value |
|--------|-------|
| Routing overflow H | 0.00% |
| Routing overflow V | 0.00% |
| DRC violations (final) | 0 |
| Total routed nets | ~3,377 |

---

## 8. Timing analysis

### Post-route timing summary (7 ns clock)

| Metric | Value | Status |
|--------|-------|--------|
| Clock period | 7 ns | — |
| Worst negative slack (WNS) | +1.300 ns | MET ✓ |
| Total negative slack (TNS) | 0.000 ns | PERFECT ✓ |
| Violating paths | 0 | CLEAN ✓ |
| max_cap violations | 0 | CLEAN ✓ |
| max_tran violations | 0 | CLEAN ✓ |
| max_fanout violations | 0 | CLEAN ✓ |

**Critical path:** Forwarding unit → ALU 32-bit adder → EX/MEM pipeline register

The 32-bit ripple-carry adder in the ALU is the bottleneck. A carry-lookahead or carry-select adder would push the frequency significantly higher.

### Post-CTS vs post-route comparison

| Stage | WNS | TNS | Violations |
|-------|-----|-----|-----------|
| Post-CTS | +1.191 ns | 0.000 ns | 0 |
| Post-route | +1.300 ns | 0.000 ns | 0 |

WNS improved after routing because Innovus performed post-route optimization that found and fixed marginal paths.

---

## 9. Results

### Final performance numbers

| Metric | Value |
|--------|-------|
| Architecture | 32-bit 5-stage pipelined RISC |
| Technology | 45 nm GPDK045, Vdd = 1.2 V |
| **Clock frequency** | **142 MHz (7 ns period)** |
| Total standard cells | 4,559 |
| Core area | 150.31 × 147.06 µm (22,093 µm²) |
| Core utilization | 72.575% |
| Post-route WNS | +1.300 ns (43% timing margin) |
| TNS | 0.000 ns |
| DRC violations | 0 |
| Clock skew | 0.014 ns |
| Total power | 0.1522 mW |
| Critical path | Forwarding unit → ALU adder → EX/MEM reg |

### Area breakdown

| Module | Cells | Area (µm²) | % of total |
|--------|-------|-----------|-----------|
| Register file | 2,990 | 11,544 | 72% |
| ID/EX register | 274 | 909 | 6% |
| EX/MEM register | 213 | 748 | 5% |
| IF/ID register | 199 | 570 | 4% |
| MEM/WB register | 142 | 485 | 3% |
| Program counter | 64 | 218 | 1% |
| Forwarding unit | 35 | 72 | 0.5% |
| Hazard detection | 16 | 35 | 0.2% |
| Control unit | 9 | 12 | 0.08% |
| ALU control | 8 | 15 | 0.09% |

> The register file accounts for 72% of total area — consistent with real chip design, where storage dominates. This is why production CPUs use dedicated SRAM macros instead of flip-flop arrays.

### Power breakdown

| Type | Value |
|------|-------|
| Internal power | 0.0377 mW |
| Switching power | 0.1145 mW |
| Leakage power | 0.0000137 mW |
| **Total power** | **0.1522 mW** |
| Clock network | 17.61% of total |

---

## Repository structure

```
RISC_PIPELINE_CPU/
├── rtl/
│   ├── alu.v
│   ├── alu_control.v
│   ├── register_file.v
│   ├── pc.v
│   ├── instruction_memory.v
│   ├── data_memory.v
│   ├── control_unit.v
│   ├── sign_extension.v
│   ├── mux.v
│   ├── pipeline_regs.v
│   ├── forwarding_unit.v
│   ├── hazard_detection.v
│   ├── pipeline_cpu_top.v
│   └── cpu_core.v
├── testbench/
│   ├── tb_alu.v
│   ├── tb_register_file.v
│   ├── tb_pipeline_cpu.v
│   └── run_sim.sh
├── reports/
│   ├── timing_report_7ns.rpt
│   ├── area_report.rpt
│   └── power_report.rpt
├── layout/
│   ├── cpu_core_final.gds
│   └── drc_report.rpt
├── docs/
│   ├── architecture_diagram.pdf
│   └── pipeline_diagram.pdf
└── README.md
```

---

## Tools used

| Tool | Purpose |
|------|---------|
| Cadence Xcelium | RTL simulation |
| Cadence SimVision | Waveform viewing |
| Cadence Genus | Logic synthesis |
| Cadence Innovus | Physical design (place and route) |
| GPDK045 | 45 nm educational process design kit |
