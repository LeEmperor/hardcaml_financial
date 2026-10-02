module uart_loopback_validation_harness (
    clk100mhz,
    sw,
    btn,
    uart_txd_in,
    eth_col,
    eth_crs,
    eth_rx_clk,
    eth_rx_dv,
    eth_rxd,
    eth_rxerr,
    eth_tx_clk,
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
    input uart_txd_in;
    input eth_col;
    input eth_crs;
    input eth_rx_clk;
    input eth_rx_dv;
    input [3:0] eth_rxd;
    input eth_rxerr;
    input eth_tx_clk;
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
    wire [1:0] signal_const_1;
    wire [1:0] signal_const_2;
    wire [1:0] signal_add;
    wire [1:0] signal_wire;
    reg [1:0] cnt;
    wire signal_select;
    wire signal_select_1;
    wire signal_const_3;
    wire signal_select_2;
    wire signal_select_3;
    wire signal_select_4;
    wire signal_select_5;
    wire signal_select_6;
    wire signal_select_7;
    wire signal_select_8;
    wire signal_select_9;
    reg signal_mux;
    wire signal_const_5;
    wire [1:0] signal_mux_1;
    wire [1:0] signal_const_8;
    wire [2:0] signal_const_9;
    wire [2:0] signal_const_10;
    wire [2:0] signal_const_11;
    wire [2:0] signal_add_1;
    wire [2:0] signal_mux_2;
    wire [2:0] signal_mux_3;
    reg [2:0] signal_cases;
    wire [2:0] signal_wire_1;
    reg [2:0] reg_data_place_counter;
    wire signal_eq;
    wire [1:0] signal_mux_4;
    wire [1:0] signal_mux_5;
    wire [1:0] signal_const_13;
    wire [1:0] signal_mux_6;
    wire [1:0] signal_mux_7;
    reg [1:0] signal_cases_1;
    wire [1:0] signal_wire_2;
    (* fsm_encoding="one_hot" *)
    reg [1:0] signal_reg;
    reg signal_cases_2;
    wire wire_tx_d;
    wire [16:0] signal_const_16;
    wire [16:0] signal_const_18;
    wire [16:0] signal_add_2;
    wire signal_select_10;
    wire [16:0] signal_mux_8;
    wire [16:0] signal_mux_9;
    wire [16:0] signal_wire_3;
    reg [16:0] phy_rst_cnt;
    wire dbg_phy_ready;
    wire [26:0] signal_const_22;
    wire [26:0] signal_const_23;
    wire [26:0] signal_const_25;
    wire [26:0] signal_add_3;
    wire [26:0] signal_mux_10;
    wire [26:0] signal_wire_4;
    reg [26:0] cnt_1;
    wire signal_eq_1;
    wire signal_mux_11;
    wire signal_wire_5;
    reg pulse;
    wire signal_not;
    wire signal_wire_6;
    reg heartbeat_toggle;
    reg signal_cases_3;
    wire signal_wire_7;
    reg signal_reg_1;
    wire signal_not_1;
    wire byte_arrived;
    wire [7:0] signal_const_30;
    wire [6:0] signal_select_11;
    wire [7:0] signal_cat;
    wire [7:0] signal_mux_12;
    wire [3:0] signal_wire_8;
    wire en;
    wire [2:0] signal_mux_13;
    wire [2:0] signal_const_33;
    wire [2:0] signal_add_4;
    wire [2:0] signal_mux_14;
    wire [2:0] signal_mux_15;
    wire [2:0] signal_mux_16;
    reg [2:0] signal_cases_4;
    wire [2:0] signal_wire_9;
    reg [2:0] bit_ctr;
    wire signal_eq_2;
    wire [2:0] signal_mux_17;
    wire [2:0] signal_mux_18;
    wire [2:0] signal_const_38;
    wire [9:0] signal_const_42;
    wire [9:0] signal_const_43;
    wire [9:0] signal_const_45;
    wire [9:0] signal_add_5;
    wire [9:0] signal_mux_19;
    wire [9:0] signal_wire_10;
    reg [9:0] cnt_2;
    wire signal_eq_3;
    wire signal_mux_20;
    wire signal_wire_11;
    reg pulse_1;
    wire [2:0] signal_mux_21;
    wire signal_not_2;
    wire [3:0] signal_wire_12;
    wire rst;
    wire gnd;
    reg signal_reg_2;
    reg sys_rst;
    wire signal_wire_13;
    wire signal_wire_14;
    reg signal_reg_3;
    wire signal_and;
    wire [2:0] signal_mux_22;
    reg [2:0] signal_cases_5;
    wire [2:0] signal_wire_15;
    (* fsm_encoding="one_hot" *)
    reg [2:0] signal_reg_4;
    reg [7:0] signal_cases_6;
    wire [7:0] signal_wire_16;
    reg [7:0] rx_byte;
    reg [7:0] echo_byte;
    wire [3:0] signal_select_12;
    assign signal_const = 4'b0000;
    assign signal_const_1 = 2'b00;
    assign signal_const_2 = 2'b01;
    assign signal_add = cnt + signal_const_2;
    assign signal_wire = signal_add;
    always @(posedge signal_wire_13) begin
        if (sys_rst)
            cnt <= signal_const_1;
        else
            cnt <= signal_wire;
    end
    assign signal_select = cnt[1:1];
    assign signal_select_1 = phy_rst_cnt[16:16];
    assign signal_const_3 = 1'b1;
    assign signal_select_2 = echo_byte[7:7];
    assign signal_select_3 = echo_byte[6:6];
    assign signal_select_4 = echo_byte[5:5];
    assign signal_select_5 = echo_byte[4:4];
    assign signal_select_6 = echo_byte[3:3];
    assign signal_select_7 = echo_byte[2:2];
    assign signal_select_8 = echo_byte[1:1];
    assign signal_select_9 = echo_byte[0:0];
    always @* begin
        case (reg_data_place_counter)
        0:
            signal_mux <= signal_select_9;
        1:
            signal_mux <= signal_select_8;
        2:
            signal_mux <= signal_select_7;
        3:
            signal_mux <= signal_select_6;
        4:
            signal_mux <= signal_select_5;
        5:
            signal_mux <= signal_select_4;
        6:
            signal_mux <= signal_select_3;
        default:
            signal_mux <= signal_select_2;
        endcase
    end
    assign signal_const_5 = 1'b0;
    assign signal_mux_1 = pulse_1 ? signal_const_1 : signal_reg;
    assign signal_const_8 = 2'b11;
    assign signal_const_9 = 3'b111;
    assign signal_const_10 = 3'b000;
    assign signal_const_11 = 3'b001;
    assign signal_add_1 = reg_data_place_counter + signal_const_11;
    assign signal_mux_2 = signal_eq ? reg_data_place_counter : signal_add_1;
    assign signal_mux_3 = pulse_1 ? signal_mux_2 : reg_data_place_counter;
    always @* begin
        case (signal_reg)
        2'b01:
            signal_cases <= signal_const_10;
        2'b10:
            signal_cases <= signal_mux_3;
        default:
            signal_cases <= reg_data_place_counter;
        endcase
    end
    assign signal_wire_1 = signal_cases;
    always @(posedge signal_wire_13) begin
        if (sys_rst)
            reg_data_place_counter <= signal_const_10;
        else
            if (en)
                reg_data_place_counter <= signal_wire_1;
    end
    assign signal_eq = reg_data_place_counter == signal_const_9;
    assign signal_mux_4 = signal_eq ? signal_const_8 : signal_const_13;
    assign signal_mux_5 = pulse_1 ? signal_mux_4 : signal_const_13;
    assign signal_const_13 = 2'b10;
    assign signal_mux_6 = pulse_1 ? signal_const_13 : signal_reg;
    assign signal_mux_7 = byte_arrived ? signal_const_2 : signal_const_1;
    always @* begin
        case (signal_reg)
        2'b00:
            signal_cases_1 <= signal_mux_7;
        2'b01:
            signal_cases_1 <= signal_mux_6;
        2'b10:
            signal_cases_1 <= signal_mux_5;
        2'b11:
            signal_cases_1 <= signal_mux_1;
        default:
            signal_cases_1 <= signal_reg;
        endcase
    end
    assign signal_wire_2 = signal_cases_1;
    always @(posedge signal_wire_13) begin
        if (sys_rst)
            signal_reg <= signal_const_1;
        else
            if (en)
                signal_reg <= signal_wire_2;
    end
    always @* begin
        case (signal_reg)
        2'b00:
            signal_cases_2 <= signal_const_3;
        2'b01:
            signal_cases_2 <= signal_const_5;
        2'b10:
            signal_cases_2 <= signal_mux;
        2'b11:
            signal_cases_2 <= signal_const_3;
        default:
            signal_cases_2 <= signal_const_3;
        endcase
    end
    assign wire_tx_d = signal_cases_2;
    assign signal_const_16 = 17'b00000000000000000;
    assign signal_const_18 = 17'b00000000000000001;
    assign signal_add_2 = phy_rst_cnt + signal_const_18;
    assign signal_select_10 = phy_rst_cnt[16:16];
    assign signal_mux_8 = signal_select_10 ? phy_rst_cnt : signal_add_2;
    assign signal_mux_9 = sys_rst ? signal_const_16 : signal_mux_8;
    assign signal_wire_3 = signal_mux_9;
    always @(posedge signal_wire_13) begin
        if (sys_rst)
            phy_rst_cnt <= signal_const_16;
        else
            phy_rst_cnt <= signal_wire_3;
    end
    assign dbg_phy_ready = phy_rst_cnt[16:16];
    assign signal_const_22 = 27'b101111101011110000011111111;
    assign signal_const_23 = 27'b000000000000000000000000000;
    assign signal_const_25 = 27'b000000000000000000000000001;
    assign signal_add_3 = cnt_1 + signal_const_25;
    assign signal_mux_10 = signal_eq_1 ? signal_const_23 : signal_add_3;
    assign signal_wire_4 = signal_mux_10;
    always @(posedge signal_wire_13) begin
        if (sys_rst)
            cnt_1 <= signal_const_23;
        else
            cnt_1 <= signal_wire_4;
    end
    assign signal_eq_1 = cnt_1 == signal_const_22;
    assign signal_mux_11 = signal_eq_1 ? signal_const_3 : signal_const_5;
    assign signal_wire_5 = signal_mux_11;
    always @(posedge signal_wire_13) begin
        if (sys_rst)
            pulse <= signal_const_5;
        else
            pulse <= signal_wire_5;
    end
    assign signal_not = ~ heartbeat_toggle;
    assign signal_wire_6 = signal_not;
    always @(posedge signal_wire_13) begin
        if (sys_rst)
            heartbeat_toggle <= signal_const_5;
        else
            if (pulse)
                heartbeat_toggle <= signal_wire_6;
    end
    always @* begin
        case (signal_reg_4)
        3'b011:
            signal_cases_3 <= signal_const_3;
        default:
            signal_cases_3 <= signal_const_5;
        endcase
    end
    assign signal_wire_7 = signal_cases_3;
    always @(posedge signal_wire_13) begin
        if (sys_rst)
            signal_reg_1 <= signal_const_5;
        else
            signal_reg_1 <= signal_wire_7;
    end
    assign signal_not_1 = ~ signal_reg_1;
    assign byte_arrived = signal_not_1 & signal_wire_7;
    assign signal_const_30 = 8'b00000000;
    assign signal_select_11 = rx_byte[7:1];
    assign signal_cat = { signal_wire_14,
                          signal_select_11 };
    assign signal_mux_12 = pulse_1 ? signal_cat : rx_byte;
    assign signal_wire_8 = sw;
    assign en = signal_wire_8[0:0];
    assign signal_mux_13 = pulse_1 ? signal_const_10 : signal_reg_4;
    assign signal_const_33 = 3'b011;
    assign signal_add_4 = bit_ctr + signal_const_11;
    assign signal_mux_14 = signal_eq_2 ? bit_ctr : signal_add_4;
    assign signal_mux_15 = pulse_1 ? signal_mux_14 : bit_ctr;
    assign signal_mux_16 = pulse_1 ? signal_const_10 : bit_ctr;
    always @* begin
        case (signal_reg_4)
        3'b001:
            signal_cases_4 <= signal_mux_16;
        3'b010:
            signal_cases_4 <= signal_mux_15;
        default:
            signal_cases_4 <= bit_ctr;
        endcase
    end
    assign signal_wire_9 = signal_cases_4;
    always @(posedge signal_wire_13) begin
        if (sys_rst)
            bit_ctr <= signal_const_10;
        else
            bit_ctr <= signal_wire_9;
    end
    assign signal_eq_2 = bit_ctr == signal_const_9;
    assign signal_mux_17 = signal_eq_2 ? signal_const_33 : signal_reg_4;
    assign signal_mux_18 = pulse_1 ? signal_mux_17 : signal_reg_4;
    assign signal_const_38 = 3'b010;
    assign signal_const_42 = 10'b1101100011;
    assign signal_const_43 = 10'b0000000000;
    assign signal_const_45 = 10'b0000000001;
    assign signal_add_5 = cnt_2 + signal_const_45;
    assign signal_mux_19 = signal_eq_3 ? signal_const_43 : signal_add_5;
    assign signal_wire_10 = signal_mux_19;
    always @(posedge signal_wire_13) begin
        if (sys_rst)
            cnt_2 <= signal_const_43;
        else
            cnt_2 <= signal_wire_10;
    end
    assign signal_eq_3 = cnt_2 == signal_const_42;
    assign signal_mux_20 = signal_eq_3 ? signal_const_3 : signal_const_5;
    assign signal_wire_11 = signal_mux_20;
    always @(posedge signal_wire_13) begin
        if (sys_rst)
            pulse_1 <= signal_const_5;
        else
            pulse_1 <= signal_wire_11;
    end
    assign signal_mux_21 = pulse_1 ? signal_const_38 : signal_reg_4;
    assign signal_not_2 = ~ signal_wire_14;
    assign signal_wire_12 = btn;
    assign rst = signal_wire_12[0:0];
    assign gnd = 1'b0;
    always @(posedge signal_wire_13 or posedge rst) begin
        if (rst)
            signal_reg_2 <= signal_const_3;
        else
            signal_reg_2 <= gnd;
    end
    always @(posedge signal_wire_13 or posedge rst) begin
        if (rst)
            sys_rst <= signal_const_3;
        else
            sys_rst <= signal_reg_2;
    end
    assign signal_wire_13 = clk100mhz;
    assign signal_wire_14 = uart_txd_in;
    always @(posedge signal_wire_13) begin
        if (sys_rst)
            signal_reg_3 <= signal_const_5;
        else
            signal_reg_3 <= signal_wire_14;
    end
    assign signal_and = signal_reg_3 & signal_not_2;
    assign signal_mux_22 = signal_and ? signal_const_11 : signal_reg_4;
    always @* begin
        case (signal_reg_4)
        3'b000:
            signal_cases_5 <= signal_mux_22;
        3'b001:
            signal_cases_5 <= signal_mux_21;
        3'b010:
            signal_cases_5 <= signal_mux_18;
        3'b011:
            signal_cases_5 <= signal_mux_13;
        default:
            signal_cases_5 <= signal_reg_4;
        endcase
    end
    assign signal_wire_15 = signal_cases_5;
    always @(posedge signal_wire_13) begin
        if (sys_rst)
            signal_reg_4 <= signal_const_10;
        else
            if (en)
                signal_reg_4 <= signal_wire_15;
    end
    always @* begin
        case (signal_reg_4)
        3'b010:
            signal_cases_6 <= signal_mux_12;
        default:
            signal_cases_6 <= rx_byte;
        endcase
    end
    assign signal_wire_16 = signal_cases_6;
    always @(posedge signal_wire_13) begin
        if (sys_rst)
            rx_byte <= signal_const_30;
        else
            rx_byte <= signal_wire_16;
    end
    always @(posedge signal_wire_13) begin
        if (sys_rst)
            echo_byte <= signal_const_30;
        else
            if (byte_arrived)
                echo_byte <= rx_byte;
    end
    assign signal_select_12 = echo_byte[3:0];
    assign led = signal_select_12;
    assign led0_r = heartbeat_toggle;
    assign led0_g = gnd;
    assign led0_b = gnd;
    assign led1_r = gnd;
    assign led1_g = dbg_phy_ready;
    assign led1_b = gnd;
    assign led2_r = gnd;
    assign led2_g = gnd;
    assign led2_b = signal_wire_7;
    assign led3_r = gnd;
    assign led3_g = gnd;
    assign led3_b = gnd;
    assign uart_rxd_out = wire_tx_d;
    assign eth_mdc = gnd;
    assign eth_rstn = signal_select_1;
    assign eth_ref_clk = signal_select;
    assign eth_tx_en = gnd;
    assign eth_txd = signal_const;

endmodule
