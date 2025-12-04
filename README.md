RV32IM Multi-Cycle RISC-V Processor Core

Welcome!
This project is my personal implementation of a custom multi-cycle RV32IM RISC-V processor core. It started as a learning journey to truly understand how a CPU works at the micro-architectural level—beyond diagrams and textbooks—and slowly grew into a complete, working design that I can simulate, test, and eventually take through an ASIC flow.

What this project is about

The processor implements the full RV32I base integer instruction set along with the M-extension (multiply/divide). Instead of using a pipelined architecture, I built a multi-cycle core that executes instructions over several well-defined FSM states.
This allowed me to focus on clarity, correctness, and resource sharing, while still keeping the design modular and easy to debug.

Along the way, I experimented with:

A folded hardware multiplier (area-efficient)

A radix-4 iterative divider

A shared datapath to reduce hardware duplication

Clean FSM control for each instruction type
All of this helped me develop a strong understanding of real CPU design trade-offs.


Why I built this

This project became a foundation for something bigger:
I plan to integrate a custom CNN hardware accelerator as a RISC-V extension in the next phase.
So the core is written cleanly, modularly, and with future expansion in mind.

Current Status

1. Instruction fetch → decode → execute → mem → writeback working
2. ALU operations validated
3. Multiplier + divider integrated
4. Test programs running in simulation
5. Future: custom CNN accelerator integration
6. Future: full ASIC flow using SAED14nm

What I learned

Designing a processor from scratch teaches you everything you don’t see on the surface—timing, control flow, datapath bottlenecks, and how every tiny decision affects the final hardware.
This repo is both a project and a personal learning log that tracks my growth in digital design, computer architecture, and RTL development.

Future Work

Add custom CNN instructions for my hardware accelerator

Run full ASIC flow (DC → ICC2 → PrimeTime)

Add more RISC-V compliance tests

Implement basic exceptions + CSR unit

Explore low-power optimizations
