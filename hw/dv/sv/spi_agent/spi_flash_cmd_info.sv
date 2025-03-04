// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// this object stores the cfg info for a command, so that when a driver/monitor receives a flash
// cmd, it knows how many addr_bytes, direction, dummy_cycles etc
class spi_flash_cmd_info extends uvm_sequence_item;
  rand bit [7:0] opcode;
  rand bit [2:0] addr_bytes;
  rand bit write_command;
  rand bit [2:0] num_lanes;
  rand int dummy_cycles;

  constraint addr_bytes_c {
    addr_bytes inside {0, 3, 4};
    // for dual/quad mode, it always contains address
    num_lanes > 1 -> addr_bytes > 0;
  }

  constraint num_lanes_c {
    write_command -> num_lanes == 1;
    num_lanes inside {1, 2, 4};
  }

  constraint dummy_cycles_c {
    dummy_cycles dist {
      0     :/ 1,
      [2:7] :/ 1,
      8     :/ 1
    };
  }

  `uvm_object_utils_begin(spi_flash_cmd_info)
    `uvm_field_int(opcode,        UVM_DEFAULT)
    `uvm_field_int(addr_bytes,    UVM_DEFAULT)
    `uvm_field_int(write_command, UVM_DEFAULT)
    `uvm_field_int(dummy_cycles,  UVM_DEFAULT)
    `uvm_field_int(num_lanes,     UVM_DEFAULT)
  `uvm_object_utils_end

  `uvm_object_new
endclass
