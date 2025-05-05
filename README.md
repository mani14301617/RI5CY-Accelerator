# RI5CY-Accelerator
# ML-Accelerated RISC-V Core (RV32IMC)

This repository contains a **modified RISC-V “RISCY” core derived from the
[OpenHW Group’s cv32e40p](https://github.com/openhwgroup/cv32e40p) implementation**.
The goal is to fuse common ML primitives directly into the pipeline so that edge-AI
workloads run with **far fewer clock cycles and minimal software changes**.
Currently I have implented a faster DOT Product ,ReLU and Sigmoid activation function mechanism and I am working on other functions which will potentially be used in ML/AI algorithms. 
 Block diagram of the 32-bit cv32e40p core highlighting the added Dot-Prod, ReLU, and Sigmoid execution units wired into the Execution stage
![Screenshot 2025-05-05 152017](https://github.com/user-attachments/assets/49194ea7-0cce-4873-8997-93556466249e)
![Screenshot 2025-05-05 152040](https://github.com/user-attachments/assets/de04386f-044c-4f47-9119-8c30a2b874ce)
![Screenshot 2025-05-05 152103](https://github.com/user-attachments/assets/1ef1287d-4e51-4faf-9df0-71808b0073a4)
