# APB FIFO UART UVM Verification

## Overview

This project verifies an **APB4-controlled FIFO with an integrated UART transmitter** using **SystemVerilog and UVM**.

The DUT accepts data through an APB4 slave interface, stores it in a configurable FIFO, and automatically transmits the data through UART.

```text
APB4 → FIFO → UART TX → uart_tx_o
```

A UVM verification environment was developed to verify the complete data path, FIFO status behavior, APB error handling, reset behavior, and corner cases.

## DUT Features

- AMBA APB4 slave interface
- Configurable FIFO depth: 8 / 16 / 32 / 64 / 128 / 256
- FIFO full, empty, and data-count status
- UART TX with configurable baud divider
- APB invalid-address detection with `PSLVERR`
- UART protection for `baud_div = 0`

## UVM Environment

```text
Sequence → Sequencer → APB Driver → DUT
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
               APB Monitor                UART Monitor
                    │                           │
                    └──────────→ Scoreboard ←──┘
```

The environment includes:

- APB and UART transactions
- APB sequences, sequencer, and driver
- APB monitor and UART monitor
- APB agent
- Scoreboard with expected queue
- Functional coverage
- Directed UVM tests

## Verification Plan

| Test | Purpose |
|---|---|
| TC01 Basic Write | APB → FIFO → UART data path |
| TC02 Multiple Writes | Data ordering |
| TC03 Data Patterns | UART bit patterns |
| TC04 FIFO Full | Full condition |
| TC05 FIFO Empty | Empty condition |
| TC06 Status Read | FIFO status through APB |
| TC07 Invalid Address | `PSLVERR` handling |
| TC08 Depth Configuration | FIFO depths 8–256 |
| TC09 Mid-Frame Reset | Reset during UART transmission |
| TC10 Read Pointer Wrap | FIFO pointer wrap-around |
| TC11 Zero Baud Divider | `baud_div = 0` boundary |

All planned tests passed with:

```text
UVM_ERROR = 0
UVM_FATAL = 0
```

## Coverage

- **Functional Coverage: 100%**
- **Final Filtered Code Coverage: 78.47%**

Coverage-driven verification was used to target reachable corner cases including FIFO pointer wrap-around and `baud_div = 0`.

The unreachable UART FSM default branch was reviewed and excluded as defensive logic.

## Key Debugging Experience

Several verification issues were identified and resolved during development:

- Fixed premature test termination caused by treating FIFO `empty` as end-to-end completion.
- Corrected scoreboard prediction for state-dependent FIFO status.
- Accounted for concurrent APB writes and UART consumption when testing FIFO full.
- Fixed late sampling of transaction-level `PSLVERR`.
- Made the UART monitor reset-aware for mid-frame reset.
- Fixed a UART monitor sampling race exposed at the minimum baud divider.

Detailed debugging notes are available in `doc/debug.log`.

## Project Structure

```text
UVM_APB_FIFO_UART/
├── dut/              # FIFO and UART RTL
├── uvm/
│   ├── transaction/
│   ├── sequence/
│   ├── driver/
│   ├── monitor/
│   ├── agent/
│   ├── scoreboard/
│   ├── coverage/
│   ├── env/
│   └── test/
├── doc/              # Test plan, debug log, project log
└── README.md
```

## Tools

- SystemVerilog
- UVM
- QuestaSim
- Functional Coverage
- Code Coverage
