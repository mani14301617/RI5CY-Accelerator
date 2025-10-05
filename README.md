# RI5CY-Accelerator
# ML-Accelerated RISC-V Core (RV32IMC)

This repository contains a **modified RISC-V “RISCY” core derived from the
[OpenHW Group’s cv32e40p](https://github.com/openhwgroup/cv32e40p) implementation**.
The goal is to fuse common ML primitives directly into the pipeline so that edge-AI
workloads run with **far fewer clock cycles and minimal software changes**.
## 🧠 Custom Hardware-Accelerated Modules

### 🔍 Overview

This project enhances a RISC-V-based processor by integrating custom **memory-mapped modules** for computing the **Sigmoid** and **ReLU** activation functions, as well as a dedicated **dot product accelerator**. The design makes use of a **4-stage pipelined floating-point adder and multiplier**, specifically for accelerating dot product operations. All modules interface with memory via the processor’s **Load-Store Unit (LSU)**.

### 🔄 Operational Flow

1. **Data Access via Load-Store Unit (LSU)**  
   All input vectors or activation data are accessed from memory through the LSU. This ensures a seamless interface with the processor’s instruction and memory system.

2. **Dot Product Acceleration**  
   - Two input vectors are loaded from memory.  
   - Each element pair is fed **serially** into a **4-stage pipelined floating-point multiplier**.  
   - The output from the multiplier is then passed to a **4-stage pipelined floating-point adder** for **accumulation**.  
   - The adder loops back internally to accumulate partial sums across all elements.  
   - Final result is written back to GPRs(General Purpose Registers) via the LSU.

3. **Activation Functions (Sigmoid & ReLU)**  
   - Input values are fetched in **batches (e.g., 16 values)**.  
   - The selected activation module processes the data:  
     - **Sigmoid Module:** Implements `f(x) = 1 / (1 + e^{-x})` using fixed logic and control.  
     - **ReLU Module:** Implements `f(x) = max(0, x)` with simple comparison logic.  
   - Output is buffered and written back to memory.  
   - This process repeats until the entire input range is processed.

![Screenshot 2025-05-05 152017](https://github.com/user-attachments/assets/49194ea7-0cce-4873-8997-93556466249e)
### ⚙️ Key Hardware Components

- **Memory-Mapped Sigmoid Module**  
  Efficiently computes sigmoid activations using internal logic. Optimized for batch processing with FSM control.

- **Memory-Mapped ReLU Module**  
  Implements thresholding logic to apply rectified linear activation with minimal delay.

- **4-Stage Pipelined Floating-Point Multiplier** *(for dot product)*  
  Accepts one pair of operands per cycle after pipeline fill; supports continuous throughput.

- **4-Stage Pipelined Floating-Point Adder** *(for dot product)*  
  Performs serial accumulation of partial products; looped back internally to sum all results.

![Screenshot 2025-05-05 152040](https://github.com/user-attachments/assets/de04386f-044c-4f47-9119-8c30a2b874ce)
### 🚀 Benefits

- **Performance Boost**  
  Hardware acceleration of dot product and activations drastically reduces cycle count compared to software execution.

- **Memory-Mapped Simplicity**  
  Easy to invoke through custom instructions and maintainable like standard memory-mapped peripherals.

- **Scalable Design**  
  Architecture supports future expansion to other functions like Softmax, BatchNorm, etc.

- **FPGA Friendly**  
  All modules are RTL-synthesizable and designed for eventual deployment on FPGA or ASIC.
![Screenshot 2025-05-05 152103](https://github.com/user-attachments/assets/1ef1287d-4e51-4faf-9df0-71808b0073a4)

## 🧩 Chip Layout (65 nm Physical Design)

This section presents the **final placed-and-routed layout** of the ML-Accelerated RISC-V Core, implemented using **Cadence Innovus** on **TSMC 65 nm CMOS** technology.  
The design integrates all accelerator modules (Dot-Product, ReLU, Sigmoid) within the RI5CY pipeline and achieves full physical sign-off.

### 🏗️ Layout Overview
- **Technology:** 65 nm CMOS (TSMC Standard Cell Library)  
- **Toolchain:** Cadence Innovus (Placement & Routing)  
- **Core Area:** ~ `X mm × Y mm`  
- **Cell Utilization:** ~ `Z %`  
- **Clock Target:** 100 MHz (FPGA-compatible timing goal)  
- **Integrated Blocks:**  
  - RI5CY Core Pipeline  
  - 4-Stage FP Multiplier & Adder  
  - Memory-Mapped Sigmoid and ReLU Modules  
  - Load-Store Unit (LSU) Interface to BRAM  

### 🖼️ Layout Visualization

<img width="833" height="805" alt="Screenshot 2025-07-15 135842" src="https://github.com/user-attachments/assets/3408a452-3847-44c1-bd8b-138aef841d7f" />



<p align="center"><em> Placed-and-Routed layout of RI5CY-Accelerator in 65 nm technology (Cadence Innovus).</em></p>

> ✅ **DRC & LVS Clean:** All physical-verification checks passed.  
> ⚡ **Integrated Accelerators:** ML modules are fused within the RISC-V datapath.  
> 🧠 **Optimized for Edge-AI:** Compact footprint with hardware-level ML acceleration.
