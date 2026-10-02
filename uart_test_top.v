module uart_test_top (
    clk100mhz,
    sw,
    btn,
    eth_col,
    eth_crs,
    eth_rx_clk,
    eth_rx_dv,
    eth_rxd,
    eth_rxerr,
    eth_tx_clk,
    uart_txd_in,
    led,
    led0_r,
    led0_g,
    led0_b,
    led1_r,
    led1_g,
    led1_b,
    led2_r,
    led2_g,
    led2_b,
    led3_r,
    led3_g,
    led3_b,
    uart_rxd_out,
    eth_mdc,
    eth_rstn,
    eth_ref_clk,
    eth_tx_en,
    eth_txd
);

    input clk100mhz;
    input [3:0] sw;
    input [3:0] btn;
    input eth_col;
    input eth_crs;
    input eth_rx_clk;
    input eth_rx_dv;
    input [3:0] eth_rxd;
    input eth_rxerr;
    input eth_tx_clk;
    input uart_txd_in;
    output [3:0] led;
    output led0_r;
    output led0_g;
    output led0_b;
    output led1_r;
    output led1_g;
    output led1_b;
    output led2_r;
    output led2_g;
    output led2_b;
    output led3_r;
    output led3_g;
    output led3_b;
    output uart_rxd_out;
    output eth_mdc;
    output eth_rstn;
    output eth_ref_clk;
    output eth_tx_en;
    output [3:0] eth_txd;

    wire [3:0] signal_const;
    wire vdd;
    wire signal_const_1;
    wire signal_const_3;
    reg signal_mux;
    wire [1:0] signal_const_13;
    wire [1:0] signal_mux_1;
    wire [1:0] signal_const_14;
    wire [2:0] signal_const_15;
    wire [3:0] signal_wire;
    wire signal_select;
    wire [2:0] signal_const_16;
    wire [2:0] signal_const_17;
    wire [2:0] signal_add;
    wire [2:0] signal_mux_2;
    wire [2:0] signal_mux_3;
    reg [2:0] signal_cases;
    wire [2:0] signal_wire_1;
    reg [2:0] reg_data_place_counter;
    wire signal_eq;
    wire [1:0] signal_mux_4;
    wire [1:0] signal_mux_5;
    wire [1:0] signal_const_19;
    wire [9:0] signal_const_23;
    wire [9:0] signal_const_24;
    wire [9:0] signal_const_26;
    wire [9:0] signal_add_1;
    wire [9:0] signal_mux_6;
    wire [9:0] signal_wire_2;
    reg [9:0] cnt;
    wire signal_eq_1;
    wire signal_mux_7;
    wire signal_wire_3;
    reg pulse;
    wire [1:0] signal_mux_8;
    wire [1:0] signal_const_27;
    reg [1:0] signal_cases_1;
    wire [1:0] signal_wire_4;
    (* fsm_encoding="one_hot" *)
    reg [1:0] signal_reg;
    reg signal_cases_2;
    wire wire_tx_d;
    wire gnd;
    wire [26:0] signal_const_32;
    wire [26:0] signal_const_33;
    wire [3:0] signal_wire_5;
    wire signal_select_1;
    wire signal_wire_6;
    wire [26:0] signal_const_35;
    wire [26:0] signal_add_2;
    wire [26:0] signal_mux_9;
    wire [26:0] signal_wire_7;
    reg [26:0] cnt_1;
    wire signal_eq_2;
    wire signal_mux_10;
    wire signal_wire_8;
    reg pulse_1;
    assign signal_const = 4'b0000;
    assign vdd = 1'b1;
    assign signal_const_1 = 1'b1;
    assign signal_const_3 = 1'b0;
    always @* begin
        case (reg_data_place_counter)
        0:
            signal_mux <= signal_const_1;
        1:
            signal_mux <= signal_const_3;
        2:
            signal_mux <= signal_const_1;
        3:
            signal_mux <= signal_const_3;
        4:
            signal_mux <= signal_const_1;
        5:
            signal_mux <= signal_const_3;
        6:
            signal_mux <= signal_const_1;
        default:
            signal_mux <= signal_const_3;
        endcase
    end
    assign signal_const_13 = 2'b00;
    assign signal_mux_1 = pulse ? signal_const_13 : signal_reg;
    assign signal_const_14 = 2'b11;
    assign signal_const_15 = 3'b111;
    assign signal_wire = sw;
    assign signal_select = signal_wire[0:0];
    assign signal_const_16 = 3'b000;
    assign signal_const_17 = 3'b001;
    assign signal_add = reg_data_place_counter + signal_const_17;
    assign signal_mux_2 = signal_eq ? reg_data_place_counter : signal_add;
    assign signal_mux_3 = pulse ? signal_mux_2 : reg_data_place_counter;
    always @* begin
        case (signal_reg)
        2'b01:
            signal_cases <= signal_const_16;
        2'b10:
            signal_cases <= signal_mux_3;
        default:
            signal_cases <= reg_data_place_counter;
        endcase
    end
    assign signal_wire_1 = signal_cases;
    always @(posedge signal_wire_6) begin
        if (signal_select_1)
            reg_data_place_counter <= signal_const_16;
        else
            if (signal_select)
                reg_data_place_counter <= signal_wire_1;
    end
    assign signal_eq = reg_data_place_counter == signal_const_15;
    assign signal_mux_4 = signal_eq ? signal_const_14 : signal_const_19;
    assign signal_mux_5 = pulse ? signal_mux_4 : signal_const_19;
    assign signal_const_19 = 2'b10;
    assign signal_const_23 = 10'b1101100011;
    assign signal_const_24 = 10'b0000000000;
    assign signal_const_26 = 10'b0000000001;
    assign signal_add_1 = cnt + signal_const_26;
    assign signal_mux_6 = signal_eq_1 ? signal_const_24 : signal_add_1;
    assign signal_wire_2 = signal_mux_6;
    always @(posedge signal_wire_6) begin
        if (signal_select_1)
            cnt <= signal_const_24;
        else
            cnt <= signal_wire_2;
    end
    assign signal_eq_1 = cnt == signal_const_23;
    assign signal_mux_7 = signal_eq_1 ? signal_const_1 : signal_const_3;
    assign signal_wire_3 = signal_mux_7;
    always @(posedge signal_wire_6) begin
        if (signal_select_1)
            pulse <= signal_const_3;
        else
            pulse <= signal_wire_3;
    end
    assign signal_mux_8 = pulse ? signal_const_19 : signal_reg;
    assign signal_const_27 = 2'b01;
    always @* begin
        case (signal_reg)
        2'b00:
            signal_cases_1 <= signal_const_27;
        2'b01:
            signal_cases_1 <= signal_mux_8;
        2'b10:
            signal_cases_1 <= signal_mux_5;
        2'b11:
            signal_cases_1 <= signal_mux_1;
        default:
            signal_cases_1 <= signal_reg;
        endcase
    end
    assign signal_wire_4 = signal_cases_1;
    always @(posedge signal_wire_6) begin
        if (signal_select_1)
            signal_reg <= signal_const_13;
        else
            if (signal_select)
                signal_reg <= signal_wire_4;
    end
    always @* begin
        case (signal_reg)
        2'b00:
            signal_cases_2 <= signal_const_1;
        2'b01:
            signal_cases_2 <= signal_const_3;
        2'b10:
            signal_cases_2 <= signal_mux;
        2'b11:
            signal_cases_2 <= signal_const_1;
        default:
            signal_cases_2 <= signal_const_1;
        endcase
    end
    assign wire_tx_d = signal_cases_2;
    assign gnd = 1'b0;
    assign signal_const_32 = 27'b101111101011110000011111111;
    assign signal_const_33 = 27'b000000000000000000000000000;
    assign signal_wire_5 = btn;
    assign signal_select_1 = signal_wire_5[0:0];
    assign signal_wire_6 = clk100mhz;
    assign signal_const_35 = 27'b000000000000000000000000001;
    assign signal_add_2 = cnt_1 + signal_const_35;
    assign signal_mux_9 = signal_eq_2 ? signal_const_33 : signal_add_2;
    assign signal_wire_7 = signal_mux_9;
    always @(posedge signal_wire_6) begin
        if (signal_select_1)
            cnt_1 <= signal_const_33;
        else
            cnt_1 <= signal_wire_7;
    end
    assign signal_eq_2 = cnt_1 == signal_const_32;
    assign signal_mux_10 = signal_eq_2 ? signal_const_1 : signal_const_3;
    assign signal_wire_8 = signal_mux_10;
    always @(posedge signal_wire_6) begin
        if (signal_select_1)
            pulse_1 <= signal_const_3;
        else
            pulse_1 <= signal_wire_8;
    end
    assign led = signal_const;
    assign led0_r = pulse_1;
    assign led0_g = gnd;
    assign led0_b = gnd;
    assign led1_r = gnd;
    assign led1_g = gnd;
    assign led1_b = gnd;
    assign led2_r = gnd;
    assign led2_g = gnd;
    assign led2_b = gnd;
    assign led3_r = gnd;
    assign led3_g = gnd;
    assign led3_b = gnd;
    assign uart_rxd_out = wire_tx_d;
    assign eth_mdc = gnd;
    assign eth_rstn = vdd;
    assign eth_ref_clk = gnd;
    assign eth_tx_en = gnd;
    assign eth_txd = signal_const;

endmodule
