// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class flash_ctrl_base_vseq extends cip_base_vseq #(
  .RAL_T              (flash_ctrl_core_reg_block),
  .CFG_T              (flash_ctrl_env_cfg),
  .COV_T              (flash_ctrl_env_cov),
  .VIRTUAL_SEQUENCER_T(flash_ctrl_virtual_sequencer)
);

  `uvm_object_utils(flash_ctrl_base_vseq)

  // OTP Scramble Keys, Used In OTP MODEL
  logic [KeyWidth-1:0] otp_addr_key;
  logic [KeyWidth-1:0] otp_addr_rand_key;
  logic [KeyWidth-1:0] otp_data_key;
  logic [KeyWidth-1:0] otp_data_rand_key;

  // flash ctrl configuration settings.
  bit [1:0]            otp_key_init_done;

  constraint num_trans_c {num_trans inside {[1 : cfg.seq_cfg.max_num_trans]};}

  `uvm_object_new

  // Determine post-reset initialization method.
  rand flash_mem_init_e flash_init;

  // rand data for program
  rand data_q_t flash_program_data;

  constraint flash_program_data_c {flash_program_data.size == 16;}

  // default region cfg
  flash_mp_region_cfg_t default_region_cfg = '{
      default: MuBi4True,
      scramble_en: MuBi4False,
      ecc_en: MuBi4False,
      he_en: MuBi4False,
      // below two won't be programmed
      // rtl uses hardcoded values
      // start:0
      // size : 2 * 256 (0x200)
      num_pages: 1,
      start_page: 0
  };

  // default info cfg
  flash_bank_mp_info_page_cfg_t default_info_page_cfg = '{
      default: MuBi4True,
      scramble_en: MuBi4False,
      ecc_en: MuBi4False,
      he_en: MuBi4False
  };

  // By default, in 30% of the times initialize flash as in initial state (all 1s),
  //  while in 70% of the times the initialization will be randomized (simulating working flash).
  constraint flash_init_c {
    flash_init dist {
      FlashMemInitSet       :/ cfg.seq_cfg.flash_init_set_pc,
      FlashMemInitRandomize :/ 100 - cfg.seq_cfg.flash_init_set_pc
    };
  }

  // Page to region map.
  // This is used to validate transactions based on their page address
  // and policy config associate with it.
  // 8 : default region
  int p2r_map[FlashNumPages] = '{default : 8};

  // Vseq to do some initial post-reset actions. Can be overriden by extending envs.
  flash_ctrl_callback_vseq callback_vseq;

  // 1page : 2048Byte
  function int addr2page(bit[OTFBankId:0] addr);
    return (int'(addr[OTFBankId:11]));
  endfunction // addr2page

  function flash_mp_region_cfg_t get_region(int page);
    if (cfg.p2r_map[page] == 8) return default_region_cfg;
    else begin
      // TODO support memory protection
    end
  endfunction // get_region

  virtual task pre_start();
    `uvm_create_on(callback_vseq, p_sequencer);
    otp_model();  // Start OTP Model
    super.pre_start();
    cfg.alert_max_delay_in_ns = cfg.alert_max_delay * (cfg.clk_rst_vif.clk_period_ps / 1000.0);
  endtask : pre_start

  virtual task dut_shutdown();
    // check for pending flash_ctrl operations and wait for them to complete
    // TODO
  endtask : dut_shutdown

  // Reset the Flash Device
  virtual task reset_flash();

    // Set all flash partitions to 1s.
    flash_dv_part_e part = part.first();
    do begin
      cfg.flash_mem_bkdr_init(part, flash_init);
      part = part.next();
    end while (part != part.first());
    // Wait for flash_ctrl to finish initializing on every reset
    // We probably need a parameter to skip this for certain tests
    csr_spinwait(.ptr(ral.status.init_wip), .exp_data(1'b0));
  endtask : reset_flash

  // Apply a Reset to the DUT, then do some additional required actions with callback_vseq
  virtual task apply_reset(string kind = "HARD");
    uvm_reg_data_t data;

    bit init_busy;
    super.apply_reset(kind);
    if (kind == "HARD") begin
      cfg.clk_rst_vif.wait_clks(cfg.post_reset_delay_clks);
    end

    if (cfg.seq_cfg.disable_flash_init == 0) begin
      reset_flash();  // Randomly Inititalise Flash After Reset
    end

    if (cfg.seq_cfg.en_init_keys_seeds == 1) begin
      csr_wr(.ptr(ral.init), .value(1));  // Enable Secret Seed Output during INIT
    end

    // Do some additional required actions
    callback_vseq.apply_reset_callback();
  endtask : apply_reset

  // Configure the memory protection regions.
  virtual task flash_ctrl_mp_region_cfg(uint index,
                                        flash_mp_region_cfg_t region_cfg = default_region_cfg);
    uvm_reg_data_t data;
    uvm_reg csr;
    data = get_csr_val_with_updated_field(ral.mp_region_cfg[index].en, data,
                                          region_cfg.en);
    data = data | get_csr_val_with_updated_field(ral.mp_region_cfg[index].rd_en, data,
                                                 region_cfg.read_en);
    data = data | get_csr_val_with_updated_field(ral.mp_region_cfg[index].prog_en, data,
                                                 region_cfg.program_en);
    data = data | get_csr_val_with_updated_field(ral.mp_region_cfg[index].erase_en, data,
                                                 region_cfg.erase_en);
    data = data | get_csr_val_with_updated_field(ral.mp_region_cfg[index].scramble_en,
                                                 data, region_cfg.scramble_en);
    data = data | get_csr_val_with_updated_field(ral.mp_region_cfg[index].ecc_en, data,
                                                 region_cfg.ecc_en);
    data = data | get_csr_val_with_updated_field(ral.mp_region_cfg[index].he_en, data,
                                                 region_cfg.he_en);
    csr_wr(.ptr(ral.mp_region_cfg[index]), .value(data));

    // reset for base/size register
    data = 0;
    data = get_csr_val_with_updated_field(ral.mp_region[index].base, data,
                                          region_cfg.start_page);
    data = data | get_csr_val_with_updated_field(ral.mp_region[index].size, data,
                                                 region_cfg.num_pages);
    csr_wr(.ptr(ral.mp_region[index]), .value(data));
  endtask : flash_ctrl_mp_region_cfg

  // Configure the protection for the "default" region (all pages that do not fall
  // into one of the memory protection regions).
  virtual task flash_ctrl_default_region_cfg(mubi4_t read_en     = MuBi4True,
                                             mubi4_t program_en  = MuBi4True,
                                             mubi4_t erase_en    = MuBi4True,
                                             mubi4_t scramble_en = MuBi4False,
                                             mubi4_t ecc_en      = MuBi4False,
                                             mubi4_t he_en       = MuBi4False);
    uvm_reg_data_t data;

    default_region_cfg.read_en = read_en;
    default_region_cfg.program_en = program_en;
    default_region_cfg.erase_en = erase_en;
    default_region_cfg.scramble_en = scramble_en;
    default_region_cfg.ecc_en = ecc_en;
    default_region_cfg.he_en = he_en;

    data = get_csr_val_with_updated_field(ral.default_region.rd_en, data, read_en);
    data = data |
        get_csr_val_with_updated_field(ral.default_region.prog_en, data, program_en);
    data = data |
        get_csr_val_with_updated_field(ral.default_region.erase_en, data, erase_en);
    data = data |
        get_csr_val_with_updated_field(ral.default_region.scramble_en, data, scramble_en);
    data = data | get_csr_val_with_updated_field(ral.default_region.ecc_en, data, ecc_en);
    data = data | get_csr_val_with_updated_field(ral.default_region.he_en, data, he_en);
    csr_wr(.ptr(ral.default_region), .value(data));
  endtask : flash_ctrl_default_region_cfg

  // Configure the memory protection of some selected page in one of the information partitions in
  //  one of the banks.
  virtual task flash_ctrl_mp_info_page_cfg(
      uint bank, uint info_part, uint page,
      flash_bank_mp_info_page_cfg_t page_cfg = default_info_page_cfg);

    uvm_reg_data_t data;
    uvm_reg csr;

    string csr_name = $sformatf("bank%0d_info%0d_page_cfg", bank, info_part);
    // If the selected information partition has only 1 page, no suffix needed to the register
    //  name, if there is more than one page, the page index should be added to the register name.
    if (flash_ctrl_pkg::InfoTypeSize[info_part] > 1) begin
      csr_name = $sformatf({csr_name, "_%0d"}, page);
    end
    csr = ral.get_reg_by_name(csr_name);
    data = get_csr_val_with_updated_field(csr.get_field_by_name("en"), data, page_cfg.en);
    data = data |
        get_csr_val_with_updated_field(csr.get_field_by_name("rd_en"), data, page_cfg.read_en);
    data = data |
        get_csr_val_with_updated_field(csr.get_field_by_name("prog_en"), data, page_cfg.program_en);
    data = data |
        get_csr_val_with_updated_field(csr.get_field_by_name("erase_en"), data, page_cfg.erase_en);
    data = data | get_csr_val_with_updated_field(csr.get_field_by_name("scramble_en"), data,
                                                 page_cfg.scramble_en);
    data = data |
        get_csr_val_with_updated_field(csr.get_field_by_name("ecc_en"), data, page_cfg.ecc_en);
    data = data |
        get_csr_val_with_updated_field(csr.get_field_by_name("he_en"), data, page_cfg.he_en);
    csr_wr(.ptr(csr), .value(data));
  endtask : flash_ctrl_mp_info_page_cfg

  // Configure bank erasability.
  virtual task flash_ctrl_bank_erase_cfg(bit [flash_ctrl_pkg::NumBanks-1:0] bank_erase_en);
    csr_wr(.ptr(ral.mp_bank_cfg_shadowed[0]), .value(bank_erase_en));
  endtask : flash_ctrl_bank_erase_cfg

  // Configure read and program fifo levels for interrupt.
  virtual task flash_ctrl_fifo_levels_cfg_intr(uint read_fifo_intr_level,
                                               uint program_fifo_intr_level);
    uvm_reg_data_t data;
    data = get_csr_val_with_updated_field(ral.fifo_lvl.prog, data, program_fifo_intr_level) |
        get_csr_val_with_updated_field(ral.fifo_lvl.rd, data, read_fifo_intr_level);
    csr_wr(.ptr(ral.fifo_lvl), .value(data));
  endtask : flash_ctrl_fifo_levels_cfg_intr

  // Reset the program and read fifos.
  virtual task flash_ctrl_fifo_reset(bit reset = 1'b1);
    csr_wr(.ptr(ral.fifo_rst), .value(reset));
  endtask : flash_ctrl_fifo_reset

  // Wait for flash_ctrl op to finish.
  virtual task wait_flash_op_done(
      bit clear_op_status = 1'b1, time timeout_ns = 10_000_000
  );  // Added because mass(bank) erase is longer then default timeout.
    uvm_reg_data_t data;
    bit done;
    `DV_SPINWAIT(do begin
        csr_rd(.ptr(ral.op_status), .value(data));
        done = get_field_val(ral.op_status.done, data);
      end while (done == 1'b0);, "wait_flash_op_done timeout occurred!", timeout_ns)
    if (clear_op_status) begin
      data = get_csr_val_with_updated_field(ral.op_status.done, data, 0);
      csr_wr(.ptr(ral.op_status), .value(data));
    end
  endtask : wait_flash_op_done

  // Wait for flash_ctrl op to finish with error.
  virtual task wait_flash_op_err(bit clear_op_status = 1'b1);
    uvm_reg_data_t data;
    bit err;
    `DV_SPINWAIT(do begin
        csr_rd(.ptr(ral.op_status), .value(data));
        err = get_field_val(ral.op_status.err, data);
      end while (err == 1'b0);, "wait_flash_op_err timeout occurred!")
    if (clear_op_status) begin
      data = get_csr_val_with_updated_field(ral.op_status.err, data, 0);
      csr_wr(.ptr(ral.op_status), .value(data));
    end
  endtask : wait_flash_op_err

  // Wait for prog fifo to not be full.
  virtual task wait_flash_ctrl_prog_fifo_not_full();
    // TODO: if intr enabled, then check interrupt, else check status.
    bit prog_full;
    `DV_SPINWAIT(do begin
        csr_rd(.ptr(ral.status.prog_full), .value(prog_full));
      end while (prog_full);, "wait_flash_ctrl_prog_fifo_not_full timeout occurred!")
  endtask : wait_flash_ctrl_prog_fifo_not_full

  // Wait for rd fifo to not be empty.
  virtual task wait_flash_ctrl_rd_fifo_not_empty();
    // TODO: if intr enabled, then check interrupt, else check status.
    bit read_empty;
    `DV_SPINWAIT(do begin
        csr_rd(.ptr(ral.status.rd_empty), .value(read_empty));
      end while (read_empty);, "wait_flash_ctrl_rd_fifo_not_empty timeout occurred!")
  endtask : wait_flash_ctrl_rd_fifo_not_empty

  // Starts an Operation on the Flash Controller
  virtual task flash_ctrl_start_op(flash_op_t flash_op);
    uvm_reg_data_t data;
    flash_part_e partition_sel;
    bit [InfoTypesWidth-1:0] info_sel;

    csr_wr(.ptr(ral.addr), .value(flash_op.addr));

    //    flash_op.partition     -> partition_sel  ,    info_sel         |
    //     (flash_dv_part_e)     | (flash_part_e)  | bit[InfoTypesWidth] |
    // --------------------------|-----------------|---------------------|
    //  FlashPartData        = 0 | FlashPartData=0 |         0           |
    //  FlashPartInfo        = 1 | FlashPartInfo=1 |         0           |
    //  FlashPartInfo1       = 2 | FlashPartInfo=1 |         1           |
    //  FlashPartInfo2       = 4 | FlashPartInfo=1 |         2           |

    partition_sel = |flash_op.partition;
    info_sel = flash_op.partition >> 1;
    data = get_csr_val_with_updated_field(ral.control.start, data, 1'b1);
    data = data | get_csr_val_with_updated_field(ral.control.op, data, flash_op.op);
    data = data | get_csr_val_with_updated_field(ral.control.prog_sel, data, flash_op.prog_sel);
    data = data | get_csr_val_with_updated_field(ral.control.erase_sel, data, flash_op.erase_type);
    data = data | get_csr_val_with_updated_field(ral.control.partition_sel, data, partition_sel);
    data = data | get_csr_val_with_updated_field(ral.control.info_sel, data, info_sel);
    data = data | get_csr_val_with_updated_field(ral.control.num, data, flash_op.num_words - 1);
    csr_wr(.ptr(ral.control), .value(data));
  endtask : flash_ctrl_start_op

  // Program data into flash, stopping whenever full.
  // The flash op is assumed to have already commenced.
  virtual task flash_ctrl_write(data_q_t data, bit poll_fifo_status);
    foreach (data[i]) begin
      // Check if prog fifo is full. If yes, then wait for space to become available.
      // Note that this polling is not needed since the interface is backpressure enabled.
      if (poll_fifo_status) begin
        wait_flash_ctrl_prog_fifo_not_full();
      end
      mem_wr(.ptr(ral.prog_fifo), .offset(0), .data(data[i]));
      `uvm_info(`gfn, $sformatf("flash_ctrl_write: 0x%0h", data[i]), UVM_HIGH)
    end
  endtask : flash_ctrl_write

  // Read data from flash, stopping whenever empty.
  // The flash op is assumed to have already commenced.
  virtual task flash_ctrl_read(uint num_words, ref data_q_t data, bit poll_fifo_status);
    for (int i = 0; i < num_words; i++) begin
      // Check if rd fifo is empty. If yes, then wait for data to become available.
      // Note that this polling is not needed since the interface is backpressure enabled.
      if (poll_fifo_status) begin
        wait_flash_ctrl_rd_fifo_not_empty();
      end
      mem_rd(.ptr(ral.rd_fifo), .offset(0), .data(data[i]));
      `uvm_info(`gfn, $sformatf("flash_ctrl_read: 0x%0h", data[i]), UVM_HIGH)
    end
  endtask : flash_ctrl_read

  // Task to perform a direct Flash read at the specified location
  // Used timeout is to match the longest waiting timeout possible for the host, which will happen
  //  when the host is waiting for the controller to finish bank-erase
  virtual task do_direct_read(
      input     addr_t addr, input bit [TL_DBW-1:0] mask = get_rand_contiguous_mask(),
      input bit blocking = $urandom_range(0, 1), input bit check_rdata = 0,
      input     data_t exp_rdata = '0, input mubi4_t instr_type = MuBi4False,
      output    data_4s_t rdata, output bit completed,
      input bit exp_err_rsp = 1'b0, input bit use_rsp_ff = 1'b0);

    bit         saw_err;

    tl_access_w_abort(.addr(addr), .write(1'b0), .completed(completed), .saw_err(saw_err),
                      .tl_access_timeout_ns(cfg.seq_cfg.erase_timeout_ns), .mask(mask),
                      .data(rdata), .exp_err_rsp(exp_err_rsp), .exp_data(exp_rdata),
                      .compare_mask(mask), .check_exp_data(check_rdata), .blocking(blocking),
                      .instr_type(instr_type),
                      .tl_sequencer_h(p_sequencer.tl_sequencer_hs[cfg.flash_ral_name]));
//confider override
//                      .use_rsp_ff(use_rsp_ff));
  endtask : do_direct_read

  // Task to Read/Erase/Program the Two Secret Seed Partitions (Creator and Owner)
  virtual task do_flash_op_secret_part(input flash_sec_part_e secret_part, input flash_op_e op,
                                       output data_q_t flash_op_data);

    // Note:
    // Secret partition 0 (used for creator): Bank 0, information partition 0, page 1
    // Secret partition 1 (used for owner):   Bank 0, information partition 0, page 2

    // Local Signals
    bit               poll_fifo_status;
    data_q_t          exp_data;
    flash_op_t        flash_op;

    // Flash Operation Assignments
    flash_op.op                         = op;
    flash_op.partition                  = FlashPartInfo;
    flash_op.erase_type                 = FlashErasePage;
    flash_op.num_words                  = FlashSecretPartWords;
    poll_fifo_status                    = 1;

    // Disable HW Access to Secret Partition from Life Cycle Controller Interface (Write/Read/Erase)
    cfg.flash_ctrl_vif.lc_seed_hw_rd_en = lc_ctrl_pkg::Off;  // Disable Secret Partition HW Access

    unique case (secret_part)
      FlashCreatorPart: begin
        flash_op.addr = FlashCreatorPartStartAddr;
        cfg.flash_ctrl_vif.lc_creator_seed_sw_rw_en = lc_ctrl_pkg::On;
      end
      FlashOwnerPart: begin
        flash_op.addr = FlashOwnerPartStartAddr;
        cfg.flash_ctrl_vif.lc_owner_seed_sw_rw_en = lc_ctrl_pkg::On;
      end
      default: `uvm_error(`gfn, "Secret Partition Unrecognised, FAIL")
    endcase

    // Perform Flash Opeation via Host Interface
    unique case (flash_op.op)
      flash_ctrl_pkg::FlashOpErase: begin
        flash_ctrl_start_op(flash_op);
        wait_flash_op_done(.timeout_ns(cfg.seq_cfg.erase_timeout_ns));
        if (cfg.seq_cfg.check_mem_post_tran) cfg.flash_mem_bkdr_erase_check(flash_op, exp_data);
      end
      flash_ctrl_pkg::FlashOpProgram: begin
        // Write Frontdoor, Read Backdoor
        // Generate Random Key
        for (int i = 0; i < flash_op.num_words; i++) begin
          flash_op_data[i] = $urandom_range(0, 2 ** (TL_DW) - 1);
        end
        // Calculate expected data for post-transaction checks
        exp_data = cfg.calculate_expected_data(flash_op, flash_op_data);
        flash_ctrl_start_op(flash_op);
        flash_ctrl_write(flash_op_data, poll_fifo_status);
        wait_flash_op_done(.timeout_ns(cfg.seq_cfg.prog_timeout_ns));
        if (cfg.seq_cfg.check_mem_post_tran) cfg.flash_mem_bkdr_read_check(flash_op, exp_data);
      end
      flash_ctrl_pkg::FlashOpRead: begin
        // Read Frontdoor, Compare Backdoor
        flash_ctrl_start_op(flash_op);
        flash_ctrl_read(flash_op.num_words, flash_op_data, poll_fifo_status);
        wait_flash_op_done();
        if (cfg.seq_cfg.check_mem_post_tran) cfg.flash_mem_bkdr_read_check(flash_op, flash_op_data);
      end
      default: `uvm_error(`gfn, "Flash Operation Unrecognised, FAIL")
    endcase

    // Disable Secret Partitions from Life Cycle Controller Interface (Write/Read/Erase)
    unique case (secret_part)
      FlashCreatorPart: begin
        cfg.flash_ctrl_vif.lc_creator_seed_sw_rw_en = lc_ctrl_pkg::Off;
      end
      FlashOwnerPart: begin
        cfg.flash_ctrl_vif.lc_owner_seed_sw_rw_en = lc_ctrl_pkg::Off;
      end
      default: `uvm_error(`gfn, "Secret Partition Unrecognised, FAIL")
    endcase

  endtask : do_flash_op_secret_part

  // Task to compare a Secret Seed sent to the Key Manager with the Value in the FLASH
  virtual task compare_secret_seed(input flash_sec_part_e secret_part,
                                   input data_q_t flash_op_data);

    // Local Variables
    data_q_t key_data;

    // Check for the Key being 'x
    foreach (cfg.flash_ctrl_vif.keymgr.seeds[bit'(secret_part)][i]) begin
      if (cfg.flash_ctrl_vif.keymgr.seeds[bit'(secret_part)][i] === 'x) begin
        `uvm_error(`gfn, "Key Manager Keys Sampled : 'x', FAIL")
      end
    end

    // Read Key Manager Interface
    foreach (flash_op_data[i]) begin
      key_data[i] = cfg.flash_ctrl_vif.keymgr.seeds[bit'(secret_part)][i*32+:32];
    end

    // Display Keys
    `uvm_info(`gfn, $sformatf("Secret Partition : %s", secret_part.name()), UVM_LOW)
    `uvm_info(`gfn, $sformatf("Data   Read      : %p", flash_op_data), UVM_LOW)
    `uvm_info(`gfn, $sformatf("KeyMgr Read      : %p", key_data), UVM_LOW)

    // Compare Seeds
    foreach (key_data[i]) begin
      `DV_CHECK_EQ(key_data[i], flash_op_data[i], $sformatf(
                   "(Read) Secret Partition : %s : Keys Mismatch, FAIL", secret_part.name()))
    end

  endtask : compare_secret_seed

  // Task to restore the stimulus from the Life Cycle Controller to its Reset State
  virtual task lc_ctrl_if_rst();

    cfg.flash_ctrl_vif.lc_creator_seed_sw_rw_en = lc_ctrl_pkg::Off;
    cfg.flash_ctrl_vif.lc_owner_seed_sw_rw_en   = lc_ctrl_pkg::Off;
    cfg.flash_ctrl_vif.lc_seed_hw_rd_en         = lc_ctrl_pkg::On;

    cfg.flash_ctrl_vif.lc_iso_part_sw_rd_en     = lc_ctrl_pkg::Off;
    cfg.flash_ctrl_vif.lc_iso_part_sw_wr_en     = lc_ctrl_pkg::Off;

    cfg.flash_ctrl_vif.lc_nvm_debug_en          = lc_ctrl_pkg::Off;
    cfg.flash_ctrl_vif.lc_escalate_en           = lc_ctrl_pkg::Off;

    cfg.flash_ctrl_vif.rma_req                  = lc_ctrl_pkg::Off;
    cfg.flash_ctrl_vif.rma_seed                 = '0;

  endtask : lc_ctrl_if_rst

  // Simple Model For The OTP Key Seeds
  virtual task otp_model();

    `uvm_info(`gfn, "Starting OTP Model ...", UVM_LOW)

    // Initial Values
    cfg.flash_ctrl_vif.otp_rsp.addr_ack   = 1'b0;
    cfg.flash_ctrl_vif.otp_rsp.data_ack   = 1'b0;
    cfg.flash_ctrl_vif.otp_rsp.seed_valid = 1'b0;
    cfg.flash_ctrl_vif.otp_rsp.key        = '0;
    cfg.flash_ctrl_vif.otp_rsp.rand_key   = '0;
    otp_key_init_done = 'h0;
    // Note 'some values' appear in both branches of this fork, this is OK because the
    // branches never run together by design.
    // The order is always 'addr' followed by 'data'.

    fork
      forever begin  // addr
        @(posedge cfg.clk_rst_vif.rst_n);
        @(posedge cfg.flash_ctrl_vif.otp_req.addr_req);
        otp_addr_key = {$urandom, $urandom, $urandom, $urandom};
        otp_addr_rand_key = {$urandom, $urandom, $urandom, $urandom};
        otp_key_init_done[1] = 0;
        `uvm_info(`gfn, $sformatf("OTP Addr Key Applied to DUT : otp_addr_key : %0x",
          otp_addr_key), UVM_MEDIUM)
        `uvm_info(`gfn, $sformatf("OTP Addr Rand Key Applied to DUT : otp_addr_rand_key : %0x",
          otp_addr_rand_key), UVM_MEDIUM)
        cfg.flash_ctrl_vif.otp_rsp.key = otp_addr_key;
        cfg.flash_ctrl_vif.otp_rsp.rand_key = otp_addr_rand_key;
        cfg.flash_ctrl_vif.otp_rsp.seed_valid = 1'b1;
        #1ns;  // Positive Hold
        cfg.flash_ctrl_vif.otp_rsp.addr_ack = 1'b1;
        @(negedge cfg.flash_ctrl_vif.otp_req.addr_req);
        #1ns;  // Positive Hold
        cfg.flash_ctrl_vif.otp_rsp.addr_ack = 1'b0;
        cfg.flash_ctrl_vif.otp_rsp.seed_valid = 1'b0;
        otp_key_init_done[1] = 1;
      end
      forever begin  // data
        @(posedge cfg.clk_rst_vif.rst_n);
        @(posedge cfg.flash_ctrl_vif.otp_req.data_req);
        otp_data_key = {$urandom, $urandom, $urandom, $urandom};
        otp_data_rand_key = {$urandom, $urandom, $urandom, $urandom};
        otp_key_init_done[0] = 0;
        cfg.flash_ctrl_vif.otp_rsp.key = otp_data_key;
        cfg.flash_ctrl_vif.otp_rsp.rand_key = otp_data_rand_key;
        `uvm_info(`gfn, $sformatf("OTP Data Key Applied to DUT : otp_data_key : %0x",
          otp_data_key), UVM_MEDIUM)
        `uvm_info(`gfn, $sformatf("OTP Data Rand Key Applied to DUT : otp_data_rand_key : %0x",
          otp_data_rand_key), UVM_MEDIUM)
        cfg.flash_ctrl_vif.otp_rsp.seed_valid = 1'b1;
        #1ns;  // Positive Hold
        cfg.flash_ctrl_vif.otp_rsp.data_ack = 1'b1;
        @(negedge cfg.flash_ctrl_vif.otp_req.data_req);
        #1ns;  // Positive Hold
        cfg.flash_ctrl_vif.otp_rsp.data_ack = 1'b0;
        cfg.flash_ctrl_vif.otp_rsp.seed_valid = 1'b0;
        otp_key_init_done[0] = 1;
      end
    join_none

  endtask : otp_model

  // Compares Two Queues Of Data
  virtual function void check_data_match(ref data_q_t data, ref data_q_t exp_data);
    foreach (exp_data[i]) begin
      `DV_CHECK_EQ(data[i], exp_data[i], $sformatf(
                   "Expected : 0x%0x, Read : 0x%0x, FAIL", exp_data[i], data[i]))
    end
  endfunction : check_data_match

  // Wait for Flash Operation, or Timeout ... Timeout Expected
  virtual task wait_flash_op_done_expect_timeout(input time timeout_ns = 10_000_000,
                                                 output bit result);

    // Looks for Status Returning in the Timeout Period

    // Expect a Timeout, with No Status Returned
    // Result 0 - Response Returned (timeout = 0, status = 1) - FAIL
    //        1 - Timeout, No Response Returned (timeout = 1, status = 0) - PASS

    // Local Variables
    uvm_reg_data_t data;
    bit timeout;
    bit status;
    bit finished;

    finished = 0;
    timeout  = 0;
    fork
      fork

        begin  // Poll Status Bit
          `uvm_info(`gfn, "Polling Flash Status ...", UVM_LOW)
          while (finished == 0) begin
            csr_rd(.ptr(ral.op_status), .value(data));
            status = get_field_val(ral.op_status.done, data);
            if (status == 1) finished = 1;
          end
        end

        begin  // Timeout - Expected
          #(timeout_ns);
          `uvm_info(`gfn, "Exiting Timeout Check ... Timeout Occured, Expected", UVM_LOW)
          timeout  = 1;
          finished = 1;
        end

      join
    join
    // Exit Gracefully

    // Decide Result
    if ((timeout == 1'b1) && (status == 1'b0)) result = 1'b1;
    else result = 1'b0;

  endtask : wait_flash_op_done_expect_timeout

  // Task to Read/Erase/Program the RMA Partitions Creator, Owner, Isolated, Data0 and Data1
  virtual task do_flash_op_rma(input flash_sec_part_e part, input flash_op_e op,
                               ref data_q_t flash_op_wdata, input bit cmp = READ_CHECK_NORM,
                               input uint data_part_addr, input uint data_part_num_words);

    // Note:
    // Special Partition (used for Creator)  : Bank 0, Information Partition 0, Page 1
    // Special Partition (used for Owner)    : Bank 0, Information Partition 0, Page 2
    // Special Partition (used for Isolated) : Bank 0, Information Partition 0, Page 3

    // Local Variables
    bit               poll_fifo_status;
    data_q_t          exp_data;
    flash_op_t        flash_op;
    data_q_t          flash_op_rdata;
    int               match_cnt;
    string            msg;

    // Assign
    flash_op.op = op;
    poll_fifo_status = 1;

    `uvm_info(`gfn, $sformatf("Operation : %s, Partition : %s ", op.name(), part.name()),
              UVM_MEDIUM)

    // Disable HW Access to Secret Partition from Life Cycle Controller Interface (Write/Read/Erase)
    cfg.flash_ctrl_vif.lc_seed_hw_rd_en = lc_ctrl_pkg::Off;  // Disable Secret Partition HW Access

    // Select Options
    unique case (part)
      FlashCreatorPart: begin
        flash_op.addr                               = FlashCreatorPartStartAddr;  // Fixed Val
        flash_op.num_words                          = FullPageNumWords;  // Fixed Val
        flash_op.partition                          = FlashPartInfo;
        cfg.flash_ctrl_vif.lc_creator_seed_sw_rw_en = lc_ctrl_pkg::On;
      end
      FlashOwnerPart: begin
        flash_op.addr                             = FlashOwnerPartStartAddr;  // Fixed Val
        flash_op.num_words                        = FullPageNumWords;  // Fixed Val
        flash_op.partition                        = FlashPartInfo;
        cfg.flash_ctrl_vif.lc_owner_seed_sw_rw_en = lc_ctrl_pkg::On;
      end
      FlashIsolPart: begin
        flash_op.addr                           = FlashIsolPartStartAddr;  // Fixed Val
        flash_op.num_words                      = FullPageNumWords;  // Fixed Val
        flash_op.partition                      = FlashPartInfo;
        cfg.flash_ctrl_vif.lc_iso_part_sw_rd_en = lc_ctrl_pkg::On;
        cfg.flash_ctrl_vif.lc_iso_part_sw_wr_en = lc_ctrl_pkg::On;
      end
      FlashData0Part, FlashData1Part: begin
        flash_op.addr      = data_part_addr;  // Variable Val
        flash_op.num_words = data_part_num_words;  // Fixed Val
        flash_op.partition = FlashPartData;
      end
      default: `uvm_error(`gfn, "Unrecognised Partiton, FAIL")
    endcase

    // Perform Flash Operations via the Host Interface
    case (flash_op.op)

      flash_ctrl_pkg::FlashOpErase: begin
        if (part inside {FlashCreatorPart, FlashOwnerPart, FlashIsolPart})
          flash_op.erase_type = flash_ctrl_pkg::FlashErasePage;
        else flash_op.erase_type = flash_ctrl_pkg::FlashEraseBank;
        flash_ctrl_start_op(flash_op);
        wait_flash_op_done(.timeout_ns(cfg.seq_cfg.erase_timeout_ns));
        if (cfg.seq_cfg.check_mem_post_tran) cfg.flash_mem_bkdr_erase_check(flash_op, exp_data);
      end

      flash_ctrl_pkg::FlashOpProgram: begin
        // Write Frontdoor, Read/Compare Backdoor
        // Random Data
        for (int i = 0; i < flash_op.num_words; i++)
          flash_op_wdata[i] = $urandom_range(0, 2 ** (TL_DW) - 1);
        flash_ctrl_write_extra(flash_op, flash_op_wdata);
      end

      flash_ctrl_pkg::FlashOpRead: begin
        flash_ctrl_read_extra(flash_op, flash_op_rdata);
        // Compare
        if (cfg.seq_cfg.check_mem_post_tran) begin

          if (cmp == 0) begin
            `uvm_info(`gfn, "Read : Compare Backdoor with Frontdoor", UVM_MEDIUM)
            cfg.flash_mem_bkdr_read_check(flash_op,
                                          flash_op_rdata);  // Compare Backdoor with Frontdoor
          end else begin
            `uvm_info(`gfn, "Read : Compare Backdoor with Erased Status", UVM_MEDIUM)
            match_cnt = 0;
            foreach (flash_op_rdata[i]) begin
              if (flash_op_rdata[i] === '1) begin
                // Data Match - Unexpected, but theoretically possible
                // Theoretically if locations are all '1 then
                // RMA Erase Worked but RMA Program did not
                `uvm_info(`gfn, "Read : Data Match (Erased), UNEXPECTED", UVM_MEDIUM)
                match_cnt++;
              end
            end

            // Decide Pass/Fail Based on Match Count
            if (match_cnt > 1)
              `uvm_error(`gfn, {"Read : Data Matches Seen (Erase), UNEXPECTED",
                $sformatf("Flash Content Should Be Random (RMA Wipe) (Matches : %0d)", match_cnt)})

            `uvm_info(`gfn, "Read : Compare Backdoor with Data Previously Written", UVM_MEDIUM)
            match_cnt = 0;
            foreach (flash_op_rdata[i]) begin
              if (flash_op_rdata[i] === flash_op_wdata[i]) begin
                // Data Match - Unlikely, but theoretically possible
                `uvm_info(`gfn, "Read :  Data Match, UNEXPECTED", UVM_MEDIUM)
                match_cnt++;
              end
            end
            // Decide Pass/Fail Based on Match Count
            if (match_cnt > 1)
              `uvm_error(`gfn, {
                         "Read : Data Matches Seen, UNEXPECTED, Flash Content Should Be ",
                         $sformatf("Random (RMA Wipe) (Matches : %0d)", match_cnt)})
          end
        end
      end
      default: `uvm_error(`gfn, "Unrecognised Partiton, FAIL")
    endcase

    // Deselect Life Cycle Controller HW Options
    unique case (part)
      FlashCreatorPart: begin
        cfg.flash_ctrl_vif.lc_creator_seed_sw_rw_en = lc_ctrl_pkg::Off;
      end
      FlashOwnerPart: begin
        cfg.flash_ctrl_vif.lc_owner_seed_sw_rw_en = lc_ctrl_pkg::Off;
      end
      FlashIsolPart: begin
        cfg.flash_ctrl_vif.lc_iso_part_sw_rd_en = lc_ctrl_pkg::Off;
        cfg.flash_ctrl_vif.lc_iso_part_sw_wr_en = lc_ctrl_pkg::Off;
      end
      FlashData0Part, FlashData1Part: ;  // No Operation
      default: `uvm_error(`gfn, "Unrecognised Partiton, FAIL")
    endcase

  endtask : do_flash_op_rma

  // Task to Program the Entire Flash Memory
  virtual task flash_ctrl_write_extra(flash_op_t flash_op, data_q_t data);

    // Local Signals
    uvm_reg_data_t           reg_data;
    flash_part_e             partition_sel;
    bit [InfoTypesWidth-1:0] info_sel;
    int                      num;
    int                      num_full;
    int                      num_part;
    data_4s_t                fifo_data;
    addr_t                   flash_addr;
    data_q_t                 exp_data;
    flash_op_t               flash_op_copy;
    data_q_t                 data_copy;

    // Calculate Number of Complete Cycles and Partial Cycle Words
    num           = data.size();
    num_full      = num / FIFO_DEPTH;
    num_part      = num % FIFO_DEPTH;

    // Other
    partition_sel = |flash_op.partition;
    info_sel      = flash_op.partition >> 1;
    flash_addr    = flash_op.addr;

    `uvm_info(`gfn, $sformatf(
              "Flash Write Summary : Words : %0d, Full Cycles : %0d, Partial Cycle Words : %0d",
              num,
              num_full,
              num_part
              ), UVM_LOW)

    // Copies
    flash_op_copy = flash_op;
    data_copy     = data;

    // If num_full > 0
    for (int cycle = 0; cycle < num_full; cycle++) begin

      `uvm_info(`gfn, $sformatf("Write Cycle : %0d, flash_addr = 0x%0x", cycle, flash_addr),
                UVM_MEDIUM)

      csr_wr(.ptr(ral.addr), .value(flash_addr));

      reg_data = '0;
      reg_data = get_csr_val_with_updated_field(ral.control.start, reg_data, 1'b1) |
          get_csr_val_with_updated_field(ral.control.op, reg_data, flash_op.op) |
          get_csr_val_with_updated_field(ral.control.erase_sel, reg_data, flash_op.erase_type) |
          get_csr_val_with_updated_field(ral.control.partition_sel, reg_data, partition_sel) |
          get_csr_val_with_updated_field(ral.control.info_sel, reg_data, info_sel) |
          get_csr_val_with_updated_field(ral.control.num, reg_data, FIFO_DEPTH - 1);
      csr_wr(.ptr(ral.control), .value(reg_data));

      for (int i = 0; i < FIFO_DEPTH; i++) begin
        fifo_data = data.pop_front();
        mem_wr(.ptr(ral.prog_fifo), .offset(0), .data(fifo_data));
      end
      wait_flash_op_done(.timeout_ns(cfg.seq_cfg.prog_timeout_ns));

      flash_addr += FIFO_DEPTH * 4;

    end

    // If there is a partial cycle
    if (num_part > 0) begin
      if (num_full == 0) flash_addr = flash_op.addr;
      `uvm_info(`gfn, $sformatf("Last Write : flash_addr = 0x%0x", flash_addr), UVM_MEDIUM)

      csr_wr(.ptr(ral.addr), .value(flash_addr));

      reg_data = '0;
      reg_data = get_csr_val_with_updated_field(ral.control.start, reg_data, 1'b1) |
          get_csr_val_with_updated_field(ral.control.op, reg_data, flash_op.op) |
          get_csr_val_with_updated_field(ral.control.erase_sel, reg_data, flash_op.erase_type) |
          get_csr_val_with_updated_field(ral.control.partition_sel, reg_data, partition_sel) |
          get_csr_val_with_updated_field(ral.control.info_sel, reg_data, info_sel) |
          get_csr_val_with_updated_field(ral.control.num, reg_data, num_part - 1);
      csr_wr(.ptr(ral.control), .value(reg_data));
      for (int i = 0; i < num_part; i++) begin
        fifo_data = data.pop_front();
        mem_wr(.ptr(ral.prog_fifo), .offset(0), .data(fifo_data));
      end
      wait_flash_op_done(.timeout_ns(cfg.seq_cfg.prog_timeout_ns));

    end

    exp_data = cfg.calculate_expected_data(flash_op_copy, data_copy);

    if (cfg.seq_cfg.check_mem_post_tran) cfg.flash_mem_bkdr_read_check(flash_op_copy, exp_data);

  endtask : flash_ctrl_write_extra

  // Task to Program the Entire Flash Memory
  virtual task flash_ctrl_read_extra(flash_op_t flash_op, ref data_q_t data);

    // Local Signals
    uvm_reg_data_t           reg_data;
    flash_part_e             partition_sel;
    bit [InfoTypesWidth-1:0] info_sel;
    logic [TL_AW:0]          flash_addr;
    int                      num;
    int                      num_full;
    int                      num_part;
    int                      num_words;
    int                      idx;

    // Calculate Number of Complete Cycles and Partial Cycle Words
    num      = flash_op.num_words;
    num_full = num / FIFO_DEPTH;
    num_part = num % FIFO_DEPTH;

    `uvm_info(`gfn, $sformatf(
              "Flash Read Summary : Words : %0d, Full Cycles : %0d, Partial Cycle Words : %0d",
              num,
              num_full,
              num_part
              ), UVM_LOW)

    // Other
    partition_sel = |flash_op.partition;
    info_sel      = flash_op.partition >> 1;
    num_words     = flash_op.num_words;
    flash_addr    = flash_op.addr;

    // If num_full > 0
    idx           = 0;
    for (int cycle = 0; cycle < num_full; cycle++) begin

      `uvm_info(`gfn, $sformatf("Read Cycle : %0d, flash_addr = 0x%0x", cycle, flash_addr),
                UVM_MEDIUM)

      csr_wr(.ptr(ral.addr), .value(flash_addr));  // Write Address

      reg_data = '0;
      reg_data = get_csr_val_with_updated_field(ral.control.start, reg_data, 1'b1) |
          get_csr_val_with_updated_field(ral.control.op, reg_data, flash_op.op) |
          get_csr_val_with_updated_field(ral.control.erase_sel, reg_data, flash_op.erase_type) |
          get_csr_val_with_updated_field(ral.control.partition_sel, reg_data, partition_sel) |
          get_csr_val_with_updated_field(ral.control.info_sel, reg_data, info_sel) |
          get_csr_val_with_updated_field(ral.control.num, reg_data, FIFO_DEPTH - 1);
      csr_wr(.ptr(ral.control), .value(reg_data));

      wait_flash_op_done(.timeout_ns(cfg.seq_cfg.prog_timeout_ns));

      // Read from FIFO
      for (int i = 0; i < FIFO_DEPTH; i++) begin
        mem_rd(.ptr(ral.rd_fifo), .offset(0), .data(data[idx++]));
      end

      flash_addr += FIFO_DEPTH * 4;

    end

    // If there is a partial Cycle
    if (num_part > 0) begin
      if (num_full == 0) flash_addr = flash_op.addr;
      `uvm_info(`gfn, $sformatf("Last Read Cycle : flash_addr = 0x%0x", flash_addr), UVM_MEDIUM)

      csr_wr(.ptr(ral.addr), .value(flash_addr));  // Write Address

      reg_data = '0;
      reg_data = get_csr_val_with_updated_field(ral.control.start, reg_data, 1'b1) |
          get_csr_val_with_updated_field(ral.control.op, reg_data, flash_op.op) |
          get_csr_val_with_updated_field(ral.control.erase_sel, reg_data, flash_op.erase_type) |
          get_csr_val_with_updated_field(ral.control.partition_sel, reg_data, partition_sel) |
          get_csr_val_with_updated_field(ral.control.info_sel, reg_data, info_sel) |
          get_csr_val_with_updated_field(ral.control.num, reg_data, FIFO_DEPTH - 1);
      csr_wr(.ptr(ral.control), .value(reg_data));

      wait_flash_op_done(.timeout_ns(cfg.seq_cfg.prog_timeout_ns));

      // Read from FIFO
      for (int i = 0; i < FIFO_DEPTH; i++) begin
        mem_rd(.ptr(ral.rd_fifo), .offset(0), .data(data[idx++]));
      end

    end

  endtask : flash_ctrl_read_extra

  // Task to send an RMA Request (with a given seed) to the Flash Controller
  virtual task send_rma_req(lc_flash_rma_seed_t rma_seed = LC_FLASH_RMA_SEED_DEFAULT);

    // Local Variables
    lc_ctrl_pkg::lc_tx_t done;
    time timeout = 15s;
    time start_time;
    bit  rma_ack_seen;

    `uvm_info(`gfn, $sformatf("RMA Seed : 0x%08x", rma_seed), UVM_LOW)

    // Set Seed and Send Req
    @(posedge cfg.clk_rst_vif.clk);
    cfg.flash_ctrl_vif.rma_seed = rma_seed;
    cfg.flash_ctrl_vif.rma_req = lc_ctrl_pkg::On;

    // RMA Start Time
    start_time = $time();

    // Wait for RMA Ack to Rise (NOTE LONG DURATION)
    `uvm_info(`gfn, "Waiting for RMA to complete ... ", UVM_LOW)

    done = 0;
    rma_ack_seen = 0;
    fork
      begin
        fork
          begin  // Poll RMA ACK
            do begin
              `uvm_info(`gfn, "Polling RMA ACK ...", UVM_LOW)
              #10ms;  // Jump Ahead (Not Sampling Clocks)
              @(posedge cfg.clk_rst_vif.clk);  // Align to Clock
              if (cfg.flash_ctrl_vif.rma_ack == lc_ctrl_pkg::On) done = 1;
            end while (done == 0);
          end
          begin  // Timeout - Unexpected
            `uvm_info(`gfn, "Starting RMA Timeout Check ...", UVM_LOW)
            #(timeout);
            `uvm_error(`gfn, {
                       "RMA ACK NOT seen within the expected time frame, Timeout - FAIL",
                       $sformatf(" (%0t)", timeout)})
          end
        join_any
        disable fork;
      end
    join

    // Note: After a valid RMA Ack is sent, the RMA State Machine remains in its last state,
    //       until reset

    // RMA End Time
    `uvm_info(`gfn, "RMA complete", UVM_LOW)
    `uvm_info(`gfn, $sformatf("RMA Duration : %t", $time() - start_time), UVM_LOW);

  endtask : send_rma_req

  // Task to Enable/Disable the 'Info' Partitions, Creator, Owner and Isolated, via the Lifetime
  // Controller Interface
  virtual task en_sw_rw_part_info(input flash_op_t flash_op, input lc_ctrl_pkg::lc_tx_t val);
    if (flash_op.partition == FlashPartInfo) begin
      cfg.flash_ctrl_vif.lc_creator_seed_sw_rw_en = val;
      cfg.flash_ctrl_vif.lc_owner_seed_sw_rw_en   = val;
      cfg.flash_ctrl_vif.lc_iso_part_sw_rd_en     = val;
      cfg.flash_ctrl_vif.lc_iso_part_sw_wr_en     = val;
    end
  endtask : en_sw_rw_part_info

  // Controller read page.
  virtual task controller_read_page(flash_op_t flash_op_r);
    data_q_t flash_read_data;
    bit poll_fifo_status = 1;
    flash_op_r.op = flash_ctrl_pkg::FlashOpRead;
    flash_op_r.num_words = 16;
    flash_op_r.addr = {flash_op_r.addr[19:11], {11{1'b0}}};
    for (int i = 0; i < 32; i++) begin
      flash_ctrl_start_op(flash_op_r);
      flash_ctrl_read(flash_op_r.num_words, flash_read_data, poll_fifo_status);
      wait_flash_op_done();
      flash_op_r.addr = flash_op_r.addr + 64;  //64B was read, 16 words
    end
  endtask : controller_read_page

  // Controller program page.
  virtual task controller_program_page(flash_op_t flash_op_p);
    bit poll_fifo_status = 1;
    flash_op_p.op = flash_ctrl_pkg::FlashOpProgram;
    flash_op_p.num_words = 16;
    flash_op_p.addr = {flash_op_p.addr[19:11], {11{1'b0}}};
    for (int i = 0; i < 32; i++) begin
      `uvm_info(`gfn, $sformatf("PROGRAM ADDRESS: 0x%0h", flash_op_p.addr), UVM_HIGH)
      // Randomize Write Data
      for (int j = 0; j < 16; j++) begin
        flash_program_data[j] = $urandom();
      end
      cfg.flash_mem_bkdr_write(.flash_op(flash_op_p), .scheme(FlashMemInitSet));
      flash_ctrl_start_op(flash_op_p);
      flash_ctrl_write(flash_program_data, poll_fifo_status);
      wait_flash_op_done(.timeout_ns(cfg.seq_cfg.prog_timeout_ns));
      flash_op_p.addr = flash_op_p.addr + 64;  //64B was written, 16 words
    end
  endtask : controller_program_page

  // Check Expected Alert for prog_type_err and prog_win_err
  virtual task check_exp_alert_status(input bit exp_alert, input string alert_name,
                                      input flash_op_t flash_op, input data_q_t flash_op_data);

    // Local Variables
    uvm_reg_data_t reg_data;

    // Read Status Bits
    case (alert_name)
      "prog_type_err" : csr_rd_check(.ptr(ral.err_code.prog_type_err), .compare_value(exp_alert));
      "prog_win_err"  : csr_rd_check(.ptr(ral.err_code.prog_win_err),  .compare_value(exp_alert));
      "mp_err"        : csr_rd_check(.ptr(ral.err_code.mp_err),        .compare_value(exp_alert));
      "op_err"        : csr_rd_check(.ptr(ral.err_code.op_err),        .compare_value(exp_alert));
      default : `uvm_fatal(`gfn, "Unrecognized alert_name, FAIL")
    endcase
    csr_rd_check(.ptr(ral.op_status.err), .compare_value(exp_alert));

    // For 'prog_type_err' and 'prog_win_err' check via backdoor if Pass,
    // 'mp_err' is Backdoor checked directly within its own test.
    if ((alert_name inside {"prog_type_err", "prog_win_err"}) && (exp_alert == 0)) begin
      cfg.flash_mem_bkdr_read_check(flash_op, flash_op_data);
    end

    // Clear Status Bits
    case (alert_name)
      "prog_type_err" : reg_data = get_csr_val_with_updated_field(ral.err_code.prog_type_err,
                                                                  reg_data, 1);
      "prog_win_err"  : reg_data = get_csr_val_with_updated_field(ral.err_code.prog_win_err,
                                                                  reg_data, 1);
      "mp_err"        : reg_data = get_csr_val_with_updated_field(ral.err_code.mp_err,
                                                                  reg_data, 1);
      "op_err"        : reg_data = get_csr_val_with_updated_field(ral.err_code.op_err,
                                                                  reg_data, 1);
      default : `uvm_fatal(`gfn, "Unrecognized alert_name")
    endcase
    csr_wr(.ptr(ral.err_code), .value(reg_data));
    reg_data = get_csr_val_with_updated_field(ral.op_status.err, reg_data, 0);
    csr_wr(.ptr(ral.op_status), .value(reg_data));

  endtask : check_exp_alert_status

  // Refill table with all default value.
  function void init_p2r_map();
    foreach (p2r_map[i]) p2r_map[i] = 8;
  endfunction

  // p2r_map needs to be in sync with rtl config.
  // Same as RTL, lower index has priority when
  // regions are content.
  function void update_p2r_map(flash_mp_region_cfg_t mp[]);
    int num = mp.size() - 1;
    int base, size;
    // Lower region has priority.
    `uvm_info("update_p2r_map", $sformatf("default     : %p", default_region_cfg), UVM_MEDIUM)
    for (int i = num; i >= 0; --i) begin
      // Check the region is enabled.
      if (mp[i].en == MuBi4True) begin
        `uvm_info("update_p2r_map", $sformatf("region %0d  : %p", i, mp[i]), UVM_MEDIUM)
        base = mp[i].start_page;
        size = mp[i].num_pages;
        for (int j = base; j < (base + size); ++j) begin
          if (p2r_map[j] > i) p2r_map[j] = i;
        end
      end
    end

    `uvm_info("update_p2r_map", $sformatf("after p2r_map update, %p", p2r_map), UVM_HIGH)
  endfunction // update_p2r_map

  // Takes flash_op and region profile and check if the flash_op is legal or not.
  // return 1 : illegal transaction
  // return 0 : legal transaction
  function bit validate_flash_op(flash_op_t flash_op, flash_mp_region_cfg_t my_region);
    case(flash_op.op)
      FlashOpRead:begin
        return (my_region.read_en != MuBi4True);
      end
      FlashOpProgram:begin
        return (my_region.program_en != MuBi4True);
      end
      FlashOpErase:begin
        return (my_region.erase_en != MuBi4True);
      end
      FlashOpInvalid:begin
        return 1;
      end
      default:begin
        `uvm_error("update_flash_op", $sformatf("got %s command", flash_op.op.name()))
        return 1;
      end
    endcase
  endfunction // validate_flash_op

  // Takes flash_op and info profile and check if the flash_op is legal or not.
  // return 1 : illegal transaction
  // return 0 : legal transaction
  // Bank erase doesn't follow rules in this function.
  function bit validate_flash_info(flash_op_t flash_op, flash_bank_mp_info_page_cfg_t my_info);
    if(my_info.en != MuBi4True) return 1;
    case(flash_op.op)
      FlashOpRead:begin
        return (my_info.read_en != MuBi4True);
      end
      FlashOpProgram:begin
        return (my_info.program_en != MuBi4True);
      end
      FlashOpErase:begin
        return (my_info.erase_en != MuBi4True);
      end
      FlashOpInvalid:begin
        return 1;
      end
      default:begin
        `uvm_error("update_flash_op", $sformatf("got %s command", flash_op.op.name()))
        return 1;
      end
    endcase
  endfunction // validate_flash_info

endclass : flash_ctrl_base_vseq
