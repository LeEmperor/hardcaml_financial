// University of Florida
// Author: Bohdan Purtell
// Module: "mii_testbench.sv"
// Full native board top: MII nibbles through MAC/IPv4/UDP, parser, sink and UART.
//
// The simulation DUT is generated from the exact board-top create function with only the
// UART divisor and snapshot interval shortened. Every functional instance and connection is
// therefore shared with the synthesizable cme_feed_parser_validation_harness_arty top.
`timescale 1ns/1ps
module mii_testbench;
    reg clk100mhz = 0, rx_clock = 0, tx_clock = 0;
    always #5 clk100mhz = !clk100mhz;
    always #20 rx_clock = !rx_clock;
    initial begin #7; forever #20 tx_clock = !tx_clock; end

    reg [3:0] btn = 4'b0001, sw = 4'b0001;
    reg rx_dv = 0;
    reg [3:0] rx_data = 0;
    wire [3:0] led;
    wire uart;
    wire eth_mdc, eth_rstn, eth_ref_clk, eth_tx_en;
    wire [3:0] eth_txd;

    cme_feed_parser_validation_harness_arty_sim dut (
        .clk100mhz(clk100mhz), .sw(sw), .btn(btn), .uart_txd_in(1'b1),
        .eth_col(1'b0), .eth_crs(1'b0), .eth_rx_dv(rx_dv), .eth_rxd(rx_data),
        .eth_rxerr(1'b0), .eth_tx_clk(tx_clock), .eth_rx_clk(rx_clock),
        .led(led), .uart_rxd_out(uart), .eth_mdc(eth_mdc), .eth_rstn(eth_rstn),
        .eth_ref_clk(eth_ref_clk), .eth_tx_en(eth_tx_en), .eth_txd(eth_txd)
    );

    // Decode the independent pin protocol at bit centres, including start and stop bits.
    reg [287:0] uart_record = 0;
    reg [7:0] uart_byte;
    integer byte_no, bit_no, uart_records = 0;
    reg [255:0] record_counters = 0;
    reg [255:0] previous_record = 0;
    initial begin
        forever begin
            for (byte_no = 0; byte_no < 36; byte_no = byte_no + 1) begin
                @(negedge uart);
                #80;
                if (uart !== 0) $fatal(1, "UART start bit");
                for (bit_no = 0; bit_no < 8; bit_no = bit_no + 1) begin
                    #160;
                    uart_byte[bit_no] = uart;
                end
                #160;
                if (uart !== 1) $fatal(1, "UART stop bit");
                uart_record[byte_no*8 +: 8] = uart_byte;
            end
            if (uart_record[31:0] !== 32'h37454d43) $fatal(1, "UART magic");
            record_counters = uart_record[287:32];
            for (bit_no = 0; bit_no < 8; bit_no = bit_no + 1)
                if (record_counters[bit_no*32 +: 32]
                    < previous_record[bit_no*32 +: 32])
                    $fatal(1, "UART record went backwards on counter %0d", bit_no);
            previous_record = record_counters;
            uart_records = uart_records + 1;
        end
    end

    integer fd, rc, frame_len, value, j, k, case_no = 0;
    integer records_before;
    reg [31:0] expected [0:7];
    reg [255:0] expected_flat;

    task wait_for_expected;
        input integer prior_records;
        integer cycles;
        begin : wait_block
            for (cycles = 0; cycles < 6000; cycles = cycles + 1) begin
                @(negedge tx_clock);
                if (uart_records > prior_records && record_counters === expected_flat)
                    disable wait_block;
            end
            $fatal(1, "no UART record matched expected counters after record %0d",
                   prior_records);
        end
    endtask

    initial begin
        repeat (10) @(negedge rx_clock);
        btn = 0;
        repeat (20) @(negedge rx_clock);
        fd = $fopen("mii_vectors.txt", "r");
        if (!fd) $fatal(1, "missing vectors");
        rc = $fscanf(fd, "%h", frame_len);
        while (rc == 1) begin
            records_before = uart_records;
            for (j = 0; j < frame_len; j = j + 1) begin
                rc = $fscanf(fd, "%h", value);
                if (rc != 1) $fatal(1, "truncated frame");
                @(negedge rx_clock); rx_dv = 1; rx_data = value[3:0];
                @(negedge rx_clock); rx_data = value[7:4];
            end
            @(negedge rx_clock); rx_dv = 0; rx_data = 0;
            expected_flat = 0;
            for (k = 0; k < 8; k = k + 1) begin
                rc = $fscanf(fd, "%h", expected[k]);
                if (rc != 1) $fatal(1, "truncated expectation");
                expected_flat[k*32 +: 32] = expected[k];
            end
            wait_for_expected(records_before);
            if (led !== expected[0][3:0])
                $fatal(1, "packet-counter LED got %0d expected %0d", led, expected[0][3:0]);
            $display("PASS MII case %0d packets=%0d updates=%0d ends=%0d diagnostics=%0d crc=%0d ip=%0d gaps=%0d duplicates=%0d",
                case_no, expected[0], expected[1], expected[2], expected[3],
                expected[4], expected[5], expected[6], expected[7]);
            case_no = case_no + 1;
            rc = $fscanf(fd, "%h", frame_len);
        end
        $fclose(fd);
        if (case_no != 9) $fatal(1, "wrong vector count");

        // Disable is synchronized into the application domain. Counters freeze while the
        // UART continues emitting complete, identical snapshots.
        sw = 0;
        repeat (10) @(negedge tx_clock);
        records_before = uart_records;
        wait_for_expected(records_before);
        records_before = uart_records;
        wait_for_expected(records_before);

        // Reset overrides disabled enable. Release reset and re-enable, then require a
        // complete all-zero record from the same board output pin.
        previous_record = 0;
        btn = 4'b0001;
        repeat (10) @(negedge tx_clock);
        if (uart !== 1) $fatal(1, "reset must return UART to idle");
        btn = 0;
        sw = 4'b0001;
        expected_flat = 0;
        records_before = uart_records;
        wait_for_expected(records_before);
        $display("PASS atomic UART records=%0d; disabled/reset checks", uart_records);
        $finish;
    end

    initial begin #4000000; $fatal(1, "simulation timeout"); end
endmodule
