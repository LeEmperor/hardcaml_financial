module cme_ingress_fifo (
    clock_i,
    reset_i,
    en_i,
    data_i,
    keep_i,
    first_i,
    last_i,
    ingress_timestamp_i,
    valid_i,
    ready_i,
    ready_o,
    valid_o,
    data_o,
    keep_o,
    first_o,
    last_o,
    ingress_timestamp_o
);

    input clock_i;
    input reset_i;
    input en_i;
    input [63:0] data_i;
    input [7:0] keep_i;
    input first_i;
    input last_i;
    input [63:0] ingress_timestamp_i;
    input valid_i;
    input ready_i;
    output ready_o;
    output valid_o;
    output [63:0] data_o;
    output [7:0] keep_o;
    output first_o;
    output last_o;
    output [63:0] ingress_timestamp_o;

    wire [63:0] signal_select;
    wire signal_select_1;
    wire signal_select_2;
    wire [7:0] signal_select_3;
    wire signal_or;
    wire [137:0] signal_const;
    reg [137:0] data_before_collision;
    wire [63:0] signal_wire;
    wire [7:0] signal_wire_1;
    wire signal_wire_2;
    wire [63:0] signal_wire_3;
    wire [63:0] signal_const_1;
    wire signal_wire_4;
    wire [63:0] signal_mux;
    wire [137:0] signal_cat;
    (* RAM_STYLE="block" *)
    reg [137:0] signal_multiport_mem[0:63];
    wire [137:0] signal_mem_read_port;
    reg [137:0] ram_rbw_data;
    wire [5:0] signal_const_2;
    wire [5:0] signal_const_3;
    wire [5:0] READ_ADDRESS_NEXT;
    (* extract_reset="FALSE" *)
    reg [5:0] READ_ADDRESS;
    wire [5:0] signal_wire_5;
    wire signal_and;
    wire [5:0] RA;
    wire [5:0] WRITE_ADDRESS_NEXT;
    (* extract_reset="FALSE" *)
    reg [5:0] WRITE_ADDRESS;
    wire [5:0] signal_wire_6;
    wire signal_eq;
    wire signal_not;
    wire signal_and_1;
    wire signal_xor;
    wire signal_const_6;
    wire [6:0] signal_const_7;
    wire signal_lt;
    reg used_gt_one;
    wire signal_or_1;
    wire signal_and_2;
    wire signal_and_3;
    reg collision;
    wire [137:0] memory;
    wire signal_xor_1;
    wire signal_eq_1;
    reg used_is_one;
    wire signal_and_4;
    wire signal_and_5;
    wire signal_and_6;
    wire bypass_cond;
    wire [137:0] signal_mux_1;
    reg [137:0] signal_reg;
    wire [63:0] signal_select_4;
    wire signal_not_1;
    wire signal_and_7;
    wire [6:0] signal_const_11;
    wire [6:0] signal_const_12;
    wire [6:0] signal_sub;
    reg [6:0] USED_MINUS_1 = 7'b1111111;
    wire [6:0] signal_wire_7;
    wire [6:0] signal_add;
    reg [6:0] USED_PLUS_1 = 7'b0000001;
    wire [6:0] signal_wire_8;
    wire [6:0] signal_mux_2;
    wire [6:0] signal_const_16;
    reg [6:0] USED;
    wire [6:0] signal_wire_9;
    wire signal_wire_10;
    wire signal_and_8;
    wire signal_wire_11;
    wire signal_wire_12;
    wire signal_wire_13;
    wire signal_eq_2;
    wire signal_not_2;
    reg not_empty;
    wire signal_wire_14;
    wire signal_not_3;
    wire signal_not_4;
    wire signal_and_9;
    wire signal_and_10;
    wire signal_wire_15;
    wire signal_xor_2;
    wire [6:0] USED_NEXT;
    wire signal_eq_3;
    reg full;
    wire signal_wire_16;
    wire signal_not_5;
    wire signal_wire_17;
    wire signal_not_6;
    wire signal_wire_18;
    wire signal_and_11;
    wire signal_and_12;
    assign signal_select = signal_reg[137:74];
    assign signal_select_1 = signal_reg[73:73];
    assign signal_select_2 = signal_reg[72:72];
    assign signal_select_3 = signal_reg[71:64];
    assign signal_or = bypass_cond | signal_wire_15;
    assign signal_const = 138'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    always @(posedge signal_wire_13) begin
        data_before_collision <= signal_cat;
    end
    assign signal_wire = data_i;
    assign signal_wire_1 = keep_i;
    assign signal_wire_2 = last_i;
    assign signal_wire_3 = ingress_timestamp_i;
    assign signal_const_1 = 64'b0000000000000000000000000000000000000000000000000000000000000000;
    assign signal_wire_4 = first_i;
    assign signal_mux = signal_wire_4 ? signal_wire_3 : signal_const_1;
    assign signal_cat = { signal_mux,
                          signal_wire_2,
                          signal_wire_4,
                          signal_wire_1,
                          signal_wire };
    always @(posedge signal_wire_13) begin
        if (signal_and_2)
            signal_multiport_mem[signal_wire_6] <= signal_cat;
    end
    assign signal_mem_read_port = signal_multiport_mem[RA];
    always @(posedge signal_wire_13) begin
        ram_rbw_data <= signal_mem_read_port;
    end
    assign signal_const_2 = 6'b000000;
    assign signal_const_3 = 6'b000001;
    assign READ_ADDRESS_NEXT = signal_wire_5 + signal_const_3;
    always @(posedge signal_wire_13) begin
        if (signal_wire_17)
            READ_ADDRESS <= signal_const_2;
        else
            if (signal_and)
                READ_ADDRESS <= READ_ADDRESS_NEXT;
    end
    assign signal_wire_5 = READ_ADDRESS;
    assign signal_and = signal_wire_15 & used_gt_one;
    assign RA = signal_and ? READ_ADDRESS_NEXT : signal_wire_5;
    assign WRITE_ADDRESS_NEXT = signal_wire_6 + signal_const_3;
    always @(posedge signal_wire_13) begin
        if (signal_wire_17)
            WRITE_ADDRESS <= signal_const_2;
        else
            if (signal_and_2)
                WRITE_ADDRESS <= WRITE_ADDRESS_NEXT;
    end
    assign signal_wire_6 = WRITE_ADDRESS;
    assign signal_eq = signal_wire_6 == RA;
    assign signal_not = ~ signal_wire_15;
    assign signal_and_1 = used_is_one & signal_not;
    assign signal_xor = signal_wire_15 ^ signal_wire_11;
    assign signal_const_6 = 1'b0;
    assign signal_const_7 = 7'b0000001;
    assign signal_lt = signal_const_7 < USED_NEXT;
    always @(posedge signal_wire_13) begin
        if (signal_wire_17)
            used_gt_one <= signal_const_6;
        else
            if (signal_xor)
                used_gt_one <= signal_lt;
    end
    assign signal_or_1 = used_gt_one | signal_and_1;
    assign signal_and_2 = signal_wire_11 & signal_or_1;
    assign signal_and_3 = signal_and_2 & signal_eq;
    always @(posedge signal_wire_13) begin
        collision <= signal_and_3;
    end
    assign memory = collision ? data_before_collision : ram_rbw_data;
    assign signal_xor_1 = signal_wire_15 ^ signal_wire_11;
    assign signal_eq_1 = USED_NEXT == signal_const_7;
    always @(posedge signal_wire_13) begin
        if (signal_wire_17)
            used_is_one <= signal_const_6;
        else
            if (signal_xor_1)
                used_is_one <= signal_eq_1;
    end
    assign signal_and_4 = used_is_one & signal_wire_11;
    assign signal_and_5 = signal_and_4 & signal_wire_15;
    assign signal_and_6 = signal_not_3 & signal_wire_11;
    assign bypass_cond = signal_and_6 | signal_and_5;
    assign signal_mux_1 = bypass_cond ? signal_cat : memory;
    always @(posedge signal_wire_13) begin
        if (signal_wire_17)
            signal_reg <= signal_const;
        else
            if (signal_or)
                signal_reg <= signal_mux_1;
    end
    assign signal_select_4 = signal_reg[63:0];
    assign signal_not_1 = ~ signal_not_3;
    assign signal_and_7 = signal_and_11 & signal_not_1;
    assign signal_const_11 = 7'b1000001;
    assign signal_const_12 = 7'b1111111;
    assign signal_sub = USED_NEXT - signal_const_7;
    always @(posedge signal_wire_13) begin
        if (signal_wire_17)
            USED_MINUS_1 <= signal_const_12;
        else
            if (signal_xor_2)
                USED_MINUS_1 <= signal_sub;
    end
    assign signal_wire_7 = USED_MINUS_1;
    assign signal_add = USED_NEXT + signal_const_7;
    always @(posedge signal_wire_13) begin
        if (signal_wire_17)
            USED_PLUS_1 <= signal_const_7;
        else
            if (signal_xor_2)
                USED_PLUS_1 <= signal_add;
    end
    assign signal_wire_8 = USED_PLUS_1;
    assign signal_mux_2 = signal_wire_15 ? signal_wire_7 : signal_wire_8;
    assign signal_const_16 = 7'b0000000;
    always @(posedge signal_wire_13) begin
        if (signal_wire_17)
            USED <= signal_const_16;
        else
            if (signal_xor_2)
                USED <= USED_NEXT;
    end
    assign signal_wire_9 = USED;
    assign signal_wire_10 = valid_i;
    assign signal_and_8 = signal_wire_10 & signal_and_12;
    assign signal_wire_11 = signal_and_8;
    assign signal_wire_12 = ready_i;
    assign signal_wire_13 = clock_i;
    assign signal_eq_2 = USED_NEXT == signal_const_16;
    assign signal_not_2 = ~ signal_eq_2;
    always @(posedge signal_wire_13) begin
        if (signal_wire_17)
            not_empty <= signal_const_6;
        else
            if (signal_xor_2)
                not_empty <= signal_not_2;
    end
    assign signal_wire_14 = not_empty;
    assign signal_not_3 = ~ signal_wire_14;
    assign signal_not_4 = ~ signal_not_3;
    assign signal_and_9 = signal_and_11 & signal_not_4;
    assign signal_and_10 = signal_and_9 & signal_wire_12;
    assign signal_wire_15 = signal_and_10;
    assign signal_xor_2 = signal_wire_15 ^ signal_wire_11;
    assign USED_NEXT = signal_xor_2 ? signal_mux_2 : signal_wire_9;
    assign signal_eq_3 = USED_NEXT == signal_const_11;
    always @(posedge signal_wire_13) begin
        if (signal_wire_17)
            full <= signal_const_6;
        else
            if (signal_xor_2)
                full <= signal_eq_3;
    end
    assign signal_wire_16 = full;
    assign signal_not_5 = ~ signal_wire_16;
    assign signal_wire_17 = reset_i;
    assign signal_not_6 = ~ signal_wire_17;
    assign signal_wire_18 = en_i;
    assign signal_and_11 = signal_wire_18 & signal_not_6;
    assign signal_and_12 = signal_and_11 & signal_not_5;
    assign ready_o = signal_and_12;
    assign valid_o = signal_and_7;
    assign data_o = signal_select_4;
    assign keep_o = signal_select_3;
    assign first_o = signal_select_2;
    assign last_o = signal_select_1;
    assign ingress_timestamp_o = signal_select;

endmodule
module cme_byte_aligner (
    clock_i,
    reset_i,
    en_i,
    data_i,
    keep_i,
    first_i,
    last_i,
    ingress_timestamp_i,
    valid_i,
    consume_valid_i,
    consume_count_i,
    ready_o,
    valid_o,
    data_o,
    available_o,
    boundary_o,
    first_o,
    ingress_timestamp_o,
    packet_byte_offset_o,
    consume_ready_o
);

    input clock_i;
    input reset_i;
    input en_i;
    input [63:0] data_i;
    input [7:0] keep_i;
    input first_i;
    input last_i;
    input [63:0] ingress_timestamp_i;
    input valid_i;
    input consume_valid_i;
    input [3:0] consume_count_i;
    output ready_o;
    output valid_o;
    output [127:0] data_o;
    output [4:0] available_o;
    output boundary_o;
    output first_o;
    output [63:0] ingress_timestamp_o;
    output [15:0] packet_byte_offset_o;
    output consume_ready_o;

    wire [15:0] signal_const;
    wire [10:0] signal_const_2;
    wire [15:0] signal_cat;
    wire [15:0] signal_add;
    wire signal_eq;
    wire signal_and;
    wire packet_end;
    wire [15:0] signal_mux;
    wire [15:0] signal_wire;
    reg [15:0] packet_offset;
    wire signal_and_1;
    wire [63:0] signal_const_3;
    wire [63:0] signal_select;
    reg [63:0] timestamp;
    wire [63:0] signal_mux_1;
    wire [2:0] signal_const_4;
    wire signal_eq_1;
    wire signal_select_1;
    wire signal_and_2;
    wire first;
    wire signal_select_2;
    wire signal_and_3;
    wire signal_or;
    wire boundary;
    wire [71:0] signal_select_3;
    wire [55:0] signal_const_5;
    wire [127:0] signal_cat_1;
    wire [79:0] signal_select_4;
    wire [47:0] signal_const_6;
    wire [127:0] signal_cat_2;
    wire [87:0] signal_select_5;
    wire [39:0] signal_const_7;
    wire [127:0] signal_cat_3;
    wire [95:0] signal_select_6;
    wire [31:0] signal_const_8;
    wire [127:0] signal_cat_4;
    wire [103:0] signal_select_7;
    wire [23:0] signal_const_9;
    wire [127:0] signal_cat_5;
    wire [111:0] signal_select_8;
    wire [127:0] signal_cat_6;
    wire [119:0] signal_select_9;
    wire [7:0] signal_const_11;
    wire [127:0] signal_cat_7;
    wire [63:0] signal_select_10;
    wire [63:0] signal_select_11;
    wire [63:0] signal_mux_2;
    wire [127:0] window;
    reg [127:0] aligned;
    wire [127:0] signal_const_13;
    wire [127:0] signal_mux_3;
    wire [1:0] signal_const_14;
    wire [1:0] signal_const_15;
    wire [1:0] signal_cat_8;
    wire [1:0] signal_const_16;
    wire [1:0] signal_cat_9;
    wire signal_eq_2;
    wire signal_lt;
    wire signal_not;
    wire [4:0] signal_const_17;
    wire signal_eq_3;
    wire signal_not_1;
    wire signal_wire_1;
    wire [4:0] signal_cat_10;
    wire [137:0] signal_const_19;
    wire [7:0] signal_select_12;
    wire signal_select_13;
    wire [7:0] signal_mux_4;
    wire [7:0] signal_select_14;
    wire signal_select_15;
    wire [7:0] signal_mux_5;
    wire [7:0] signal_select_16;
    wire signal_select_17;
    wire [7:0] signal_mux_6;
    wire [7:0] signal_select_18;
    wire signal_select_19;
    wire [7:0] signal_mux_7;
    wire [7:0] signal_select_20;
    wire signal_select_21;
    wire [7:0] signal_mux_8;
    wire [7:0] signal_select_22;
    wire signal_select_23;
    wire [7:0] signal_mux_9;
    wire [7:0] signal_select_24;
    wire signal_select_25;
    wire [7:0] signal_mux_10;
    wire [63:0] signal_wire_2;
    wire [7:0] signal_select_26;
    wire signal_select_27;
    wire [7:0] signal_mux_11;
    wire [63:0] signal_cat_11;
    wire signal_wire_3;
    wire [63:0] signal_wire_4;
    wire signal_wire_5;
    wire [63:0] signal_mux_12;
    wire [137:0] signal_cat_12;
    wire signal_eq_4;
    wire signal_and_4;
    wire [137:0] next_slot2;
    reg [137:0] slot2;
    wire [137:0] signal_wire_6;
    wire [137:0] next_mid;
    wire [1:0] signal_const_32;
    wire signal_eq_5;
    wire signal_and_5;
    wire [137:0] next_slot1;
    reg [137:0] slot1;
    wire [137:0] signal_wire_7;
    wire [137:0] signal_mux_13;
    wire [137:0] next_head;
    wire signal_eq_6;
    wire signal_and_6;
    wire [137:0] next_slot0;
    reg [137:0] slot0;
    wire [137:0] signal_wire_8;
    wire signal_select_28;
    wire signal_not_2;
    wire signal_lt_1;
    wire signal_not_3;
    wire join_tail;
    wire [4:0] tail_available;
    wire [4:0] signal_sub;
    wire [2:0] signal_select_29;
    wire [2:0] signal_select_30;
    wire [2:0] signal_add_1;
    wire [2:0] signal_mux_14;
    wire [2:0] next_offset;
    reg [2:0] offset;
    wire [2:0] signal_wire_9;
    wire [4:0] signal_cat_13;
    wire [3:0] signal_const_38;
    wire signal_wire_10;
    wire [3:0] signal_const_43;
    wire signal_select_31;
    wire [3:0] signal_mux_15;
    wire signal_eq_7;
    wire signal_not_4;
    wire [3:0] signal_mux_16;
    wire [3:0] signal_const_46;
    wire signal_select_32;
    wire [3:0] signal_mux_17;
    wire signal_eq_8;
    wire signal_not_5;
    wire [3:0] signal_mux_18;
    wire [3:0] signal_const_49;
    wire signal_select_33;
    wire [3:0] signal_mux_19;
    wire signal_eq_9;
    wire signal_not_6;
    wire [3:0] signal_mux_20;
    wire [3:0] signal_const_52;
    wire signal_select_34;
    wire [3:0] signal_mux_21;
    wire signal_eq_10;
    wire signal_not_7;
    wire [3:0] signal_mux_22;
    wire [3:0] signal_const_55;
    wire signal_select_35;
    wire [3:0] signal_mux_23;
    wire signal_eq_11;
    wire signal_not_8;
    wire [3:0] signal_mux_24;
    wire [3:0] signal_const_58;
    wire signal_select_36;
    wire [3:0] signal_mux_25;
    wire signal_eq_12;
    wire signal_not_9;
    wire [3:0] signal_mux_26;
    wire [3:0] signal_const_61;
    wire signal_select_37;
    wire [3:0] signal_mux_27;
    wire signal_eq_13;
    wire signal_not_10;
    wire [3:0] signal_mux_28;
    wire [3:0] signal_const_64;
    wire [7:0] signal_wire_11;
    wire signal_select_38;
    wire [3:0] signal_mux_29;
    wire signal_eq_14;
    wire signal_not_11;
    wire [3:0] input_bytes;
    wire signal_eq_15;
    wire signal_and_7;
    wire [3:0] next_slot2_bytes;
    reg [3:0] slot2_bytes;
    wire [3:0] signal_wire_12;
    wire [3:0] next_mid_bytes;
    wire signal_eq_16;
    wire signal_and_8;
    wire [3:0] next_slot1_bytes;
    reg [3:0] slot1_bytes;
    wire [3:0] signal_wire_13;
    wire [3:0] signal_mux_30;
    wire [3:0] next_head_bytes;
    wire signal_eq_17;
    wire signal_wire_14;
    wire push;
    wire signal_and_9;
    wire [3:0] next_slot0_bytes;
    reg [3:0] slot0_bytes;
    wire [3:0] signal_wire_15;
    wire [4:0] signal_cat_14;
    wire [4:0] remaining;
    wire [4:0] stored_available;
    wire [4:0] available;
    wire signal_lt_2;
    wire signal_not_12;
    wire [3:0] signal_wire_16;
    wire gnd;
    wire [4:0] requested;
    wire [4:0] signal_const_70;
    wire signal_lt_3;
    wire signal_not_13;
    wire signal_eq_18;
    wire occupied;
    wire valid;
    wire signal_and_10;
    wire consume_ready;
    wire signal_and_11;
    wire consume;
    wire pop_head;
    wire signal_and_12;
    wire pop_tail;
    wire [1:0] pops;
    wire [1:0] retained;
    wire [1:0] signal_add_2;
    reg [1:0] occupied_slot_count;
    wire [1:0] signal_wire_17;
    wire signal_lt_4;
    wire signal_wire_18;
    wire signal_not_14;
    wire signal_wire_19;
    wire active;
    wire ready;
    assign signal_const = 16'b0000000000000000;
    assign signal_const_2 = 11'b00000000000;
    assign signal_cat = { signal_const_2,
                          requested };
    assign signal_add = packet_offset + signal_cat;
    assign signal_eq = requested == available;
    assign signal_and = consume & boundary;
    assign packet_end = signal_and & signal_eq;
    assign signal_mux = packet_end ? signal_const : signal_add;
    assign signal_wire = signal_mux;
    always @(posedge signal_wire_10) begin
        if (signal_wire_18)
            packet_offset <= signal_const;
        else
            if (consume)
                packet_offset <= signal_wire;
    end
    assign signal_and_1 = consume & first;
    assign signal_const_3 = 64'b0000000000000000000000000000000000000000000000000000000000000000;
    assign signal_select = signal_wire_8[137:74];
    always @(posedge signal_wire_10) begin
        if (signal_wire_18)
            timestamp <= signal_const_3;
        else
            if (signal_and_1)
                timestamp <= signal_select;
    end
    assign signal_mux_1 = first ? signal_select : timestamp;
    assign signal_const_4 = 3'b000;
    assign signal_eq_1 = signal_wire_9 == signal_const_4;
    assign signal_select_1 = signal_wire_8[72:72];
    assign signal_and_2 = occupied & signal_select_1;
    assign first = signal_and_2 & signal_eq_1;
    assign signal_select_2 = signal_wire_7[73:73];
    assign signal_and_3 = join_tail & signal_select_2;
    assign signal_or = signal_select_28 | signal_and_3;
    assign boundary = occupied & signal_or;
    assign signal_select_3 = window[127:56];
    assign signal_const_5 = 56'b00000000000000000000000000000000000000000000000000000000;
    assign signal_cat_1 = { signal_const_5,
                            signal_select_3 };
    assign signal_select_4 = window[127:48];
    assign signal_const_6 = 48'b000000000000000000000000000000000000000000000000;
    assign signal_cat_2 = { signal_const_6,
                            signal_select_4 };
    assign signal_select_5 = window[127:40];
    assign signal_const_7 = 40'b0000000000000000000000000000000000000000;
    assign signal_cat_3 = { signal_const_7,
                            signal_select_5 };
    assign signal_select_6 = window[127:32];
    assign signal_const_8 = 32'b00000000000000000000000000000000;
    assign signal_cat_4 = { signal_const_8,
                            signal_select_6 };
    assign signal_select_7 = window[127:24];
    assign signal_const_9 = 24'b000000000000000000000000;
    assign signal_cat_5 = { signal_const_9,
                            signal_select_7 };
    assign signal_select_8 = window[127:16];
    assign signal_cat_6 = { signal_const,
                            signal_select_8 };
    assign signal_select_9 = window[127:8];
    assign signal_const_11 = 8'b00000000;
    assign signal_cat_7 = { signal_const_11,
                            signal_select_9 };
    assign signal_select_10 = signal_wire_8[63:0];
    assign signal_select_11 = signal_wire_7[63:0];
    assign signal_mux_2 = join_tail ? signal_select_11 : signal_const_3;
    assign window = { signal_mux_2,
                      signal_select_10 };
    always @* begin
        case (signal_wire_9)
        0:
            aligned <= window;
        1:
            aligned <= signal_cat_7;
        2:
            aligned <= signal_cat_6;
        3:
            aligned <= signal_cat_5;
        4:
            aligned <= signal_cat_4;
        5:
            aligned <= signal_cat_3;
        6:
            aligned <= signal_cat_2;
        default:
            aligned <= signal_cat_1;
        endcase
    end
    assign signal_const_13 = 128'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_mux_3 = occupied ? aligned : signal_const_13;
    assign signal_const_14 = 2'b11;
    assign signal_const_15 = 2'b00;
    assign signal_cat_8 = { gnd,
                            push };
    assign signal_const_16 = 2'b10;
    assign signal_cat_9 = { gnd,
                            pop_head };
    assign signal_eq_2 = requested == available;
    assign signal_lt = requested < remaining;
    assign signal_not = ~ signal_lt;
    assign signal_const_17 = 5'b00000;
    assign signal_eq_3 = requested == signal_const_17;
    assign signal_not_1 = ~ signal_eq_3;
    assign signal_wire_1 = consume_valid_i;
    assign signal_cat_10 = { gnd,
                             signal_wire_13 };
    assign signal_const_19 = 138'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_select_12 = signal_wire_2[7:0];
    assign signal_select_13 = signal_wire_11[0:0];
    assign signal_mux_4 = signal_select_13 ? signal_select_12 : signal_const_11;
    assign signal_select_14 = signal_wire_2[15:8];
    assign signal_select_15 = signal_wire_11[1:1];
    assign signal_mux_5 = signal_select_15 ? signal_select_14 : signal_const_11;
    assign signal_select_16 = signal_wire_2[23:16];
    assign signal_select_17 = signal_wire_11[2:2];
    assign signal_mux_6 = signal_select_17 ? signal_select_16 : signal_const_11;
    assign signal_select_18 = signal_wire_2[31:24];
    assign signal_select_19 = signal_wire_11[3:3];
    assign signal_mux_7 = signal_select_19 ? signal_select_18 : signal_const_11;
    assign signal_select_20 = signal_wire_2[39:32];
    assign signal_select_21 = signal_wire_11[4:4];
    assign signal_mux_8 = signal_select_21 ? signal_select_20 : signal_const_11;
    assign signal_select_22 = signal_wire_2[47:40];
    assign signal_select_23 = signal_wire_11[5:5];
    assign signal_mux_9 = signal_select_23 ? signal_select_22 : signal_const_11;
    assign signal_select_24 = signal_wire_2[55:48];
    assign signal_select_25 = signal_wire_11[6:6];
    assign signal_mux_10 = signal_select_25 ? signal_select_24 : signal_const_11;
    assign signal_wire_2 = data_i;
    assign signal_select_26 = signal_wire_2[63:56];
    assign signal_select_27 = signal_wire_11[7:7];
    assign signal_mux_11 = signal_select_27 ? signal_select_26 : signal_const_11;
    assign signal_cat_11 = { signal_mux_11,
                             signal_mux_10,
                             signal_mux_9,
                             signal_mux_8,
                             signal_mux_7,
                             signal_mux_6,
                             signal_mux_5,
                             signal_mux_4 };
    assign signal_wire_3 = last_i;
    assign signal_wire_4 = ingress_timestamp_i;
    assign signal_wire_5 = first_i;
    assign signal_mux_12 = signal_wire_5 ? signal_wire_4 : signal_const_3;
    assign signal_cat_12 = { signal_mux_12,
                             signal_wire_3,
                             signal_wire_5,
                             signal_wire_11,
                             signal_cat_11 };
    assign signal_eq_4 = retained == signal_const_16;
    assign signal_and_4 = push & signal_eq_4;
    assign next_slot2 = signal_and_4 ? signal_cat_12 : signal_wire_6;
    always @(posedge signal_wire_10) begin
        if (signal_wire_18)
            slot2 <= signal_const_19;
        else
            if (active)
                slot2 <= next_slot2;
    end
    assign signal_wire_6 = slot2;
    assign next_mid = pop_head ? signal_wire_6 : signal_wire_7;
    assign signal_const_32 = 2'b01;
    assign signal_eq_5 = retained == signal_const_32;
    assign signal_and_5 = push & signal_eq_5;
    assign next_slot1 = signal_and_5 ? signal_cat_12 : next_mid;
    always @(posedge signal_wire_10) begin
        if (signal_wire_18)
            slot1 <= signal_const_19;
        else
            if (active)
                slot1 <= next_slot1;
    end
    assign signal_wire_7 = slot1;
    assign signal_mux_13 = pop_head ? signal_wire_7 : signal_wire_8;
    assign next_head = pop_tail ? signal_wire_6 : signal_mux_13;
    assign signal_eq_6 = retained == signal_const_15;
    assign signal_and_6 = push & signal_eq_6;
    assign next_slot0 = signal_and_6 ? signal_cat_12 : next_head;
    always @(posedge signal_wire_10) begin
        if (signal_wire_18)
            slot0 <= signal_const_19;
        else
            if (active)
                slot0 <= next_slot0;
    end
    assign signal_wire_8 = slot0;
    assign signal_select_28 = signal_wire_8[73:73];
    assign signal_not_2 = ~ signal_select_28;
    assign signal_lt_1 = signal_wire_17 < signal_const_16;
    assign signal_not_3 = ~ signal_lt_1;
    assign join_tail = signal_not_3 & signal_not_2;
    assign tail_available = join_tail ? signal_cat_10 : signal_const_17;
    assign signal_sub = requested - remaining;
    assign signal_select_29 = signal_sub[2:0];
    assign signal_select_30 = requested[2:0];
    assign signal_add_1 = signal_wire_9 + signal_select_30;
    assign signal_mux_14 = pop_head ? signal_select_29 : signal_add_1;
    assign next_offset = pop_tail ? signal_const_4 : signal_mux_14;
    always @(posedge signal_wire_10) begin
        if (signal_wire_18)
            offset <= signal_const_4;
        else
            if (consume)
                offset <= next_offset;
    end
    assign signal_wire_9 = offset;
    assign signal_cat_13 = { signal_const_15,
                             signal_wire_9 };
    assign signal_const_38 = 4'b0000;
    assign signal_wire_10 = clock_i;
    assign signal_const_43 = 4'b0001;
    assign signal_select_31 = signal_wire_11[0:0];
    assign signal_mux_15 = signal_select_31 ? signal_const_43 : signal_const_38;
    assign signal_eq_7 = signal_mux_15 == signal_const_38;
    assign signal_not_4 = ~ signal_eq_7;
    assign signal_mux_16 = signal_not_4 ? signal_mux_15 : signal_const_38;
    assign signal_const_46 = 4'b0010;
    assign signal_select_32 = signal_wire_11[1:1];
    assign signal_mux_17 = signal_select_32 ? signal_const_46 : signal_const_38;
    assign signal_eq_8 = signal_mux_17 == signal_const_38;
    assign signal_not_5 = ~ signal_eq_8;
    assign signal_mux_18 = signal_not_5 ? signal_mux_17 : signal_mux_16;
    assign signal_const_49 = 4'b0011;
    assign signal_select_33 = signal_wire_11[2:2];
    assign signal_mux_19 = signal_select_33 ? signal_const_49 : signal_const_38;
    assign signal_eq_9 = signal_mux_19 == signal_const_38;
    assign signal_not_6 = ~ signal_eq_9;
    assign signal_mux_20 = signal_not_6 ? signal_mux_19 : signal_mux_18;
    assign signal_const_52 = 4'b0100;
    assign signal_select_34 = signal_wire_11[3:3];
    assign signal_mux_21 = signal_select_34 ? signal_const_52 : signal_const_38;
    assign signal_eq_10 = signal_mux_21 == signal_const_38;
    assign signal_not_7 = ~ signal_eq_10;
    assign signal_mux_22 = signal_not_7 ? signal_mux_21 : signal_mux_20;
    assign signal_const_55 = 4'b0101;
    assign signal_select_35 = signal_wire_11[4:4];
    assign signal_mux_23 = signal_select_35 ? signal_const_55 : signal_const_38;
    assign signal_eq_11 = signal_mux_23 == signal_const_38;
    assign signal_not_8 = ~ signal_eq_11;
    assign signal_mux_24 = signal_not_8 ? signal_mux_23 : signal_mux_22;
    assign signal_const_58 = 4'b0110;
    assign signal_select_36 = signal_wire_11[5:5];
    assign signal_mux_25 = signal_select_36 ? signal_const_58 : signal_const_38;
    assign signal_eq_12 = signal_mux_25 == signal_const_38;
    assign signal_not_9 = ~ signal_eq_12;
    assign signal_mux_26 = signal_not_9 ? signal_mux_25 : signal_mux_24;
    assign signal_const_61 = 4'b0111;
    assign signal_select_37 = signal_wire_11[6:6];
    assign signal_mux_27 = signal_select_37 ? signal_const_61 : signal_const_38;
    assign signal_eq_13 = signal_mux_27 == signal_const_38;
    assign signal_not_10 = ~ signal_eq_13;
    assign signal_mux_28 = signal_not_10 ? signal_mux_27 : signal_mux_26;
    assign signal_const_64 = 4'b1000;
    assign signal_wire_11 = keep_i;
    assign signal_select_38 = signal_wire_11[7:7];
    assign signal_mux_29 = signal_select_38 ? signal_const_64 : signal_const_38;
    assign signal_eq_14 = signal_mux_29 == signal_const_38;
    assign signal_not_11 = ~ signal_eq_14;
    assign input_bytes = signal_not_11 ? signal_mux_29 : signal_mux_28;
    assign signal_eq_15 = retained == signal_const_16;
    assign signal_and_7 = push & signal_eq_15;
    assign next_slot2_bytes = signal_and_7 ? input_bytes : signal_wire_12;
    always @(posedge signal_wire_10) begin
        if (signal_wire_18)
            slot2_bytes <= signal_const_38;
        else
            if (active)
                slot2_bytes <= next_slot2_bytes;
    end
    assign signal_wire_12 = slot2_bytes;
    assign next_mid_bytes = pop_head ? signal_wire_12 : signal_wire_13;
    assign signal_eq_16 = retained == signal_const_32;
    assign signal_and_8 = push & signal_eq_16;
    assign next_slot1_bytes = signal_and_8 ? input_bytes : next_mid_bytes;
    always @(posedge signal_wire_10) begin
        if (signal_wire_18)
            slot1_bytes <= signal_const_38;
        else
            if (active)
                slot1_bytes <= next_slot1_bytes;
    end
    assign signal_wire_13 = slot1_bytes;
    assign signal_mux_30 = pop_head ? signal_wire_13 : signal_wire_15;
    assign next_head_bytes = pop_tail ? signal_wire_12 : signal_mux_30;
    assign signal_eq_17 = retained == signal_const_15;
    assign signal_wire_14 = valid_i;
    assign push = ready & signal_wire_14;
    assign signal_and_9 = push & signal_eq_17;
    assign next_slot0_bytes = signal_and_9 ? input_bytes : next_head_bytes;
    always @(posedge signal_wire_10) begin
        if (signal_wire_18)
            slot0_bytes <= signal_const_38;
        else
            if (active)
                slot0_bytes <= next_slot0_bytes;
    end
    assign signal_wire_15 = slot0_bytes;
    assign signal_cat_14 = { gnd,
                             signal_wire_15 };
    assign remaining = signal_cat_14 - signal_cat_13;
    assign stored_available = remaining + tail_available;
    assign available = occupied ? stored_available : signal_const_17;
    assign signal_lt_2 = available < requested;
    assign signal_not_12 = ~ signal_lt_2;
    assign signal_wire_16 = consume_count_i;
    assign gnd = 1'b0;
    assign requested = { gnd,
                         signal_wire_16 };
    assign signal_const_70 = 5'b01111;
    assign signal_lt_3 = signal_const_70 < requested;
    assign signal_not_13 = ~ signal_lt_3;
    assign signal_eq_18 = signal_wire_17 == signal_const_15;
    assign occupied = ~ signal_eq_18;
    assign valid = active & occupied;
    assign signal_and_10 = valid & signal_not_13;
    assign consume_ready = signal_and_10 & signal_not_12;
    assign signal_and_11 = consume_ready & signal_wire_1;
    assign consume = signal_and_11 & signal_not_1;
    assign pop_head = consume & signal_not;
    assign signal_and_12 = pop_head & join_tail;
    assign pop_tail = signal_and_12 & signal_eq_2;
    assign pops = pop_tail ? signal_const_16 : signal_cat_9;
    assign retained = signal_wire_17 - pops;
    assign signal_add_2 = retained + signal_cat_8;
    always @(posedge signal_wire_10) begin
        if (signal_wire_18)
            occupied_slot_count <= signal_const_15;
        else
            if (active)
                occupied_slot_count <= signal_add_2;
    end
    assign signal_wire_17 = occupied_slot_count;
    assign signal_lt_4 = signal_wire_17 < signal_const_14;
    assign signal_wire_18 = reset_i;
    assign signal_not_14 = ~ signal_wire_18;
    assign signal_wire_19 = en_i;
    assign active = signal_wire_19 & signal_not_14;
    assign ready = active & signal_lt_4;
    assign ready_o = ready;
    assign valid_o = valid;
    assign data_o = signal_mux_3;
    assign available_o = available;
    assign boundary_o = boundary;
    assign first_o = first;
    assign ingress_timestamp_o = signal_mux_1;
    assign packet_byte_offset_o = packet_offset;
    assign consume_ready_o = consume_ready;

endmodule
module cme_packet_header (
    clock_i,
    reset_i,
    en_i,
    data_i,
    keep_i,
    first_i,
    last_i,
    ingress_timestamp_i,
    valid_i,
    ready_i,
    ready_o,
    valid_o,
    item_o,
    idle_o
);

    input clock_i;
    input reset_i;
    input en_i;
    input [63:0] data_i;
    input [7:0] keep_i;
    input first_i;
    input last_i;
    input [63:0] ingress_timestamp_i;
    input valid_i;
    input ready_i;
    output ready_o;
    output valid_o;
    output [916:0] item_o;
    output idle_o;

    wire [4:0] signal_const;
    wire signal_eq;
    wire [2:0] signal_const_1;
    wire signal_eq_1;
    wire signal_and;
    wire [1:0] signal_const_2;
    wire [1:0] signal_const_3;
    wire [1:0] signal_const_4;
    wire [1:0] signal_mux;
    wire [1:0] signal_mux_1;
    wire [1:0] signal_mux_2;
    wire [63:0] signal_const_6;
    wire [63:0] signal_mux_3;
    wire [63:0] signal_mux_4;
    wire [63:0] signal_mux_5;
    wire signal_const_8;
    wire signal_mux_6;
    wire signal_mux_7;
    wire signal_mux_8;
    wire [31:0] signal_const_10;
    wire [31:0] signal_select;
    wire [31:0] signal_mux_9;
    wire [31:0] signal_mux_10;
    wire [31:0] signal_mux_11;
    wire signal_eq_2;
    wire signal_and_1;
    wire [63:0] signal_select_1;
    reg [63:0] signal_reg;
    wire [31:0] signal_select_2;
    wire [31:0] signal_select_3;
    reg [31:0] signal_reg_1;
    wire [63:0] signal_cat;
    wire [63:0] signal_mux_12;
    wire [63:0] signal_mux_13;
    wire [63:0] signal_mux_14;
    wire signal_mux_15;
    wire signal_mux_16;
    wire signal_mux_17;
    wire signal_mux_18;
    wire signal_mux_19;
    wire signal_mux_20;
    wire signal_mux_21;
    wire signal_mux_22;
    wire [7:0] signal_select_4;
    wire [7:0] signal_const_23;
    wire signal_select_5;
    wire [7:0] signal_mux_23;
    wire [7:0] signal_select_6;
    wire signal_select_7;
    wire [7:0] signal_mux_24;
    wire [7:0] signal_select_8;
    wire signal_select_9;
    wire [7:0] signal_mux_25;
    wire [7:0] signal_select_10;
    wire signal_select_11;
    wire [7:0] signal_mux_26;
    wire [7:0] signal_select_12;
    wire signal_select_13;
    wire [7:0] signal_mux_27;
    wire [7:0] signal_select_14;
    wire signal_select_15;
    wire [7:0] signal_mux_28;
    wire [7:0] signal_select_16;
    wire signal_select_17;
    wire [7:0] signal_mux_29;
    wire [127:0] signal_select_18;
    wire [63:0] signal_select_19;
    wire [7:0] signal_select_20;
    wire signal_select_21;
    wire [7:0] signal_mux_30;
    wire [63:0] signal_cat_1;
    wire [63:0] signal_mux_31;
    wire [63:0] signal_mux_32;
    wire [7:0] signal_const_32;
    wire [7:0] signal_const_33;
    wire [7:0] signal_const_34;
    wire [7:0] signal_const_35;
    wire [7:0] signal_const_36;
    wire [7:0] signal_const_37;
    wire [7:0] signal_const_38;
    wire [7:0] signal_const_39;
    wire [3:0] signal_select_22;
    reg [7:0] signal_mux_33;
    wire [7:0] signal_mux_34;
    wire [7:0] signal_mux_35;
    wire gnd;
    wire vdd;
    wire signal_and_2;
    wire signal_mux_36;
    wire signal_mux_37;
    wire signal_wire;
    reg signal_reg_2;
    wire signal_not;
    wire signal_mux_38;
    wire signal_mux_39;
    wire signal_mux_40;
    wire signal_mux_41;
    wire [1:0] signal_mux_42;
    wire [1:0] signal_mux_43;
    wire signal_eq_3;
    wire signal_and_3;
    wire [63:0] signal_select_23;
    reg [63:0] signal_reg_3;
    wire [63:0] signal_mux_44;
    wire [63:0] signal_mux_45;
    wire signal_mux_46;
    wire signal_mux_47;
    wire [31:0] signal_mux_48;
    wire [31:0] signal_mux_49;
    wire [63:0] signal_mux_50;
    wire [63:0] signal_mux_51;
    wire signal_mux_52;
    wire signal_mux_53;
    wire signal_mux_54;
    wire signal_mux_55;
    wire [15:0] signal_const_59;
    wire [15:0] signal_mux_56;
    wire [15:0] signal_mux_57;
    wire [15:0] signal_mux_58;
    wire [15:0] signal_mux_59;
    wire [15:0] signal_mux_60;
    wire [15:0] signal_mux_61;
    wire [15:0] signal_mux_62;
    wire [15:0] signal_mux_63;
    wire [15:0] signal_mux_64;
    wire [15:0] signal_mux_65;
    wire signal_mux_66;
    wire signal_mux_67;
    wire [63:0] signal_mux_68;
    wire [63:0] signal_mux_69;
    wire signal_mux_70;
    wire signal_mux_71;
    wire [15:0] signal_mux_72;
    wire [15:0] signal_mux_73;
    wire [15:0] signal_mux_74;
    wire [15:0] signal_mux_75;
    wire [15:0] signal_mux_76;
    wire [15:0] signal_mux_77;
    wire [31:0] signal_mux_78;
    wire [31:0] signal_mux_79;
    wire [31:0] signal_mux_80;
    wire [31:0] signal_mux_81;
    wire [63:0] signal_mux_82;
    wire [63:0] signal_mux_83;
    wire signal_mux_84;
    wire signal_mux_85;
    wire [31:0] signal_mux_86;
    wire [31:0] signal_mux_87;
    wire signal_mux_88;
    wire signal_mux_89;
    wire [31:0] signal_mux_90;
    wire [31:0] signal_mux_91;
    wire signal_mux_92;
    wire signal_mux_93;
    wire [7:0] signal_mux_94;
    wire [7:0] signal_mux_95;
    wire [7:0] signal_mux_96;
    wire [7:0] signal_mux_97;
    wire [7:0] signal_mux_98;
    wire [7:0] signal_mux_99;
    wire [31:0] signal_mux_100;
    wire [31:0] signal_mux_101;
    wire signal_mux_102;
    wire signal_mux_103;
    wire [7:0] signal_mux_104;
    wire [7:0] signal_mux_105;
    wire signal_mux_106;
    wire signal_mux_107;
    wire [7:0] signal_mux_108;
    wire [7:0] signal_mux_109;
    wire [31:0] signal_mux_110;
    wire [31:0] signal_mux_111;
    wire signal_mux_112;
    wire signal_mux_113;
    wire [10:0] signal_const_118;
    wire [15:0] signal_cat_2;
    wire [15:0] signal_select_24;
    wire [15:0] signal_add;
    reg [15:0] signal_reg_4;
    wire [2:0] signal_const_120;
    wire signal_eq_4;
    wire [15:0] signal_mux_114;
    wire [2:0] signal_const_121;
    wire signal_eq_5;
    wire [15:0] signal_mux_115;
    wire [916:0] signal_cat_3;
    wire [4:0] signal_mux_116;
    wire [4:0] signal_const_122;
    wire signal_lt;
    wire signal_not_1;
    wire [4:0] signal_mux_117;
    wire [4:0] signal_mux_118;
    wire [3:0] signal_select_25;
    wire [3:0] signal_wire_1;
    wire signal_and_4;
    wire signal_or;
    wire [2:0] signal_const_128;
    wire [4:0] signal_const_129;
    wire signal_eq_6;
    wire signal_and_5;
    wire [2:0] signal_mux_119;
    wire signal_lt_1;
    wire signal_not_2;
    wire signal_not_3;
    wire signal_and_6;
    wire [2:0] signal_mux_120;
    wire signal_lt_2;
    wire signal_not_4;
    wire signal_and_7;
    wire signal_eq_7;
    wire signal_not_5;
    wire signal_or_1;
    wire signal_wire_2;
    wire signal_eq_8;
    wire signal_eq_9;
    wire signal_select_26;
    wire [4:0] signal_select_27;
    wire signal_lt_3;
    wire signal_not_6;
    wire signal_or_2;
    wire signal_select_28;
    wire signal_eq_10;
    wire signal_and_8;
    wire signal_and_9;
    wire signal_or_3;
    wire signal_or_4;
    wire signal_not_7;
    wire signal_and_10;
    wire signal_and_11;
    wire signal_and_12;
    wire signal_and_13;
    wire [2:0] signal_mux_121;
    wire [2:0] signal_mux_122;
    reg [2:0] signal_reg_5;
    wire [2:0] signal_wire_3;
    wire signal_eq_11;
    wire signal_and_14;
    wire signal_and_15;
    wire signal_or_5;
    wire signal_wire_4;
    wire signal_wire_5;
    wire [63:0] signal_wire_6;
    wire signal_wire_7;
    wire signal_wire_8;
    wire [7:0] signal_wire_9;
    wire [63:0] signal_wire_10;
    wire signal_wire_11;
    wire signal_wire_12;
    wire signal_wire_13;
    wire [217:0] signal_inst;
    wire signal_select_29;
    assign signal_const = 5'b00000;
    assign signal_eq = signal_select_27 == signal_const;
    assign signal_const_1 = 3'b000;
    assign signal_eq_1 = signal_wire_3 == signal_const_1;
    assign signal_and = signal_eq_1 & signal_eq;
    assign signal_const_2 = 2'b10;
    assign signal_const_3 = 2'b00;
    assign signal_const_4 = 2'b01;
    assign signal_mux = signal_reg_2 ? signal_const_4 : signal_const_3;
    assign signal_mux_1 = signal_eq_4 ? signal_const_3 : signal_mux;
    assign signal_mux_2 = signal_eq_5 ? signal_const_2 : signal_mux_1;
    assign signal_const_6 = 64'b0000000000000000000000000000000000000000000000000000000000000000;
    assign signal_mux_3 = signal_reg_2 ? signal_const_6 : signal_reg_3;
    assign signal_mux_4 = signal_eq_4 ? signal_reg_3 : signal_mux_3;
    assign signal_mux_5 = signal_eq_5 ? signal_const_6 : signal_mux_4;
    assign signal_const_8 = 1'b0;
    assign signal_mux_6 = signal_reg_2 ? signal_const_8 : gnd;
    assign signal_mux_7 = signal_eq_4 ? gnd : signal_mux_6;
    assign signal_mux_8 = signal_eq_5 ? signal_const_8 : signal_mux_7;
    assign signal_const_10 = 32'b00000000000000000000000000000000;
    assign signal_select = signal_reg[31:0];
    assign signal_mux_9 = signal_reg_2 ? signal_const_10 : signal_select;
    assign signal_mux_10 = signal_eq_4 ? signal_select : signal_mux_9;
    assign signal_mux_11 = signal_eq_5 ? signal_const_10 : signal_mux_10;
    assign signal_eq_2 = signal_wire_3 == signal_const_1;
    assign signal_and_1 = signal_and_15 & signal_eq_2;
    assign signal_select_1 = signal_select_18[63:0];
    always @(posedge signal_wire_13) begin
        if (signal_wire_12)
            signal_reg <= signal_const_6;
        else
            if (signal_and_1)
                signal_reg <= signal_select_1;
    end
    assign signal_select_2 = signal_reg[63:32];
    assign signal_select_3 = signal_select_18[95:64];
    always @(posedge signal_wire_13) begin
        if (signal_wire_12)
            signal_reg_1 <= signal_const_10;
        else
            if (signal_and_15)
                signal_reg_1 <= signal_select_3;
    end
    assign signal_cat = { signal_reg_1,
                          signal_select_2 };
    assign signal_mux_12 = signal_reg_2 ? signal_const_6 : signal_cat;
    assign signal_mux_13 = signal_eq_4 ? signal_cat : signal_mux_12;
    assign signal_mux_14 = signal_eq_5 ? signal_const_6 : signal_mux_13;
    assign signal_mux_15 = signal_reg_2 ? signal_const_8 : vdd;
    assign signal_mux_16 = signal_eq_4 ? vdd : signal_mux_15;
    assign signal_mux_17 = signal_eq_5 ? signal_const_8 : signal_mux_16;
    assign signal_mux_18 = signal_reg_2 ? signal_const_8 : gnd;
    assign signal_mux_19 = signal_eq_4 ? gnd : signal_mux_18;
    assign signal_mux_20 = signal_eq_5 ? signal_const_8 : signal_mux_19;
    assign signal_mux_21 = signal_eq_4 ? vdd : signal_const_8;
    assign signal_mux_22 = signal_eq_5 ? signal_const_8 : signal_mux_21;
    assign signal_select_4 = signal_select_19[7:0];
    assign signal_const_23 = 8'b00000000;
    assign signal_select_5 = signal_mux_33[0:0];
    assign signal_mux_23 = signal_select_5 ? signal_select_4 : signal_const_23;
    assign signal_select_6 = signal_select_19[15:8];
    assign signal_select_7 = signal_mux_33[1:1];
    assign signal_mux_24 = signal_select_7 ? signal_select_6 : signal_const_23;
    assign signal_select_8 = signal_select_19[23:16];
    assign signal_select_9 = signal_mux_33[2:2];
    assign signal_mux_25 = signal_select_9 ? signal_select_8 : signal_const_23;
    assign signal_select_10 = signal_select_19[31:24];
    assign signal_select_11 = signal_mux_33[3:3];
    assign signal_mux_26 = signal_select_11 ? signal_select_10 : signal_const_23;
    assign signal_select_12 = signal_select_19[39:32];
    assign signal_select_13 = signal_mux_33[4:4];
    assign signal_mux_27 = signal_select_13 ? signal_select_12 : signal_const_23;
    assign signal_select_14 = signal_select_19[47:40];
    assign signal_select_15 = signal_mux_33[5:5];
    assign signal_mux_28 = signal_select_15 ? signal_select_14 : signal_const_23;
    assign signal_select_16 = signal_select_19[55:48];
    assign signal_select_17 = signal_mux_33[6:6];
    assign signal_mux_29 = signal_select_17 ? signal_select_16 : signal_const_23;
    assign signal_select_18 = signal_inst[129:2];
    assign signal_select_19 = signal_select_18[63:0];
    assign signal_select_20 = signal_select_19[63:56];
    assign signal_select_21 = signal_mux_33[7:7];
    assign signal_mux_30 = signal_select_21 ? signal_select_20 : signal_const_23;
    assign signal_cat_1 = { signal_mux_30,
                            signal_mux_29,
                            signal_mux_28,
                            signal_mux_27,
                            signal_mux_26,
                            signal_mux_25,
                            signal_mux_24,
                            signal_mux_23 };
    assign signal_mux_31 = signal_eq_4 ? signal_const_6 : signal_cat_1;
    assign signal_mux_32 = signal_eq_5 ? signal_const_6 : signal_mux_31;
    assign signal_const_32 = 8'b11111111;
    assign signal_const_33 = 8'b01111111;
    assign signal_const_34 = 8'b00111111;
    assign signal_const_35 = 8'b00011111;
    assign signal_const_36 = 8'b00001111;
    assign signal_const_37 = 8'b00000111;
    assign signal_const_38 = 8'b00000011;
    assign signal_const_39 = 8'b00000001;
    assign signal_select_22 = signal_mux_117[3:0];
    always @* begin
        case (signal_select_22)
        0:
            signal_mux_33 <= signal_const_23;
        1:
            signal_mux_33 <= signal_const_39;
        2:
            signal_mux_33 <= signal_const_38;
        3:
            signal_mux_33 <= signal_const_37;
        4:
            signal_mux_33 <= signal_const_36;
        5:
            signal_mux_33 <= signal_const_35;
        6:
            signal_mux_33 <= signal_const_34;
        7:
            signal_mux_33 <= signal_const_33;
        default:
            signal_mux_33 <= signal_const_32;
        endcase
    end
    assign signal_mux_34 = signal_eq_4 ? signal_const_23 : signal_mux_33;
    assign signal_mux_35 = signal_eq_5 ? signal_const_23 : signal_mux_34;
    assign gnd = 1'b0;
    assign vdd = 1'b1;
    assign signal_and_2 = signal_and_12 & signal_and_9;
    assign signal_mux_36 = signal_and_2 ? vdd : signal_reg_2;
    assign signal_mux_37 = signal_eq_11 ? gnd : signal_mux_36;
    assign signal_wire = signal_mux_37;
    always @(posedge signal_wire_13) begin
        if (signal_wire_12)
            signal_reg_2 <= signal_const_8;
        else
            if (signal_and_10)
                signal_reg_2 <= signal_wire;
    end
    assign signal_not = ~ signal_reg_2;
    assign signal_mux_38 = signal_eq_4 ? signal_const_8 : signal_not;
    assign signal_mux_39 = signal_eq_5 ? signal_const_8 : signal_mux_38;
    assign signal_mux_40 = signal_eq_4 ? signal_const_8 : signal_and_7;
    assign signal_mux_41 = signal_eq_5 ? signal_const_8 : signal_mux_40;
    assign signal_mux_42 = signal_eq_4 ? signal_const_3 : signal_const_3;
    assign signal_mux_43 = signal_eq_5 ? signal_const_2 : signal_mux_42;
    assign signal_eq_3 = signal_wire_3 == signal_const_1;
    assign signal_and_3 = signal_and_15 & signal_eq_3;
    assign signal_select_23 = signal_inst[200:137];
    always @(posedge signal_wire_13) begin
        if (signal_wire_12)
            signal_reg_3 <= signal_const_6;
        else
            if (signal_and_3)
                signal_reg_3 <= signal_select_23;
    end
    assign signal_mux_44 = signal_eq_4 ? signal_const_6 : signal_const_6;
    assign signal_mux_45 = signal_eq_5 ? signal_reg_3 : signal_mux_44;
    assign signal_mux_46 = signal_eq_4 ? signal_const_8 : signal_const_8;
    assign signal_mux_47 = signal_eq_5 ? signal_const_8 : signal_mux_46;
    assign signal_mux_48 = signal_eq_4 ? signal_const_10 : signal_const_10;
    assign signal_mux_49 = signal_eq_5 ? signal_const_10 : signal_mux_48;
    assign signal_mux_50 = signal_eq_4 ? signal_const_6 : signal_const_6;
    assign signal_mux_51 = signal_eq_5 ? signal_const_6 : signal_mux_50;
    assign signal_mux_52 = signal_eq_4 ? signal_const_8 : signal_const_8;
    assign signal_mux_53 = signal_eq_5 ? signal_const_8 : signal_mux_52;
    assign signal_mux_54 = signal_eq_4 ? signal_const_8 : signal_const_8;
    assign signal_mux_55 = signal_eq_5 ? signal_const_8 : signal_mux_54;
    assign signal_const_59 = 16'b0000000000000000;
    assign signal_mux_56 = signal_eq_4 ? signal_const_59 : signal_const_59;
    assign signal_mux_57 = signal_eq_5 ? signal_const_59 : signal_mux_56;
    assign signal_mux_58 = signal_eq_4 ? signal_const_59 : signal_const_59;
    assign signal_mux_59 = signal_eq_5 ? signal_const_59 : signal_mux_58;
    assign signal_mux_60 = signal_eq_4 ? signal_const_59 : signal_const_59;
    assign signal_mux_61 = signal_eq_5 ? signal_const_59 : signal_mux_60;
    assign signal_mux_62 = signal_eq_4 ? signal_const_59 : signal_const_59;
    assign signal_mux_63 = signal_eq_5 ? signal_const_59 : signal_mux_62;
    assign signal_mux_64 = signal_eq_4 ? signal_const_59 : signal_const_59;
    assign signal_mux_65 = signal_eq_5 ? signal_const_59 : signal_mux_64;
    assign signal_mux_66 = signal_eq_4 ? signal_const_8 : signal_const_8;
    assign signal_mux_67 = signal_eq_5 ? signal_const_8 : signal_mux_66;
    assign signal_mux_68 = signal_eq_4 ? signal_const_6 : signal_const_6;
    assign signal_mux_69 = signal_eq_5 ? signal_const_6 : signal_mux_68;
    assign signal_mux_70 = signal_eq_4 ? signal_const_8 : signal_const_8;
    assign signal_mux_71 = signal_eq_5 ? signal_const_8 : signal_mux_70;
    assign signal_mux_72 = signal_eq_4 ? signal_const_59 : signal_const_59;
    assign signal_mux_73 = signal_eq_5 ? signal_const_59 : signal_mux_72;
    assign signal_mux_74 = signal_eq_4 ? signal_const_59 : signal_const_59;
    assign signal_mux_75 = signal_eq_5 ? signal_const_59 : signal_mux_74;
    assign signal_mux_76 = signal_eq_4 ? signal_const_59 : signal_const_59;
    assign signal_mux_77 = signal_eq_5 ? signal_const_59 : signal_mux_76;
    assign signal_mux_78 = signal_eq_4 ? signal_const_10 : signal_const_10;
    assign signal_mux_79 = signal_eq_5 ? signal_const_10 : signal_mux_78;
    assign signal_mux_80 = signal_eq_4 ? signal_const_10 : signal_const_10;
    assign signal_mux_81 = signal_eq_5 ? signal_const_10 : signal_mux_80;
    assign signal_mux_82 = signal_eq_4 ? signal_const_6 : signal_const_6;
    assign signal_mux_83 = signal_eq_5 ? signal_const_6 : signal_mux_82;
    assign signal_mux_84 = signal_eq_4 ? signal_const_8 : signal_const_8;
    assign signal_mux_85 = signal_eq_5 ? signal_const_8 : signal_mux_84;
    assign signal_mux_86 = signal_eq_4 ? signal_const_10 : signal_const_10;
    assign signal_mux_87 = signal_eq_5 ? signal_const_10 : signal_mux_86;
    assign signal_mux_88 = signal_eq_4 ? signal_const_8 : signal_const_8;
    assign signal_mux_89 = signal_eq_5 ? signal_const_8 : signal_mux_88;
    assign signal_mux_90 = signal_eq_4 ? signal_const_10 : signal_const_10;
    assign signal_mux_91 = signal_eq_5 ? signal_const_10 : signal_mux_90;
    assign signal_mux_92 = signal_eq_4 ? signal_const_8 : signal_const_8;
    assign signal_mux_93 = signal_eq_5 ? signal_const_8 : signal_mux_92;
    assign signal_mux_94 = signal_eq_4 ? signal_const_23 : signal_const_23;
    assign signal_mux_95 = signal_eq_5 ? signal_const_23 : signal_mux_94;
    assign signal_mux_96 = signal_eq_4 ? signal_const_23 : signal_const_23;
    assign signal_mux_97 = signal_eq_5 ? signal_const_23 : signal_mux_96;
    assign signal_mux_98 = signal_eq_4 ? signal_const_23 : signal_const_23;
    assign signal_mux_99 = signal_eq_5 ? signal_const_23 : signal_mux_98;
    assign signal_mux_100 = signal_eq_4 ? signal_const_10 : signal_const_10;
    assign signal_mux_101 = signal_eq_5 ? signal_const_10 : signal_mux_100;
    assign signal_mux_102 = signal_eq_4 ? signal_const_8 : signal_const_8;
    assign signal_mux_103 = signal_eq_5 ? signal_const_8 : signal_mux_102;
    assign signal_mux_104 = signal_eq_4 ? signal_const_23 : signal_const_23;
    assign signal_mux_105 = signal_eq_5 ? signal_const_23 : signal_mux_104;
    assign signal_mux_106 = signal_eq_4 ? signal_const_8 : signal_const_8;
    assign signal_mux_107 = signal_eq_5 ? signal_const_8 : signal_mux_106;
    assign signal_mux_108 = signal_eq_4 ? signal_const_23 : signal_const_23;
    assign signal_mux_109 = signal_eq_5 ? signal_const_38 : signal_mux_108;
    assign signal_mux_110 = signal_eq_4 ? signal_const_10 : signal_const_10;
    assign signal_mux_111 = signal_eq_5 ? signal_const_10 : signal_mux_110;
    assign signal_mux_112 = signal_eq_4 ? signal_const_8 : signal_const_8;
    assign signal_mux_113 = signal_eq_5 ? signal_const_8 : signal_mux_112;
    assign signal_const_118 = 11'b00000000000;
    assign signal_cat_2 = { signal_const_118,
                            signal_select_27 };
    assign signal_select_24 = signal_inst[216:201];
    assign signal_add = signal_select_24 + signal_cat_2;
    always @(posedge signal_wire_13) begin
        if (signal_wire_12)
            signal_reg_4 <= signal_const_59;
        else
            if (signal_and_6)
                signal_reg_4 <= signal_add;
    end
    assign signal_const_120 = 3'b011;
    assign signal_eq_4 = signal_wire_3 == signal_const_120;
    assign signal_mux_114 = signal_eq_4 ? signal_const_59 : signal_const_59;
    assign signal_const_121 = 3'b100;
    assign signal_eq_5 = signal_wire_3 == signal_const_121;
    assign signal_mux_115 = signal_eq_5 ? signal_reg_4 : signal_mux_114;
    assign signal_cat_3 = { signal_mux_115,
                            signal_mux_113,
                            signal_mux_111,
                            signal_mux_109,
                            signal_mux_107,
                            signal_mux_105,
                            signal_mux_103,
                            signal_mux_101,
                            signal_mux_99,
                            signal_mux_97,
                            signal_mux_95,
                            signal_mux_93,
                            signal_mux_91,
                            signal_mux_89,
                            signal_mux_87,
                            signal_mux_85,
                            signal_mux_83,
                            signal_mux_81,
                            signal_mux_79,
                            signal_mux_77,
                            signal_mux_75,
                            signal_mux_73,
                            signal_mux_71,
                            signal_mux_69,
                            signal_mux_67,
                            signal_mux_65,
                            signal_mux_63,
                            signal_mux_61,
                            signal_mux_59,
                            signal_mux_57,
                            signal_mux_55,
                            signal_mux_53,
                            signal_mux_51,
                            signal_mux_49,
                            signal_mux_47,
                            signal_mux_45,
                            signal_mux_43,
                            signal_mux_41,
                            signal_mux_39,
                            signal_mux_35,
                            signal_mux_32,
                            signal_mux_22,
                            signal_mux_20,
                            signal_mux_17,
                            signal_mux_14,
                            signal_mux_11,
                            signal_mux_8,
                            signal_mux_5,
                            signal_mux_2 };
    assign signal_mux_116 = signal_not_2 ? signal_const_129 : signal_select_27;
    assign signal_const_122 = 5'b01000;
    assign signal_lt = signal_select_27 < signal_const_122;
    assign signal_not_1 = ~ signal_lt;
    assign signal_mux_117 = signal_not_1 ? signal_const_122 : signal_select_27;
    assign signal_mux_118 = signal_eq_11 ? signal_mux_116 : signal_mux_117;
    assign signal_select_25 = signal_mux_118[3:0];
    assign signal_wire_1 = signal_select_25;
    assign signal_and_4 = signal_and_9 & signal_wire_2;
    assign signal_or = signal_not_2 | signal_select_26;
    assign signal_const_128 = 3'b010;
    assign signal_const_129 = 5'b01100;
    assign signal_eq_6 = signal_select_27 == signal_const_129;
    assign signal_and_5 = signal_select_26 & signal_eq_6;
    assign signal_mux_119 = signal_and_5 ? signal_const_120 : signal_const_128;
    assign signal_lt_1 = signal_select_27 < signal_const_129;
    assign signal_not_2 = ~ signal_lt_1;
    assign signal_not_3 = ~ signal_not_2;
    assign signal_and_6 = signal_and_15 & signal_not_3;
    assign signal_mux_120 = signal_and_6 ? signal_const_121 : signal_mux_119;
    assign signal_lt_2 = signal_const_122 < signal_select_27;
    assign signal_not_4 = ~ signal_lt_2;
    assign signal_and_7 = signal_select_26 & signal_not_4;
    assign signal_eq_7 = signal_wire_3 == signal_const_128;
    assign signal_not_5 = ~ signal_eq_7;
    assign signal_or_1 = signal_not_5 | signal_and_7;
    assign signal_wire_2 = ready_i;
    assign signal_eq_8 = signal_wire_3 == signal_const_121;
    assign signal_eq_9 = signal_wire_3 == signal_const_120;
    assign signal_select_26 = signal_inst[135:135];
    assign signal_select_27 = signal_inst[134:130];
    assign signal_lt_3 = signal_select_27 < signal_const_122;
    assign signal_not_6 = ~ signal_lt_3;
    assign signal_or_2 = signal_not_6 | signal_select_26;
    assign signal_select_28 = signal_inst[1:1];
    assign signal_eq_10 = signal_wire_3 == signal_const_128;
    assign signal_and_8 = signal_eq_10 & signal_select_28;
    assign signal_and_9 = signal_and_8 & signal_or_2;
    assign signal_or_3 = signal_and_9 | signal_eq_9;
    assign signal_or_4 = signal_or_3 | signal_eq_8;
    assign signal_not_7 = ~ signal_wire_12;
    assign signal_and_10 = signal_wire_11 & signal_not_7;
    assign signal_and_11 = signal_and_10 & signal_or_4;
    assign signal_and_12 = signal_and_11 & signal_wire_2;
    assign signal_and_13 = signal_and_12 & signal_or_1;
    assign signal_mux_121 = signal_and_13 ? signal_const_1 : signal_wire_3;
    assign signal_mux_122 = signal_and_15 ? signal_mux_120 : signal_mux_121;
    always @(posedge signal_wire_13) begin
        if (signal_wire_12)
            signal_reg_5 <= signal_const_1;
        else
            if (signal_and_10)
                signal_reg_5 <= signal_mux_122;
    end
    assign signal_wire_3 = signal_reg_5;
    assign signal_eq_11 = signal_wire_3 == signal_const_1;
    assign signal_and_14 = signal_eq_11 & signal_select_28;
    assign signal_and_15 = signal_and_14 & signal_or;
    assign signal_or_5 = signal_and_15 | signal_and_4;
    assign signal_wire_4 = signal_or_5;
    assign signal_wire_5 = valid_i;
    assign signal_wire_6 = ingress_timestamp_i;
    assign signal_wire_7 = last_i;
    assign signal_wire_8 = first_i;
    assign signal_wire_9 = keep_i;
    assign signal_wire_10 = data_i;
    assign signal_wire_11 = en_i;
    assign signal_wire_12 = reset_i;
    assign signal_wire_13 = clock_i;
    cme_byte_aligner
        cme_byte_aligner
        ( .clock_i(signal_wire_13),
          .reset_i(signal_wire_12),
          .en_i(signal_wire_11),
          .data_i(signal_wire_10),
          .keep_i(signal_wire_9),
          .first_i(signal_wire_8),
          .last_i(signal_wire_7),
          .ingress_timestamp_i(signal_wire_6),
          .valid_i(signal_wire_5),
          .consume_valid_i(signal_wire_4),
          .consume_count_i(signal_wire_1),
          .ready_o(signal_inst[0:0]),
          .valid_o(signal_inst[1:1]),
          .data_o(signal_inst[129:2]),
          .available_o(signal_inst[134:130]),
          .boundary_o(signal_inst[135:135]),
          .first_o(signal_inst[136:136]),
          .ingress_timestamp_o(signal_inst[200:137]),
          .packet_byte_offset_o(signal_inst[216:201]),
          .consume_ready_o(signal_inst[217:217]) );
    assign signal_select_29 = signal_inst[0:0];
    assign ready_o = signal_select_29;
    assign valid_o = signal_and_11;
    assign item_o = signal_cat_3;
    assign idle_o = signal_and;

endmodule
module cme_single_feed_sequencer (
    clock_i,
    reset_i,
    en_i,
    item_i,
    valid_i,
    ready_i,
    quiescent_i,
    session_reset_i,
    resync_valid_i,
    resync_next_seq_i,
    ready_o,
    valid_o,
    item_o,
    control_ready_o,
    idle_o
);

    input clock_i;
    input reset_i;
    input en_i;
    input [916:0] item_i;
    input valid_i;
    input ready_i;
    input quiescent_i;
    input session_reset_i;
    input resync_valid_i;
    input [31:0] resync_next_seq_i;
    output ready_o;
    output valid_o;
    output [916:0] item_o;
    output control_ready_o;
    output idle_o;

    wire [1:0] signal_const;
    wire [1:0] signal_mux;
    wire [63:0] signal_const_1;
    wire [63:0] signal_mux_1;
    wire [63:0] signal_mux_2;
    wire signal_const_2;
    wire signal_mux_3;
    wire signal_mux_4;
    wire [31:0] signal_const_3;
    wire [31:0] signal_mux_5;
    wire [31:0] signal_mux_6;
    wire [63:0] signal_mux_7;
    wire [63:0] signal_mux_8;
    wire signal_mux_9;
    wire signal_mux_10;
    wire signal_mux_11;
    wire signal_select;
    wire signal_mux_12;
    wire signal_mux_13;
    wire signal_mux_14;
    wire [63:0] signal_select_1;
    wire [63:0] signal_mux_15;
    wire [7:0] signal_const_9;
    wire [7:0] signal_select_2;
    wire [7:0] signal_mux_16;
    wire signal_select_3;
    wire signal_mux_17;
    wire signal_mux_18;
    wire [1:0] signal_select_4;
    wire [1:0] signal_mux_19;
    wire [1:0] signal_mux_20;
    wire [63:0] signal_select_5;
    wire [63:0] signal_select_6;
    wire [63:0] signal_mux_21;
    wire [63:0] signal_mux_22;
    wire signal_select_7;
    wire signal_select_8;
    wire signal_mux_23;
    wire signal_mux_24;
    wire [31:0] signal_select_9;
    wire [31:0] signal_mux_25;
    wire [31:0] signal_mux_26;
    wire [63:0] signal_select_10;
    wire [63:0] signal_select_11;
    wire [63:0] signal_mux_27;
    wire [63:0] signal_mux_28;
    wire signal_select_12;
    wire signal_select_13;
    wire signal_mux_29;
    wire signal_mux_30;
    wire signal_mux_31;
    wire signal_not;
    wire signal_and;
    wire signal_mux_32;
    wire signal_not_1;
    wire signal_and_1;
    wire signal_mux_33;
    wire signal_mux_34;
    wire signal_mux_35;
    reg signal_reg;
    wire signal_wire;
    wire signal_select_14;
    wire signal_mux_36;
    wire signal_mux_37;
    wire [15:0] signal_const_14;
    wire [15:0] signal_select_15;
    wire [15:0] signal_mux_38;
    wire [15:0] signal_mux_39;
    wire [15:0] signal_select_16;
    wire [15:0] signal_mux_40;
    wire [15:0] signal_mux_41;
    wire [15:0] signal_select_17;
    wire [15:0] signal_mux_42;
    wire [15:0] signal_mux_43;
    wire [15:0] signal_select_18;
    wire [15:0] signal_mux_44;
    wire [15:0] signal_mux_45;
    wire [15:0] signal_select_19;
    wire [15:0] signal_mux_46;
    wire [15:0] signal_mux_47;
    wire signal_select_20;
    wire signal_mux_48;
    wire signal_mux_49;
    wire [63:0] signal_select_21;
    wire [63:0] signal_mux_50;
    wire [63:0] signal_mux_51;
    wire signal_select_22;
    wire signal_mux_52;
    wire signal_mux_53;
    wire [15:0] signal_select_23;
    wire [15:0] signal_mux_54;
    wire [15:0] signal_mux_55;
    wire [15:0] signal_select_24;
    wire [15:0] signal_mux_56;
    wire [15:0] signal_mux_57;
    wire [15:0] signal_select_25;
    wire [15:0] signal_mux_58;
    wire [15:0] signal_mux_59;
    wire [31:0] signal_select_26;
    wire [31:0] signal_mux_60;
    wire [31:0] signal_mux_61;
    wire [31:0] signal_select_27;
    wire [31:0] signal_mux_62;
    wire [31:0] signal_mux_63;
    wire [63:0] signal_select_28;
    wire [63:0] signal_mux_64;
    wire [63:0] signal_mux_65;
    wire signal_select_29;
    wire signal_mux_66;
    wire signal_mux_67;
    wire [31:0] signal_select_30;
    wire [31:0] signal_mux_68;
    wire [31:0] signal_mux_69;
    wire signal_select_31;
    wire signal_mux_70;
    wire signal_mux_71;
    wire [31:0] signal_select_32;
    wire [31:0] signal_mux_72;
    wire [31:0] signal_mux_73;
    wire signal_select_33;
    wire signal_mux_74;
    wire signal_mux_75;
    wire [7:0] signal_select_34;
    wire [7:0] signal_mux_76;
    wire [7:0] signal_mux_77;
    wire [7:0] signal_select_35;
    wire [7:0] signal_mux_78;
    wire [7:0] signal_mux_79;
    wire [7:0] signal_select_36;
    wire [7:0] signal_mux_80;
    wire [7:0] signal_mux_81;
    wire [31:0] signal_select_37;
    wire [31:0] signal_mux_82;
    wire [31:0] signal_mux_83;
    wire signal_select_38;
    wire signal_mux_84;
    wire signal_mux_85;
    wire [7:0] signal_select_39;
    wire [7:0] signal_mux_86;
    wire [7:0] signal_mux_87;
    wire signal_select_40;
    wire signal_mux_88;
    wire signal_mux_89;
    wire [7:0] signal_const_40;
    wire [7:0] signal_const_41;
    wire [7:0] signal_mux_90;
    wire [7:0] signal_select_41;
    wire [7:0] signal_mux_91;
    wire [7:0] signal_mux_92;
    wire [31:0] signal_select_42;
    wire [31:0] signal_mux_93;
    wire [31:0] signal_mux_94;
    wire signal_select_43;
    wire signal_mux_95;
    wire signal_mux_96;
    wire [15:0] signal_select_44;
    wire [15:0] signal_mux_97;
    wire [15:0] signal_mux_98;
    wire [916:0] signal_cat;
    wire signal_not_2;
    wire signal_and_2;
    wire signal_or;
    wire signal_wire_1;
    wire signal_not_3;
    wire signal_eq;
    wire signal_not_4;
    wire signal_and_3;
    wire signal_mux_99;
    reg signal_reg_1;
    wire signal_wire_2;
    wire signal_select_45;
    wire signal_and_4;
    wire signal_select_46;
    wire signal_or_1;
    wire signal_and_5;
    wire signal_mux_100;
    wire signal_not_5;
    wire signal_mux_101;
    wire signal_select_47;
    wire signal_not_6;
    wire signal_and_6;
    wire signal_mux_102;
    reg signal_reg_2;
    wire signal_wire_3;
    wire signal_not_7;
    wire [31:0] signal_wire_4;
    wire [31:0] signal_const_50;
    wire [31:0] signal_add;
    wire [31:0] signal_mux_103;
    wire [31:0] signal_mux_104;
    wire [31:0] signal_mux_105;
    reg [31:0] signal_reg_3;
    wire [31:0] signal_wire_5;
    wire [31:0] signal_select_48;
    wire [31:0] signal_sub;
    wire signal_eq_1;
    wire signal_not_8;
    wire signal_wire_6;
    wire gnd;
    wire vdd;
    wire signal_not_9;
    wire signal_and_7;
    wire signal_and_8;
    wire signal_and_9;
    wire signal_wire_7;
    wire signal_wire_8;
    wire signal_not_10;
    wire signal_and_10;
    wire signal_and_11;
    wire signal_or_2;
    wire signal_mux_106;
    wire signal_mux_107;
    reg signal_reg_4;
    wire signal_wire_9;
    wire [1:0] signal_const_52;
    wire [916:0] signal_wire_10;
    wire [1:0] signal_select_49;
    wire signal_eq_2;
    wire signal_and_12;
    wire signal_and_13;
    wire signal_and_14;
    wire signal_and_15;
    wire signal_wire_11;
    wire signal_not_11;
    wire signal_not_12;
    wire signal_wire_12;
    wire signal_and_16;
    wire signal_and_17;
    wire signal_and_18;
    wire signal_and_19;
    wire signal_and_20;
    wire signal_and_21;
    wire signal_mux_108;
    reg signal_reg_5;
    wire signal_wire_13;
    wire signal_or_3;
    wire signal_or_4;
    wire signal_not_13;
    wire signal_and_22;
    wire signal_and_23;
    wire signal_and_24;
    wire signal_or_5;
    wire signal_not_14;
    wire signal_wire_14;
    wire signal_not_15;
    wire signal_wire_15;
    wire signal_and_25;
    wire signal_and_26;
    wire signal_and_27;
    assign signal_const = 2'b10;
    assign signal_mux = signal_and_15 ? signal_const : signal_select_49;
    assign signal_const_1 = 64'b0000000000000000000000000000000000000000000000000000000000000000;
    assign signal_mux_1 = signal_eq_2 ? signal_select_5 : signal_select_5;
    assign signal_mux_2 = signal_and_15 ? signal_const_1 : signal_mux_1;
    assign signal_const_2 = 1'b0;
    assign signal_mux_3 = signal_eq_2 ? signal_select_7 : signal_select_7;
    assign signal_mux_4 = signal_and_15 ? signal_const_2 : signal_mux_3;
    assign signal_const_3 = 32'b00000000000000000000000000000000;
    assign signal_mux_5 = signal_eq_2 ? signal_select_48 : signal_select_48;
    assign signal_mux_6 = signal_and_15 ? signal_const_3 : signal_mux_5;
    assign signal_mux_7 = signal_eq_2 ? signal_select_10 : signal_select_10;
    assign signal_mux_8 = signal_and_15 ? signal_const_1 : signal_mux_7;
    assign signal_mux_9 = signal_eq_2 ? signal_select_12 : signal_select_12;
    assign signal_mux_10 = signal_and_15 ? signal_const_2 : signal_mux_9;
    assign signal_mux_11 = signal_wire_9 ? signal_wire : vdd;
    assign signal_select = signal_wire_10[164:164];
    assign signal_mux_12 = signal_eq_2 ? signal_mux_11 : signal_select;
    assign signal_mux_13 = signal_and_15 ? signal_const_2 : signal_mux_12;
    assign signal_mux_14 = signal_and_15 ? signal_const_2 : signal_select_45;
    assign signal_select_1 = signal_wire_10[229:166];
    assign signal_mux_15 = signal_and_15 ? signal_const_1 : signal_select_1;
    assign signal_const_9 = 8'b00000000;
    assign signal_select_2 = signal_wire_10[237:230];
    assign signal_mux_16 = signal_and_15 ? signal_const_9 : signal_select_2;
    assign signal_select_3 = signal_wire_10[238:238];
    assign signal_mux_17 = signal_and_15 ? signal_const_2 : signal_select_3;
    assign signal_mux_18 = signal_and_15 ? signal_const_2 : signal_select_46;
    assign signal_select_4 = signal_wire_10[241:240];
    assign signal_mux_19 = signal_eq ? signal_select_4 : signal_select_4;
    assign signal_mux_20 = signal_and_15 ? signal_const : signal_mux_19;
    assign signal_select_5 = signal_wire_10[65:2];
    assign signal_select_6 = signal_wire_10[305:242];
    assign signal_mux_21 = signal_eq ? signal_select_6 : signal_select_6;
    assign signal_mux_22 = signal_and_15 ? signal_select_5 : signal_mux_21;
    assign signal_select_7 = signal_wire_10[66:66];
    assign signal_select_8 = signal_wire_10[306:306];
    assign signal_mux_23 = signal_eq ? signal_select_8 : signal_select_8;
    assign signal_mux_24 = signal_and_15 ? signal_select_7 : signal_mux_23;
    assign signal_select_9 = signal_wire_10[338:307];
    assign signal_mux_25 = signal_eq ? signal_select_9 : signal_select_9;
    assign signal_mux_26 = signal_and_15 ? signal_select_48 : signal_mux_25;
    assign signal_select_10 = signal_wire_10[162:99];
    assign signal_select_11 = signal_wire_10[402:339];
    assign signal_mux_27 = signal_eq ? signal_select_11 : signal_select_11;
    assign signal_mux_28 = signal_and_15 ? signal_select_10 : signal_mux_27;
    assign signal_select_12 = signal_wire_10[163:163];
    assign signal_select_13 = signal_wire_10[403:403];
    assign signal_mux_29 = signal_eq ? signal_select_13 : signal_select_13;
    assign signal_mux_30 = signal_and_15 ? signal_select_12 : signal_mux_29;
    assign signal_mux_31 = signal_select_47 ? signal_wire : gnd;
    assign signal_not = ~ signal_wire_9;
    assign signal_and = signal_and_9 & signal_not;
    assign signal_mux_32 = signal_and ? vdd : signal_wire;
    assign signal_not_1 = ~ signal_select_47;
    assign signal_and_1 = signal_and_20 & signal_not_1;
    assign signal_mux_33 = signal_and_1 ? gnd : signal_mux_32;
    assign signal_mux_34 = signal_and_11 ? vdd : signal_mux_33;
    assign signal_mux_35 = signal_and_24 ? gnd : signal_mux_34;
    always @(posedge signal_wire_6) begin
        if (signal_wire_14)
            signal_reg <= signal_const_2;
        else
            if (signal_and_25)
                signal_reg <= signal_mux_35;
    end
    assign signal_wire = signal_reg;
    assign signal_select_14 = signal_wire_10[404:404];
    assign signal_mux_36 = signal_eq ? signal_wire : signal_select_14;
    assign signal_mux_37 = signal_and_15 ? signal_mux_31 : signal_mux_36;
    assign signal_const_14 = 16'b0000000000000000;
    assign signal_select_15 = signal_wire_10[420:405];
    assign signal_mux_38 = signal_eq ? signal_select_15 : signal_select_15;
    assign signal_mux_39 = signal_and_15 ? signal_const_14 : signal_mux_38;
    assign signal_select_16 = signal_wire_10[436:421];
    assign signal_mux_40 = signal_eq ? signal_select_16 : signal_select_16;
    assign signal_mux_41 = signal_and_15 ? signal_const_14 : signal_mux_40;
    assign signal_select_17 = signal_wire_10[452:437];
    assign signal_mux_42 = signal_eq ? signal_select_17 : signal_select_17;
    assign signal_mux_43 = signal_and_15 ? signal_const_14 : signal_mux_42;
    assign signal_select_18 = signal_wire_10[468:453];
    assign signal_mux_44 = signal_eq ? signal_select_18 : signal_select_18;
    assign signal_mux_45 = signal_and_15 ? signal_const_14 : signal_mux_44;
    assign signal_select_19 = signal_wire_10[484:469];
    assign signal_mux_46 = signal_eq ? signal_select_19 : signal_select_19;
    assign signal_mux_47 = signal_and_15 ? signal_const_14 : signal_mux_46;
    assign signal_select_20 = signal_wire_10[485:485];
    assign signal_mux_48 = signal_eq ? signal_select_20 : signal_select_20;
    assign signal_mux_49 = signal_and_15 ? signal_const_2 : signal_mux_48;
    assign signal_select_21 = signal_wire_10[549:486];
    assign signal_mux_50 = signal_eq ? signal_select_21 : signal_select_21;
    assign signal_mux_51 = signal_and_15 ? signal_const_1 : signal_mux_50;
    assign signal_select_22 = signal_wire_10[550:550];
    assign signal_mux_52 = signal_eq ? signal_select_22 : signal_select_22;
    assign signal_mux_53 = signal_and_15 ? signal_const_2 : signal_mux_52;
    assign signal_select_23 = signal_wire_10[566:551];
    assign signal_mux_54 = signal_eq ? signal_select_23 : signal_select_23;
    assign signal_mux_55 = signal_and_15 ? signal_const_14 : signal_mux_54;
    assign signal_select_24 = signal_wire_10[582:567];
    assign signal_mux_56 = signal_eq ? signal_select_24 : signal_select_24;
    assign signal_mux_57 = signal_and_15 ? signal_const_14 : signal_mux_56;
    assign signal_select_25 = signal_wire_10[598:583];
    assign signal_mux_58 = signal_eq ? signal_select_25 : signal_select_25;
    assign signal_mux_59 = signal_and_15 ? signal_const_14 : signal_mux_58;
    assign signal_select_26 = signal_wire_10[630:599];
    assign signal_mux_60 = signal_eq ? signal_select_26 : signal_select_26;
    assign signal_mux_61 = signal_and_15 ? signal_const_3 : signal_mux_60;
    assign signal_select_27 = signal_wire_10[662:631];
    assign signal_mux_62 = signal_eq ? signal_select_27 : signal_select_27;
    assign signal_mux_63 = signal_and_15 ? signal_const_3 : signal_mux_62;
    assign signal_select_28 = signal_wire_10[726:663];
    assign signal_mux_64 = signal_eq ? signal_select_28 : signal_select_28;
    assign signal_mux_65 = signal_and_15 ? signal_const_1 : signal_mux_64;
    assign signal_select_29 = signal_wire_10[727:727];
    assign signal_mux_66 = signal_eq ? signal_select_29 : signal_select_29;
    assign signal_mux_67 = signal_and_15 ? signal_const_2 : signal_mux_66;
    assign signal_select_30 = signal_wire_10[759:728];
    assign signal_mux_68 = signal_eq ? signal_select_30 : signal_select_30;
    assign signal_mux_69 = signal_and_15 ? signal_const_3 : signal_mux_68;
    assign signal_select_31 = signal_wire_10[760:760];
    assign signal_mux_70 = signal_eq ? signal_select_31 : signal_select_31;
    assign signal_mux_71 = signal_and_15 ? signal_const_2 : signal_mux_70;
    assign signal_select_32 = signal_wire_10[792:761];
    assign signal_mux_72 = signal_eq ? signal_select_32 : signal_select_32;
    assign signal_mux_73 = signal_and_15 ? signal_const_3 : signal_mux_72;
    assign signal_select_33 = signal_wire_10[793:793];
    assign signal_mux_74 = signal_eq ? signal_select_33 : signal_select_33;
    assign signal_mux_75 = signal_and_15 ? signal_const_2 : signal_mux_74;
    assign signal_select_34 = signal_wire_10[801:794];
    assign signal_mux_76 = signal_eq ? signal_select_34 : signal_select_34;
    assign signal_mux_77 = signal_and_15 ? signal_const_9 : signal_mux_76;
    assign signal_select_35 = signal_wire_10[809:802];
    assign signal_mux_78 = signal_eq ? signal_select_35 : signal_select_35;
    assign signal_mux_79 = signal_and_15 ? signal_const_9 : signal_mux_78;
    assign signal_select_36 = signal_wire_10[817:810];
    assign signal_mux_80 = signal_eq ? signal_select_36 : signal_select_36;
    assign signal_mux_81 = signal_and_15 ? signal_const_9 : signal_mux_80;
    assign signal_select_37 = signal_wire_10[849:818];
    assign signal_mux_82 = signal_eq ? signal_select_37 : signal_select_37;
    assign signal_mux_83 = signal_and_15 ? signal_const_3 : signal_mux_82;
    assign signal_select_38 = signal_wire_10[850:850];
    assign signal_mux_84 = signal_eq ? signal_select_38 : signal_select_38;
    assign signal_mux_85 = signal_and_15 ? signal_const_2 : signal_mux_84;
    assign signal_select_39 = signal_wire_10[858:851];
    assign signal_mux_86 = signal_eq ? signal_select_39 : signal_select_39;
    assign signal_mux_87 = signal_and_15 ? signal_const_9 : signal_mux_86;
    assign signal_select_40 = signal_wire_10[859:859];
    assign signal_mux_88 = signal_eq ? signal_select_40 : signal_select_40;
    assign signal_mux_89 = signal_and_15 ? signal_const_2 : signal_mux_88;
    assign signal_const_40 = 8'b00000010;
    assign signal_const_41 = 8'b00000001;
    assign signal_mux_90 = signal_select_47 ? signal_const_40 : signal_const_41;
    assign signal_select_41 = signal_wire_10[867:860];
    assign signal_mux_91 = signal_eq ? signal_select_41 : signal_select_41;
    assign signal_mux_92 = signal_and_15 ? signal_mux_90 : signal_mux_91;
    assign signal_select_42 = signal_wire_10[899:868];
    assign signal_mux_93 = signal_eq ? signal_select_42 : signal_select_42;
    assign signal_mux_94 = signal_and_15 ? signal_wire_5 : signal_mux_93;
    assign signal_select_43 = signal_wire_10[900:900];
    assign signal_mux_95 = signal_eq ? signal_select_43 : signal_select_43;
    assign signal_mux_96 = signal_and_15 ? vdd : signal_mux_95;
    assign signal_select_44 = signal_wire_10[916:901];
    assign signal_mux_97 = signal_eq ? signal_select_44 : signal_select_44;
    assign signal_mux_98 = signal_and_15 ? signal_const_14 : signal_mux_97;
    assign signal_cat = { signal_mux_98,
                          signal_mux_96,
                          signal_mux_94,
                          signal_mux_92,
                          signal_mux_89,
                          signal_mux_87,
                          signal_mux_85,
                          signal_mux_83,
                          signal_mux_81,
                          signal_mux_79,
                          signal_mux_77,
                          signal_mux_75,
                          signal_mux_73,
                          signal_mux_71,
                          signal_mux_69,
                          signal_mux_67,
                          signal_mux_65,
                          signal_mux_63,
                          signal_mux_61,
                          signal_mux_59,
                          signal_mux_57,
                          signal_mux_55,
                          signal_mux_53,
                          signal_mux_51,
                          signal_mux_49,
                          signal_mux_47,
                          signal_mux_45,
                          signal_mux_43,
                          signal_mux_41,
                          signal_mux_39,
                          signal_mux_37,
                          signal_mux_30,
                          signal_mux_28,
                          signal_mux_26,
                          signal_mux_24,
                          signal_mux_22,
                          signal_mux_20,
                          signal_mux_18,
                          signal_mux_17,
                          signal_mux_16,
                          signal_mux_15,
                          signal_mux_14,
                          signal_mux_13,
                          signal_mux_10,
                          signal_mux_8,
                          signal_mux_6,
                          signal_mux_4,
                          signal_mux_2,
                          signal_mux };
    assign signal_not_2 = ~ signal_and_15;
    assign signal_and_2 = signal_wire_11 & signal_not_2;
    assign signal_or = signal_wire_13 | signal_and_2;
    assign signal_wire_1 = quiescent_i;
    assign signal_not_3 = ~ signal_or_1;
    assign signal_eq = signal_select_49 == signal_const;
    assign signal_not_4 = ~ signal_eq;
    assign signal_and_3 = signal_and_7 & signal_not_4;
    assign signal_mux_99 = signal_and_3 ? signal_not_3 : signal_wire_2;
    always @(posedge signal_wire_6) begin
        if (signal_wire_14)
            signal_reg_1 <= signal_const_2;
        else
            if (signal_and_25)
                signal_reg_1 <= signal_mux_99;
    end
    assign signal_wire_2 = signal_reg_1;
    assign signal_select_45 = signal_wire_10[165:165];
    assign signal_and_4 = signal_eq_2 & signal_select_45;
    assign signal_select_46 = signal_wire_10[239:239];
    assign signal_or_1 = signal_select_46 | signal_and_4;
    assign signal_and_5 = signal_and_7 & signal_or_1;
    assign signal_mux_100 = signal_and_5 ? gnd : signal_wire_13;
    assign signal_not_5 = ~ signal_wire_13;
    assign signal_mux_101 = signal_and_9 ? gnd : signal_wire_3;
    assign signal_select_47 = signal_sub[31:31];
    assign signal_not_6 = ~ signal_select_47;
    assign signal_and_6 = signal_and_20 & signal_not_6;
    assign signal_mux_102 = signal_and_6 ? vdd : signal_mux_101;
    always @(posedge signal_wire_6) begin
        if (signal_wire_14)
            signal_reg_2 <= signal_const_2;
        else
            if (signal_and_25)
                signal_reg_2 <= signal_mux_102;
    end
    assign signal_wire_3 = signal_reg_2;
    assign signal_not_7 = ~ signal_wire_3;
    assign signal_wire_4 = resync_next_seq_i;
    assign signal_const_50 = 32'b00000000000000000000000000000001;
    assign signal_add = signal_select_48 + signal_const_50;
    assign signal_mux_103 = signal_and_9 ? signal_add : signal_wire_5;
    assign signal_mux_104 = signal_and_11 ? signal_wire_4 : signal_mux_103;
    assign signal_mux_105 = signal_and_24 ? signal_const_3 : signal_mux_104;
    always @(posedge signal_wire_6) begin
        if (signal_wire_14)
            signal_reg_3 <= signal_const_3;
        else
            if (signal_and_25)
                signal_reg_3 <= signal_mux_105;
    end
    assign signal_wire_5 = signal_reg_3;
    assign signal_select_48 = signal_wire_10[98:67];
    assign signal_sub = signal_select_48 - signal_wire_5;
    assign signal_eq_1 = signal_sub == signal_const_3;
    assign signal_not_8 = ~ signal_eq_1;
    assign signal_wire_6 = clock_i;
    assign gnd = 1'b0;
    assign vdd = 1'b1;
    assign signal_not_9 = ~ signal_wire_13;
    assign signal_and_7 = signal_wire_12 & signal_and_27;
    assign signal_and_8 = signal_and_7 & signal_eq_2;
    assign signal_and_9 = signal_and_8 & signal_not_9;
    assign signal_wire_7 = resync_valid_i;
    assign signal_wire_8 = session_reset_i;
    assign signal_not_10 = ~ signal_wire_8;
    assign signal_and_10 = signal_and_23 & signal_not_10;
    assign signal_and_11 = signal_and_10 & signal_wire_7;
    assign signal_or_2 = signal_and_11 | signal_and_9;
    assign signal_mux_106 = signal_or_2 ? vdd : signal_wire_9;
    assign signal_mux_107 = signal_and_24 ? gnd : signal_mux_106;
    always @(posedge signal_wire_6) begin
        if (signal_wire_14)
            signal_reg_4 <= signal_const_2;
        else
            if (signal_and_25)
                signal_reg_4 <= signal_mux_107;
    end
    assign signal_wire_9 = signal_reg_4;
    assign signal_const_52 = 2'b00;
    assign signal_wire_10 = item_i;
    assign signal_select_49 = signal_wire_10[1:0];
    assign signal_eq_2 = signal_select_49 == signal_const_52;
    assign signal_and_12 = signal_eq_2 & signal_wire_9;
    assign signal_and_13 = signal_and_12 & signal_not_8;
    assign signal_and_14 = signal_and_13 & signal_not_7;
    assign signal_and_15 = signal_and_14 & signal_not_5;
    assign signal_wire_11 = ready_i;
    assign signal_not_11 = ~ signal_or_5;
    assign signal_not_12 = ~ signal_wire_13;
    assign signal_wire_12 = valid_i;
    assign signal_and_16 = signal_and_25 & signal_wire_12;
    assign signal_and_17 = signal_and_16 & signal_not_12;
    assign signal_and_18 = signal_and_17 & signal_not_11;
    assign signal_and_19 = signal_and_18 & signal_wire_11;
    assign signal_and_20 = signal_and_19 & signal_and_15;
    assign signal_and_21 = signal_and_20 & signal_select_47;
    assign signal_mux_108 = signal_and_21 ? vdd : signal_mux_100;
    always @(posedge signal_wire_6) begin
        if (signal_wire_14)
            signal_reg_5 <= signal_const_2;
        else
            if (signal_and_25)
                signal_reg_5 <= signal_mux_108;
    end
    assign signal_wire_13 = signal_reg_5;
    assign signal_or_3 = signal_wire_13 | signal_wire_3;
    assign signal_or_4 = signal_or_3 | signal_wire_2;
    assign signal_not_13 = ~ signal_or_4;
    assign signal_and_22 = signal_and_25 & signal_not_13;
    assign signal_and_23 = signal_and_22 & signal_wire_1;
    assign signal_and_24 = signal_and_23 & signal_wire_8;
    assign signal_or_5 = signal_and_24 | signal_and_11;
    assign signal_not_14 = ~ signal_or_5;
    assign signal_wire_14 = reset_i;
    assign signal_not_15 = ~ signal_wire_14;
    assign signal_wire_15 = en_i;
    assign signal_and_25 = signal_wire_15 & signal_not_15;
    assign signal_and_26 = signal_and_25 & signal_not_14;
    assign signal_and_27 = signal_and_26 & signal_or;
    assign ready_o = signal_and_27;
    assign valid_o = signal_and_18;
    assign item_o = signal_cat;
    assign control_ready_o = signal_and_23;
    assign idle_o = signal_not_13;

endmodule
module cme_packet_pipeline (
    clock_i,
    reset_i,
    en_i,
    data_i,
    keep_i,
    first_i,
    last_i,
    ingress_timestamp_i,
    valid_i,
    ready_i,
    downstream_idle_i,
    session_reset_i,
    resync_valid_i,
    resync_next_seq_i,
    ready_o,
    valid_o,
    item_o,
    control_ready_o
);

    input clock_i;
    input reset_i;
    input en_i;
    input [63:0] data_i;
    input [7:0] keep_i;
    input first_i;
    input last_i;
    input [63:0] ingress_timestamp_i;
    input valid_i;
    input ready_i;
    input downstream_idle_i;
    input session_reset_i;
    input resync_valid_i;
    input [31:0] resync_next_seq_i;
    output ready_o;
    output valid_o;
    output [916:0] item_o;
    output control_ready_o;

    wire signal_select;
    wire [916:0] signal_select_1;
    wire signal_select_2;
    wire [31:0] signal_wire;
    wire signal_wire_1;
    wire signal_select_3;
    wire signal_not;
    wire signal_not_1;
    wire signal_and;
    wire signal_and_1;
    wire signal_and_2;
    wire signal_wire_2;
    wire signal_select_4;
    wire [916:0] signal_select_5;
    wire [920:0] signal_inst;
    wire signal_select_6;
    wire signal_wire_3;
    wire signal_select_7;
    wire [63:0] signal_select_8;
    wire signal_select_9;
    wire signal_select_10;
    wire [7:0] signal_select_11;
    wire [63:0] signal_select_12;
    wire [919:0] signal_inst_1;
    wire signal_select_13;
    wire signal_wire_4;
    wire signal_and_3;
    wire signal_const;
    wire signal_not_2;
    reg signal_reg;
    wire signal_wire_5;
    wire signal_wire_6;
    wire signal_wire_7;
    wire signal_or;
    wire signal_not_3;
    wire signal_or_1;
    wire signal_wire_8;
    wire signal_and_4;
    wire [63:0] signal_wire_9;
    wire signal_wire_10;
    wire signal_wire_11;
    wire [7:0] signal_wire_12;
    wire [63:0] signal_wire_13;
    wire signal_wire_14;
    wire signal_wire_15;
    wire signal_wire_16;
    wire [139:0] signal_inst_2;
    wire signal_select_14;
    wire signal_and_5;
    assign signal_select = signal_inst[919:919];
    assign signal_select_1 = signal_inst[918:2];
    assign signal_select_2 = signal_inst[1:1];
    assign signal_wire = resync_next_seq_i;
    assign signal_wire_1 = downstream_idle_i;
    assign signal_select_3 = signal_inst_1[919:919];
    assign signal_not = ~ signal_select_7;
    assign signal_not_1 = ~ signal_wire_5;
    assign signal_and = signal_not_1 & signal_not;
    assign signal_and_1 = signal_and & signal_select_3;
    assign signal_and_2 = signal_and_1 & signal_wire_1;
    assign signal_wire_2 = ready_i;
    assign signal_select_4 = signal_inst_1[1:1];
    assign signal_select_5 = signal_inst_1[918:2];
    cme_single_feed_sequencer
        cme_single_feed_sequencer
        ( .clock_i(signal_wire_16),
          .reset_i(signal_wire_15),
          .en_i(signal_wire_14),
          .item_i(signal_select_5),
          .valid_i(signal_select_4),
          .ready_i(signal_wire_2),
          .quiescent_i(signal_and_2),
          .session_reset_i(signal_wire_7),
          .resync_valid_i(signal_wire_6),
          .resync_next_seq_i(signal_wire),
          .ready_o(signal_inst[0:0]),
          .valid_o(signal_inst[1:1]),
          .item_o(signal_inst[918:2]),
          .control_ready_o(signal_inst[919:919]),
          .idle_o(signal_inst[920:920]) );
    assign signal_select_6 = signal_inst[0:0];
    assign signal_wire_3 = signal_select_6;
    assign signal_select_7 = signal_inst_2[1:1];
    assign signal_select_8 = signal_inst_2[139:76];
    assign signal_select_9 = signal_inst_2[75:75];
    assign signal_select_10 = signal_inst_2[74:74];
    assign signal_select_11 = signal_inst_2[73:66];
    assign signal_select_12 = signal_inst_2[65:2];
    cme_packet_header
        cme_packet_header
        ( .clock_i(signal_wire_16),
          .reset_i(signal_wire_15),
          .en_i(signal_wire_14),
          .data_i(signal_select_12),
          .keep_i(signal_select_11),
          .first_i(signal_select_10),
          .last_i(signal_select_9),
          .ingress_timestamp_i(signal_select_8),
          .valid_i(signal_select_7),
          .ready_i(signal_wire_3),
          .ready_o(signal_inst_1[0:0]),
          .valid_o(signal_inst_1[1:1]),
          .item_o(signal_inst_1[918:2]),
          .idle_o(signal_inst_1[919:919]) );
    assign signal_select_13 = signal_inst_1[0:0];
    assign signal_wire_4 = signal_select_13;
    assign signal_and_3 = signal_and_5 & signal_wire_8;
    assign signal_const = 1'b0;
    assign signal_not_2 = ~ signal_wire_10;
    always @(posedge signal_wire_16) begin
        if (signal_wire_15)
            signal_reg <= signal_const;
        else
            if (signal_and_3)
                signal_reg <= signal_not_2;
    end
    assign signal_wire_5 = signal_reg;
    assign signal_wire_6 = resync_valid_i;
    assign signal_wire_7 = session_reset_i;
    assign signal_or = signal_wire_7 | signal_wire_6;
    assign signal_not_3 = ~ signal_or;
    assign signal_or_1 = signal_not_3 | signal_wire_5;
    assign signal_wire_8 = valid_i;
    assign signal_and_4 = signal_wire_8 & signal_or_1;
    assign signal_wire_9 = ingress_timestamp_i;
    assign signal_wire_10 = last_i;
    assign signal_wire_11 = first_i;
    assign signal_wire_12 = keep_i;
    assign signal_wire_13 = data_i;
    assign signal_wire_14 = en_i;
    assign signal_wire_15 = reset_i;
    assign signal_wire_16 = clock_i;
    cme_ingress_fifo
        cme_ingress_fifo
        ( .clock_i(signal_wire_16),
          .reset_i(signal_wire_15),
          .en_i(signal_wire_14),
          .data_i(signal_wire_13),
          .keep_i(signal_wire_12),
          .first_i(signal_wire_11),
          .last_i(signal_wire_10),
          .ingress_timestamp_i(signal_wire_9),
          .valid_i(signal_and_4),
          .ready_i(signal_wire_4),
          .ready_o(signal_inst_2[0:0]),
          .valid_o(signal_inst_2[1:1]),
          .data_o(signal_inst_2[65:2]),
          .keep_o(signal_inst_2[73:66]),
          .first_o(signal_inst_2[74:74]),
          .last_o(signal_inst_2[75:75]),
          .ingress_timestamp_o(signal_inst_2[139:76]) );
    assign signal_select_14 = signal_inst_2[0:0];
    assign signal_and_5 = signal_select_14 & signal_or_1;
    assign ready_o = signal_and_5;
    assign valid_o = signal_select_2;
    assign item_o = signal_select_1;
    assign control_ready_o = signal_select;

endmodule
module cme_sbe_message_iterator (
    clock_i,
    reset_i,
    en_i,
    item_i,
    valid_i,
    ready_i,
    ready_o,
    valid_o,
    item_o,
    idle_o
);

    input clock_i;
    input reset_i;
    input en_i;
    input [916:0] item_i;
    input valid_i;
    input ready_i;
    output ready_o;
    output valid_o;
    output [1078:0] item_o;
    output idle_o;

    wire signal_not;
    wire [4:0] signal_const;
    wire signal_eq;
    wire signal_and;
    wire signal_and_1;
    wire signal_or;
    wire [1078:0] signal_const_1;
    wire [1:0] signal_const_2;
    wire [1:0] signal_const_3;
    wire [1:0] signal_const_4;
    wire [1:0] signal_mux;
    wire [1:0] signal_mux_1;
    wire [1:0] signal_mux_2;
    wire [63:0] signal_const_6;
    wire [63:0] signal_mux_3;
    wire [63:0] signal_mux_4;
    wire [63:0] signal_mux_5;
    wire signal_const_8;
    wire signal_mux_6;
    wire signal_mux_7;
    wire signal_mux_8;
    wire [31:0] signal_const_10;
    wire [31:0] signal_mux_9;
    wire [31:0] signal_mux_10;
    wire [31:0] signal_mux_11;
    wire [63:0] signal_mux_12;
    wire [63:0] signal_mux_13;
    wire [63:0] signal_mux_14;
    wire signal_mux_15;
    wire signal_mux_16;
    wire signal_mux_17;
    wire signal_mux_18;
    wire signal_mux_19;
    wire signal_mux_20;
    wire [15:0] signal_const_18;
    wire [15:0] signal_mux_21;
    wire [15:0] signal_mux_22;
    wire [15:0] signal_mux_23;
    wire [15:0] signal_mux_24;
    wire [15:0] signal_mux_25;
    wire [15:0] signal_mux_26;
    wire [15:0] signal_mux_27;
    wire [15:0] signal_mux_28;
    wire [15:0] signal_mux_29;
    wire [15:0] signal_mux_30;
    wire [15:0] signal_mux_31;
    wire [15:0] signal_mux_32;
    wire [15:0] signal_mux_33;
    wire [15:0] signal_mux_34;
    wire [15:0] signal_mux_35;
    wire signal_mux_36;
    wire signal_mux_37;
    wire signal_mux_38;
    wire [63:0] signal_mux_39;
    wire [63:0] signal_mux_40;
    wire [63:0] signal_mux_41;
    wire signal_mux_42;
    wire signal_mux_43;
    wire signal_mux_44;
    wire [15:0] signal_mux_45;
    wire [15:0] signal_mux_46;
    wire [15:0] signal_mux_47;
    wire signal_mux_48;
    wire signal_mux_49;
    wire [7:0] signal_select;
    wire [7:0] signal_const_38;
    wire signal_select_1;
    wire [7:0] signal_mux_50;
    wire [7:0] signal_select_2;
    wire signal_select_3;
    wire [7:0] signal_mux_51;
    wire [7:0] signal_select_4;
    wire signal_select_5;
    wire [7:0] signal_mux_52;
    wire [7:0] signal_select_6;
    wire signal_select_7;
    wire [7:0] signal_mux_53;
    wire [7:0] signal_select_8;
    wire signal_select_9;
    wire [7:0] signal_mux_54;
    wire [7:0] signal_select_10;
    wire signal_select_11;
    wire [7:0] signal_mux_55;
    wire [7:0] signal_select_12;
    wire signal_select_13;
    wire [7:0] signal_mux_56;
    wire [63:0] signal_select_14;
    wire [7:0] signal_select_15;
    wire signal_select_16;
    wire [7:0] signal_mux_57;
    wire [63:0] signal_cat;
    wire [63:0] signal_mux_58;
    wire [63:0] signal_mux_59;
    wire [7:0] signal_const_47;
    wire [7:0] signal_const_48;
    wire [7:0] signal_const_49;
    wire [7:0] signal_const_50;
    wire [7:0] signal_const_51;
    wire [7:0] signal_const_52;
    wire [7:0] signal_const_53;
    wire [7:0] signal_const_54;
    wire [3:0] signal_select_17;
    reg [7:0] signal_mux_60;
    wire [7:0] signal_mux_61;
    wire [7:0] signal_mux_62;
    wire signal_mux_63;
    wire signal_or_1;
    wire signal_mux_64;
    reg signal_reg;
    wire signal_wire;
    wire signal_not_1;
    wire signal_mux_65;
    wire signal_mux_66;
    wire signal_mux_67;
    wire signal_mux_68;
    wire [1:0] signal_select_18;
    wire [1:0] signal_select_19;
    wire [1:0] signal_mux_69;
    wire [1:0] signal_mux_70;
    wire [1:0] signal_mux_71;
    wire [63:0] signal_select_20;
    wire [63:0] signal_select_21;
    wire [63:0] signal_mux_72;
    wire [63:0] signal_mux_73;
    wire [63:0] signal_mux_74;
    wire signal_select_22;
    wire signal_select_23;
    wire signal_mux_75;
    wire signal_mux_76;
    wire signal_mux_77;
    wire [31:0] signal_select_24;
    wire [31:0] signal_select_25;
    wire [31:0] signal_mux_78;
    wire [31:0] signal_mux_79;
    wire [31:0] signal_mux_80;
    wire [63:0] signal_select_26;
    wire [63:0] signal_select_27;
    wire [63:0] signal_mux_81;
    wire [63:0] signal_mux_82;
    wire [63:0] signal_mux_83;
    wire signal_select_28;
    wire signal_select_29;
    wire signal_mux_84;
    wire signal_mux_85;
    wire signal_mux_86;
    wire signal_select_30;
    wire signal_select_31;
    wire signal_mux_87;
    wire signal_mux_88;
    wire signal_mux_89;
    wire [15:0] signal_select_32;
    wire [15:0] signal_select_33;
    wire [15:0] signal_mux_90;
    wire [15:0] signal_mux_91;
    wire [15:0] signal_mux_92;
    wire [15:0] signal_select_34;
    wire [15:0] signal_select_35;
    wire [15:0] signal_mux_93;
    wire [15:0] signal_mux_94;
    wire [15:0] signal_mux_95;
    wire [15:0] signal_select_36;
    wire [15:0] signal_select_37;
    wire [15:0] signal_mux_96;
    wire [15:0] signal_mux_97;
    wire [15:0] signal_mux_98;
    wire [15:0] signal_select_38;
    wire [15:0] signal_select_39;
    wire [15:0] signal_mux_99;
    wire [15:0] signal_mux_100;
    wire [15:0] signal_mux_101;
    wire [15:0] signal_select_40;
    wire [15:0] signal_select_41;
    wire [15:0] signal_mux_102;
    wire [15:0] signal_mux_103;
    wire [15:0] signal_mux_104;
    wire signal_select_42;
    wire signal_select_43;
    wire signal_mux_105;
    wire signal_mux_106;
    wire signal_mux_107;
    wire [63:0] signal_select_44;
    wire [63:0] signal_select_45;
    wire [63:0] signal_mux_108;
    wire [63:0] signal_mux_109;
    wire [63:0] signal_mux_110;
    wire signal_select_46;
    wire signal_select_47;
    wire signal_mux_111;
    wire signal_mux_112;
    wire signal_mux_113;
    wire [15:0] signal_select_48;
    wire [15:0] signal_mux_114;
    wire [15:0] signal_mux_115;
    wire [15:0] signal_mux_116;
    wire [15:0] signal_select_49;
    wire [15:0] signal_select_50;
    wire [15:0] signal_mux_117;
    wire [15:0] signal_mux_118;
    wire [15:0] signal_mux_119;
    wire [15:0] signal_select_51;
    wire [15:0] signal_select_52;
    wire [15:0] signal_mux_120;
    wire [15:0] signal_mux_121;
    wire [15:0] signal_mux_122;
    wire [31:0] signal_select_53;
    wire [31:0] signal_select_54;
    wire [31:0] signal_mux_123;
    wire [31:0] signal_mux_124;
    wire [31:0] signal_mux_125;
    wire [31:0] signal_select_55;
    wire [31:0] signal_select_56;
    wire [31:0] signal_mux_126;
    wire [31:0] signal_mux_127;
    wire [31:0] signal_mux_128;
    wire [63:0] signal_select_57;
    wire [63:0] signal_select_58;
    wire [63:0] signal_mux_129;
    wire [63:0] signal_mux_130;
    wire [63:0] signal_mux_131;
    wire signal_select_59;
    wire signal_select_60;
    wire signal_mux_132;
    wire signal_mux_133;
    wire signal_mux_134;
    wire [31:0] signal_select_61;
    wire [31:0] signal_select_62;
    wire [31:0] signal_mux_135;
    wire [31:0] signal_mux_136;
    wire [31:0] signal_mux_137;
    wire signal_select_63;
    wire signal_select_64;
    wire signal_mux_138;
    wire signal_mux_139;
    wire signal_mux_140;
    wire [31:0] signal_select_65;
    wire [31:0] signal_select_66;
    wire [31:0] signal_mux_141;
    wire [31:0] signal_mux_142;
    wire [31:0] signal_mux_143;
    wire signal_select_67;
    wire signal_select_68;
    wire signal_mux_144;
    wire signal_mux_145;
    wire signal_mux_146;
    wire [7:0] signal_select_69;
    wire [7:0] signal_select_70;
    wire [7:0] signal_mux_147;
    wire [7:0] signal_mux_148;
    wire [7:0] signal_mux_149;
    wire [7:0] signal_select_71;
    wire [7:0] signal_select_72;
    wire [7:0] signal_mux_150;
    wire [7:0] signal_mux_151;
    wire [7:0] signal_mux_152;
    wire [7:0] signal_select_73;
    wire [7:0] signal_select_74;
    wire [7:0] signal_mux_153;
    wire [7:0] signal_mux_154;
    wire [7:0] signal_mux_155;
    wire [31:0] signal_select_75;
    wire [31:0] signal_select_76;
    wire [31:0] signal_mux_156;
    wire [31:0] signal_mux_157;
    wire [31:0] signal_mux_158;
    wire signal_select_77;
    wire signal_select_78;
    wire signal_mux_159;
    wire signal_mux_160;
    wire signal_mux_161;
    wire [7:0] signal_select_79;
    wire [7:0] signal_select_80;
    wire [7:0] signal_mux_162;
    wire [7:0] signal_mux_163;
    wire [7:0] signal_mux_164;
    wire signal_select_81;
    wire signal_select_82;
    wire signal_mux_165;
    wire signal_mux_166;
    wire signal_mux_167;
    wire [7:0] signal_select_83;
    wire [7:0] signal_const_92;
    wire [7:0] signal_select_84;
    wire [7:0] signal_mux_168;
    wire [7:0] signal_mux_169;
    wire [7:0] signal_mux_170;
    wire [7:0] signal_mux_171;
    wire [31:0] signal_select_85;
    wire [31:0] signal_select_86;
    wire [31:0] signal_mux_172;
    wire [31:0] signal_mux_173;
    wire [31:0] signal_mux_174;
    wire signal_select_87;
    wire signal_select_88;
    wire signal_mux_175;
    wire signal_mux_176;
    wire signal_mux_177;
    wire [15:0] signal_select_89;
    wire [15:0] signal_const_96;
    wire [15:0] signal_select_90;
    wire [15:0] signal_add;
    wire [676:0] signal_const_97;
    wire [63:0] signal_select_91;
    wire signal_select_92;
    wire [31:0] signal_select_93;
    wire [63:0] signal_select_94;
    wire signal_select_95;
    wire [162:0] signal_const_99;
    wire [63:0] signal_select_96;
    wire signal_select_97;
    wire [31:0] signal_select_98;
    wire [63:0] signal_select_99;
    wire signal_select_100;
    wire signal_select_101;
    wire [162:0] signal_cat_1;
    reg [162:0] signal_reg_1;
    wire signal_select_102;
    wire [15:0] signal_select_103;
    wire [15:0] signal_mux_178;
    wire [15:0] signal_mux_179;
    wire [15:0] signal_select_104;
    wire [15:0] signal_mux_180;
    wire [15:0] signal_mux_181;
    wire [15:0] signal_select_105;
    wire [15:0] signal_mux_182;
    wire [15:0] signal_mux_183;
    wire [15:0] signal_select_106;
    wire [15:0] signal_mux_184;
    wire [15:0] signal_mux_185;
    wire [15:0] signal_select_107;
    wire [15:0] signal_mux_186;
    wire [15:0] signal_mux_187;
    wire signal_select_108;
    wire signal_mux_188;
    wire signal_mux_189;
    wire [63:0] signal_select_109;
    wire [63:0] signal_mux_190;
    wire [63:0] signal_mux_191;
    wire signal_select_110;
    wire signal_mux_192;
    wire signal_mux_193;
    wire [161:0] signal_const_109;
    wire [15:0] signal_select_111;
    wire [15:0] signal_select_112;
    wire [15:0] signal_select_113;
    wire [15:0] signal_select_114;
    wire [15:0] signal_mux_194;
    wire [65:0] signal_const_110;
    wire [161:0] signal_cat_2;
    reg [161:0] signal_reg_2;
    wire [15:0] signal_select_115;
    wire [15:0] signal_mux_195;
    wire [15:0] signal_mux_196;
    wire [292:0] signal_const_111;
    wire [7:0] signal_const_113;
    wire [7:0] signal_const_114;
    wire [7:0] signal_mux_197;
    wire [7:0] signal_mux_198;
    wire [7:0] signal_mux_199;
    wire [32:0] signal_const_116;
    wire [15:0] signal_const_117;
    wire signal_and_2;
    wire signal_or_2;
    wire [10:0] signal_const_119;
    wire [15:0] signal_cat_3;
    wire [15:0] signal_mux_200;
    wire [15:0] signal_const_121;
    wire [15:0] signal_add_1;
    wire [15:0] signal_add_2;
    reg [15:0] signal_reg_3;
    wire signal_or_3;
    wire [15:0] signal_mux_201;
    wire [15:0] signal_add_3;
    wire [15:0] signal_cat_4;
    wire [15:0] signal_add_4;
    wire [15:0] signal_add_5;
    wire [15:0] signal_mux_202;
    wire [15:0] signal_mux_203;
    wire [676:0] signal_cat_5;
    reg [676:0] signal_reg_4;
    wire [15:0] signal_select_116;
    wire [15:0] signal_mux_204;
    wire [15:0] signal_mux_205;
    wire [2:0] signal_const_125;
    wire signal_eq_1;
    wire [15:0] signal_mux_206;
    wire [2:0] signal_const_126;
    wire signal_eq_2;
    wire signal_or_4;
    wire [15:0] signal_mux_207;
    wire [1078:0] signal_cat_6;
    wire signal_not_2;
    wire signal_and_3;
    wire signal_or_5;
    wire signal_and_4;
    wire WRITE_ADDRESS_NEXT;
    (* extract_reset="FALSE" *)
    reg WRITE_ADDRESS;
    wire signal_wire_1;
    (* RAM_STYLE="distributed" *)
    reg [1078:0] signal_multiport_mem[0:1];
    wire vdd;
    wire READ_ADDRESS_NEXT;
    (* extract_reset="FALSE" *)
    reg READ_ADDRESS;
    wire signal_wire_2;
    wire signal_xor;
    wire signal_lt;
    reg used_gt_one;
    wire signal_and_5;
    wire RA;
    reg signal_reg_5;
    wire [1078:0] memory;
    wire [1078:0] ram_wbr_data;
    wire signal_xor_1;
    wire signal_eq_3;
    reg used_is_one;
    wire signal_and_6;
    wire signal_and_7;
    wire signal_and_8;
    wire bypass_cond;
    wire [1078:0] signal_mux_208;
    reg [1078:0] signal_reg_6;
    wire signal_not_3;
    wire signal_and_9;
    wire signal_and_10;
    wire signal_or_6;
    wire signal_mux_209;
    wire signal_select_117;
    wire signal_not_4;
    wire signal_and_11;
    wire [2:0] signal_const_133;
    wire [2:0] signal_const_136;
    wire [2:0] signal_const_137;
    wire [2:0] signal_mux_210;
    wire [2:0] signal_const_139;
    wire signal_eq_4;
    wire [2:0] signal_mux_211;
    wire [2:0] signal_mux_212;
    wire [2:0] signal_mux_213;
    wire [2:0] signal_mux_214;
    wire signal_eq_5;
    wire [2:0] signal_mux_215;
    wire [2:0] signal_mux_216;
    wire [2:0] signal_const_150;
    wire signal_lt_1;
    wire signal_not_5;
    wire signal_and_12;
    wire [2:0] signal_mux_217;
    wire [2:0] signal_const_155;
    wire signal_eq_6;
    wire [2:0] signal_mux_218;
    wire [2:0] signal_mux_219;
    wire signal_or_7;
    wire [2:0] signal_mux_220;
    wire [2:0] signal_mux_221;
    reg [2:0] signal_reg_7;
    wire gnd;
    wire signal_not_6;
    wire signal_and_13;
    wire signal_mux_222;
    wire signal_mux_223;
    reg signal_reg_8;
    wire signal_wire_3;
    wire signal_not_7;
    wire signal_and_14;
    reg signal_reg_9;
    wire signal_and_15;
    wire [2:0] signal_mux_224;
    wire [4:0] signal_const_160;
    wire signal_lt_2;
    wire signal_not_8;
    wire signal_and_16;
    wire signal_and_17;
    wire [2:0] signal_mux_225;
    wire signal_eq_7;
    wire signal_and_18;
    wire signal_and_19;
    wire [2:0] signal_mux_226;
    wire signal_eq_8;
    wire signal_and_20;
    wire [2:0] signal_mux_227;
    wire signal_and_21;
    wire [2:0] signal_mux_228;
    wire [2:0] signal_mux_229;
    wire [2:0] signal_mux_230;
    wire signal_lt_3;
    wire [4:0] signal_const_164;
    wire [4:0] signal_add_6;
    wire [4:0] signal_mux_231;
    wire [4:0] signal_mux_232;
    wire signal_eq_9;
    wire signal_and_22;
    wire signal_not_9;
    wire signal_and_23;
    wire signal_and_24;
    wire signal_and_25;
    wire [15:0] signal_const_166;
    wire [15:0] signal_select_118;
    wire signal_eq_10;
    wire signal_not_10;
    wire signal_not_11;
    wire signal_and_26;
    wire signal_and_27;
    wire signal_lt_4;
    wire signal_and_28;
    wire signal_eq_11;
    wire signal_and_29;
    wire signal_and_30;
    wire signal_lt_5;
    wire signal_or_8;
    wire signal_lt_6;
    wire signal_not_12;
    wire signal_or_9;
    wire [4:0] signal_mux_233;
    wire [4:0] signal_add_7;
    wire [4:0] signal_const_171;
    wire [4:0] signal_mux_234;
    wire [4:0] signal_mux_235;
    wire signal_lt_7;
    wire [4:0] signal_mux_236;
    wire signal_lt_8;
    wire [4:0] signal_mux_237;
    wire [4:0] signal_mux_238;
    wire [4:0] signal_mux_239;
    wire [4:0] signal_mux_240;
    wire [3:0] signal_select_119;
    wire [3:0] phase6_iterator_count;
    wire signal_eq_12;
    wire signal_and_31;
    wire signal_or_10;
    wire signal_or_11;
    wire phase6_iterator_consume;
    wire signal_and_32;
    wire signal_and_33;
    wire signal_or_12;
    wire signal_not_13;
    wire signal_or_13;
    wire signal_and_34;
    wire signal_and_35;
    wire signal_and_36;
    wire signal_and_37;
    wire signal_or_14;
    wire signal_mux_241;
    reg signal_reg_10;
    wire signal_wire_4;
    wire signal_not_14;
    wire signal_not_15;
    wire signal_and_38;
    wire signal_not_16;
    wire signal_lt_9;
    wire signal_not_17;
    wire signal_not_18;
    wire signal_and_39;
    wire signal_and_40;
    wire signal_and_41;
    wire [1:0] signal_const_179;
    wire [1:0] signal_sub;
    reg [1:0] USED_MINUS_1 = 2'b11;
    wire [1:0] signal_wire_5;
    wire [1:0] signal_add_8;
    reg [1:0] USED_PLUS_1 = 2'b01;
    wire [1:0] signal_wire_6;
    wire [1:0] signal_mux_242;
    reg [1:0] USED;
    wire [1:0] signal_wire_7;
    wire signal_eq_13;
    wire signal_eq_14;
    wire signal_eq_15;
    wire signal_and_42;
    wire signal_and_43;
    wire signal_or_15;
    wire signal_or_16;
    wire signal_or_17;
    wire signal_and_44;
    wire signal_and_45;
    wire signal_wire_8;
    wire signal_wire_9;
    wire signal_eq_16;
    wire signal_not_19;
    reg not_empty;
    wire signal_wire_10;
    wire signal_not_20;
    wire signal_not_21;
    wire signal_and_46;
    wire signal_and_47;
    wire signal_wire_11;
    wire signal_xor_2;
    wire [1:0] USED_NEXT;
    wire signal_eq_17;
    reg full;
    wire signal_wire_12;
    wire signal_not_22;
    wire signal_not_23;
    wire signal_and_48;
    wire signal_and_49;
    wire phase6_iterator_ready;
    wire signal_lt_10;
    wire signal_not_24;
    wire signal_and_50;
    wire signal_or_18;
    wire [63:0] signal_select_120;
    reg [63:0] signal_reg_11;
    wire [71:0] signal_select_121;
    wire [55:0] signal_const_193;
    wire [127:0] signal_cat_7;
    wire [79:0] signal_select_122;
    wire [47:0] signal_const_194;
    wire [127:0] signal_cat_8;
    wire [87:0] signal_select_123;
    wire [39:0] signal_const_195;
    wire [127:0] signal_cat_9;
    wire [95:0] signal_select_124;
    wire [127:0] signal_cat_10;
    wire [103:0] signal_select_125;
    wire [23:0] signal_const_197;
    wire [127:0] signal_cat_11;
    wire [111:0] signal_select_126;
    wire [127:0] signal_cat_12;
    wire [119:0] signal_select_127;
    wire [127:0] signal_cat_13;
    wire [2:0] signal_select_128;
    reg [127:0] signal_mux_243;
    wire [127:0] signal_select_129;
    wire [4:0] signal_add_9;
    wire signal_eq_18;
    wire signal_and_51;
    wire signal_not_25;
    wire [4:0] signal_add_10;
    wire signal_lt_11;
    wire signal_not_26;
    wire [4:0] signal_const_202;
    wire signal_lt_12;
    wire signal_not_27;
    wire signal_not_28;
    wire signal_not_29;
    wire signal_and_52;
    wire signal_and_53;
    wire signal_and_54;
    wire signal_and_55;
    wire signal_and_56;
    wire signal_and_57;
    wire signal_wire_13;
    wire signal_or_19;
    wire [127:0] signal_mux_244;
    wire [63:0] signal_select_130;
    wire [63:0] signal_mux_245;
    wire [15:0] signal_select_131;
    wire [15:0] signal_sub_1;
    wire [15:0] signal_cat_14;
    wire [15:0] signal_sub_2;
    wire [15:0] signal_mux_246;
    wire [4:0] signal_add_11;
    wire signal_lt_13;
    wire signal_not_30;
    wire [4:0] signal_const_205;
    wire signal_lt_14;
    wire signal_not_31;
    wire [4:0] signal_select_132;
    wire [15:0] signal_const_207;
    wire signal_lt_15;
    wire [4:0] signal_mux_247;
    wire signal_eq_19;
    wire signal_and_58;
    wire signal_not_32;
    wire signal_lt_16;
    wire signal_not_33;
    wire signal_and_59;
    wire signal_and_60;
    wire signal_and_61;
    wire signal_and_62;
    wire signal_wire_14;
    wire signal_not_34;
    wire [15:0] phase6_iterator_offset;
    wire [2:0] signal_select_133;
    wire signal_eq_20;
    wire signal_and_63;
    wire signal_not_35;
    wire signal_and_64;
    wire signal_and_65;
    wire phase6_iterator_prefix;
    wire [15:0] signal_mux_248;
    reg [15:0] signal_reg_12;
    wire [15:0] signal_wire_15;
    wire [4:0] phase6_iterator_available;
    wire [15:0] signal_cat_15;
    wire signal_lt_17;
    wire signal_select_134;
    wire signal_eq_21;
    wire signal_or_20;
    wire signal_and_66;
    wire signal_and_67;
    wire signal_and_68;
    wire signal_not_36;
    wire signal_eq_22;
    wire signal_and_69;
    wire signal_and_70;
    wire signal_and_71;
    wire phase6_iterator_body;
    wire signal_or_21;
    wire signal_and_72;
    wire signal_and_73;
    wire signal_wire_16;
    wire signal_and_74;
    wire signal_and_75;
    wire signal_select_135;
    wire signal_not_37;
    wire [1:0] signal_select_136;
    wire signal_eq_23;
    wire signal_and_76;
    wire signal_and_77;
    wire signal_or_22;
    wire signal_or_23;
    wire signal_wire_17;
    wire signal_and_78;
    wire signal_select_137;
    wire signal_select_138;
    wire [7:0] signal_select_139;
    wire [916:0] signal_wire_18;
    wire [63:0] signal_select_140;
    wire signal_wire_19;
    wire [217:0] signal_inst;
    wire signal_select_141;
    wire signal_eq_24;
    wire signal_eq_25;
    wire signal_or_24;
    wire signal_and_79;
    wire signal_and_80;
    wire signal_and_81;
    wire signal_or_25;
    wire signal_or_26;
    wire signal_or_27;
    wire signal_or_28;
    wire [2:0] signal_mux_249;
    reg [2:0] signal_reg_13;
    wire [2:0] phase6_iterator_state;
    wire signal_eq_26;
    wire signal_or_29;
    wire signal_mux_250;
    wire signal_wire_20;
    wire signal_not_38;
    wire signal_wire_21;
    wire signal_and_82;
    wire signal_and_83;
    assign signal_not = ~ signal_and_9;
    assign signal_const = 5'b00000;
    assign signal_eq = phase6_iterator_available == signal_const;
    assign signal_and = signal_eq_26 & signal_eq;
    assign signal_and_1 = signal_and & signal_not;
    assign signal_or = bypass_cond | signal_wire_11;
    assign signal_const_1 = 1079'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_const_2 = 2'b10;
    assign signal_const_3 = 2'b00;
    assign signal_const_4 = 2'b01;
    assign signal_mux = signal_wire ? signal_const_4 : signal_const_3;
    assign signal_mux_1 = signal_eq_1 ? signal_const_3 : signal_mux;
    assign signal_mux_2 = signal_or_4 ? signal_const_2 : signal_mux_1;
    assign signal_const_6 = 64'b0000000000000000000000000000000000000000000000000000000000000000;
    assign signal_mux_3 = signal_wire ? signal_const_6 : signal_select_91;
    assign signal_mux_4 = signal_eq_1 ? signal_select_91 : signal_mux_3;
    assign signal_mux_5 = signal_or_4 ? signal_const_6 : signal_mux_4;
    assign signal_const_8 = 1'b0;
    assign signal_mux_6 = signal_wire ? signal_const_8 : signal_select_92;
    assign signal_mux_7 = signal_eq_1 ? signal_select_92 : signal_mux_6;
    assign signal_mux_8 = signal_or_4 ? signal_const_8 : signal_mux_7;
    assign signal_const_10 = 32'b00000000000000000000000000000000;
    assign signal_mux_9 = signal_wire ? signal_const_10 : signal_select_93;
    assign signal_mux_10 = signal_eq_1 ? signal_select_93 : signal_mux_9;
    assign signal_mux_11 = signal_or_4 ? signal_const_10 : signal_mux_10;
    assign signal_mux_12 = signal_wire ? signal_const_6 : signal_select_94;
    assign signal_mux_13 = signal_eq_1 ? signal_select_94 : signal_mux_12;
    assign signal_mux_14 = signal_or_4 ? signal_const_6 : signal_mux_13;
    assign signal_mux_15 = signal_wire ? signal_const_8 : signal_select_95;
    assign signal_mux_16 = signal_eq_1 ? signal_select_95 : signal_mux_15;
    assign signal_mux_17 = signal_or_4 ? signal_const_8 : signal_mux_16;
    assign signal_mux_18 = signal_wire ? signal_const_8 : signal_select_102;
    assign signal_mux_19 = signal_eq_1 ? signal_select_102 : signal_mux_18;
    assign signal_mux_20 = signal_or_4 ? signal_const_8 : signal_mux_19;
    assign signal_const_18 = 16'b0000000000000000;
    assign signal_mux_21 = signal_wire ? signal_const_18 : signal_select_103;
    assign signal_mux_22 = signal_eq_1 ? signal_select_103 : signal_mux_21;
    assign signal_mux_23 = signal_or_4 ? signal_const_18 : signal_mux_22;
    assign signal_mux_24 = signal_wire ? signal_const_18 : signal_select_104;
    assign signal_mux_25 = signal_eq_1 ? signal_select_104 : signal_mux_24;
    assign signal_mux_26 = signal_or_4 ? signal_const_18 : signal_mux_25;
    assign signal_mux_27 = signal_wire ? signal_const_18 : signal_select_105;
    assign signal_mux_28 = signal_eq_1 ? signal_select_105 : signal_mux_27;
    assign signal_mux_29 = signal_or_4 ? signal_const_18 : signal_mux_28;
    assign signal_mux_30 = signal_wire ? signal_const_18 : signal_select_106;
    assign signal_mux_31 = signal_eq_1 ? signal_select_106 : signal_mux_30;
    assign signal_mux_32 = signal_or_4 ? signal_const_18 : signal_mux_31;
    assign signal_mux_33 = signal_wire ? signal_const_18 : signal_select_107;
    assign signal_mux_34 = signal_eq_1 ? signal_select_107 : signal_mux_33;
    assign signal_mux_35 = signal_or_4 ? signal_const_18 : signal_mux_34;
    assign signal_mux_36 = signal_wire ? signal_const_8 : signal_select_108;
    assign signal_mux_37 = signal_eq_1 ? signal_select_108 : signal_mux_36;
    assign signal_mux_38 = signal_or_4 ? signal_const_8 : signal_mux_37;
    assign signal_mux_39 = signal_wire ? signal_const_6 : signal_select_109;
    assign signal_mux_40 = signal_eq_1 ? signal_select_109 : signal_mux_39;
    assign signal_mux_41 = signal_or_4 ? signal_const_6 : signal_mux_40;
    assign signal_mux_42 = signal_wire ? signal_const_8 : signal_select_110;
    assign signal_mux_43 = signal_eq_1 ? signal_select_110 : signal_mux_42;
    assign signal_mux_44 = signal_or_4 ? signal_const_8 : signal_mux_43;
    assign signal_mux_45 = signal_wire ? signal_const_18 : signal_select_115;
    assign signal_mux_46 = signal_eq_1 ? signal_select_115 : signal_mux_45;
    assign signal_mux_47 = signal_or_4 ? signal_const_18 : signal_mux_46;
    assign signal_mux_48 = signal_eq_1 ? vdd : signal_const_8;
    assign signal_mux_49 = signal_or_4 ? signal_const_8 : signal_mux_48;
    assign signal_select = signal_select_14[7:0];
    assign signal_const_38 = 8'b00000000;
    assign signal_select_1 = signal_mux_60[0:0];
    assign signal_mux_50 = signal_select_1 ? signal_select : signal_const_38;
    assign signal_select_2 = signal_select_14[15:8];
    assign signal_select_3 = signal_mux_60[1:1];
    assign signal_mux_51 = signal_select_3 ? signal_select_2 : signal_const_38;
    assign signal_select_4 = signal_select_14[23:16];
    assign signal_select_5 = signal_mux_60[2:2];
    assign signal_mux_52 = signal_select_5 ? signal_select_4 : signal_const_38;
    assign signal_select_6 = signal_select_14[31:24];
    assign signal_select_7 = signal_mux_60[3:3];
    assign signal_mux_53 = signal_select_7 ? signal_select_6 : signal_const_38;
    assign signal_select_8 = signal_select_14[39:32];
    assign signal_select_9 = signal_mux_60[4:4];
    assign signal_mux_54 = signal_select_9 ? signal_select_8 : signal_const_38;
    assign signal_select_10 = signal_select_14[47:40];
    assign signal_select_11 = signal_mux_60[5:5];
    assign signal_mux_55 = signal_select_11 ? signal_select_10 : signal_const_38;
    assign signal_select_12 = signal_select_14[55:48];
    assign signal_select_13 = signal_mux_60[6:6];
    assign signal_mux_56 = signal_select_13 ? signal_select_12 : signal_const_38;
    assign signal_select_14 = signal_select_129[63:0];
    assign signal_select_15 = signal_select_14[63:56];
    assign signal_select_16 = signal_mux_60[7:7];
    assign signal_mux_57 = signal_select_16 ? signal_select_15 : signal_const_38;
    assign signal_cat = { signal_mux_57,
                          signal_mux_56,
                          signal_mux_55,
                          signal_mux_54,
                          signal_mux_53,
                          signal_mux_52,
                          signal_mux_51,
                          signal_mux_50 };
    assign signal_mux_58 = signal_eq_1 ? signal_const_6 : signal_cat;
    assign signal_mux_59 = signal_or_4 ? signal_const_6 : signal_mux_58;
    assign signal_const_47 = 8'b11111111;
    assign signal_const_48 = 8'b01111111;
    assign signal_const_49 = 8'b00111111;
    assign signal_const_50 = 8'b00011111;
    assign signal_const_51 = 8'b00001111;
    assign signal_const_52 = 8'b00000111;
    assign signal_const_53 = 8'b00000011;
    assign signal_const_54 = 8'b00000001;
    assign signal_select_17 = signal_mux_247[3:0];
    always @* begin
        case (signal_select_17)
        0:
            signal_mux_60 <= signal_const_38;
        1:
            signal_mux_60 <= signal_const_54;
        2:
            signal_mux_60 <= signal_const_53;
        3:
            signal_mux_60 <= signal_const_52;
        4:
            signal_mux_60 <= signal_const_51;
        5:
            signal_mux_60 <= signal_const_50;
        6:
            signal_mux_60 <= signal_const_49;
        7:
            signal_mux_60 <= signal_const_48;
        default:
            signal_mux_60 <= signal_const_47;
        endcase
    end
    assign signal_mux_61 = signal_eq_1 ? signal_const_38 : signal_mux_60;
    assign signal_mux_62 = signal_or_4 ? signal_const_38 : signal_mux_61;
    assign signal_mux_63 = phase6_iterator_body ? vdd : signal_wire;
    assign signal_or_1 = signal_or_24 | signal_or_19;
    assign signal_mux_64 = signal_or_1 ? gnd : signal_mux_63;
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            signal_reg <= signal_const_8;
        else
            if (signal_and_82)
                signal_reg <= signal_mux_64;
    end
    assign signal_wire = signal_reg;
    assign signal_not_1 = ~ signal_wire;
    assign signal_mux_65 = signal_eq_1 ? signal_const_8 : signal_not_1;
    assign signal_mux_66 = signal_or_4 ? signal_const_8 : signal_mux_65;
    assign signal_mux_67 = signal_eq_1 ? signal_const_8 : signal_not_33;
    assign signal_mux_68 = signal_or_4 ? signal_const_8 : signal_mux_67;
    assign signal_select_18 = signal_wire_18[241:240];
    assign signal_select_19 = signal_reg_4[1:0];
    assign signal_mux_69 = signal_eq_26 ? signal_select_18 : signal_select_19;
    assign signal_mux_70 = signal_eq_1 ? signal_const_3 : signal_const_3;
    assign signal_mux_71 = signal_or_4 ? signal_mux_69 : signal_mux_70;
    assign signal_select_20 = signal_wire_18[305:242];
    assign signal_select_21 = signal_reg_4[65:2];
    assign signal_mux_72 = signal_eq_26 ? signal_select_20 : signal_select_21;
    assign signal_mux_73 = signal_eq_1 ? signal_const_6 : signal_const_6;
    assign signal_mux_74 = signal_or_4 ? signal_mux_72 : signal_mux_73;
    assign signal_select_22 = signal_wire_18[306:306];
    assign signal_select_23 = signal_reg_4[66:66];
    assign signal_mux_75 = signal_eq_26 ? signal_select_22 : signal_select_23;
    assign signal_mux_76 = signal_eq_1 ? signal_const_8 : signal_const_8;
    assign signal_mux_77 = signal_or_4 ? signal_mux_75 : signal_mux_76;
    assign signal_select_24 = signal_wire_18[338:307];
    assign signal_select_25 = signal_reg_4[98:67];
    assign signal_mux_78 = signal_eq_26 ? signal_select_24 : signal_select_25;
    assign signal_mux_79 = signal_eq_1 ? signal_const_10 : signal_const_10;
    assign signal_mux_80 = signal_or_4 ? signal_mux_78 : signal_mux_79;
    assign signal_select_26 = signal_wire_18[402:339];
    assign signal_select_27 = signal_reg_4[162:99];
    assign signal_mux_81 = signal_eq_26 ? signal_select_26 : signal_select_27;
    assign signal_mux_82 = signal_eq_1 ? signal_const_6 : signal_const_6;
    assign signal_mux_83 = signal_or_4 ? signal_mux_81 : signal_mux_82;
    assign signal_select_28 = signal_wire_18[403:403];
    assign signal_select_29 = signal_reg_4[163:163];
    assign signal_mux_84 = signal_eq_26 ? signal_select_28 : signal_select_29;
    assign signal_mux_85 = signal_eq_1 ? signal_const_8 : signal_const_8;
    assign signal_mux_86 = signal_or_4 ? signal_mux_84 : signal_mux_85;
    assign signal_select_30 = signal_wire_18[404:404];
    assign signal_select_31 = signal_reg_4[164:164];
    assign signal_mux_87 = signal_eq_26 ? signal_select_30 : signal_select_31;
    assign signal_mux_88 = signal_eq_1 ? signal_const_8 : signal_const_8;
    assign signal_mux_89 = signal_or_4 ? signal_mux_87 : signal_mux_88;
    assign signal_select_32 = signal_wire_18[420:405];
    assign signal_select_33 = signal_reg_4[180:165];
    assign signal_mux_90 = signal_eq_26 ? signal_select_32 : signal_select_33;
    assign signal_mux_91 = signal_eq_1 ? signal_const_18 : signal_const_18;
    assign signal_mux_92 = signal_or_4 ? signal_mux_90 : signal_mux_91;
    assign signal_select_34 = signal_wire_18[436:421];
    assign signal_select_35 = signal_reg_4[196:181];
    assign signal_mux_93 = signal_eq_26 ? signal_select_34 : signal_select_35;
    assign signal_mux_94 = signal_eq_1 ? signal_const_18 : signal_const_18;
    assign signal_mux_95 = signal_or_4 ? signal_mux_93 : signal_mux_94;
    assign signal_select_36 = signal_wire_18[452:437];
    assign signal_select_37 = signal_reg_4[212:197];
    assign signal_mux_96 = signal_eq_26 ? signal_select_36 : signal_select_37;
    assign signal_mux_97 = signal_eq_1 ? signal_const_18 : signal_const_18;
    assign signal_mux_98 = signal_or_4 ? signal_mux_96 : signal_mux_97;
    assign signal_select_38 = signal_wire_18[468:453];
    assign signal_select_39 = signal_reg_4[228:213];
    assign signal_mux_99 = signal_eq_26 ? signal_select_38 : signal_select_39;
    assign signal_mux_100 = signal_eq_1 ? signal_const_18 : signal_const_18;
    assign signal_mux_101 = signal_or_4 ? signal_mux_99 : signal_mux_100;
    assign signal_select_40 = signal_wire_18[484:469];
    assign signal_select_41 = signal_reg_4[244:229];
    assign signal_mux_102 = signal_eq_26 ? signal_select_40 : signal_select_41;
    assign signal_mux_103 = signal_eq_1 ? signal_const_18 : signal_const_18;
    assign signal_mux_104 = signal_or_4 ? signal_mux_102 : signal_mux_103;
    assign signal_select_42 = signal_wire_18[485:485];
    assign signal_select_43 = signal_reg_4[245:245];
    assign signal_mux_105 = signal_eq_26 ? signal_select_42 : signal_select_43;
    assign signal_mux_106 = signal_eq_1 ? signal_const_8 : signal_const_8;
    assign signal_mux_107 = signal_or_4 ? signal_mux_105 : signal_mux_106;
    assign signal_select_44 = signal_wire_18[549:486];
    assign signal_select_45 = signal_reg_4[309:246];
    assign signal_mux_108 = signal_eq_26 ? signal_select_44 : signal_select_45;
    assign signal_mux_109 = signal_eq_1 ? signal_const_6 : signal_const_6;
    assign signal_mux_110 = signal_or_4 ? signal_mux_108 : signal_mux_109;
    assign signal_select_46 = signal_wire_18[550:550];
    assign signal_select_47 = signal_reg_4[310:310];
    assign signal_mux_111 = signal_eq_26 ? signal_select_46 : signal_select_47;
    assign signal_mux_112 = signal_eq_1 ? signal_const_8 : signal_const_8;
    assign signal_mux_113 = signal_or_4 ? signal_mux_111 : signal_mux_112;
    assign signal_select_48 = signal_wire_18[566:551];
    assign signal_mux_114 = signal_eq_26 ? signal_select_48 : signal_select_90;
    assign signal_mux_115 = signal_eq_1 ? signal_const_18 : signal_const_18;
    assign signal_mux_116 = signal_or_4 ? signal_mux_114 : signal_mux_115;
    assign signal_select_49 = signal_wire_18[582:567];
    assign signal_select_50 = signal_reg_4[342:327];
    assign signal_mux_117 = signal_eq_26 ? signal_select_49 : signal_select_50;
    assign signal_mux_118 = signal_eq_1 ? signal_const_18 : signal_const_18;
    assign signal_mux_119 = signal_or_4 ? signal_mux_117 : signal_mux_118;
    assign signal_select_51 = signal_wire_18[598:583];
    assign signal_select_52 = signal_reg_4[358:343];
    assign signal_mux_120 = signal_eq_26 ? signal_select_51 : signal_select_52;
    assign signal_mux_121 = signal_eq_1 ? signal_const_18 : signal_const_18;
    assign signal_mux_122 = signal_or_4 ? signal_mux_120 : signal_mux_121;
    assign signal_select_53 = signal_wire_18[630:599];
    assign signal_select_54 = signal_reg_4[390:359];
    assign signal_mux_123 = signal_eq_26 ? signal_select_53 : signal_select_54;
    assign signal_mux_124 = signal_eq_1 ? signal_const_10 : signal_const_10;
    assign signal_mux_125 = signal_or_4 ? signal_mux_123 : signal_mux_124;
    assign signal_select_55 = signal_wire_18[662:631];
    assign signal_select_56 = signal_reg_4[422:391];
    assign signal_mux_126 = signal_eq_26 ? signal_select_55 : signal_select_56;
    assign signal_mux_127 = signal_eq_1 ? signal_const_10 : signal_const_10;
    assign signal_mux_128 = signal_or_4 ? signal_mux_126 : signal_mux_127;
    assign signal_select_57 = signal_wire_18[726:663];
    assign signal_select_58 = signal_reg_4[486:423];
    assign signal_mux_129 = signal_eq_26 ? signal_select_57 : signal_select_58;
    assign signal_mux_130 = signal_eq_1 ? signal_const_6 : signal_const_6;
    assign signal_mux_131 = signal_or_4 ? signal_mux_129 : signal_mux_130;
    assign signal_select_59 = signal_wire_18[727:727];
    assign signal_select_60 = signal_reg_4[487:487];
    assign signal_mux_132 = signal_eq_26 ? signal_select_59 : signal_select_60;
    assign signal_mux_133 = signal_eq_1 ? signal_const_8 : signal_const_8;
    assign signal_mux_134 = signal_or_4 ? signal_mux_132 : signal_mux_133;
    assign signal_select_61 = signal_wire_18[759:728];
    assign signal_select_62 = signal_reg_4[519:488];
    assign signal_mux_135 = signal_eq_26 ? signal_select_61 : signal_select_62;
    assign signal_mux_136 = signal_eq_1 ? signal_const_10 : signal_const_10;
    assign signal_mux_137 = signal_or_4 ? signal_mux_135 : signal_mux_136;
    assign signal_select_63 = signal_wire_18[760:760];
    assign signal_select_64 = signal_reg_4[520:520];
    assign signal_mux_138 = signal_eq_26 ? signal_select_63 : signal_select_64;
    assign signal_mux_139 = signal_eq_1 ? signal_const_8 : signal_const_8;
    assign signal_mux_140 = signal_or_4 ? signal_mux_138 : signal_mux_139;
    assign signal_select_65 = signal_wire_18[792:761];
    assign signal_select_66 = signal_reg_4[552:521];
    assign signal_mux_141 = signal_eq_26 ? signal_select_65 : signal_select_66;
    assign signal_mux_142 = signal_eq_1 ? signal_const_10 : signal_const_10;
    assign signal_mux_143 = signal_or_4 ? signal_mux_141 : signal_mux_142;
    assign signal_select_67 = signal_wire_18[793:793];
    assign signal_select_68 = signal_reg_4[553:553];
    assign signal_mux_144 = signal_eq_26 ? signal_select_67 : signal_select_68;
    assign signal_mux_145 = signal_eq_1 ? signal_const_8 : signal_const_8;
    assign signal_mux_146 = signal_or_4 ? signal_mux_144 : signal_mux_145;
    assign signal_select_69 = signal_wire_18[801:794];
    assign signal_select_70 = signal_reg_4[561:554];
    assign signal_mux_147 = signal_eq_26 ? signal_select_69 : signal_select_70;
    assign signal_mux_148 = signal_eq_1 ? signal_const_38 : signal_const_38;
    assign signal_mux_149 = signal_or_4 ? signal_mux_147 : signal_mux_148;
    assign signal_select_71 = signal_wire_18[809:802];
    assign signal_select_72 = signal_reg_4[569:562];
    assign signal_mux_150 = signal_eq_26 ? signal_select_71 : signal_select_72;
    assign signal_mux_151 = signal_eq_1 ? signal_const_38 : signal_const_38;
    assign signal_mux_152 = signal_or_4 ? signal_mux_150 : signal_mux_151;
    assign signal_select_73 = signal_wire_18[817:810];
    assign signal_select_74 = signal_reg_4[577:570];
    assign signal_mux_153 = signal_eq_26 ? signal_select_73 : signal_select_74;
    assign signal_mux_154 = signal_eq_1 ? signal_const_38 : signal_const_38;
    assign signal_mux_155 = signal_or_4 ? signal_mux_153 : signal_mux_154;
    assign signal_select_75 = signal_wire_18[849:818];
    assign signal_select_76 = signal_reg_4[609:578];
    assign signal_mux_156 = signal_eq_26 ? signal_select_75 : signal_select_76;
    assign signal_mux_157 = signal_eq_1 ? signal_const_10 : signal_const_10;
    assign signal_mux_158 = signal_or_4 ? signal_mux_156 : signal_mux_157;
    assign signal_select_77 = signal_wire_18[850:850];
    assign signal_select_78 = signal_reg_4[610:610];
    assign signal_mux_159 = signal_eq_26 ? signal_select_77 : signal_select_78;
    assign signal_mux_160 = signal_eq_1 ? signal_const_8 : signal_const_8;
    assign signal_mux_161 = signal_or_4 ? signal_mux_159 : signal_mux_160;
    assign signal_select_79 = signal_wire_18[858:851];
    assign signal_select_80 = signal_reg_4[618:611];
    assign signal_mux_162 = signal_eq_26 ? signal_select_79 : signal_select_80;
    assign signal_mux_163 = signal_eq_1 ? signal_const_38 : signal_const_38;
    assign signal_mux_164 = signal_or_4 ? signal_mux_162 : signal_mux_163;
    assign signal_select_81 = signal_wire_18[859:859];
    assign signal_select_82 = signal_reg_4[619:619];
    assign signal_mux_165 = signal_eq_26 ? signal_select_81 : signal_select_82;
    assign signal_mux_166 = signal_eq_1 ? signal_const_8 : signal_const_8;
    assign signal_mux_167 = signal_or_4 ? signal_mux_165 : signal_mux_166;
    assign signal_select_83 = signal_wire_18[867:860];
    assign signal_const_92 = 8'b00000101;
    assign signal_select_84 = signal_reg_4[627:620];
    assign signal_mux_168 = signal_wire_3 ? signal_const_92 : signal_select_84;
    assign signal_mux_169 = signal_eq_26 ? signal_select_83 : signal_mux_168;
    assign signal_mux_170 = signal_eq_1 ? signal_const_38 : signal_const_38;
    assign signal_mux_171 = signal_or_4 ? signal_mux_169 : signal_mux_170;
    assign signal_select_85 = signal_wire_18[899:868];
    assign signal_select_86 = signal_reg_4[659:628];
    assign signal_mux_172 = signal_eq_26 ? signal_select_85 : signal_select_86;
    assign signal_mux_173 = signal_eq_1 ? signal_const_10 : signal_const_10;
    assign signal_mux_174 = signal_or_4 ? signal_mux_172 : signal_mux_173;
    assign signal_select_87 = signal_wire_18[900:900];
    assign signal_select_88 = signal_reg_4[660:660];
    assign signal_mux_175 = signal_eq_26 ? signal_select_87 : signal_select_88;
    assign signal_mux_176 = signal_eq_1 ? signal_const_8 : signal_const_8;
    assign signal_mux_177 = signal_or_4 ? signal_mux_175 : signal_mux_176;
    assign signal_select_89 = signal_wire_18[916:901];
    assign signal_const_96 = 16'b0000000000001010;
    assign signal_select_90 = signal_reg_4[326:311];
    assign signal_add = signal_select_90 + signal_const_96;
    assign signal_const_97 = 677'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_select_91 = signal_reg_1[63:0];
    assign signal_select_92 = signal_reg_1[64:64];
    assign signal_select_93 = signal_reg_1[96:65];
    assign signal_select_94 = signal_reg_1[160:97];
    assign signal_select_95 = signal_reg_1[161:161];
    assign signal_const_99 = 163'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_select_96 = signal_wire_18[65:2];
    assign signal_select_97 = signal_wire_18[66:66];
    assign signal_select_98 = signal_wire_18[98:67];
    assign signal_select_99 = signal_wire_18[162:99];
    assign signal_select_100 = signal_wire_18[163:163];
    assign signal_select_101 = signal_wire_18[164:164];
    assign signal_cat_1 = { signal_select_101,
                            signal_select_100,
                            signal_select_99,
                            signal_select_98,
                            signal_select_97,
                            signal_select_96 };
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            signal_reg_1 <= signal_const_99;
        else
            if (signal_and_37)
                signal_reg_1 <= signal_cat_1;
    end
    assign signal_select_102 = signal_reg_1[162:162];
    assign signal_select_103 = signal_reg_2[15:0];
    assign signal_mux_178 = phase6_iterator_prefix ? signal_select_131 : signal_select_103;
    assign signal_mux_179 = signal_and_81 ? signal_const_18 : signal_mux_178;
    assign signal_select_104 = signal_reg_2[31:16];
    assign signal_mux_180 = phase6_iterator_prefix ? signal_select_111 : signal_select_104;
    assign signal_mux_181 = signal_and_81 ? signal_const_18 : signal_mux_180;
    assign signal_select_105 = signal_reg_2[47:32];
    assign signal_mux_182 = phase6_iterator_prefix ? signal_select_118 : signal_select_105;
    assign signal_mux_183 = signal_and_81 ? signal_const_18 : signal_mux_182;
    assign signal_select_106 = signal_reg_2[63:48];
    assign signal_mux_184 = phase6_iterator_prefix ? signal_select_112 : signal_select_106;
    assign signal_mux_185 = signal_and_81 ? signal_const_18 : signal_mux_184;
    assign signal_select_107 = signal_reg_2[79:64];
    assign signal_mux_186 = phase6_iterator_prefix ? signal_mux_194 : signal_select_107;
    assign signal_mux_187 = signal_and_81 ? signal_const_18 : signal_mux_186;
    assign signal_select_108 = signal_reg_2[80:80];
    assign signal_mux_188 = phase6_iterator_prefix ? vdd : signal_select_108;
    assign signal_mux_189 = signal_and_81 ? signal_const_8 : signal_mux_188;
    assign signal_select_109 = signal_reg_2[144:81];
    assign signal_mux_190 = phase6_iterator_prefix ? signal_const_6 : signal_select_109;
    assign signal_mux_191 = signal_and_81 ? signal_const_6 : signal_mux_190;
    assign signal_select_110 = signal_reg_2[145:145];
    assign signal_mux_192 = phase6_iterator_prefix ? gnd : signal_select_110;
    assign signal_mux_193 = signal_and_81 ? signal_const_8 : signal_mux_192;
    assign signal_const_109 = 162'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_select_111 = signal_mux_245[31:16];
    assign signal_select_112 = signal_mux_245[63:48];
    assign signal_select_113 = signal_select_129[15:0];
    assign signal_select_114 = signal_mux_244[79:64];
    assign signal_mux_194 = signal_eq_24 ? signal_select_113 : signal_select_114;
    assign signal_const_110 = 66'b000000000000000000000000000000000000000000000000000000000000000001;
    assign signal_cat_2 = { signal_mux_201,
                            signal_const_110,
                            signal_mux_194,
                            signal_select_112,
                            signal_select_118,
                            signal_select_111,
                            signal_select_131 };
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            signal_reg_2 <= signal_const_109;
        else
            if (phase6_iterator_prefix)
                signal_reg_2 <= signal_cat_2;
    end
    assign signal_select_115 = signal_reg_2[161:146];
    assign signal_mux_195 = phase6_iterator_prefix ? signal_mux_201 : signal_select_115;
    assign signal_mux_196 = signal_and_81 ? signal_mux_201 : signal_mux_195;
    assign signal_const_111 = 293'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_const_113 = 8'b00000100;
    assign signal_const_114 = 8'b00000110;
    assign signal_mux_197 = signal_and_27 ? signal_const_114 : signal_const_92;
    assign signal_mux_198 = signal_and_28 ? signal_const_113 : signal_mux_197;
    assign signal_mux_199 = signal_and_81 ? signal_const_92 : signal_mux_198;
    assign signal_const_116 = 33'b000000000000000000000000000000000;
    assign signal_const_117 = 16'b0000000000000100;
    assign signal_and_2 = signal_and_80 & signal_eq_25;
    assign signal_or_2 = signal_and_2 | signal_or_19;
    assign signal_const_119 = 11'b00000000000;
    assign signal_cat_3 = { signal_const_119,
                            signal_mux_247 };
    assign signal_mux_200 = signal_or_19 ? signal_cat_3 : signal_const_18;
    assign signal_const_121 = 16'b0000000000001100;
    assign signal_add_1 = phase6_iterator_offset + signal_const_121;
    assign signal_add_2 = signal_add_1 + signal_mux_200;
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            signal_reg_3 <= signal_const_18;
        else
            if (signal_or_2)
                signal_reg_3 <= signal_add_2;
    end
    assign signal_or_3 = signal_eq_25 | signal_or_19;
    assign signal_mux_201 = signal_or_3 ? signal_add_2 : signal_reg_3;
    assign signal_add_3 = signal_mux_201 + signal_const_117;
    assign signal_cat_4 = { signal_const_119,
                            phase6_iterator_available };
    assign signal_add_4 = phase6_iterator_offset + signal_cat_4;
    assign signal_add_5 = signal_add_4 + signal_const_121;
    assign signal_mux_202 = signal_and_27 ? signal_add_3 : signal_add_5;
    assign signal_mux_203 = signal_and_28 ? signal_mux_201 : signal_mux_202;
    assign signal_cat_5 = { signal_mux_203,
                            signal_const_116,
                            signal_mux_199,
                            signal_const_111,
                            signal_mux_196,
                            signal_mux_193,
                            signal_mux_191,
                            signal_mux_189,
                            signal_mux_187,
                            signal_mux_185,
                            signal_mux_183,
                            signal_mux_181,
                            signal_mux_179,
                            signal_select_102,
                            signal_select_95,
                            signal_select_94,
                            signal_select_93,
                            signal_select_92,
                            signal_select_91,
                            signal_const_2 };
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            signal_reg_4 <= signal_const_97;
        else
            if (signal_or_28)
                signal_reg_4 <= signal_cat_5;
    end
    assign signal_select_116 = signal_reg_4[676:661];
    assign signal_mux_204 = signal_wire_3 ? signal_add : signal_select_116;
    assign signal_mux_205 = signal_eq_26 ? signal_select_89 : signal_mux_204;
    assign signal_const_125 = 3'b100;
    assign signal_eq_1 = phase6_iterator_state == signal_const_125;
    assign signal_mux_206 = signal_eq_1 ? signal_const_18 : signal_const_18;
    assign signal_const_126 = 3'b111;
    assign signal_eq_2 = phase6_iterator_state == signal_const_126;
    assign signal_or_4 = signal_eq_26 | signal_eq_2;
    assign signal_mux_207 = signal_or_4 ? signal_mux_205 : signal_mux_206;
    assign signal_cat_6 = { signal_mux_207,
                            signal_mux_177,
                            signal_mux_174,
                            signal_mux_171,
                            signal_mux_167,
                            signal_mux_164,
                            signal_mux_161,
                            signal_mux_158,
                            signal_mux_155,
                            signal_mux_152,
                            signal_mux_149,
                            signal_mux_146,
                            signal_mux_143,
                            signal_mux_140,
                            signal_mux_137,
                            signal_mux_134,
                            signal_mux_131,
                            signal_mux_128,
                            signal_mux_125,
                            signal_mux_122,
                            signal_mux_119,
                            signal_mux_116,
                            signal_mux_113,
                            signal_mux_110,
                            signal_mux_107,
                            signal_mux_104,
                            signal_mux_101,
                            signal_mux_98,
                            signal_mux_95,
                            signal_mux_92,
                            signal_mux_89,
                            signal_mux_86,
                            signal_mux_83,
                            signal_mux_80,
                            signal_mux_77,
                            signal_mux_74,
                            signal_mux_71,
                            signal_mux_68,
                            signal_mux_66,
                            signal_mux_62,
                            signal_mux_59,
                            signal_mux_49,
                            signal_mux_47,
                            signal_mux_44,
                            signal_mux_41,
                            signal_mux_38,
                            signal_mux_35,
                            signal_mux_32,
                            signal_mux_29,
                            signal_mux_26,
                            signal_mux_23,
                            signal_mux_20,
                            signal_mux_17,
                            signal_mux_14,
                            signal_mux_11,
                            signal_mux_8,
                            signal_mux_5,
                            signal_mux_2 };
    assign signal_not_2 = ~ signal_wire_11;
    assign signal_and_3 = used_is_one & signal_not_2;
    assign signal_or_5 = used_gt_one | signal_and_3;
    assign signal_and_4 = signal_wire_8 & signal_or_5;
    assign WRITE_ADDRESS_NEXT = signal_wire_1 + vdd;
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            WRITE_ADDRESS <= signal_const_8;
        else
            if (signal_and_4)
                WRITE_ADDRESS <= WRITE_ADDRESS_NEXT;
    end
    assign signal_wire_1 = WRITE_ADDRESS;
    always @(posedge signal_wire_19) begin
        if (signal_and_4)
            signal_multiport_mem[signal_wire_1] <= signal_cat_6;
    end
    assign vdd = 1'b1;
    assign READ_ADDRESS_NEXT = signal_wire_2 + vdd;
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            READ_ADDRESS <= signal_const_8;
        else
            if (signal_and_5)
                READ_ADDRESS <= READ_ADDRESS_NEXT;
    end
    assign signal_wire_2 = READ_ADDRESS;
    assign signal_xor = signal_wire_11 ^ signal_wire_8;
    assign signal_lt = signal_const_4 < USED_NEXT;
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            used_gt_one <= signal_const_8;
        else
            if (signal_xor)
                used_gt_one <= signal_lt;
    end
    assign signal_and_5 = signal_wire_11 & used_gt_one;
    assign RA = signal_and_5 ? READ_ADDRESS_NEXT : signal_wire_2;
    always @(posedge signal_wire_19) begin
        signal_reg_5 <= RA;
    end
    assign memory = signal_multiport_mem[signal_reg_5];
    assign signal_xor_1 = signal_wire_11 ^ signal_wire_8;
    assign signal_eq_3 = USED_NEXT == signal_const_4;
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            used_is_one <= signal_const_8;
        else
            if (signal_xor_1)
                used_is_one <= signal_eq_3;
    end
    assign signal_and_6 = used_is_one & signal_wire_8;
    assign signal_and_7 = signal_and_6 & signal_wire_11;
    assign signal_and_8 = signal_not_20 & signal_wire_8;
    assign bypass_cond = signal_and_8 | signal_and_7;
    assign signal_mux_208 = bypass_cond ? signal_cat_6 : memory;
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            signal_reg_6 <= signal_const_1;
        else
            if (signal_or)
                signal_reg_6 <= signal_mux_208;
    end
    assign signal_not_3 = ~ signal_not_20;
    assign signal_and_9 = signal_and_48 & signal_not_3;
    assign signal_and_10 = signal_eq_23 & signal_select_135;
    assign signal_or_6 = signal_and_10 | signal_select_117;
    assign signal_mux_209 = signal_eq_15 ? phase6_iterator_ready : signal_or_6;
    assign signal_select_117 = signal_inst[0:0];
    assign signal_not_4 = ~ signal_wire_4;
    assign signal_and_11 = signal_not_4 & signal_select_117;
    assign signal_const_133 = 3'b000;
    assign signal_const_136 = 3'b001;
    assign signal_const_137 = 3'b010;
    assign signal_mux_210 = signal_and_63 ? signal_const_137 : signal_mux_211;
    assign signal_const_139 = 3'b011;
    assign signal_eq_4 = signal_select_131 == signal_const_96;
    assign signal_mux_211 = signal_eq_4 ? signal_const_125 : signal_const_139;
    assign signal_mux_212 = signal_and_58 ? signal_const_133 : signal_const_136;
    assign signal_mux_213 = signal_wire_13 ? signal_const_137 : signal_mux_212;
    assign signal_mux_214 = signal_wire_14 ? signal_mux_211 : signal_mux_213;
    assign signal_eq_5 = phase6_iterator_available == signal_const;
    assign signal_mux_215 = signal_eq_5 ? signal_const_133 : signal_const_136;
    assign signal_mux_216 = signal_wire_4 ? signal_mux_215 : signal_const_136;
    assign signal_const_150 = 3'b110;
    assign signal_lt_1 = signal_mux_232 < phase6_iterator_available;
    assign signal_not_5 = ~ signal_lt_1;
    assign signal_and_12 = signal_select_134 & signal_not_5;
    assign signal_mux_217 = signal_and_12 ? signal_const_133 : signal_const_150;
    assign signal_const_155 = 3'b101;
    assign signal_eq_6 = signal_select_131 == signal_const_96;
    assign signal_mux_218 = signal_eq_6 ? signal_const_136 : signal_const_155;
    assign signal_mux_219 = signal_and_22 ? signal_const_133 : signal_mux_218;
    assign signal_or_7 = signal_and_81 | signal_and_28;
    assign signal_mux_220 = signal_or_7 ? signal_mux_217 : signal_mux_219;
    assign signal_mux_221 = signal_and_68 ? signal_const_150 : signal_mux_220;
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            signal_reg_7 <= signal_const_133;
        else
            if (signal_or_28)
                signal_reg_7 <= signal_mux_221;
    end
    assign gnd = 1'b0;
    assign signal_not_6 = ~ signal_wire_3;
    assign signal_and_13 = signal_reg_9 & signal_not_6;
    assign signal_mux_222 = signal_and_19 ? signal_and_13 : signal_wire_3;
    assign signal_mux_223 = signal_or_28 ? gnd : signal_mux_222;
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            signal_reg_8 <= signal_const_8;
        else
            if (signal_and_82)
                signal_reg_8 <= signal_mux_223;
    end
    assign signal_wire_3 = signal_reg_8;
    assign signal_not_7 = ~ signal_wire_3;
    assign signal_and_14 = signal_and_27 & signal_and_25;
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            signal_reg_9 <= signal_const_8;
        else
            if (signal_or_28)
                signal_reg_9 <= signal_and_14;
    end
    assign signal_and_15 = signal_reg_9 & signal_not_7;
    assign signal_mux_224 = signal_and_15 ? signal_const_126 : signal_reg_7;
    assign signal_const_160 = 5'b01000;
    assign signal_lt_2 = signal_const_160 < phase6_iterator_available;
    assign signal_not_8 = ~ signal_lt_2;
    assign signal_and_16 = signal_select_134 & signal_not_8;
    assign signal_and_17 = signal_and_31 & signal_and_16;
    assign signal_mux_225 = signal_and_17 ? signal_const_133 : phase6_iterator_state;
    assign signal_eq_7 = phase6_iterator_state == signal_const_126;
    assign signal_and_18 = signal_and_82 & signal_eq_7;
    assign signal_and_19 = signal_and_18 & phase6_iterator_ready;
    assign signal_mux_226 = signal_and_19 ? signal_mux_224 : signal_mux_225;
    assign signal_eq_8 = phase6_iterator_state == signal_const_125;
    assign signal_and_20 = signal_eq_8 & phase6_iterator_ready;
    assign signal_mux_227 = signal_and_20 ? signal_mux_216 : signal_mux_226;
    assign signal_and_21 = signal_or_21 & signal_not_33;
    assign signal_mux_228 = signal_and_21 ? signal_mux_214 : signal_mux_227;
    assign signal_mux_229 = signal_and_80 ? signal_mux_210 : signal_mux_228;
    assign signal_mux_230 = signal_and_37 ? signal_const_136 : signal_mux_229;
    assign signal_lt_3 = signal_const_96 < signal_select_131;
    assign signal_const_164 = 5'b01010;
    assign signal_add_6 = signal_mux_247 + signal_const_164;
    assign signal_mux_231 = signal_wire_14 ? signal_add_6 : signal_const;
    assign signal_mux_232 = signal_wire_14 ? signal_mux_231 : signal_mux_235;
    assign signal_eq_9 = phase6_iterator_available == signal_mux_232;
    assign signal_and_22 = signal_select_134 & signal_eq_9;
    assign signal_not_9 = ~ signal_and_28;
    assign signal_and_23 = phase6_iterator_prefix & signal_not_9;
    assign signal_and_24 = signal_and_23 & signal_and_22;
    assign signal_and_25 = signal_and_24 & signal_lt_3;
    assign signal_const_166 = 16'b0000000000101110;
    assign signal_select_118 = signal_mux_245[47:32];
    assign signal_eq_10 = signal_select_118 == signal_const_166;
    assign signal_not_10 = ~ signal_eq_10;
    assign signal_not_11 = ~ signal_and_28;
    assign signal_and_26 = phase6_iterator_prefix & signal_not_11;
    assign signal_and_27 = signal_and_26 & signal_not_10;
    assign signal_lt_4 = signal_select_131 < signal_const_96;
    assign signal_and_28 = phase6_iterator_prefix & signal_lt_4;
    assign signal_eq_11 = phase6_iterator_available == signal_const_160;
    assign signal_and_29 = signal_and_63 & signal_select_134;
    assign signal_and_30 = signal_and_29 & signal_eq_11;
    assign signal_lt_5 = phase6_iterator_available < signal_mux_235;
    assign signal_or_8 = signal_lt_5 | signal_and_30;
    assign signal_lt_6 = phase6_iterator_available < signal_mux_235;
    assign signal_not_12 = ~ signal_lt_6;
    assign signal_or_9 = signal_not_12 | signal_select_134;
    assign signal_mux_233 = signal_wire_14 ? signal_const_164 : signal_const_160;
    assign signal_add_7 = signal_mux_247 + signal_mux_233;
    assign signal_const_171 = 5'b00010;
    assign signal_mux_234 = signal_and_63 ? signal_const_160 : signal_const_164;
    assign signal_mux_235 = signal_eq_24 ? signal_const_171 : signal_mux_234;
    assign signal_lt_7 = phase6_iterator_available < signal_mux_235;
    assign signal_mux_236 = signal_lt_7 ? phase6_iterator_available : signal_mux_235;
    assign signal_lt_8 = phase6_iterator_available < signal_const_160;
    assign signal_mux_237 = signal_lt_8 ? phase6_iterator_available : signal_const_160;
    assign signal_mux_238 = signal_eq_12 ? signal_mux_237 : signal_mux_247;
    assign signal_mux_239 = signal_or_24 ? signal_mux_236 : signal_mux_238;
    assign signal_mux_240 = signal_or_19 ? signal_add_7 : signal_mux_239;
    assign signal_select_119 = signal_mux_240[3:0];
    assign phase6_iterator_count = signal_select_119;
    assign signal_eq_12 = phase6_iterator_state == signal_const_150;
    assign signal_and_31 = signal_eq_12 & signal_select_141;
    assign signal_or_10 = signal_and_80 | signal_or_21;
    assign signal_or_11 = signal_or_10 | signal_and_31;
    assign phase6_iterator_consume = signal_or_11;
    assign signal_and_32 = signal_and_37 & signal_select_137;
    assign signal_and_33 = signal_and_34 & signal_select_137;
    assign signal_or_12 = signal_wire_4 | signal_and_33;
    assign signal_not_13 = ~ signal_select_135;
    assign signal_or_13 = signal_eq_26 | signal_and_75;
    assign signal_and_34 = signal_wire_17 & signal_and_83;
    assign signal_and_35 = signal_and_34 & signal_or_13;
    assign signal_and_36 = signal_and_35 & signal_eq_23;
    assign signal_and_37 = signal_and_36 & signal_not_13;
    assign signal_or_14 = signal_eq_26 | signal_and_37;
    assign signal_mux_241 = signal_or_14 ? signal_and_32 : signal_or_12;
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            signal_reg_10 <= signal_const_8;
        else
            if (signal_and_82)
                signal_reg_10 <= signal_mux_241;
    end
    assign signal_wire_4 = signal_reg_10;
    assign signal_not_14 = ~ signal_wire_4;
    assign signal_not_15 = ~ signal_eq_26;
    assign signal_and_38 = signal_not_15 & signal_not_14;
    assign signal_not_16 = ~ signal_select_135;
    assign signal_lt_9 = phase6_iterator_available < signal_mux_247;
    assign signal_not_17 = ~ signal_lt_9;
    assign signal_not_18 = ~ signal_and_68;
    assign signal_and_39 = signal_eq_21 & signal_select_141;
    assign signal_and_40 = signal_and_39 & signal_not_18;
    assign signal_and_41 = signal_and_40 & signal_not_17;
    assign signal_const_179 = 2'b11;
    assign signal_sub = USED_NEXT - signal_const_4;
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            USED_MINUS_1 <= signal_const_179;
        else
            if (signal_xor_2)
                USED_MINUS_1 <= signal_sub;
    end
    assign signal_wire_5 = USED_MINUS_1;
    assign signal_add_8 = USED_NEXT + signal_const_4;
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            USED_PLUS_1 <= signal_const_4;
        else
            if (signal_xor_2)
                USED_PLUS_1 <= signal_add_8;
    end
    assign signal_wire_6 = USED_PLUS_1;
    assign signal_mux_242 = signal_wire_11 ? signal_wire_5 : signal_wire_6;
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            USED <= signal_const_3;
        else
            if (signal_xor_2)
                USED <= USED_NEXT;
    end
    assign signal_wire_7 = USED;
    assign signal_eq_13 = phase6_iterator_state == signal_const_126;
    assign signal_eq_14 = phase6_iterator_state == signal_const_125;
    assign signal_eq_15 = signal_select_136 == signal_const_2;
    assign signal_and_42 = signal_eq_26 & signal_wire_17;
    assign signal_and_43 = signal_and_42 & signal_eq_15;
    assign signal_or_15 = signal_and_43 | signal_and_71;
    assign signal_or_16 = signal_or_15 | signal_eq_14;
    assign signal_or_17 = signal_or_16 | signal_eq_13;
    assign signal_and_44 = signal_and_82 & signal_or_17;
    assign signal_and_45 = signal_and_44 & signal_and_49;
    assign signal_wire_8 = signal_and_45;
    assign signal_wire_9 = ready_i;
    assign signal_eq_16 = USED_NEXT == signal_const_3;
    assign signal_not_19 = ~ signal_eq_16;
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            not_empty <= signal_const_8;
        else
            if (signal_xor_2)
                not_empty <= signal_not_19;
    end
    assign signal_wire_10 = not_empty;
    assign signal_not_20 = ~ signal_wire_10;
    assign signal_not_21 = ~ signal_not_20;
    assign signal_and_46 = signal_and_48 & signal_not_21;
    assign signal_and_47 = signal_and_46 & signal_wire_9;
    assign signal_wire_11 = signal_and_47;
    assign signal_xor_2 = signal_wire_11 ^ signal_wire_8;
    assign USED_NEXT = signal_xor_2 ? signal_mux_242 : signal_wire_7;
    assign signal_eq_17 = USED_NEXT == signal_const_179;
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            full <= signal_const_8;
        else
            if (signal_xor_2)
                full <= signal_eq_17;
    end
    assign signal_wire_12 = full;
    assign signal_not_22 = ~ signal_wire_12;
    assign signal_not_23 = ~ signal_wire_20;
    assign signal_and_48 = signal_wire_21 & signal_not_23;
    assign signal_and_49 = signal_and_48 & signal_not_22;
    assign phase6_iterator_ready = signal_and_49;
    assign signal_lt_10 = phase6_iterator_available < signal_mux_247;
    assign signal_not_24 = ~ signal_lt_10;
    assign signal_and_50 = signal_and_80 & signal_and_63;
    assign signal_or_18 = signal_and_50 | signal_wire_13;
    assign signal_select_120 = signal_mux_244[63:0];
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            signal_reg_11 <= signal_const_6;
        else
            if (signal_or_18)
                signal_reg_11 <= signal_select_120;
    end
    assign signal_select_121 = signal_select_129[127:56];
    assign signal_const_193 = 56'b00000000000000000000000000000000000000000000000000000000;
    assign signal_cat_7 = { signal_const_193,
                            signal_select_121 };
    assign signal_select_122 = signal_select_129[127:48];
    assign signal_const_194 = 48'b000000000000000000000000000000000000000000000000;
    assign signal_cat_8 = { signal_const_194,
                            signal_select_122 };
    assign signal_select_123 = signal_select_129[127:40];
    assign signal_const_195 = 40'b0000000000000000000000000000000000000000;
    assign signal_cat_9 = { signal_const_195,
                            signal_select_123 };
    assign signal_select_124 = signal_select_129[127:32];
    assign signal_cat_10 = { signal_const_10,
                             signal_select_124 };
    assign signal_select_125 = signal_select_129[127:24];
    assign signal_const_197 = 24'b000000000000000000000000;
    assign signal_cat_11 = { signal_const_197,
                             signal_select_125 };
    assign signal_select_126 = signal_select_129[127:16];
    assign signal_cat_12 = { signal_const_18,
                             signal_select_126 };
    assign signal_select_127 = signal_select_129[127:8];
    assign signal_cat_13 = { signal_const_38,
                             signal_select_127 };
    assign signal_select_128 = signal_mux_247[2:0];
    always @* begin
        case (signal_select_128)
        0:
            signal_mux_243 <= signal_select_129;
        1:
            signal_mux_243 <= signal_cat_13;
        2:
            signal_mux_243 <= signal_cat_12;
        3:
            signal_mux_243 <= signal_cat_11;
        4:
            signal_mux_243 <= signal_cat_10;
        5:
            signal_mux_243 <= signal_cat_9;
        6:
            signal_mux_243 <= signal_cat_8;
        default:
            signal_mux_243 <= signal_cat_7;
        endcase
    end
    assign signal_select_129 = signal_inst[129:2];
    assign signal_add_9 = signal_mux_247 + signal_const_160;
    assign signal_eq_18 = phase6_iterator_available == signal_add_9;
    assign signal_and_51 = signal_select_134 & signal_eq_18;
    assign signal_not_25 = ~ signal_and_51;
    assign signal_add_10 = signal_mux_247 + signal_const_160;
    assign signal_lt_11 = phase6_iterator_available < signal_add_10;
    assign signal_not_26 = ~ signal_lt_11;
    assign signal_const_202 = 5'b00111;
    assign signal_lt_12 = signal_const_202 < signal_mux_247;
    assign signal_not_27 = ~ signal_lt_12;
    assign signal_not_28 = ~ signal_wire_14;
    assign signal_not_29 = ~ signal_and_58;
    assign signal_and_52 = signal_or_21 & signal_not_33;
    assign signal_and_53 = signal_and_52 & signal_not_29;
    assign signal_and_54 = signal_and_53 & signal_not_28;
    assign signal_and_55 = signal_and_54 & signal_not_27;
    assign signal_and_56 = signal_and_55 & signal_not_26;
    assign signal_and_57 = signal_and_56 & signal_not_25;
    assign signal_wire_13 = signal_and_57;
    assign signal_or_19 = signal_wire_14 | signal_wire_13;
    assign signal_mux_244 = signal_or_19 ? signal_mux_243 : signal_select_129;
    assign signal_select_130 = signal_mux_244[63:0];
    assign signal_mux_245 = signal_eq_24 ? signal_reg_11 : signal_select_130;
    assign signal_select_131 = signal_mux_245[15:0];
    assign signal_sub_1 = signal_select_131 - signal_const_96;
    assign signal_cat_14 = { signal_const_119,
                             signal_mux_247 };
    assign signal_sub_2 = signal_wire_15 - signal_cat_14;
    assign signal_mux_246 = signal_or_21 ? signal_sub_2 : signal_wire_15;
    assign signal_add_11 = signal_mux_247 + signal_const_164;
    assign signal_lt_13 = phase6_iterator_available < signal_add_11;
    assign signal_not_30 = ~ signal_lt_13;
    assign signal_const_205 = 5'b00101;
    assign signal_lt_14 = signal_const_205 < signal_mux_247;
    assign signal_not_31 = ~ signal_lt_14;
    assign signal_select_132 = signal_wire_15[4:0];
    assign signal_const_207 = 16'b0000000000001000;
    assign signal_lt_15 = signal_wire_15 < signal_const_207;
    assign signal_mux_247 = signal_lt_15 ? signal_select_132 : signal_const_160;
    assign signal_eq_19 = phase6_iterator_available == signal_mux_247;
    assign signal_and_58 = signal_select_134 & signal_eq_19;
    assign signal_not_32 = ~ signal_and_58;
    assign signal_lt_16 = signal_const_207 < signal_wire_15;
    assign signal_not_33 = ~ signal_lt_16;
    assign signal_and_59 = signal_or_21 & signal_not_33;
    assign signal_and_60 = signal_and_59 & signal_not_32;
    assign signal_and_61 = signal_and_60 & signal_not_31;
    assign signal_and_62 = signal_and_61 & signal_not_30;
    assign signal_wire_14 = signal_and_62;
    assign signal_not_34 = ~ signal_and_81;
    assign phase6_iterator_offset = signal_inst[216:201];
    assign signal_select_133 = phase6_iterator_offset[2:0];
    assign signal_eq_20 = signal_select_133 == signal_const_126;
    assign signal_and_63 = signal_eq_25 & signal_eq_20;
    assign signal_not_35 = ~ signal_and_63;
    assign signal_and_64 = signal_and_80 & signal_not_35;
    assign signal_and_65 = signal_and_64 & signal_not_34;
    assign phase6_iterator_prefix = signal_and_65 | signal_wire_14;
    assign signal_mux_248 = phase6_iterator_prefix ? signal_sub_1 : signal_mux_246;
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            signal_reg_12 <= signal_const_18;
        else
            if (signal_and_82)
                signal_reg_12 <= signal_mux_248;
    end
    assign signal_wire_15 = signal_reg_12;
    assign phase6_iterator_available = signal_inst[134:130];
    assign signal_cat_15 = { signal_const_119,
                             phase6_iterator_available };
    assign signal_lt_17 = signal_cat_15 < signal_wire_15;
    assign signal_select_134 = signal_inst[135:135];
    assign signal_eq_21 = phase6_iterator_state == signal_const_155;
    assign signal_or_20 = signal_eq_22 | signal_eq_21;
    assign signal_and_66 = signal_or_20 & signal_select_141;
    assign signal_and_67 = signal_and_66 & signal_select_134;
    assign signal_and_68 = signal_and_67 & signal_lt_17;
    assign signal_not_36 = ~ signal_and_68;
    assign signal_eq_22 = phase6_iterator_state == signal_const_139;
    assign signal_and_69 = signal_eq_22 & signal_select_141;
    assign signal_and_70 = signal_and_69 & signal_not_36;
    assign signal_and_71 = signal_and_70 & signal_not_24;
    assign phase6_iterator_body = signal_and_71 & phase6_iterator_ready;
    assign signal_or_21 = phase6_iterator_body | signal_and_41;
    assign signal_and_72 = signal_or_21 & signal_not_33;
    assign signal_and_73 = signal_and_72 & signal_and_58;
    assign signal_wire_16 = signal_and_73;
    assign signal_and_74 = signal_wire_16 & signal_eq_23;
    assign signal_and_75 = signal_and_74 & signal_not_16;
    assign signal_select_135 = signal_wire_18[165:165];
    assign signal_not_37 = ~ signal_select_135;
    assign signal_select_136 = signal_wire_18[1:0];
    assign signal_eq_23 = signal_select_136 == signal_const_3;
    assign signal_and_76 = signal_eq_26 & signal_eq_23;
    assign signal_and_77 = signal_and_76 & signal_not_37;
    assign signal_or_22 = signal_and_77 | signal_and_75;
    assign signal_or_23 = signal_or_22 | signal_and_38;
    assign signal_wire_17 = valid_i;
    assign signal_and_78 = signal_wire_17 & signal_or_23;
    assign signal_select_137 = signal_wire_18[239:239];
    assign signal_select_138 = signal_wire_18[238:238];
    assign signal_select_139 = signal_wire_18[237:230];
    assign signal_wire_18 = item_i;
    assign signal_select_140 = signal_wire_18[229:166];
    assign signal_wire_19 = clock_i;
    cme_byte_aligner
        cme_byte_aligner
        ( .clock_i(signal_wire_19),
          .reset_i(signal_wire_20),
          .en_i(signal_wire_21),
          .data_i(signal_select_140),
          .keep_i(signal_select_139),
          .first_i(signal_select_138),
          .last_i(signal_select_137),
          .ingress_timestamp_i(signal_const_6),
          .valid_i(signal_and_78),
          .consume_valid_i(phase6_iterator_consume),
          .consume_count_i(phase6_iterator_count),
          .ready_o(signal_inst[0:0]),
          .valid_o(signal_inst[1:1]),
          .data_o(signal_inst[129:2]),
          .available_o(signal_inst[134:130]),
          .boundary_o(signal_inst[135:135]),
          .first_o(signal_inst[136:136]),
          .ingress_timestamp_o(signal_inst[200:137]),
          .packet_byte_offset_o(signal_inst[216:201]),
          .consume_ready_o(signal_inst[217:217]) );
    assign signal_select_141 = signal_inst[1:1];
    assign signal_eq_24 = phase6_iterator_state == signal_const_137;
    assign signal_eq_25 = phase6_iterator_state == signal_const_136;
    assign signal_or_24 = signal_eq_25 | signal_eq_24;
    assign signal_and_79 = signal_or_24 & signal_select_141;
    assign signal_and_80 = signal_and_79 & signal_or_9;
    assign signal_and_81 = signal_and_80 & signal_or_8;
    assign signal_or_25 = signal_and_81 | signal_and_28;
    assign signal_or_26 = signal_or_25 | signal_and_27;
    assign signal_or_27 = signal_or_26 | signal_and_68;
    assign signal_or_28 = signal_or_27 | signal_and_25;
    assign signal_mux_249 = signal_or_28 ? signal_const_126 : signal_mux_230;
    always @(posedge signal_wire_19) begin
        if (signal_wire_20)
            signal_reg_13 <= signal_const_133;
        else
            if (signal_and_82)
                signal_reg_13 <= signal_mux_249;
    end
    assign phase6_iterator_state = signal_reg_13;
    assign signal_eq_26 = phase6_iterator_state == signal_const_133;
    assign signal_or_29 = signal_eq_26 | signal_and_75;
    assign signal_mux_250 = signal_or_29 ? signal_mux_209 : signal_and_11;
    assign signal_wire_20 = reset_i;
    assign signal_not_38 = ~ signal_wire_20;
    assign signal_wire_21 = en_i;
    assign signal_and_82 = signal_wire_21 & signal_not_38;
    assign signal_and_83 = signal_and_82 & signal_mux_250;
    assign ram_wbr_data = memory;
    assign ready_o = signal_and_83;
    assign valid_o = signal_and_9;
    assign item_o = signal_reg_6;
    assign idle_o = signal_and_1;

endmodule
module cme_message_pipeline (
    clock_i,
    reset_i,
    en_i,
    data_i,
    keep_i,
    first_i,
    last_i,
    ingress_timestamp_i,
    valid_i,
    ready_i,
    downstream_idle_i,
    session_reset_i,
    resync_valid_i,
    resync_next_seq_i,
    ready_o,
    valid_o,
    item_o,
    control_ready_o
);

    input clock_i;
    input reset_i;
    input en_i;
    input [63:0] data_i;
    input [7:0] keep_i;
    input first_i;
    input last_i;
    input [63:0] ingress_timestamp_i;
    input valid_i;
    input ready_i;
    input downstream_idle_i;
    input session_reset_i;
    input resync_valid_i;
    input [31:0] resync_next_seq_i;
    output ready_o;
    output valid_o;
    output [1078:0] item_o;
    output control_ready_o;

    wire signal_select;
    wire [1078:0] signal_select_1;
    wire signal_select_2;
    wire [31:0] signal_wire;
    wire signal_wire_1;
    wire signal_wire_2;
    wire signal_wire_3;
    wire signal_select_3;
    wire signal_wire_4;
    wire signal_and;
    wire signal_wire_5;
    wire signal_select_4;
    wire [916:0] signal_select_5;
    wire [1081:0] signal_inst;
    wire signal_select_6;
    wire signal_wire_6;
    wire signal_wire_7;
    wire [63:0] signal_wire_8;
    wire signal_wire_9;
    wire signal_wire_10;
    wire [7:0] signal_wire_11;
    wire [63:0] signal_wire_12;
    wire signal_wire_13;
    wire signal_wire_14;
    wire signal_wire_15;
    wire [919:0] signal_inst_1;
    wire signal_select_7;
    assign signal_select = signal_inst_1[919:919];
    assign signal_select_1 = signal_inst[1080:2];
    assign signal_select_2 = signal_inst[1:1];
    assign signal_wire = resync_next_seq_i;
    assign signal_wire_1 = resync_valid_i;
    assign signal_wire_2 = session_reset_i;
    assign signal_wire_3 = downstream_idle_i;
    assign signal_select_3 = signal_inst[1081:1081];
    assign signal_wire_4 = signal_select_3;
    assign signal_and = signal_wire_4 & signal_wire_3;
    assign signal_wire_5 = ready_i;
    assign signal_select_4 = signal_inst_1[1:1];
    assign signal_select_5 = signal_inst_1[918:2];
    cme_sbe_message_iterator
        cme_sbe_message_iterator
        ( .clock_i(signal_wire_15),
          .reset_i(signal_wire_14),
          .en_i(signal_wire_13),
          .item_i(signal_select_5),
          .valid_i(signal_select_4),
          .ready_i(signal_wire_5),
          .ready_o(signal_inst[0:0]),
          .valid_o(signal_inst[1:1]),
          .item_o(signal_inst[1080:2]),
          .idle_o(signal_inst[1081:1081]) );
    assign signal_select_6 = signal_inst[0:0];
    assign signal_wire_6 = signal_select_6;
    assign signal_wire_7 = valid_i;
    assign signal_wire_8 = ingress_timestamp_i;
    assign signal_wire_9 = last_i;
    assign signal_wire_10 = first_i;
    assign signal_wire_11 = keep_i;
    assign signal_wire_12 = data_i;
    assign signal_wire_13 = en_i;
    assign signal_wire_14 = reset_i;
    assign signal_wire_15 = clock_i;
    cme_packet_pipeline
        cme_packet_pipeline
        ( .clock_i(signal_wire_15),
          .reset_i(signal_wire_14),
          .en_i(signal_wire_13),
          .data_i(signal_wire_12),
          .keep_i(signal_wire_11),
          .first_i(signal_wire_10),
          .last_i(signal_wire_9),
          .ingress_timestamp_i(signal_wire_8),
          .valid_i(signal_wire_7),
          .ready_i(signal_wire_6),
          .downstream_idle_i(signal_and),
          .session_reset_i(signal_wire_2),
          .resync_valid_i(signal_wire_1),
          .resync_next_seq_i(signal_wire),
          .ready_o(signal_inst_1[0:0]),
          .valid_o(signal_inst_1[1:1]),
          .item_o(signal_inst_1[918:2]),
          .control_ready_o(signal_inst_1[919:919]) );
    assign signal_select_7 = signal_inst_1[0:0];
    assign ready_o = signal_select_7;
    assign valid_o = signal_select_2;
    assign item_o = signal_select_1;
    assign control_ready_o = signal_select;

endmodule
module cme_event_orderer (
    clock_i,
    reset_i,
    en_i,
    item_i,
    valid_i,
    decoder_ready_i,
    decoder_event_i,
    decoder_event_valid_i,
    decoder_done_i,
    event_ready_i,
    ready_o,
    decoder_item_o,
    decoder_valid_o,
    decoder_event_ready_o,
    decoder_done_ready_o,
    event_o,
    event_valid_o,
    idle_o
);

    input clock_i;
    input reset_i;
    input en_i;
    input [1078:0] item_i;
    input valid_i;
    input decoder_ready_i;
    input [676:0] decoder_event_i;
    input decoder_event_valid_i;
    input decoder_done_i;
    input event_ready_i;
    output ready_o;
    output [1078:0] decoder_item_o;
    output decoder_valid_o;
    output decoder_event_ready_o;
    output decoder_done_ready_o;
    output [676:0] event_o;
    output event_valid_o;
    output idle_o;

    wire signal_not;
    wire signal_not_1;
    wire signal_and;
    wire signal_mux;
    wire signal_and_1;
    wire [676:0] signal_wire;
    wire signal_and_2;
    wire [676:0] signal_const;
    wire [676:0] signal_cat;
    reg [676:0] signal_reg;
    wire [1:0] signal_select;
    wire [63:0] signal_select_1;
    wire signal_select_2;
    wire [31:0] signal_select_3;
    wire [63:0] signal_select_4;
    wire signal_select_5;
    wire signal_select_6;
    wire [15:0] signal_select_7;
    wire [15:0] signal_select_8;
    wire [15:0] signal_select_9;
    wire [15:0] signal_select_10;
    wire [15:0] signal_select_11;
    wire signal_select_12;
    wire [63:0] signal_select_13;
    wire signal_select_14;
    wire [15:0] signal_select_15;
    wire [15:0] signal_select_16;
    wire [15:0] signal_select_17;
    wire [31:0] signal_select_18;
    wire [31:0] signal_select_19;
    wire [63:0] signal_select_20;
    wire signal_select_21;
    wire [31:0] signal_select_22;
    wire signal_select_23;
    wire [31:0] signal_select_24;
    wire signal_select_25;
    wire [7:0] signal_select_26;
    wire [7:0] signal_select_27;
    wire [7:0] signal_select_28;
    wire [31:0] signal_select_29;
    wire signal_select_30;
    wire [7:0] signal_select_31;
    wire signal_select_32;
    wire [7:0] signal_select_33;
    wire [31:0] signal_select_34;
    wire signal_select_35;
    wire [15:0] signal_select_36;
    wire [676:0] signal_cat_1;
    wire [676:0] signal_mux_1;
    wire [676:0] signal_mux_2;
    wire signal_and_3;
    wire signal_and_4;
    wire signal_and_5;
    wire signal_not_2;
    wire signal_not_3;
    wire signal_or;
    wire signal_and_6;
    wire signal_and_7;
    wire signal_and_8;
    wire signal_and_9;
    wire signal_and_10;
    wire signal_not_4;
    wire signal_or_1;
    wire signal_not_5;
    wire signal_and_11;
    wire signal_mux_3;
    wire signal_const_1;
    wire signal_not_6;
    wire signal_not_7;
    wire signal_and_12;
    wire signal_and_13;
    wire signal_and_14;
    wire signal_or_2;
    wire signal_not_8;
    wire signal_and_15;
    wire signal_and_16;
    wire signal_and_17;
    wire signal_mux_4;
    wire signal_not_9;
    wire vdd;
    wire signal_wire_1;
    wire signal_wire_2;
    wire signal_wire_3;
    wire signal_not_10;
    wire signal_or_3;
    wire signal_wire_4;
    wire signal_select_37;
    wire signal_select_38;
    wire [1:0] signal_const_4;
    wire signal_eq;
    wire signal_or_4;
    wire signal_or_5;
    wire gnd;
    wire signal_mux_5;
    wire signal_mux_6;
    reg signal_reg_1;
    wire signal_wire_5;
    wire signal_and_18;
    wire signal_and_19;
    wire signal_and_20;
    wire signal_and_21;
    wire signal_mux_7;
    wire [1:0] signal_const_5;
    wire [1078:0] signal_wire_6;
    wire [1:0] signal_select_39;
    wire signal_eq_1;
    wire signal_and_22;
    wire signal_mux_8;
    reg signal_reg_2;
    wire signal_wire_7;
    wire signal_and_23;
    wire signal_and_24;
    wire signal_wire_8;
    wire signal_wire_9;
    wire signal_and_25;
    wire signal_and_26;
    wire signal_and_27;
    wire signal_and_28;
    wire signal_mux_9;
    reg signal_reg_3;
    wire signal_wire_10;
    wire signal_not_11;
    wire signal_and_29;
    wire signal_mux_10;
    wire signal_wire_11;
    wire signal_not_12;
    wire signal_wire_12;
    wire signal_and_30;
    wire signal_and_31;
    assign signal_not = ~ signal_wire_10;
    assign signal_not_1 = ~ signal_wire_7;
    assign signal_and = signal_not_1 & signal_not;
    assign signal_mux = signal_wire_7 ? signal_wire_3 : signal_and_15;
    assign signal_and_1 = signal_and_30 & signal_mux;
    assign signal_wire = decoder_event_i;
    assign signal_and_2 = signal_and_27 & signal_and_24;
    assign signal_const = 677'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_cat = { signal_select_36,
                          signal_select_35,
                          signal_select_34,
                          signal_select_33,
                          signal_select_32,
                          signal_select_31,
                          signal_select_30,
                          signal_select_29,
                          signal_select_28,
                          signal_select_27,
                          signal_select_26,
                          signal_select_25,
                          signal_select_24,
                          signal_select_23,
                          signal_select_22,
                          signal_select_21,
                          signal_select_20,
                          signal_select_19,
                          signal_select_18,
                          signal_select_17,
                          signal_select_16,
                          signal_select_15,
                          signal_select_14,
                          signal_select_13,
                          signal_select_12,
                          signal_select_11,
                          signal_select_10,
                          signal_select_9,
                          signal_select_8,
                          signal_select_7,
                          signal_select_6,
                          signal_select_5,
                          signal_select_4,
                          signal_select_3,
                          signal_select_2,
                          signal_select_1,
                          signal_select };
    always @(posedge signal_wire_4) begin
        if (signal_wire_11)
            signal_reg <= signal_const;
        else
            if (signal_and_2)
                signal_reg <= signal_cat;
    end
    assign signal_select = signal_wire_6[403:402];
    assign signal_select_1 = signal_wire_6[467:404];
    assign signal_select_2 = signal_wire_6[468:468];
    assign signal_select_3 = signal_wire_6[500:469];
    assign signal_select_4 = signal_wire_6[564:501];
    assign signal_select_5 = signal_wire_6[565:565];
    assign signal_select_6 = signal_wire_6[566:566];
    assign signal_select_7 = signal_wire_6[582:567];
    assign signal_select_8 = signal_wire_6[598:583];
    assign signal_select_9 = signal_wire_6[614:599];
    assign signal_select_10 = signal_wire_6[630:615];
    assign signal_select_11 = signal_wire_6[646:631];
    assign signal_select_12 = signal_wire_6[647:647];
    assign signal_select_13 = signal_wire_6[711:648];
    assign signal_select_14 = signal_wire_6[712:712];
    assign signal_select_15 = signal_wire_6[728:713];
    assign signal_select_16 = signal_wire_6[744:729];
    assign signal_select_17 = signal_wire_6[760:745];
    assign signal_select_18 = signal_wire_6[792:761];
    assign signal_select_19 = signal_wire_6[824:793];
    assign signal_select_20 = signal_wire_6[888:825];
    assign signal_select_21 = signal_wire_6[889:889];
    assign signal_select_22 = signal_wire_6[921:890];
    assign signal_select_23 = signal_wire_6[922:922];
    assign signal_select_24 = signal_wire_6[954:923];
    assign signal_select_25 = signal_wire_6[955:955];
    assign signal_select_26 = signal_wire_6[963:956];
    assign signal_select_27 = signal_wire_6[971:964];
    assign signal_select_28 = signal_wire_6[979:972];
    assign signal_select_29 = signal_wire_6[1011:980];
    assign signal_select_30 = signal_wire_6[1012:1012];
    assign signal_select_31 = signal_wire_6[1020:1013];
    assign signal_select_32 = signal_wire_6[1021:1021];
    assign signal_select_33 = signal_wire_6[1029:1022];
    assign signal_select_34 = signal_wire_6[1061:1030];
    assign signal_select_35 = signal_wire_6[1062:1062];
    assign signal_select_36 = signal_wire_6[1078:1063];
    assign signal_cat_1 = { signal_select_36,
                            signal_select_35,
                            signal_select_34,
                            signal_select_33,
                            signal_select_32,
                            signal_select_31,
                            signal_select_30,
                            signal_select_29,
                            signal_select_28,
                            signal_select_27,
                            signal_select_26,
                            signal_select_25,
                            signal_select_24,
                            signal_select_23,
                            signal_select_22,
                            signal_select_21,
                            signal_select_20,
                            signal_select_19,
                            signal_select_18,
                            signal_select_17,
                            signal_select_16,
                            signal_select_15,
                            signal_select_14,
                            signal_select_13,
                            signal_select_12,
                            signal_select_11,
                            signal_select_10,
                            signal_select_9,
                            signal_select_8,
                            signal_select_7,
                            signal_select_6,
                            signal_select_5,
                            signal_select_4,
                            signal_select_3,
                            signal_select_2,
                            signal_select_1,
                            signal_select };
    assign signal_mux_1 = signal_wire_10 ? signal_reg : signal_cat_1;
    assign signal_mux_2 = signal_wire_7 ? signal_wire : signal_mux_1;
    assign signal_and_3 = signal_and_30 & signal_wire_7;
    assign signal_and_4 = signal_and_3 & signal_wire_2;
    assign signal_and_5 = signal_and_13 & signal_wire_2;
    assign signal_not_2 = ~ signal_eq;
    assign signal_not_3 = ~ signal_wire_3;
    assign signal_or = signal_not_3 | signal_wire_2;
    assign signal_and_6 = signal_wire_7 & signal_wire_5;
    assign signal_and_7 = signal_and_6 & signal_wire_1;
    assign signal_and_8 = signal_and_7 & signal_or;
    assign signal_and_9 = signal_and_8 & signal_eq_1;
    assign signal_and_10 = signal_and_9 & signal_not_2;
    assign signal_not_4 = ~ signal_wire_5;
    assign signal_or_1 = signal_not_4 | signal_and_10;
    assign signal_not_5 = ~ signal_eq;
    assign signal_and_11 = signal_eq_1 & signal_not_5;
    assign signal_mux_3 = signal_wire_7 ? signal_or_1 : signal_and_11;
    assign signal_const_1 = 1'b0;
    assign signal_not_6 = ~ signal_wire_10;
    assign signal_not_7 = ~ signal_wire_7;
    assign signal_and_12 = signal_not_7 & signal_not_6;
    assign signal_and_13 = signal_and_12 & signal_eq;
    assign signal_and_14 = signal_and_13 & signal_wire_9;
    assign signal_or_2 = signal_wire_10 | signal_and_14;
    assign signal_not_8 = ~ signal_wire_7;
    assign signal_and_15 = signal_not_8 & signal_or_2;
    assign signal_and_16 = signal_and_30 & signal_and_15;
    assign signal_and_17 = signal_and_16 & signal_wire_2;
    assign signal_mux_4 = signal_and_17 ? gnd : signal_wire_10;
    assign signal_not_9 = ~ signal_wire_5;
    assign vdd = 1'b1;
    assign signal_wire_1 = decoder_done_i;
    assign signal_wire_2 = event_ready_i;
    assign signal_wire_3 = decoder_event_valid_i;
    assign signal_not_10 = ~ signal_wire_3;
    assign signal_or_3 = signal_not_10 | signal_wire_2;
    assign signal_wire_4 = clock_i;
    assign signal_select_37 = signal_wire_6[401:401];
    assign signal_select_38 = signal_wire_6[327:327];
    assign signal_const_4 = 2'b10;
    assign signal_eq = signal_select_39 == signal_const_4;
    assign signal_or_4 = signal_eq | signal_select_38;
    assign signal_or_5 = signal_or_4 | signal_select_37;
    assign gnd = 1'b0;
    assign signal_mux_5 = signal_and_21 ? gnd : signal_wire_5;
    assign signal_mux_6 = signal_and_27 ? signal_or_5 : signal_mux_5;
    always @(posedge signal_wire_4) begin
        if (signal_wire_11)
            signal_reg_1 <= signal_const_1;
        else
            if (signal_and_30)
                signal_reg_1 <= signal_mux_6;
    end
    assign signal_wire_5 = signal_reg_1;
    assign signal_and_18 = signal_and_30 & signal_wire_7;
    assign signal_and_19 = signal_and_18 & signal_wire_5;
    assign signal_and_20 = signal_and_19 & signal_or_3;
    assign signal_and_21 = signal_and_20 & signal_wire_1;
    assign signal_mux_7 = signal_and_21 ? gnd : signal_wire_7;
    assign signal_const_5 = 2'b00;
    assign signal_wire_6 = item_i;
    assign signal_select_39 = signal_wire_6[1:0];
    assign signal_eq_1 = signal_select_39 == signal_const_5;
    assign signal_and_22 = signal_and_27 & signal_eq_1;
    assign signal_mux_8 = signal_and_22 ? vdd : signal_mux_7;
    always @(posedge signal_wire_4) begin
        if (signal_wire_11)
            signal_reg_2 <= signal_const_1;
        else
            if (signal_and_30)
                signal_reg_2 <= signal_mux_8;
    end
    assign signal_wire_7 = signal_reg_2;
    assign signal_and_23 = signal_wire_7 & signal_not_9;
    assign signal_and_24 = signal_and_23 & signal_eq;
    assign signal_wire_8 = decoder_ready_i;
    assign signal_wire_9 = valid_i;
    assign signal_and_25 = signal_and_30 & signal_wire_9;
    assign signal_and_26 = signal_and_25 & signal_and_29;
    assign signal_and_27 = signal_and_26 & signal_wire_8;
    assign signal_and_28 = signal_and_27 & signal_and_24;
    assign signal_mux_9 = signal_and_28 ? vdd : signal_mux_4;
    always @(posedge signal_wire_4) begin
        if (signal_wire_11)
            signal_reg_3 <= signal_const_1;
        else
            if (signal_and_30)
                signal_reg_3 <= signal_mux_9;
    end
    assign signal_wire_10 = signal_reg_3;
    assign signal_not_11 = ~ signal_wire_10;
    assign signal_and_29 = signal_not_11 & signal_mux_3;
    assign signal_mux_10 = signal_and_29 ? signal_wire_8 : signal_and_5;
    assign signal_wire_11 = reset_i;
    assign signal_not_12 = ~ signal_wire_11;
    assign signal_wire_12 = en_i;
    assign signal_and_30 = signal_wire_12 & signal_not_12;
    assign signal_and_31 = signal_and_30 & signal_mux_10;
    assign ready_o = signal_and_31;
    assign decoder_item_o = signal_wire_6;
    assign decoder_valid_o = signal_and_26;
    assign decoder_event_ready_o = signal_and_4;
    assign decoder_done_ready_o = signal_and_20;
    assign event_o = signal_mux_2;
    assign event_valid_o = signal_and_1;
    assign idle_o = signal_and;

endmodule
module cme_mbp_decoder (
    clock_i,
    reset_i,
    en_i,
    item_i,
    valid_i,
    event_ready_i,
    done_ready_i,
    ready_o,
    event_o,
    event_valid_o,
    done_o,
    idle_o
);

    input clock_i;
    input reset_i;
    input en_i;
    input [1078:0] item_i;
    input valid_i;
    input event_ready_i;
    input done_ready_i;
    output ready_o;
    output [676:0] event_o;
    output event_valid_o;
    output done_o;
    output idle_o;

    wire [4:0] signal_const;
    wire signal_eq;
    wire signal_not;
    wire signal_eq_1;
    wire signal_and;
    wire signal_and_1;
    wire [4:0] signal_const_2;
    wire signal_eq_2;
    wire signal_and_2;
    wire signal_and_3;
    wire signal_and_4;
    wire [676:0] signal_const_3;
    wire [1:0] signal_const_4;
    wire [333:0] signal_const_5;
    wire [15:0] signal_sub;
    wire [4:0] signal_const_6;
    wire signal_eq_3;
    wire [15:0] signal_mux;
    wire [15:0] signal_add;
    wire [676:0] signal_cat;
    wire [676:0] signal_mux_1;
    wire [676:0] signal_mux_2;
    wire [676:0] signal_mux_3;
    wire [676:0] signal_mux_4;
    wire [676:0] signal_mux_5;
    wire [676:0] signal_mux_6;
    wire [676:0] signal_mux_7;
    wire [15:0] signal_const_9;
    wire [15:0] signal_add_1;
    wire [15:0] signal_sub_1;
    wire [676:0] signal_cat_1;
    wire [676:0] signal_mux_8;
    wire [676:0] signal_mux_9;
    wire [676:0] signal_mux_10;
    wire [676:0] signal_mux_11;
    wire [676:0] signal_mux_12;
    wire [676:0] signal_mux_13;
    wire [1:0] signal_const_10;
    wire [283:0] signal_const_11;
    wire [57:0] signal_const_12;
    wire [676:0] signal_cat_2;
    wire [676:0] signal_mux_14;
    wire [676:0] signal_mux_15;
    wire [676:0] signal_mux_16;
    wire [676:0] signal_mux_17;
    wire [333:0] signal_const_14;
    wire [15:0] signal_const_15;
    wire [15:0] signal_const_16;
    wire [15:0] signal_mux_18;
    wire [15:0] signal_add_2;
    wire [15:0] signal_add_3;
    wire [676:0] signal_cat_3;
    wire [56:0] signal_const_17;
    wire [676:0] signal_cat_4;
    wire [676:0] signal_mux_19;
    wire [676:0] signal_mux_20;
    wire [15:0] signal_mux_21;
    wire [15:0] signal_const_22;
    wire [15:0] signal_select;
    wire [15:0] signal_add_4;
    wire [15:0] signal_mux_22;
    wire [15:0] signal_mux_23;
    wire [15:0] signal_mux_24;
    wire [15:0] signal_mux_25;
    wire [15:0] signal_mux_26;
    wire [15:0] signal_mux_27;
    wire [11:0] signal_const_23;
    wire [15:0] signal_cat_5;
    wire [15:0] signal_add_5;
    wire [15:0] signal_mux_28;
    wire [15:0] signal_mux_29;
    wire [15:0] signal_mux_30;
    wire [15:0] signal_mux_31;
    wire [15:0] signal_mux_32;
    wire [15:0] signal_mux_33;
    wire [15:0] signal_mux_34;
    wire [15:0] signal_cat_6;
    wire [15:0] next_position;
    wire [15:0] signal_mux_35;
    wire [15:0] signal_mux_36;
    reg [15:0] signal_cases;
    wire [15:0] signal_wire;
    reg [15:0] entry_position;
    wire [15:0] signal_add_6;
    wire [15:0] signal_add_7;
    wire [676:0] signal_cat_7;
    wire [1:0] signal_const_25;
    wire [31:0] signal_select_1;
    wire [31:0] signal_select_2;
    wire [63:0] signal_const_26;
    wire [63:0] signal_mux_37;
    wire [63:0] signal_const_27;
    wire [63:0] signal_select_3;
    wire signal_eq_4;
    wire [15:0] signal_const_28;
    wire signal_lt;
    wire signal_or;
    wire [31:0] signal_const_29;
    wire [31:0] signal_mux_38;
    wire [31:0] signal_const_30;
    wire [31:0] signal_select_4;
    wire signal_eq_5;
    wire signal_lt_1;
    wire signal_or_1;
    wire [31:0] signal_mux_39;
    wire [31:0] signal_select_5;
    wire signal_eq_6;
    wire signal_lt_2;
    wire signal_or_2;
    wire [7:0] signal_select_6;
    wire [31:0] signal_mux_40;
    wire [31:0] signal_select_7;
    wire signal_eq_7;
    wire [15:0] signal_const_37;
    wire signal_lt_3;
    wire signal_or_3;
    wire [15:0] signal_const_38;
    wire [15:0] signal_add_8;
    wire signal_eq_8;
    wire [676:0] signal_cat_8;
    wire [676:0] signal_mux_41;
    wire [676:0] signal_mux_42;
    wire [15:0] signal_select_8;
    wire [15:0] signal_add_9;
    wire [15:0] signal_mux_43;
    wire [15:0] signal_mux_44;
    wire [15:0] signal_mux_45;
    wire [15:0] signal_mux_46;
    reg [15:0] signal_cases_1;
    wire [15:0] signal_wire_1;
    reg [15:0] dimension_position;
    wire [15:0] signal_add_10;
    wire [676:0] signal_cat_9;
    wire [676:0] signal_mux_47;
    wire [676:0] signal_mux_48;
    wire [15:0] signal_add_11;
    wire [15:0] signal_add_12;
    wire [676:0] signal_cat_10;
    wire [676:0] signal_mux_49;
    wire [676:0] signal_mux_50;
    wire [676:0] signal_mux_51;
    wire [15:0] signal_const_48;
    wire [15:0] signal_add_13;
    wire [676:0] signal_cat_11;
    wire [15:0] signal_add_14;
    wire [676:0] signal_cat_12;
    wire [15:0] signal_const_54;
    wire [15:0] signal_add_15;
    wire [676:0] signal_cat_13;
    wire [63:0] signal_select_9;
    wire signal_select_10;
    wire [31:0] signal_select_11;
    wire [63:0] signal_select_12;
    wire signal_select_13;
    wire [162:0] signal_const_56;
    wire [63:0] signal_select_14;
    wire signal_select_15;
    wire [31:0] signal_select_16;
    wire [63:0] signal_select_17;
    wire signal_select_18;
    wire signal_select_19;
    wire [162:0] signal_cat_14;
    wire [162:0] signal_mux_52;
    wire [162:0] signal_wire_2;
    reg [162:0] packet_bits;
    wire signal_select_20;
    wire [15:0] signal_select_21;
    wire signal_select_22;
    wire [63:0] signal_select_23;
    wire [63:0] signal_select_24;
    wire [63:0] signal_select_25;
    wire signal_eq_9;
    wire [63:0] signal_mux_53;
    wire [63:0] signal_select_26;
    wire [63:0] signal_mux_54;
    wire [63:0] signal_mux_55;
    reg [63:0] signal_cases_2;
    wire [63:0] signal_mux_56;
    wire [63:0] signal_wire_3;
    reg [63:0] transaction;
    wire signal_const_60;
    wire signal_mux_57;
    wire signal_mux_58;
    reg signal_cases_3;
    wire signal_mux_59;
    wire signal_wire_4;
    reg transaction_present;
    wire [15:0] signal_select_27;
    wire [15:0] signal_add_16;
    wire [676:0] signal_cat_15;
    wire [676:0] signal_mux_60;
    wire [676:0] signal_mux_61;
    wire [676:0] signal_mux_62;
    wire [676:0] signal_mux_63;
    wire [676:0] signal_mux_64;
    reg [676:0] signal_cases_4;
    wire [676:0] signal_mux_65;
    wire [676:0] signal_wire_5;
    reg [676:0] event_bits;
    wire [10:0] signal_const_63;
    wire [15:0] signal_cat_16;
    wire signal_lt_4;
    wire signal_not_1;
    wire [4:0] signal_const_64;
    wire signal_eq_10;
    wire signal_and_5;
    wire signal_and_6;
    wire [4:0] signal_const_65;
    wire signal_eq_11;
    wire signal_or_4;
    wire signal_not_2;
    wire signal_wire_6;
    wire signal_select_28;
    wire signal_or_5;
    wire signal_mux_66;
    wire signal_not_3;
    wire signal_eq_12;
    wire signal_not_4;
    wire signal_and_7;
    wire [4:0] signal_const_69;
    wire [4:0] signal_const_71;
    wire [4:0] signal_const_72;
    wire [4:0] signal_mux_67;
    wire signal_wire_7;
    wire signal_eq_13;
    wire signal_and_8;
    wire retiring;
    wire [4:0] signal_mux_68;
    wire signal_eq_14;
    wire signal_and_9;
    wire [4:0] signal_mux_69;
    wire [4:0] signal_mux_70;
    wire [4:0] signal_mux_71;
    wire [4:0] signal_const_79;
    wire [4:0] signal_mux_72;
    wire [4:0] signal_mux_73;
    wire [4:0] signal_const_81;
    wire [4:0] signal_mux_74;
    wire [4:0] signal_mux_75;
    wire [4:0] signal_mux_76;
    wire [20:0] signal_const_83;
    wire [24:0] signal_cat_17;
    wire signal_lt_5;
    wire signal_not_5;
    wire [24:0] signal_cat_18;
    wire [24:0] headroom_live_orders;
    wire signal_select_29;
    wire signal_not_6;
    wire fits_after_consume_live_orders;
    wire [7:0] signal_const_84;
    wire signal_eq_15;
    wire signal_not_7;
    wire [15:0] signal_const_85;
    wire signal_lt_6;
    wire signal_not_8;
    wire signal_and_10;
    wire signal_and_11;
    wire [4:0] signal_mux_77;
    wire [4:0] signal_mux_78;
    wire [4:0] signal_mux_79;
    wire [4:0] signal_const_88;
    wire [24:0] signal_cat_19;
    wire signal_lt_7;
    wire signal_not_9;
    wire [24:0] signal_cat_20;
    wire [24:0] headroom_prefetched_orders;
    wire signal_select_30;
    wire signal_not_10;
    wire fits_after_consume_prefetched_orders;
    wire signal_eq_16;
    wire signal_not_11;
    wire signal_lt_8;
    wire signal_not_12;
    wire signal_and_12;
    wire signal_and_13;
    wire [4:0] signal_mux_80;
    wire [4:0] signal_mux_81;
    wire [4:0] signal_mux_82;
    wire [4:0] signal_mux_83;
    wire [4:0] signal_mux_84;
    wire [4:0] signal_mux_85;
    wire [4:0] signal_mux_86;
    wire [4:0] signal_const_98;
    wire [4:0] signal_mux_87;
    wire [4:0] signal_mux_88;
    wire [4:0] signal_mux_89;
    wire [4:0] signal_mux_90;
    wire [4:0] signal_mux_91;
    wire [4:0] signal_mux_92;
    wire [4:0] signal_mux_93;
    wire [4:0] signal_mux_94;
    wire [4:0] signal_mux_95;
    wire [4:0] signal_mux_96;
    wire [4:0] signal_mux_97;
    wire [4:0] signal_const_108;
    wire [4:0] signal_mux_98;
    wire [4:0] signal_const_109;
    wire [4:0] signal_mux_99;
    wire [4:0] signal_mux_100;
    wire [4:0] signal_mux_101;
    wire [4:0] signal_const_111;
    wire [4:0] signal_mux_102;
    wire [4:0] signal_mux_103;
    wire [4:0] signal_mux_104;
    wire [4:0] signal_mux_105;
    wire [4:0] signal_mux_106;
    wire [4:0] signal_mux_107;
    wire [4:0] signal_mux_108;
    wire [4:0] signal_add_17;
    wire signal_lt_9;
    wire signal_not_13;
    wire signal_eq_17;
    wire signal_not_14;
    wire signal_and_14;
    wire [4:0] signal_mux_109;
    wire [4:0] signal_mux_110;
    wire [4:0] signal_mux_111;
    reg [4:0] signal_cases_5;
    wire [4:0] signal_mux_112;
    wire [15:0] signal_cat_21;
    wire signal_lt_10;
    wire signal_eq_18;
    wire signal_and_15;
    wire [15:0] signal_cat_22;
    wire signal_lt_11;
    wire signal_eq_19;
    wire signal_not_15;
    wire signal_or_6;
    wire signal_or_7;
    wire signal_eq_20;
    wire signal_not_16;
    wire [4:0] signal_select_31;
    wire signal_lt_12;
    wire [4:0] tail_available;
    wire [15:0] signal_cat_23;
    wire [15:0] tail_remaining;
    wire signal_lt_13;
    wire [4:0] tail_count;
    wire [4:0] signal_select_32;
    wire signal_lt_14;
    wire signal_and_16;
    wire [15:0] signal_const_134;
    wire [15:0] signal_add_18;
    wire signal_lt_15;
    wire signal_not_17;
    reg hdr_dimensions_fit;
    wire signal_and_17;
    wire [15:0] signal_const_136;
    wire signal_lt_16;
    wire signal_not_18;
    reg hdr_root_within_window;
    wire signal_eq_21;
    wire signal_and_18;
    wire signal_and_19;
    wire [15:0] signal_const_139;
    wire signal_lt_17;
    wire signal_not_19;
    reg hdr_root_within_head;
    wire [15:0] signal_sub_2;
    wire signal_lt_18;
    wire signal_not_20;
    wire signal_lt_19;
    wire signal_not_21;
    wire [15:0] signal_const_145;
    wire signal_lt_20;
    wire signal_not_22;
    wire signal_lt_21;
    wire signal_not_23;
    wire signal_lt_22;
    wire signal_not_24;
    wire signal_eq_22;
    wire signal_and_20;
    wire signal_and_21;
    wire signal_and_22;
    wire signal_and_23;
    wire signal_and_24;
    wire [15:0] signal_mux_113;
    wire [15:0] signal_select_33;
    wire [15:0] signal_mux_114;
    wire [15:0] signal_add_19;
    wire signal_eq_23;
    wire [15:0] signal_mux_115;
    wire [15:0] signal_mux_116;
    wire [15:0] signal_mux_117;
    wire [15:0] signal_add_20;
    wire signal_eq_24;
    wire [15:0] signal_mux_118;
    wire [15:0] signal_mux_119;
    wire [15:0] signal_mux_120;
    wire [15:0] signal_mux_121;
    wire [15:0] signal_add_21;
    wire signal_eq_25;
    wire [15:0] signal_mux_122;
    wire [15:0] signal_mux_123;
    wire [15:0] signal_mux_124;
    wire [15:0] signal_mux_125;
    wire signal_eq_26;
    wire [15:0] signal_mux_126;
    wire [15:0] signal_mux_127;
    wire [15:0] signal_mux_128;
    wire signal_eq_27;
    wire [15:0] signal_mux_129;
    wire [15:0] signal_mux_130;
    wire [15:0] signal_mux_131;
    wire [15:0] signal_mux_132;
    wire [15:0] signal_mux_133;
    wire signal_eq_28;
    wire [15:0] signal_mux_134;
    wire [15:0] signal_mux_135;
    wire [15:0] signal_mux_136;
    wire [15:0] signal_mux_137;
    wire [15:0] signal_mux_138;
    wire [15:0] signal_mux_139;
    wire [15:0] signal_cat_24;
    wire [15:0] signal_add_22;
    wire [15:0] signal_mux_140;
    wire signal_mux_141;
    wire signal_mux_142;
    wire signal_mux_143;
    wire signal_eq_29;
    wire signal_and_25;
    wire signal_and_26;
    wire signal_mux_144;
    wire signal_mux_145;
    wire [4:0] signal_sub_3;
    wire [4:0] signal_mux_146;
    wire signal_eq_30;
    wire signal_and_27;
    wire signal_and_28;
    wire signal_mux_147;
    wire [18:0] signal_const_176;
    wire [23:0] signal_cat_25;
    wire signal_eq_31;
    wire signal_and_29;
    wire [23:0] signal_const_177;
    wire signal_eq_32;
    wire signal_or_8;
    wire signal_mux_148;
    wire signal_mux_149;
    wire signal_mux_150;
    wire signal_mux_151;
    wire signal_mux_152;
    wire signal_mux_153;
    wire [7:0] signal_select_34;
    wire signal_eq_33;
    wire [15:0] signal_select_35;
    wire signal_lt_23;
    wire signal_not_25;
    wire signal_eq_34;
    wire signal_eq_35;
    wire signal_and_30;
    wire signal_and_31;
    wire signal_and_32;
    wire signal_and_33;
    wire signal_and_34;
    wire final_order_dimension;
    wire signal_mux_154;
    wire signal_not_26;
    wire [7:0] signal_select_36;
    wire [7:0] signal_select_37;
    wire [7:0] signal_select_38;
    wire signal_eq_36;
    wire [7:0] signal_mux_155;
    wire [63:0] signal_select_39;
    reg [63:0] signal_reg;
    wire signal_eq_37;
    wire signal_eq_38;
    wire signal_and_35;
    wire signal_and_36;
    wire [63:0] signal_mux_156;
    wire [23:0] signal_select_40;
    reg [23:0] signal_reg_1;
    wire signal_eq_39;
    wire signal_eq_40;
    wire signal_and_37;
    wire signal_and_38;
    wire [23:0] signal_mux_157;
    wire [87:0] root;
    wire [7:0] signal_select_41;
    wire [7:0] signal_mux_158;
    wire [7:0] signal_mux_159;
    reg [7:0] signal_cases_6;
    wire [7:0] signal_mux_160;
    wire [7:0] signal_wire_8;
    reg [7:0] indicator;
    wire signal_select_42;
    wire signal_and_39;
    wire signal_mux_161;
    wire signal_mux_162;
    wire signal_mux_163;
    wire signal_mux_164;
    wire signal_mux_165;
    wire signal_mux_166;
    wire signal_mux_167;
    wire signal_mux_168;
    wire signal_mux_169;
    wire signal_mux_170;
    wire [24:0] signal_const_191;
    wire signal_lt_24;
    wire signal_not_27;
    wire signal_select_43;
    wire signal_not_28;
    wire fits_dimensions;
    wire signal_mux_171;
    wire signal_eq_41;
    wire signal_and_40;
    wire signal_mux_172;
    wire [23:0] signal_const_193;
    wire [23:0] signal_cat_26;
    wire [23:0] signal_add_23;
    wire [23:0] signal_add_24;
    wire [15:0] signal_select_44;
    wire [15:0] signal_sub_4;
    wire [23:0] signal_cat_27;
    wire signal_lt_25;
    wire signal_not_29;
    wire [23:0] signal_add_25;
    wire [23:0] signal_cat_28;
    wire signal_lt_26;
    wire signal_not_30;
    wire signal_eq_42;
    wire signal_eq_43;
    wire signal_and_41;
    wire signal_and_42;
    wire [23:0] signal_mux_173;
    wire [7:0] order_count;
    wire [23:0] orders_bytes;
    wire [24:0] signal_cat_29;
    wire signal_lt_27;
    wire signal_not_31;
    wire signal_select_45;
    wire signal_not_32;
    wire fits_orders;
    wire signal_not_33;
    wire signal_eq_44;
    wire signal_eq_45;
    wire signal_and_43;
    wire signal_and_44;
    wire signal_or_9;
    wire signal_and_45;
    wire [127:0] signal_mux_174;
    wire [63:0] signal_select_46;
    reg [63:0] order_dimensions;
    wire [15:0] order_block;
    wire signal_lt_28;
    wire signal_or_10;
    wire [23:0] signal_mux_175;
    wire [23:0] signal_mux_176;
    wire [7:0] signal_select_47;
    wire [15:0] signal_select_48;
    wire [23:0] order_bytes_live_orders;
    wire [23:0] signal_mux_177;
    wire [7:0] signal_select_49;
    wire [15:0] signal_select_50;
    wire [23:0] order_bytes_prefetched_orders;
    wire [7:0] signal_select_51;
    wire signal_eq_46;
    wire [15:0] signal_select_52;
    wire signal_lt_29;
    wire signal_not_34;
    wire signal_eq_47;
    wire signal_and_46;
    wire signal_and_47;
    wire signal_and_48;
    wire signal_and_49;
    wire [23:0] signal_mux_178;
    wire [23:0] signal_mux_179;
    wire [23:0] signal_mux_180;
    wire [15:0] signal_cat_30;
    wire [15:0] signal_sub_5;
    wire [15:0] signal_sub_6;
    wire [23:0] signal_cat_31;
    wire [23:0] signal_mux_181;
    wire [23:0] signal_mux_182;
    wire [23:0] signal_mux_183;
    wire [15:0] signal_cat_32;
    wire [15:0] signal_sub_7;
    wire [15:0] signal_sub_8;
    wire [23:0] signal_cat_33;
    wire [23:0] signal_mux_184;
    wire [23:0] signal_mux_185;
    wire [23:0] signal_mux_186;
    wire [23:0] signal_cat_34;
    wire signal_and_50;
    wire [15:0] signal_sub_9;
    reg [15:0] hdr_root_extension;
    wire [23:0] signal_cat_35;
    wire [23:0] signal_cat_36;
    wire [23:0] signal_sub_10;
    wire signal_or_11;
    wire [23:0] signal_mux_187;
    wire [23:0] signal_add_26;
    wire [4:0] signal_select_53;
    wire [23:0] signal_const_222;
    wire [23:0] signal_add_27;
    wire [4:0] signal_select_54;
    wire [4:0] signal_mux_188;
    wire [4:0] signal_select_55;
    wire signal_lt_30;
    wire [4:0] available_skip;
    wire [23:0] signal_cat_37;
    wire signal_lt_31;
    wire [4:0] signal_mux_189;
    wire [23:0] signal_add_28;
    wire [23:0] signal_cat_38;
    wire signal_lt_32;
    wire signal_not_35;
    wire [23:0] signal_const_228;
    wire signal_lt_33;
    wire signal_not_36;
    wire signal_and_51;
    wire [23:0] signal_cat_39;
    wire signal_lt_34;
    wire [23:0] signal_const_230;
    wire signal_lt_35;
    wire signal_and_52;
    wire [15:0] signal_mux_190;
    wire [15:0] signal_mux_191;
    wire [15:0] signal_mux_192;
    wire [15:0] signal_mux_193;
    wire [15:0] signal_mux_194;
    wire [15:0] signal_mux_195;
    reg [15:0] signal_cases_7;
    wire [15:0] signal_wire_9;
    reg [15:0] entry_count;
    wire [15:0] signal_add_29;
    wire [15:0] signal_add_30;
    wire [23:0] signal_cat_40;
    wire signal_eq_48;
    wire signal_and_53;
    wire signal_eq_49;
    wire signal_or_12;
    wire [15:0] signal_mux_196;
    wire [15:0] signal_mux_197;
    wire [15:0] signal_add_31;
    wire [15:0] signal_cat_41;
    wire [15:0] signal_add_32;
    wire signal_eq_50;
    wire [15:0] signal_mux_198;
    wire signal_not_37;
    wire signal_not_38;
    wire signal_or_13;
    wire [15:0] signal_mux_199;
    wire [15:0] signal_mux_200;
    wire [15:0] signal_add_33;
    wire [15:0] signal_cat_42;
    wire [15:0] signal_add_34;
    wire [15:0] signal_mux_201;
    wire [15:0] signal_mux_202;
    wire [15:0] signal_mux_203;
    wire [15:0] signal_mux_204;
    wire [15:0] signal_mux_205;
    wire [15:0] signal_mux_206;
    reg [15:0] signal_cases_8;
    wire [15:0] signal_wire_10;
    reg [15:0] entry_block;
    wire signal_eq_51;
    wire [15:0] signal_mux_207;
    wire signal_lt_36;
    wire signal_not_39;
    wire [7:0] signal_const_246;
    wire signal_eq_52;
    wire signal_and_54;
    wire signal_lt_37;
    wire signal_not_40;
    wire [7:0] signal_const_248;
    wire signal_eq_53;
    wire signal_and_55;
    wire signal_lt_38;
    wire signal_not_41;
    wire [7:0] signal_const_250;
    wire signal_eq_54;
    wire signal_and_56;
    wire signal_lt_39;
    wire signal_not_42;
    wire [7:0] signal_const_252;
    wire signal_eq_55;
    wire signal_and_57;
    wire signal_lt_40;
    wire signal_not_43;
    wire [7:0] signal_const_254;
    wire signal_eq_56;
    wire signal_and_58;
    wire signal_lt_41;
    wire signal_not_44;
    wire [7:0] signal_const_256;
    wire signal_eq_57;
    wire signal_and_59;
    wire signal_lt_42;
    wire signal_not_45;
    wire [7:0] signal_const_258;
    wire [7:0] signal_select_56;
    wire signal_eq_58;
    wire signal_and_60;
    wire signal_or_14;
    wire signal_or_15;
    wire signal_or_16;
    wire signal_or_17;
    wire signal_or_18;
    wire signal_or_19;
    wire signal_not_46;
    wire signal_lt_43;
    wire signal_not_47;
    wire [7:0] signal_const_260;
    wire signal_eq_59;
    wire signal_and_61;
    wire signal_lt_44;
    wire signal_not_48;
    wire [7:0] signal_const_262;
    wire signal_eq_60;
    wire signal_and_62;
    wire signal_lt_45;
    wire signal_not_49;
    wire [7:0] signal_const_264;
    wire signal_eq_61;
    wire signal_and_63;
    wire signal_lt_46;
    wire signal_not_50;
    wire [7:0] signal_const_266;
    wire signal_eq_62;
    wire signal_and_64;
    wire signal_lt_47;
    wire signal_not_51;
    wire [7:0] signal_const_268;
    wire signal_eq_63;
    wire signal_and_65;
    wire signal_lt_48;
    wire signal_not_52;
    wire [7:0] signal_select_57;
    wire [7:0] signal_select_58;
    wire [7:0] signal_select_59;
    wire [7:0] signal_select_60;
    wire [7:0] signal_select_61;
    wire [7:0] signal_select_62;
    wire [7:0] signal_select_63;
    wire [7:0] signal_select_64;
    wire [7:0] signal_select_65;
    wire [7:0] signal_select_66;
    wire [7:0] signal_select_67;
    wire [7:0] signal_select_68;
    wire [7:0] signal_select_69;
    wire [7:0] signal_select_70;
    wire [7:0] signal_select_71;
    wire [7:0] signal_select_72;
    wire [7:0] signal_select_73;
    wire [15:0] signal_sub_11;
    wire [3:0] signal_select_74;
    reg [7:0] signal_mux_208;
    wire [7:0] signal_mux_209;
    reg [7:0] signal_reg_2;
    wire signal_lt_49;
    wire signal_not_53;
    wire signal_and_66;
    wire signal_and_67;
    wire [15:0] signal_cat_43;
    wire [15:0] signal_add_35;
    wire signal_lt_50;
    wire signal_lt_51;
    wire signal_not_54;
    wire signal_eq_64;
    wire signal_and_68;
    wire signal_and_69;
    wire signal_and_70;
    wire signal_or_20;
    wire [7:0] signal_mux_210;
    wire [7:0] signal_select_75;
    wire [7:0] signal_select_76;
    wire [7:0] signal_select_77;
    wire [7:0] signal_select_78;
    wire [7:0] signal_select_79;
    wire [7:0] signal_select_80;
    wire [7:0] signal_select_81;
    wire [7:0] signal_select_82;
    wire [7:0] signal_select_83;
    wire [7:0] signal_select_84;
    wire [7:0] signal_select_85;
    wire [7:0] signal_select_86;
    wire [7:0] signal_select_87;
    wire [7:0] signal_select_88;
    wire [7:0] signal_select_89;
    wire [7:0] signal_select_90;
    wire [7:0] signal_select_91;
    wire [15:0] signal_sub_12;
    wire [3:0] signal_select_92;
    reg [7:0] signal_mux_211;
    wire [7:0] signal_mux_212;
    reg [7:0] signal_reg_3;
    wire [23:0] signal_const_280;
    wire signal_lt_52;
    wire signal_not_55;
    wire signal_and_71;
    wire signal_and_72;
    wire [15:0] signal_cat_44;
    wire [15:0] signal_add_36;
    wire signal_lt_53;
    wire signal_lt_54;
    wire signal_not_56;
    wire signal_eq_65;
    wire signal_and_73;
    wire signal_and_74;
    wire signal_and_75;
    wire signal_or_21;
    wire [7:0] signal_mux_213;
    wire [7:0] signal_select_93;
    wire [7:0] signal_select_94;
    wire [7:0] signal_select_95;
    wire [7:0] signal_select_96;
    wire [7:0] signal_select_97;
    wire [7:0] signal_select_98;
    wire [7:0] signal_select_99;
    wire [7:0] signal_select_100;
    wire [7:0] signal_select_101;
    wire [7:0] signal_select_102;
    wire [7:0] signal_select_103;
    wire [7:0] signal_select_104;
    wire [7:0] signal_select_105;
    wire [7:0] signal_select_106;
    wire [7:0] signal_select_107;
    wire [7:0] signal_select_108;
    wire [7:0] signal_select_109;
    wire [15:0] signal_sub_13;
    wire [3:0] signal_select_110;
    reg [7:0] signal_mux_214;
    wire [7:0] signal_mux_215;
    reg [7:0] signal_reg_4;
    wire [23:0] signal_const_287;
    wire signal_lt_55;
    wire signal_not_57;
    wire signal_and_76;
    wire signal_and_77;
    wire [15:0] signal_cat_45;
    wire [15:0] signal_add_37;
    wire signal_lt_56;
    wire signal_lt_57;
    wire signal_not_58;
    wire signal_eq_66;
    wire signal_and_78;
    wire signal_and_79;
    wire signal_and_80;
    wire signal_or_22;
    wire [7:0] signal_mux_216;
    wire [7:0] signal_select_111;
    wire [7:0] signal_select_112;
    wire [7:0] signal_select_113;
    wire [7:0] signal_select_114;
    wire [7:0] signal_select_115;
    wire [7:0] signal_select_116;
    wire [7:0] signal_select_117;
    wire [7:0] signal_select_118;
    wire [7:0] signal_select_119;
    wire [7:0] signal_select_120;
    wire [7:0] signal_select_121;
    wire [7:0] signal_select_122;
    wire [7:0] signal_select_123;
    wire [7:0] signal_select_124;
    wire [7:0] signal_select_125;
    wire [7:0] signal_select_126;
    wire [7:0] signal_select_127;
    wire [15:0] signal_const_293;
    wire [15:0] signal_sub_14;
    wire [3:0] signal_select_128;
    reg [7:0] signal_mux_217;
    wire [7:0] signal_mux_218;
    reg [7:0] signal_reg_5;
    wire signal_lt_58;
    wire signal_not_59;
    wire signal_and_81;
    wire signal_and_82;
    wire [15:0] signal_cat_46;
    wire [15:0] signal_add_38;
    wire signal_lt_59;
    wire signal_lt_60;
    wire signal_not_60;
    wire signal_eq_67;
    wire signal_and_83;
    wire signal_and_84;
    wire signal_and_85;
    wire signal_or_23;
    wire [7:0] signal_mux_219;
    wire [7:0] signal_select_129;
    wire [7:0] signal_select_130;
    wire [7:0] signal_select_131;
    wire [7:0] signal_select_132;
    wire [7:0] signal_select_133;
    wire [7:0] signal_select_134;
    wire [7:0] signal_select_135;
    wire [7:0] signal_select_136;
    wire [7:0] signal_select_137;
    wire [7:0] signal_select_138;
    wire [7:0] signal_select_139;
    wire [7:0] signal_select_140;
    wire [7:0] signal_select_141;
    wire [7:0] signal_select_142;
    wire [7:0] signal_select_143;
    wire [7:0] signal_select_144;
    wire [7:0] signal_select_145;
    wire [15:0] signal_const_300;
    wire [15:0] signal_sub_15;
    wire [3:0] signal_select_146;
    reg [7:0] signal_mux_220;
    wire [7:0] signal_mux_221;
    reg [7:0] signal_reg_6;
    wire [23:0] signal_const_301;
    wire signal_lt_61;
    wire signal_not_61;
    wire signal_and_86;
    wire signal_and_87;
    wire [15:0] signal_cat_47;
    wire [15:0] signal_add_39;
    wire signal_lt_62;
    wire signal_lt_63;
    wire signal_not_62;
    wire signal_eq_68;
    wire signal_and_88;
    wire signal_and_89;
    wire signal_and_90;
    wire signal_or_24;
    wire [7:0] signal_mux_222;
    wire [7:0] signal_select_147;
    wire [7:0] signal_select_148;
    wire [7:0] signal_select_149;
    wire [7:0] signal_select_150;
    wire [7:0] signal_select_151;
    wire [7:0] signal_select_152;
    wire [7:0] signal_select_153;
    wire [7:0] signal_select_154;
    wire [7:0] signal_select_155;
    wire [7:0] signal_select_156;
    wire [7:0] signal_select_157;
    wire [7:0] signal_select_158;
    wire [7:0] signal_select_159;
    wire [7:0] signal_select_160;
    wire [7:0] signal_select_161;
    wire [7:0] signal_select_162;
    wire [7:0] signal_select_163;
    wire [15:0] signal_const_307;
    wire [15:0] signal_sub_16;
    wire [3:0] signal_select_164;
    reg [7:0] signal_mux_223;
    wire [7:0] signal_mux_224;
    reg [7:0] signal_reg_7;
    wire [23:0] signal_const_308;
    wire signal_lt_64;
    wire signal_not_63;
    wire signal_and_91;
    wire signal_and_92;
    wire [15:0] signal_cat_48;
    wire [15:0] signal_add_40;
    wire signal_lt_65;
    wire signal_lt_66;
    wire signal_not_64;
    wire signal_eq_69;
    wire signal_and_93;
    wire signal_and_94;
    wire signal_and_95;
    wire signal_or_25;
    wire [7:0] signal_mux_225;
    wire [7:0] signal_select_165;
    wire [7:0] signal_select_166;
    wire [7:0] signal_select_167;
    wire [7:0] signal_select_168;
    wire [7:0] signal_select_169;
    wire [7:0] signal_select_170;
    wire [7:0] signal_select_171;
    wire [7:0] signal_select_172;
    wire [7:0] signal_select_173;
    wire [7:0] signal_select_174;
    wire [7:0] signal_select_175;
    wire [7:0] signal_select_176;
    wire [7:0] signal_select_177;
    wire [7:0] signal_select_178;
    wire [7:0] signal_select_179;
    wire [7:0] signal_select_180;
    wire [7:0] signal_select_181;
    wire [15:0] signal_sub_17;
    wire [3:0] signal_select_182;
    reg [7:0] signal_mux_226;
    wire [7:0] signal_mux_227;
    reg [7:0] signal_reg_8;
    wire [23:0] signal_const_315;
    wire signal_lt_67;
    wire signal_not_65;
    wire signal_and_96;
    wire signal_and_97;
    wire [15:0] signal_cat_49;
    wire [15:0] signal_add_41;
    wire signal_lt_68;
    wire signal_lt_69;
    wire signal_not_66;
    wire signal_eq_70;
    wire signal_and_98;
    wire signal_and_99;
    wire signal_and_100;
    wire signal_or_26;
    wire [7:0] signal_mux_228;
    wire [7:0] signal_select_183;
    wire [7:0] signal_select_184;
    wire [7:0] signal_select_185;
    wire [7:0] signal_select_186;
    wire [7:0] signal_select_187;
    wire [7:0] signal_select_188;
    wire [7:0] signal_select_189;
    wire [7:0] signal_select_190;
    wire [7:0] signal_select_191;
    wire [7:0] signal_select_192;
    wire [7:0] signal_select_193;
    wire [7:0] signal_select_194;
    wire [7:0] signal_select_195;
    wire [7:0] signal_select_196;
    wire [7:0] signal_select_197;
    wire [7:0] signal_select_198;
    wire [7:0] signal_select_199;
    wire [15:0] signal_const_321;
    wire [15:0] signal_sub_18;
    wire [3:0] signal_select_200;
    reg [7:0] signal_mux_229;
    wire [7:0] signal_mux_230;
    reg [7:0] signal_reg_9;
    wire signal_lt_70;
    wire signal_not_67;
    wire signal_and_101;
    wire signal_and_102;
    wire [15:0] signal_cat_50;
    wire [15:0] signal_add_42;
    wire signal_lt_71;
    wire signal_lt_72;
    wire signal_not_68;
    wire signal_eq_71;
    wire signal_and_103;
    wire signal_and_104;
    wire signal_and_105;
    wire signal_or_27;
    wire [7:0] signal_mux_231;
    wire [7:0] signal_select_201;
    wire [7:0] signal_select_202;
    wire [7:0] signal_select_203;
    wire [7:0] signal_select_204;
    wire [7:0] signal_select_205;
    wire [7:0] signal_select_206;
    wire [7:0] signal_select_207;
    wire [7:0] signal_select_208;
    wire [7:0] signal_select_209;
    wire [7:0] signal_select_210;
    wire [7:0] signal_select_211;
    wire [7:0] signal_select_212;
    wire [7:0] signal_select_213;
    wire [7:0] signal_select_214;
    wire [7:0] signal_select_215;
    wire [7:0] signal_select_216;
    wire [7:0] signal_select_217;
    wire [15:0] signal_sub_19;
    wire [3:0] signal_select_218;
    reg [7:0] signal_mux_232;
    wire [7:0] signal_mux_233;
    reg [7:0] signal_reg_10;
    wire signal_lt_73;
    wire signal_not_69;
    wire signal_and_106;
    wire signal_and_107;
    wire [15:0] signal_cat_51;
    wire [15:0] signal_add_43;
    wire signal_lt_74;
    wire signal_lt_75;
    wire signal_not_70;
    wire signal_eq_72;
    wire signal_and_108;
    wire signal_and_109;
    wire signal_and_110;
    wire signal_or_28;
    wire [7:0] signal_mux_234;
    wire [7:0] signal_select_219;
    wire [7:0] signal_select_220;
    wire [7:0] signal_select_221;
    wire [7:0] signal_select_222;
    wire [7:0] signal_select_223;
    wire [7:0] signal_select_224;
    wire [7:0] signal_select_225;
    wire [7:0] signal_select_226;
    wire [7:0] signal_select_227;
    wire [7:0] signal_select_228;
    wire [7:0] signal_select_229;
    wire [7:0] signal_select_230;
    wire [7:0] signal_select_231;
    wire [7:0] signal_select_232;
    wire [7:0] signal_select_233;
    wire [7:0] signal_select_234;
    wire [7:0] signal_select_235;
    wire [15:0] signal_sub_20;
    wire [3:0] signal_select_236;
    reg [7:0] signal_mux_235;
    wire [7:0] signal_mux_236;
    reg [7:0] signal_reg_11;
    wire [23:0] signal_const_336;
    wire signal_lt_76;
    wire signal_not_71;
    wire signal_and_111;
    wire signal_and_112;
    wire [15:0] signal_cat_52;
    wire [15:0] signal_add_44;
    wire signal_lt_77;
    wire signal_lt_78;
    wire signal_not_72;
    wire signal_eq_73;
    wire signal_and_113;
    wire signal_and_114;
    wire signal_and_115;
    wire signal_or_29;
    wire [7:0] signal_mux_237;
    wire [7:0] signal_select_237;
    wire [7:0] signal_select_238;
    wire [7:0] signal_select_239;
    wire [7:0] signal_select_240;
    wire [7:0] signal_select_241;
    wire [7:0] signal_select_242;
    wire [7:0] signal_select_243;
    wire [7:0] signal_select_244;
    wire [7:0] signal_select_245;
    wire [7:0] signal_select_246;
    wire [7:0] signal_select_247;
    wire [7:0] signal_select_248;
    wire [7:0] signal_select_249;
    wire [7:0] signal_select_250;
    wire [7:0] signal_select_251;
    wire [7:0] signal_select_252;
    wire [7:0] signal_select_253;
    wire [15:0] signal_sub_21;
    wire [3:0] signal_select_254;
    reg [7:0] signal_mux_238;
    wire [7:0] signal_mux_239;
    reg [7:0] signal_reg_12;
    wire [23:0] signal_const_343;
    wire signal_lt_79;
    wire signal_not_73;
    wire signal_and_116;
    wire signal_and_117;
    wire [15:0] signal_cat_53;
    wire [15:0] signal_add_45;
    wire signal_lt_80;
    wire signal_lt_81;
    wire signal_not_74;
    wire signal_eq_74;
    wire signal_and_118;
    wire signal_and_119;
    wire signal_and_120;
    wire signal_or_30;
    wire [7:0] signal_mux_240;
    wire [7:0] signal_select_255;
    wire [7:0] signal_select_256;
    wire [7:0] signal_select_257;
    wire [7:0] signal_select_258;
    wire [7:0] signal_select_259;
    wire [7:0] signal_select_260;
    wire [7:0] signal_select_261;
    wire [7:0] signal_select_262;
    wire [7:0] signal_select_263;
    wire [7:0] signal_select_264;
    wire [7:0] signal_select_265;
    wire [7:0] signal_select_266;
    wire [7:0] signal_select_267;
    wire [7:0] signal_select_268;
    wire [7:0] signal_select_269;
    wire [7:0] signal_select_270;
    wire [7:0] signal_select_271;
    wire [15:0] signal_sub_22;
    wire [3:0] signal_select_272;
    reg [7:0] signal_mux_241;
    wire [7:0] signal_mux_242;
    reg [7:0] signal_reg_13;
    wire [23:0] signal_const_350;
    wire signal_lt_82;
    wire signal_not_75;
    wire signal_and_121;
    wire signal_and_122;
    wire [15:0] signal_cat_54;
    wire [15:0] signal_add_46;
    wire signal_lt_83;
    wire signal_lt_84;
    wire signal_not_76;
    wire signal_eq_75;
    wire signal_and_123;
    wire signal_and_124;
    wire signal_and_125;
    wire signal_or_31;
    wire [7:0] signal_mux_243;
    wire [7:0] signal_select_273;
    wire [7:0] signal_select_274;
    wire [7:0] signal_select_275;
    wire [7:0] signal_select_276;
    wire [7:0] signal_select_277;
    wire [7:0] signal_select_278;
    wire [7:0] signal_select_279;
    wire [7:0] signal_select_280;
    wire [7:0] signal_select_281;
    wire [7:0] signal_select_282;
    wire [7:0] signal_select_283;
    wire [7:0] signal_select_284;
    wire [7:0] signal_select_285;
    wire [7:0] signal_select_286;
    wire [7:0] signal_select_287;
    wire [7:0] signal_select_288;
    wire [7:0] signal_select_289;
    wire [15:0] signal_sub_23;
    wire [3:0] signal_select_290;
    reg [7:0] signal_mux_244;
    wire [7:0] signal_mux_245;
    reg [7:0] signal_reg_14;
    wire [23:0] signal_const_357;
    wire signal_lt_85;
    wire signal_not_77;
    wire signal_and_126;
    wire signal_and_127;
    wire [15:0] signal_cat_55;
    wire [15:0] signal_add_47;
    wire signal_lt_86;
    wire signal_lt_87;
    wire signal_not_78;
    wire signal_eq_76;
    wire signal_and_128;
    wire signal_and_129;
    wire signal_and_130;
    wire signal_or_32;
    wire [7:0] signal_mux_246;
    wire [7:0] signal_select_291;
    wire [7:0] signal_select_292;
    wire [7:0] signal_select_293;
    wire [7:0] signal_select_294;
    wire [7:0] signal_select_295;
    wire [7:0] signal_select_296;
    wire [7:0] signal_select_297;
    wire [7:0] signal_select_298;
    wire [7:0] signal_select_299;
    wire [7:0] signal_select_300;
    wire [7:0] signal_select_301;
    wire [7:0] signal_select_302;
    wire [7:0] signal_select_303;
    wire [7:0] signal_select_304;
    wire [7:0] signal_select_305;
    wire [7:0] signal_select_306;
    wire [7:0] signal_select_307;
    wire [15:0] signal_sub_24;
    wire [3:0] signal_select_308;
    reg [7:0] signal_mux_247;
    wire [7:0] signal_mux_248;
    reg [7:0] signal_reg_15;
    wire [23:0] signal_const_364;
    wire signal_lt_88;
    wire signal_not_79;
    wire signal_and_131;
    wire signal_and_132;
    wire [15:0] signal_cat_56;
    wire [15:0] signal_add_48;
    wire signal_lt_89;
    wire signal_lt_90;
    wire signal_not_80;
    wire signal_eq_77;
    wire signal_and_133;
    wire signal_and_134;
    wire signal_and_135;
    wire signal_or_33;
    wire [7:0] signal_mux_249;
    wire [7:0] signal_select_309;
    wire [7:0] signal_select_310;
    wire [7:0] signal_select_311;
    wire [7:0] signal_select_312;
    wire [7:0] signal_select_313;
    wire [7:0] signal_select_314;
    wire [7:0] signal_select_315;
    wire [7:0] signal_select_316;
    wire [7:0] signal_select_317;
    wire [7:0] signal_select_318;
    wire [7:0] signal_select_319;
    wire [7:0] signal_select_320;
    wire [7:0] signal_select_321;
    wire [7:0] signal_select_322;
    wire [7:0] signal_select_323;
    wire [7:0] signal_select_324;
    wire [7:0] signal_select_325;
    wire [15:0] signal_const_370;
    wire [15:0] signal_sub_25;
    wire [3:0] signal_select_326;
    reg [7:0] signal_mux_250;
    wire [7:0] signal_mux_251;
    reg [7:0] signal_reg_16;
    wire [23:0] signal_cat_57;
    wire [23:0] prefetched_count;
    wire [23:0] signal_const_372;
    wire signal_lt_91;
    wire signal_not_81;
    wire signal_and_136;
    wire signal_and_137;
    wire [15:0] signal_cat_58;
    wire [15:0] signal_add_49;
    wire signal_lt_92;
    wire signal_lt_93;
    wire signal_not_82;
    wire signal_eq_78;
    wire signal_and_138;
    wire signal_and_139;
    wire signal_and_140;
    wire signal_or_34;
    wire [7:0] signal_mux_252;
    wire [7:0] signal_select_327;
    wire [7:0] signal_select_328;
    wire [7:0] signal_select_329;
    wire [7:0] signal_select_330;
    wire [7:0] signal_select_331;
    wire [7:0] signal_select_332;
    wire [7:0] signal_select_333;
    wire [7:0] signal_select_334;
    wire [7:0] signal_select_335;
    wire [7:0] signal_select_336;
    wire [7:0] signal_select_337;
    wire [7:0] signal_select_338;
    wire [7:0] signal_select_339;
    wire [7:0] signal_select_340;
    wire [7:0] signal_select_341;
    wire [7:0] signal_select_342;
    wire [15:0] signal_const_378;
    wire [15:0] signal_sub_26;
    wire [3:0] signal_select_343;
    reg [7:0] signal_mux_253;
    reg [7:0] signal_reg_17;
    wire [15:0] signal_cat_59;
    wire [15:0] signal_add_50;
    wire signal_lt_94;
    wire signal_lt_95;
    wire signal_not_83;
    wire signal_eq_79;
    wire signal_and_141;
    wire signal_and_142;
    wire signal_and_143;
    wire [7:0] signal_mux_254;
    wire [7:0] signal_select_344;
    wire [7:0] signal_select_345;
    wire [7:0] signal_select_346;
    wire [7:0] signal_select_347;
    wire [7:0] signal_select_348;
    wire [7:0] signal_select_349;
    wire [7:0] signal_select_350;
    wire [7:0] signal_select_351;
    wire [7:0] signal_select_352;
    wire [7:0] signal_select_353;
    wire [7:0] signal_select_354;
    wire [7:0] signal_select_355;
    wire [7:0] signal_select_356;
    wire [7:0] signal_select_357;
    wire [7:0] signal_select_358;
    wire [7:0] signal_select_359;
    wire [15:0] signal_const_384;
    wire [15:0] signal_sub_27;
    wire [3:0] signal_select_360;
    reg [7:0] signal_mux_255;
    reg [7:0] signal_reg_18;
    wire [15:0] signal_cat_60;
    wire [15:0] signal_add_51;
    wire signal_lt_96;
    wire signal_lt_97;
    wire signal_not_84;
    wire signal_eq_80;
    wire signal_and_144;
    wire signal_and_145;
    wire signal_and_146;
    wire [7:0] signal_mux_256;
    wire [7:0] signal_select_361;
    wire [7:0] signal_select_362;
    wire [7:0] signal_select_363;
    wire [7:0] signal_select_364;
    wire [7:0] signal_select_365;
    wire [7:0] signal_select_366;
    wire [7:0] signal_select_367;
    wire [7:0] signal_select_368;
    wire [7:0] signal_select_369;
    wire [7:0] signal_select_370;
    wire [7:0] signal_select_371;
    wire [7:0] signal_select_372;
    wire [7:0] signal_select_373;
    wire [7:0] signal_select_374;
    wire [7:0] signal_select_375;
    wire [7:0] signal_select_376;
    wire [15:0] signal_const_390;
    wire [15:0] signal_sub_28;
    wire [3:0] signal_select_377;
    reg [7:0] signal_mux_257;
    reg [7:0] signal_reg_19;
    wire [15:0] signal_cat_61;
    wire [15:0] signal_add_52;
    wire signal_lt_98;
    wire signal_lt_99;
    wire signal_not_85;
    wire signal_eq_81;
    wire signal_and_147;
    wire signal_and_148;
    wire signal_and_149;
    wire [7:0] signal_mux_258;
    wire [7:0] signal_select_378;
    wire [7:0] signal_select_379;
    wire [7:0] signal_select_380;
    wire [7:0] signal_select_381;
    wire [7:0] signal_select_382;
    wire [7:0] signal_select_383;
    wire [7:0] signal_select_384;
    wire [7:0] signal_select_385;
    wire [7:0] signal_select_386;
    wire [7:0] signal_select_387;
    wire [7:0] signal_select_388;
    wire [7:0] signal_select_389;
    wire [7:0] signal_select_390;
    wire [7:0] signal_select_391;
    wire [7:0] signal_select_392;
    wire [7:0] signal_select_393;
    wire [15:0] signal_const_396;
    wire [15:0] signal_sub_29;
    wire [3:0] signal_select_394;
    reg [7:0] signal_mux_259;
    reg [7:0] signal_reg_20;
    wire [15:0] signal_cat_62;
    wire [15:0] signal_add_53;
    wire signal_lt_100;
    wire signal_lt_101;
    wire signal_not_86;
    wire signal_eq_82;
    wire signal_and_150;
    wire signal_and_151;
    wire signal_and_152;
    wire [7:0] signal_mux_260;
    wire [7:0] signal_select_395;
    wire [7:0] signal_select_396;
    wire [7:0] signal_select_397;
    wire [7:0] signal_select_398;
    wire [7:0] signal_select_399;
    wire [7:0] signal_select_400;
    wire [7:0] signal_select_401;
    wire [7:0] signal_select_402;
    wire [7:0] signal_select_403;
    wire [7:0] signal_select_404;
    wire [7:0] signal_select_405;
    wire [7:0] signal_select_406;
    wire [7:0] signal_select_407;
    wire [7:0] signal_select_408;
    wire [7:0] signal_select_409;
    wire [7:0] signal_select_410;
    wire [15:0] signal_const_402;
    wire [15:0] signal_sub_30;
    wire [3:0] signal_select_411;
    reg [7:0] signal_mux_261;
    reg [7:0] signal_reg_21;
    wire [15:0] signal_cat_63;
    wire [15:0] signal_add_54;
    wire signal_lt_102;
    wire signal_lt_103;
    wire signal_not_87;
    wire signal_eq_83;
    wire signal_and_153;
    wire signal_and_154;
    wire signal_and_155;
    wire [7:0] signal_mux_262;
    wire [7:0] signal_select_412;
    wire [7:0] signal_select_413;
    wire [7:0] signal_select_414;
    wire [7:0] signal_select_415;
    wire [7:0] signal_select_416;
    wire [7:0] signal_select_417;
    wire [7:0] signal_select_418;
    wire [7:0] signal_select_419;
    wire [7:0] signal_select_420;
    wire [7:0] signal_select_421;
    wire [7:0] signal_select_422;
    wire [7:0] signal_select_423;
    wire [7:0] signal_select_424;
    wire [7:0] signal_select_425;
    wire [7:0] signal_select_426;
    wire [7:0] signal_select_427;
    wire [15:0] signal_sub_31;
    wire [3:0] signal_select_428;
    reg [7:0] signal_mux_263;
    reg [7:0] signal_reg_22;
    wire [15:0] signal_cat_64;
    wire [15:0] signal_add_55;
    wire signal_lt_104;
    wire signal_lt_105;
    wire signal_not_88;
    wire signal_eq_84;
    wire signal_and_156;
    wire signal_and_157;
    wire signal_and_158;
    wire [7:0] signal_mux_264;
    wire [7:0] signal_select_429;
    wire [7:0] signal_select_430;
    wire [7:0] signal_select_431;
    wire [7:0] signal_select_432;
    wire [7:0] signal_select_433;
    wire [7:0] signal_select_434;
    wire [7:0] signal_select_435;
    wire [7:0] signal_select_436;
    wire [7:0] signal_select_437;
    wire [7:0] signal_select_438;
    wire [7:0] signal_select_439;
    wire [7:0] signal_select_440;
    wire [7:0] signal_select_441;
    wire [7:0] signal_select_442;
    wire [7:0] signal_select_443;
    wire [7:0] signal_select_444;
    wire [15:0] signal_const_414;
    wire [15:0] signal_sub_32;
    wire [3:0] signal_select_445;
    reg [7:0] signal_mux_265;
    reg [7:0] signal_reg_23;
    wire [15:0] signal_cat_65;
    wire [15:0] signal_add_56;
    wire signal_lt_106;
    wire signal_lt_107;
    wire signal_not_89;
    wire signal_eq_85;
    wire signal_and_159;
    wire signal_and_160;
    wire signal_and_161;
    wire [7:0] signal_mux_266;
    wire [7:0] signal_select_446;
    wire [7:0] signal_select_447;
    wire [7:0] signal_select_448;
    wire [7:0] signal_select_449;
    wire [7:0] signal_select_450;
    wire [7:0] signal_select_451;
    wire [7:0] signal_select_452;
    wire [7:0] signal_select_453;
    wire [7:0] signal_select_454;
    wire [7:0] signal_select_455;
    wire [7:0] signal_select_456;
    wire [7:0] signal_select_457;
    wire [7:0] signal_select_458;
    wire [7:0] signal_select_459;
    wire [7:0] signal_select_460;
    wire [7:0] signal_select_461;
    wire [15:0] signal_const_420;
    wire [15:0] signal_sub_33;
    wire [3:0] signal_select_462;
    reg [7:0] signal_mux_267;
    reg [7:0] signal_reg_24;
    wire [15:0] signal_cat_66;
    wire [15:0] signal_add_57;
    wire signal_lt_108;
    wire signal_lt_109;
    wire signal_not_90;
    wire signal_eq_86;
    wire signal_and_162;
    wire signal_and_163;
    wire signal_and_164;
    wire [7:0] signal_mux_268;
    wire [7:0] signal_select_463;
    wire [7:0] signal_select_464;
    wire [7:0] signal_select_465;
    wire [7:0] signal_select_466;
    wire [7:0] signal_select_467;
    wire [7:0] signal_select_468;
    wire [7:0] signal_select_469;
    wire [7:0] signal_select_470;
    wire [7:0] signal_select_471;
    wire [7:0] signal_select_472;
    wire [7:0] signal_select_473;
    wire [7:0] signal_select_474;
    wire [7:0] signal_select_475;
    wire [7:0] signal_select_476;
    wire [7:0] signal_select_477;
    wire [7:0] signal_select_478;
    wire [15:0] signal_const_426;
    wire [15:0] signal_sub_34;
    wire [3:0] signal_select_479;
    reg [7:0] signal_mux_269;
    reg [7:0] signal_reg_25;
    wire [15:0] signal_cat_67;
    wire [15:0] signal_add_58;
    wire signal_lt_110;
    wire signal_lt_111;
    wire signal_not_91;
    wire signal_eq_87;
    wire signal_and_165;
    wire signal_and_166;
    wire signal_and_167;
    wire [7:0] signal_mux_270;
    wire [7:0] signal_select_480;
    wire [7:0] signal_select_481;
    wire [7:0] signal_select_482;
    wire [7:0] signal_select_483;
    wire [7:0] signal_select_484;
    wire [7:0] signal_select_485;
    wire [7:0] signal_select_486;
    wire [7:0] signal_select_487;
    wire [7:0] signal_select_488;
    wire [7:0] signal_select_489;
    wire [7:0] signal_select_490;
    wire [7:0] signal_select_491;
    wire [7:0] signal_select_492;
    wire [7:0] signal_select_493;
    wire [7:0] signal_select_494;
    wire [7:0] signal_select_495;
    wire [15:0] signal_sub_35;
    wire [3:0] signal_select_496;
    reg [7:0] signal_mux_271;
    reg [7:0] signal_reg_26;
    wire [15:0] signal_cat_68;
    wire [15:0] signal_add_59;
    wire signal_lt_112;
    wire signal_lt_113;
    wire signal_not_92;
    wire signal_eq_88;
    wire signal_and_168;
    wire signal_and_169;
    wire signal_and_170;
    wire [7:0] signal_mux_272;
    wire [7:0] signal_select_497;
    wire [7:0] signal_select_498;
    wire [7:0] signal_select_499;
    wire [7:0] signal_select_500;
    wire [7:0] signal_select_501;
    wire [7:0] signal_select_502;
    wire [7:0] signal_select_503;
    wire [7:0] signal_select_504;
    wire [7:0] signal_select_505;
    wire [7:0] signal_select_506;
    wire [7:0] signal_select_507;
    wire [7:0] signal_select_508;
    wire [7:0] signal_select_509;
    wire [7:0] signal_select_510;
    wire [7:0] signal_select_511;
    wire [7:0] signal_select_512;
    wire [15:0] signal_sub_36;
    wire [3:0] signal_select_513;
    reg [7:0] signal_mux_273;
    reg [7:0] signal_reg_27;
    wire [15:0] signal_cat_69;
    wire [15:0] signal_add_60;
    wire signal_lt_114;
    wire signal_lt_115;
    wire signal_not_93;
    wire signal_eq_89;
    wire signal_and_171;
    wire signal_and_172;
    wire signal_and_173;
    wire [7:0] signal_mux_274;
    wire [7:0] signal_select_514;
    wire [7:0] signal_select_515;
    wire [7:0] signal_select_516;
    wire [7:0] signal_select_517;
    wire [7:0] signal_select_518;
    wire [7:0] signal_select_519;
    wire [7:0] signal_select_520;
    wire [7:0] signal_select_521;
    wire [7:0] signal_select_522;
    wire [7:0] signal_select_523;
    wire [7:0] signal_select_524;
    wire [7:0] signal_select_525;
    wire [7:0] signal_select_526;
    wire [7:0] signal_select_527;
    wire [7:0] signal_select_528;
    wire [7:0] signal_select_529;
    wire [15:0] signal_sub_37;
    wire [3:0] signal_select_530;
    reg [7:0] signal_mux_275;
    reg [7:0] signal_reg_28;
    wire [15:0] signal_cat_70;
    wire [15:0] signal_add_61;
    wire signal_lt_116;
    wire signal_lt_117;
    wire signal_not_94;
    wire signal_eq_90;
    wire signal_and_174;
    wire signal_and_175;
    wire signal_and_176;
    wire [7:0] signal_mux_276;
    wire [7:0] signal_select_531;
    wire [7:0] signal_select_532;
    wire [7:0] signal_select_533;
    wire [7:0] signal_select_534;
    wire [7:0] signal_select_535;
    wire [7:0] signal_select_536;
    wire [7:0] signal_select_537;
    wire [7:0] signal_select_538;
    wire [7:0] signal_select_539;
    wire [7:0] signal_select_540;
    wire [7:0] signal_select_541;
    wire [7:0] signal_select_542;
    wire [7:0] signal_select_543;
    wire [7:0] signal_select_544;
    wire [7:0] signal_select_545;
    wire [7:0] signal_select_546;
    wire [15:0] signal_const_450;
    wire [15:0] signal_sub_38;
    wire [3:0] signal_select_547;
    reg [7:0] signal_mux_277;
    reg [7:0] signal_reg_29;
    wire [15:0] signal_cat_71;
    wire [15:0] signal_add_62;
    wire signal_lt_118;
    wire signal_lt_119;
    wire signal_not_95;
    wire signal_eq_91;
    wire signal_and_177;
    wire signal_and_178;
    wire signal_and_179;
    wire [7:0] signal_mux_278;
    wire [7:0] signal_select_548;
    wire [7:0] signal_select_549;
    wire [7:0] signal_select_550;
    wire [7:0] signal_select_551;
    wire [7:0] signal_select_552;
    wire [7:0] signal_select_553;
    wire [7:0] signal_select_554;
    wire [7:0] signal_select_555;
    wire [7:0] signal_select_556;
    wire [7:0] signal_select_557;
    wire [7:0] signal_select_558;
    wire [7:0] signal_select_559;
    wire [7:0] signal_select_560;
    wire [7:0] signal_select_561;
    wire [7:0] signal_select_562;
    wire [7:0] signal_select_563;
    wire [15:0] signal_const_456;
    wire [15:0] signal_sub_39;
    wire [3:0] signal_select_564;
    reg [7:0] signal_mux_279;
    reg [7:0] signal_reg_30;
    wire [15:0] signal_cat_72;
    wire [15:0] signal_add_63;
    wire signal_lt_120;
    wire signal_lt_121;
    wire signal_not_96;
    wire signal_eq_92;
    wire signal_and_180;
    wire signal_and_181;
    wire signal_and_182;
    wire [7:0] signal_mux_280;
    wire [7:0] signal_select_565;
    wire [7:0] signal_select_566;
    wire [7:0] signal_select_567;
    wire [7:0] signal_select_568;
    wire [7:0] signal_select_569;
    wire [7:0] signal_select_570;
    wire [7:0] signal_select_571;
    wire [7:0] signal_select_572;
    wire [7:0] signal_select_573;
    wire [7:0] signal_select_574;
    wire [7:0] signal_select_575;
    wire [7:0] signal_select_576;
    wire [7:0] signal_select_577;
    wire [7:0] signal_select_578;
    wire [7:0] signal_select_579;
    wire [7:0] signal_select_580;
    wire [15:0] signal_const_462;
    wire [15:0] signal_sub_40;
    wire [3:0] signal_select_581;
    reg [7:0] signal_mux_281;
    reg [7:0] signal_reg_31;
    wire [15:0] signal_cat_73;
    wire [15:0] signal_add_64;
    wire signal_lt_122;
    wire signal_lt_123;
    wire signal_not_97;
    wire signal_eq_93;
    wire signal_and_183;
    wire signal_and_184;
    wire signal_and_185;
    wire [7:0] signal_mux_282;
    wire [7:0] signal_select_582;
    wire [7:0] signal_select_583;
    wire [7:0] signal_select_584;
    wire [7:0] signal_select_585;
    wire [7:0] signal_select_586;
    wire [7:0] signal_select_587;
    wire [7:0] signal_select_588;
    wire [7:0] signal_select_589;
    wire [7:0] signal_select_590;
    wire [7:0] signal_select_591;
    wire [7:0] signal_select_592;
    wire [7:0] signal_select_593;
    wire [7:0] signal_select_594;
    wire [7:0] signal_select_595;
    wire [7:0] signal_select_596;
    wire [7:0] signal_select_597;
    wire [15:0] signal_const_468;
    wire [15:0] signal_sub_41;
    wire [3:0] signal_select_598;
    reg [7:0] signal_mux_283;
    reg [7:0] signal_reg_32;
    wire [15:0] signal_cat_74;
    wire [15:0] signal_add_65;
    wire signal_lt_124;
    wire signal_lt_125;
    wire signal_not_98;
    wire signal_eq_94;
    wire signal_and_186;
    wire signal_and_187;
    wire signal_and_188;
    wire [7:0] signal_mux_284;
    wire [7:0] signal_select_599;
    wire [7:0] signal_select_600;
    wire [7:0] signal_select_601;
    wire [7:0] signal_select_602;
    wire [7:0] signal_select_603;
    wire [7:0] signal_select_604;
    wire [7:0] signal_select_605;
    wire [7:0] signal_select_606;
    wire [7:0] signal_select_607;
    wire [7:0] signal_select_608;
    wire [7:0] signal_select_609;
    wire [7:0] signal_select_610;
    wire [7:0] signal_select_611;
    wire [7:0] signal_select_612;
    wire [7:0] signal_select_613;
    wire [7:0] signal_select_614;
    wire [15:0] signal_const_474;
    wire [15:0] signal_sub_42;
    wire [3:0] signal_select_615;
    reg [7:0] signal_mux_285;
    reg [7:0] signal_reg_33;
    wire [15:0] signal_cat_75;
    wire [15:0] signal_add_66;
    wire signal_lt_126;
    wire signal_lt_127;
    wire signal_not_99;
    wire signal_eq_95;
    wire signal_and_189;
    wire signal_and_190;
    wire signal_and_191;
    wire [7:0] signal_mux_286;
    wire [255:0] entry;
    wire [7:0] signal_select_616;
    wire signal_eq_96;
    wire signal_and_192;
    wire signal_or_35;
    wire signal_or_36;
    wire signal_or_37;
    wire signal_or_38;
    wire signal_or_39;
    wire signal_not_100;
    wire signal_or_40;
    wire [15:0] signal_mux_287;
    wire [15:0] signal_cat_76;
    wire signal_lt_128;
    wire signal_not_101;
    wire signal_and_193;
    wire [15:0] signal_mux_288;
    wire [7:0] signal_select_617;
    wire [15:0] count_entries;
    wire [31:0] signal_mulu;
    wire [23:0] entries_bytes;
    wire [24:0] signal_cat_77;
    wire signal_lt_129;
    wire signal_not_102;
    wire signal_select_618;
    wire signal_not_103;
    wire fits_entries;
    wire signal_not_104;
    wire [15:0] signal_const_483;
    wire signal_and_194;
    reg [23:0] combined_dimensions;
    wire signal_eq_97;
    wire signal_eq_98;
    wire signal_and_195;
    wire signal_and_196;
    wire signal_or_41;
    wire [127:0] signal_mux_289;
    wire [23:0] signal_select_619;
    reg [23:0] ordinary_dimensions;
    wire signal_eq_99;
    wire signal_and_197;
    reg used_combined_root;
    wire [23:0] dimensions;
    wire [15:0] block;
    wire signal_lt_130;
    wire signal_or_42;
    wire [15:0] signal_mux_290;
    wire [15:0] signal_mux_291;
    wire [24:0] signal_cat_78;
    wire signal_lt_131;
    wire signal_not_105;
    wire [7:0] signal_select_620;
    wire [15:0] signal_cat_79;
    wire [31:0] signal_mulu_1;
    wire [23:0] prefetch_root_bytes;
    wire [24:0] signal_cat_80;
    wire [24:0] headroom_prefetch_root;
    wire signal_select_621;
    wire signal_not_106;
    wire fits_after_consume_prefetch_root;
    wire [7:0] signal_select_622;
    wire [119:0] signal_const_495;
    wire [127:0] signal_cat_81;
    wire [15:0] signal_select_623;
    wire [111:0] signal_const_496;
    wire [127:0] signal_cat_82;
    wire [23:0] signal_select_624;
    wire [103:0] signal_const_497;
    wire [127:0] signal_cat_83;
    wire [31:0] signal_select_625;
    wire [95:0] signal_const_498;
    wire [127:0] signal_cat_84;
    wire [39:0] signal_select_626;
    wire [87:0] signal_const_499;
    wire [127:0] signal_cat_85;
    wire [47:0] signal_select_627;
    wire [79:0] signal_const_500;
    wire [127:0] signal_cat_86;
    wire [55:0] signal_select_628;
    wire [71:0] signal_const_501;
    wire [127:0] signal_cat_87;
    wire [63:0] signal_select_629;
    wire [127:0] signal_cat_88;
    wire [71:0] signal_select_630;
    wire [55:0] signal_const_503;
    wire [127:0] signal_cat_89;
    wire [79:0] signal_select_631;
    wire [47:0] signal_const_504;
    wire [127:0] signal_cat_90;
    wire [87:0] signal_select_632;
    wire [39:0] signal_const_505;
    wire [127:0] signal_cat_91;
    wire [95:0] signal_select_633;
    wire [127:0] signal_cat_92;
    wire [103:0] signal_select_634;
    wire [127:0] signal_cat_93;
    wire [111:0] signal_select_635;
    wire [127:0] signal_cat_94;
    wire [119:0] signal_select_636;
    wire [127:0] signal_cat_95;
    wire [3:0] signal_select_637;
    reg [127:0] prefetched_data;
    wire [15:0] signal_select_638;
    wire signal_lt_132;
    wire signal_not_107;
    wire signal_and_198;
    wire [15:0] signal_mux_292;
    wire [15:0] signal_mux_293;
    wire [24:0] signal_cat_96;
    wire signal_lt_133;
    wire signal_not_108;
    wire [7:0] signal_select_639;
    wire [15:0] combined_count;
    wire [31:0] signal_mulu_2;
    wire [23:0] combined_entries_bytes;
    wire [24:0] signal_cat_97;
    wire signal_lt_134;
    wire [4:0] drain_count;
    wire [4:0] signal_mux_294;
    wire [4:0] signal_mux_295;
    wire [3:0] signal_select_640;
    wire [3:0] consume_count;
    wire [15:0] signal_cat_98;
    wire [15:0] signal_add_67;
    wire signal_eq_100;
    wire signal_eq_101;
    wire draining;
    wire signal_and_199;
    wire drain;
    wire signal_or_43;
    wire signal_or_44;
    wire [15:0] signal_mux_296;
    wire [15:0] signal_mux_297;
    wire [15:0] signal_wire_11;
    reg [15:0] position;
    wire [8:0] signal_const_520;
    wire [24:0] signal_cat_99;
    wire signal_and_200;
    wire [15:0] signal_sub_43;
    reg [15:0] hdr_body_size;
    wire [24:0] signal_cat_100;
    wire [24:0] room;
    wire [24:0] room_1;
    wire [24:0] headroom_combined;
    wire signal_select_641;
    wire signal_not_109;
    wire combined_fits;
    wire fits_after_consume_combined;
    wire [7:0] signal_select_642;
    wire [127:0] signal_cat_101;
    wire [15:0] signal_select_643;
    wire [127:0] signal_cat_102;
    wire [23:0] signal_select_644;
    wire [127:0] signal_cat_103;
    wire [31:0] signal_select_645;
    wire [127:0] signal_cat_104;
    wire [39:0] signal_select_646;
    wire [127:0] signal_cat_105;
    wire [47:0] signal_select_647;
    wire [127:0] signal_cat_106;
    wire [55:0] signal_select_648;
    wire [127:0] signal_cat_107;
    wire [63:0] signal_select_649;
    wire [127:0] signal_cat_108;
    wire [71:0] signal_select_650;
    wire [127:0] signal_cat_109;
    wire [79:0] signal_select_651;
    wire [127:0] signal_cat_110;
    wire [87:0] signal_select_652;
    wire [127:0] signal_cat_111;
    wire [95:0] signal_select_653;
    wire [127:0] signal_cat_112;
    wire [103:0] signal_select_654;
    wire [127:0] signal_cat_113;
    wire [111:0] signal_select_655;
    wire [127:0] signal_cat_114;
    wire [119:0] signal_select_656;
    wire [127:0] signal_cat_115;
    wire [127:0] signal_select_657;
    wire [15:0] signal_sub_44;
    wire [3:0] signal_select_658;
    reg [127:0] signal_mux_298;
    wire [23:0] combined_dimension_data;
    wire [15:0] combined_block;
    wire signal_lt_135;
    wire signal_not_110;
    wire signal_and_201;
    wire [15:0] signal_mux_299;
    wire signal_and_202;
    wire [15:0] signal_mux_300;
    reg [15:0] signal_cases_9;
    wire [15:0] signal_wire_12;
    reg [15:0] entry_index;
    wire [15:0] signal_add_68;
    wire next_is_order;
    wire signal_mux_301;
    wire signal_lt_136;
    wire signal_eq_102;
    wire signal_and_203;
    wire signal_and_204;
    wire signal_and_205;
    wire prefetch_next;
    wire [4:0] signal_mux_302;
    wire [4:0] skip_count;
    wire signal_lt_137;
    wire signal_not_111;
    wire signal_eq_103;
    wire signal_not_112;
    wire signal_or_45;
    wire signal_eq_104;
    wire signal_eq_105;
    wire signal_eq_106;
    wire signal_or_46;
    wire skipping;
    wire signal_and_206;
    wire signal_and_207;
    wire signal_and_208;
    wire skip;
    wire [23:0] signal_mux_303;
    wire signal_and_209;
    wire [15:0] signal_add_69;
    reg [15:0] hdr_root_plus_dimensions;
    wire [15:0] signal_mux_304;
    wire signal_lt_138;
    wire [15:0] signal_mux_305;
    wire signal_eq_107;
    wire [15:0] signal_mux_306;
    wire signal_eq_108;
    wire [15:0] signal_mux_307;
    wire signal_eq_109;
    wire [15:0] target;
    wire [15:0] required;
    wire signal_lt_139;
    wire signal_not_113;
    wire signal_not_114;
    wire signal_and_210;
    wire signal_and_211;
    wire [23:0] signal_mux_308;
    reg [23:0] signal_cases_10;
    wire [23:0] signal_wire_13;
    reg [23:0] skip_left;
    wire signal_lt_140;
    wire signal_not_115;
    wire signal_eq_110;
    wire signal_and_212;
    wire signal_and_213;
    wire signal_and_214;
    wire signal_and_215;
    wire prefetch_root;
    wire signal_mux_309;
    wire signal_lt_141;
    wire signal_mux_310;
    wire signal_and_216;
    wire [15:0] signal_sub_45;
    wire signal_lt_142;
    reg hdr_root_over_body;
    wire [15:0] signal_select_659;
    wire signal_lt_143;
    wire signal_or_47;
    wire signal_mux_311;
    wire [15:0] signal_select_660;
    wire signal_lt_144;
    wire signal_mux_312;
    wire [161:0] signal_const_568;
    wire [15:0] signal_select_661;
    wire [15:0] signal_select_662;
    wire [15:0] signal_select_663;
    wire [15:0] signal_select_664;
    wire [15:0] signal_select_665;
    wire signal_select_666;
    wire [63:0] signal_select_667;
    wire signal_select_668;
    wire [15:0] signal_select_669;
    wire [161:0] signal_cat_116;
    wire [161:0] signal_mux_313;
    wire [161:0] signal_wire_14;
    reg [161:0] message_bits;
    wire [15:0] signal_select_670;
    wire signal_eq_111;
    wire signal_not_116;
    wire signal_mux_314;
    wire signal_wire_15;
    wire signal_and_217;
    wire signal_mux_315;
    wire signal_mux_316;
    reg signal_cases_11;
    wire signal_mux_317;
    wire signal_wire_16;
    reg event_pending;
    wire signal_not_117;
    wire event_space;
    wire [15:0] signal_mux_318;
    reg [15:0] signal_cases_12;
    wire [15:0] signal_mux_319;
    wire [15:0] signal_wire_17;
    reg [15:0] collected;
    wire signal_eq_112;
    wire signal_and_218;
    wire signal_or_48;
    wire signal_eq_113;
    wire signal_and_219;
    wire combined_root;
    wire signal_or_49;
    wire [4:0] signal_mux_320;
    wire signal_eq_114;
    wire [4:0] count;
    wire signal_lt_145;
    wire signal_not_118;
    wire signal_select_671;
    wire signal_and_220;
    wire signal_and_221;
    wire signal_and_222;
    wire signal_and_223;
    wire collect;
    wire signal_or_50;
    wire signal_or_51;
    wire consume_valid;
    wire signal_not_119;
    wire signal_not_120;
    wire signal_and_224;
    wire signal_and_225;
    wire signal_and_226;
    wire signal_select_672;
    wire [7:0] signal_select_673;
    wire [63:0] signal_select_674;
    wire [217:0] signal_inst;
    wire [4:0] available;
    wire signal_lt_146;
    wire signal_or_52;
    wire vdd;
    wire gnd;
    wire start;
    wire signal_mux_321;
    wire signal_mux_322;
    wire signal_wire_18;
    reg aborted;
    wire signal_not_121;
    wire signal_wire_19;
    wire signal_select_675;
    wire signal_select_676;
    wire signal_or_53;
    wire signal_or_54;
    wire signal_mux_323;
    wire signal_wire_20;
    reg input_done;
    wire signal_eq_115;
    wire signal_eq_116;
    wire signal_eq_117;
    wire signal_eq_118;
    wire signal_or_55;
    wire signal_or_56;
    wire collecting;
    wire signal_and_227;
    wire signal_and_228;
    wire signal_and_229;
    wire signal_and_230;
    wire [4:0] signal_mux_324;
    wire [1078:0] signal_wire_21;
    wire [1:0] signal_select_677;
    wire signal_eq_119;
    wire signal_wire_22;
    wire transfer;
    wire abort;
    wire [4:0] signal_mux_325;
    wire [4:0] signal_wire_23;
    reg [4:0] state;
    wire signal_eq_120;
    wire signal_or_57;
    wire signal_or_58;
    wire signal_wire_24;
    wire signal_not_122;
    wire signal_wire_25;
    wire signal_and_231;
    wire signal_and_232;
    wire ready;
    assign signal_const = 5'b00000;
    assign signal_eq = available == signal_const;
    assign signal_not = ~ event_pending;
    assign signal_eq_1 = state == signal_const;
    assign signal_and = signal_eq_1 & signal_not;
    assign signal_and_1 = signal_and & signal_eq;
    assign signal_const_2 = 5'b10000;
    assign signal_eq_2 = state == signal_const_2;
    assign signal_and_2 = signal_and_231 & signal_eq_2;
    assign signal_and_3 = signal_and_2 & event_space;
    assign signal_and_4 = signal_and_231 & event_pending;
    assign signal_const_3 = 677'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_const_4 = 2'b10;
    assign signal_const_5 = 334'b0000000000000000000000000000000000000011100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_sub = position - collected;
    assign signal_const_6 = 5'b01010;
    assign signal_eq_3 = state == signal_const_6;
    assign signal_mux = signal_eq_3 ? signal_sub : dimension_position;
    assign signal_add = signal_add_11 + signal_mux;
    assign signal_cat = { signal_add,
                          signal_const_5,
                          signal_select_27,
                          transaction_present,
                          transaction,
                          signal_select_22,
                          signal_select_660,
                          signal_select_670,
                          signal_select_21,
                          signal_select_659,
                          signal_select_44,
                          signal_select_20,
                          signal_select_13,
                          signal_select_12,
                          signal_select_11,
                          signal_select_10,
                          signal_select_9,
                          signal_const_4 };
    assign signal_mux_1 = signal_and_39 ? signal_cat_2 : event_bits;
    assign signal_mux_2 = event_space ? signal_mux_1 : event_bits;
    assign signal_mux_3 = signal_and_39 ? signal_cat_2 : event_bits;
    assign signal_mux_4 = signal_and_26 ? signal_mux_3 : event_bits;
    assign signal_mux_5 = signal_and_39 ? signal_cat_2 : event_bits;
    assign signal_mux_6 = signal_and_28 ? signal_mux_5 : event_bits;
    assign signal_mux_7 = signal_or_8 ? signal_mux_6 : event_bits;
    assign signal_const_9 = 16'b0000000000001000;
    assign signal_add_1 = signal_add_11 + position;
    assign signal_sub_1 = signal_add_1 - signal_const_9;
    assign signal_cat_1 = { signal_sub_1,
                            signal_const_5,
                            signal_select_27,
                            transaction_present,
                            transaction,
                            signal_select_22,
                            signal_select_660,
                            signal_select_670,
                            signal_select_21,
                            signal_select_659,
                            signal_select_44,
                            signal_select_20,
                            signal_select_13,
                            signal_select_12,
                            signal_select_11,
                            signal_select_10,
                            signal_select_9,
                            signal_const_4 };
    assign signal_mux_8 = signal_and_39 ? signal_cat_2 : event_bits;
    assign signal_mux_9 = signal_and_42 ? signal_mux_8 : event_bits;
    assign signal_mux_10 = signal_or_10 ? signal_cat_1 : signal_mux_9;
    assign signal_mux_11 = event_space ? signal_mux_10 : event_bits;
    assign signal_mux_12 = signal_and_39 ? signal_cat_2 : event_bits;
    assign signal_mux_13 = final_order_dimension ? signal_mux_12 : event_bits;
    assign signal_const_10 = 2'b01;
    assign signal_const_11 = 284'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_const_12 = 58'b0000000000000000000000000000000000000000000000000000000000;
    assign signal_cat_2 = { signal_const_12,
                            indicator,
                            signal_const_11,
                            signal_select_27,
                            transaction_present,
                            transaction,
                            signal_select_22,
                            signal_select_660,
                            signal_select_670,
                            signal_select_21,
                            signal_select_659,
                            signal_select_44,
                            signal_select_20,
                            signal_select_13,
                            signal_select_12,
                            signal_select_11,
                            signal_select_10,
                            signal_select_9,
                            signal_const_10 };
    assign signal_mux_14 = signal_and_39 ? signal_cat_2 : event_bits;
    assign signal_mux_15 = signal_and_49 ? signal_mux_14 : event_bits;
    assign signal_mux_16 = next_is_order ? signal_mux_15 : event_bits;
    assign signal_mux_17 = prefetch_next ? signal_mux_16 : event_bits;
    assign signal_const_14 = 334'b0000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_const_15 = 16'b0000000000011010;
    assign signal_const_16 = 16'b0000000000011001;
    assign signal_mux_18 = signal_or_39 ? signal_const_15 : signal_const_16;
    assign signal_add_2 = signal_add_11 + entry_position;
    assign signal_add_3 = signal_add_2 + signal_mux_18;
    assign signal_cat_3 = { signal_add_3,
                            signal_const_14,
                            signal_select_27,
                            transaction_present,
                            transaction,
                            signal_select_22,
                            signal_select_660,
                            signal_select_670,
                            signal_select_21,
                            signal_select_659,
                            signal_select_44,
                            signal_select_20,
                            signal_select_13,
                            signal_select_12,
                            signal_select_11,
                            signal_select_10,
                            signal_select_9,
                            signal_const_4 };
    assign signal_const_17 = 57'b000000000000000000000000000000000000000000000000000000000;
    assign signal_cat_4 = { signal_const_17,
                            signal_eq_8,
                            indicator,
                            signal_or_3,
                            signal_mux_40,
                            signal_select_56,
                            signal_select_616,
                            signal_select_6,
                            signal_or_2,
                            signal_mux_39,
                            signal_or_1,
                            signal_mux_38,
                            signal_or,
                            signal_mux_37,
                            signal_select_2,
                            signal_select_1,
                            entry_count,
                            entry_index,
                            signal_select_27,
                            transaction_present,
                            transaction,
                            signal_select_22,
                            signal_select_660,
                            signal_select_670,
                            signal_select_21,
                            signal_select_659,
                            signal_select_44,
                            signal_select_20,
                            signal_select_13,
                            signal_select_12,
                            signal_select_11,
                            signal_select_10,
                            signal_select_9,
                            signal_const_25 };
    assign signal_mux_19 = signal_or_13 ? signal_cat_3 : signal_cat_4;
    assign signal_mux_20 = event_space ? signal_mux_19 : event_bits;
    assign signal_mux_21 = signal_or_39 ? signal_const_15 : signal_const_16;
    assign signal_const_22 = 16'b0000000000000000;
    assign signal_select = skip_left[15:0];
    assign signal_add_4 = position + signal_select;
    assign signal_mux_22 = skip ? next_position : position;
    assign signal_mux_23 = signal_or_12 ? signal_mux_22 : entry_position;
    assign signal_mux_24 = prefetch_next ? signal_add_4 : signal_mux_23;
    assign signal_mux_25 = signal_eq_50 ? position : entry_position;
    assign signal_mux_26 = signal_or_13 ? entry_position : signal_mux_25;
    assign signal_mux_27 = event_space ? signal_mux_26 : entry_position;
    assign signal_const_23 = 12'b000000000000;
    assign signal_cat_5 = { signal_const_23,
                            consume_count };
    assign signal_add_5 = position + signal_cat_5;
    assign signal_mux_28 = signal_eq_51 ? signal_add_5 : entry_position;
    assign signal_mux_29 = signal_or_40 ? entry_position : signal_mux_28;
    assign signal_mux_30 = signal_and_193 ? signal_mux_29 : entry_position;
    assign signal_mux_31 = signal_or_42 ? entry_position : position;
    assign signal_mux_32 = event_space ? signal_mux_31 : entry_position;
    assign signal_mux_33 = signal_and_198 ? next_position : entry_position;
    assign signal_mux_34 = prefetch_root ? signal_mux_33 : entry_position;
    assign signal_cat_6 = { signal_const_23,
                            consume_count };
    assign next_position = position + signal_cat_6;
    assign signal_mux_35 = signal_and_201 ? next_position : entry_position;
    assign signal_mux_36 = signal_and_202 ? signal_mux_35 : entry_position;
    always @* begin
        case (state)
        5'b00010:
            signal_cases <= signal_mux_36;
        5'b00100:
            signal_cases <= signal_mux_34;
        5'b00110:
            signal_cases <= signal_mux_32;
        5'b00111:
            signal_cases <= signal_mux_30;
        5'b01000:
            signal_cases <= signal_mux_27;
        5'b01001:
            signal_cases <= signal_mux_24;
        default:
            signal_cases <= entry_position;
        endcase
    end
    assign signal_wire = signal_cases;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            entry_position <= signal_const_22;
        else
            if (signal_and_231)
                entry_position <= signal_wire;
    end
    assign signal_add_6 = signal_add_11 + entry_position;
    assign signal_add_7 = signal_add_6 + signal_mux_21;
    assign signal_cat_7 = { signal_add_7,
                            signal_const_14,
                            signal_select_27,
                            transaction_present,
                            transaction,
                            signal_select_22,
                            signal_select_660,
                            signal_select_670,
                            signal_select_21,
                            signal_select_659,
                            signal_select_44,
                            signal_select_20,
                            signal_select_13,
                            signal_select_12,
                            signal_select_11,
                            signal_select_10,
                            signal_select_9,
                            signal_const_4 };
    assign signal_const_25 = 2'b00;
    assign signal_select_1 = entry[127:96];
    assign signal_select_2 = entry[159:128];
    assign signal_const_26 = 64'b0000000000000000000000000000000000000000000000000000000000000000;
    assign signal_mux_37 = signal_or ? signal_const_26 : signal_select_3;
    assign signal_const_27 = 64'b0111111111111111111111111111111111111111111111111111111111111111;
    assign signal_select_3 = entry[63:0];
    assign signal_eq_4 = signal_select_3 == signal_const_27;
    assign signal_const_28 = 16'b0000000000001001;
    assign signal_lt = signal_select_660 < signal_const_28;
    assign signal_or = signal_lt | signal_eq_4;
    assign signal_const_29 = 32'b00000000000000000000000000000000;
    assign signal_mux_38 = signal_or_1 ? signal_const_29 : signal_select_4;
    assign signal_const_30 = 32'b01111111111111111111111111111111;
    assign signal_select_4 = entry[95:64];
    assign signal_eq_5 = signal_select_4 == signal_const_30;
    assign signal_lt_1 = signal_select_660 < signal_const_22;
    assign signal_or_1 = signal_lt_1 | signal_eq_5;
    assign signal_mux_39 = signal_or_2 ? signal_const_29 : signal_select_5;
    assign signal_select_5 = entry[191:160];
    assign signal_eq_6 = signal_select_5 == signal_const_30;
    assign signal_lt_2 = signal_select_660 < signal_const_22;
    assign signal_or_2 = signal_lt_2 | signal_eq_6;
    assign signal_select_6 = entry[199:192];
    assign signal_mux_40 = signal_or_3 ? signal_const_29 : signal_select_7;
    assign signal_select_7 = entry[247:216];
    assign signal_eq_7 = signal_select_7 == signal_const_30;
    assign signal_const_37 = 16'b0000000000001010;
    assign signal_lt_3 = signal_select_660 < signal_const_37;
    assign signal_or_3 = signal_lt_3 | signal_eq_7;
    assign signal_const_38 = 16'b0000000000000001;
    assign signal_add_8 = entry_index + signal_const_38;
    assign signal_eq_8 = signal_add_8 == entry_count;
    assign signal_cat_8 = { signal_const_17,
                            signal_eq_8,
                            indicator,
                            signal_or_3,
                            signal_mux_40,
                            signal_select_56,
                            signal_select_616,
                            signal_select_6,
                            signal_or_2,
                            signal_mux_39,
                            signal_or_1,
                            signal_mux_38,
                            signal_or,
                            signal_mux_37,
                            signal_select_2,
                            signal_select_1,
                            entry_count,
                            entry_index,
                            signal_select_27,
                            transaction_present,
                            transaction,
                            signal_select_22,
                            signal_select_660,
                            signal_select_670,
                            signal_select_21,
                            signal_select_659,
                            signal_select_44,
                            signal_select_20,
                            signal_select_13,
                            signal_select_12,
                            signal_select_11,
                            signal_select_10,
                            signal_select_9,
                            signal_const_25 };
    assign signal_mux_41 = signal_or_40 ? signal_cat_7 : signal_cat_8;
    assign signal_mux_42 = signal_and_193 ? signal_mux_41 : event_bits;
    assign signal_select_8 = skip_left[15:0];
    assign signal_add_9 = position + signal_select_8;
    assign signal_mux_43 = fits_dimensions ? position : dimension_position;
    assign signal_mux_44 = signal_and_40 ? signal_mux_43 : dimension_position;
    assign signal_mux_45 = prefetch_root ? signal_add_9 : signal_mux_44;
    assign signal_mux_46 = signal_and_202 ? signal_select_659 : dimension_position;
    always @* begin
        case (state)
        5'b00010:
            signal_cases_1 <= signal_mux_46;
        5'b00100:
            signal_cases_1 <= signal_mux_45;
        default:
            signal_cases_1 <= dimension_position;
        endcase
    end
    assign signal_wire_1 = signal_cases_1;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            dimension_position <= signal_const_22;
        else
            if (signal_and_231)
                dimension_position <= signal_wire_1;
    end
    assign signal_add_10 = signal_add_11 + dimension_position;
    assign signal_cat_9 = { signal_add_10,
                            signal_const_5,
                            signal_select_27,
                            transaction_present,
                            transaction,
                            signal_select_22,
                            signal_select_660,
                            signal_select_670,
                            signal_select_21,
                            signal_select_659,
                            signal_select_44,
                            signal_select_20,
                            signal_select_13,
                            signal_select_12,
                            signal_select_11,
                            signal_select_10,
                            signal_select_9,
                            signal_const_4 };
    assign signal_mux_47 = signal_or_42 ? signal_cat_9 : event_bits;
    assign signal_mux_48 = event_space ? signal_mux_47 : event_bits;
    assign signal_add_11 = signal_select_27 + signal_const_37;
    assign signal_add_12 = signal_add_11 + position;
    assign signal_cat_10 = { signal_add_12,
                             signal_const_5,
                             signal_select_27,
                             transaction_present,
                             transaction,
                             signal_select_22,
                             signal_select_660,
                             signal_select_670,
                             signal_select_21,
                             signal_select_659,
                             signal_select_44,
                             signal_select_20,
                             signal_select_13,
                             signal_select_12,
                             signal_select_11,
                             signal_select_10,
                             signal_select_9,
                             signal_const_4 };
    assign signal_mux_49 = fits_dimensions ? event_bits : signal_cat_10;
    assign signal_mux_50 = signal_and_40 ? signal_mux_49 : event_bits;
    assign signal_mux_51 = prefetch_root ? event_bits : signal_mux_50;
    assign signal_const_48 = 16'b0000000000000110;
    assign signal_add_13 = signal_select_27 + signal_const_48;
    assign signal_cat_11 = { signal_add_13,
                             signal_const_5,
                             signal_select_27,
                             transaction_present,
                             transaction,
                             signal_select_22,
                             signal_select_660,
                             signal_select_670,
                             signal_select_21,
                             signal_select_659,
                             signal_select_44,
                             signal_select_20,
                             signal_select_13,
                             signal_select_12,
                             signal_select_11,
                             signal_select_10,
                             signal_select_9,
                             signal_const_4 };
    assign signal_add_14 = signal_select_27 + signal_const_9;
    assign signal_cat_12 = { signal_add_14,
                             signal_const_5,
                             signal_select_27,
                             transaction_present,
                             transaction,
                             signal_select_22,
                             signal_select_660,
                             signal_select_670,
                             signal_select_21,
                             signal_select_659,
                             signal_select_44,
                             signal_select_20,
                             signal_select_13,
                             signal_select_12,
                             signal_select_11,
                             signal_select_10,
                             signal_select_9,
                             signal_const_4 };
    assign signal_const_54 = 16'b0000000000000010;
    assign signal_add_15 = signal_select_27 + signal_const_54;
    assign signal_cat_13 = { signal_add_15,
                             signal_const_5,
                             signal_select_27,
                             transaction_present,
                             transaction,
                             signal_select_22,
                             signal_select_660,
                             signal_select_670,
                             signal_select_21,
                             signal_select_659,
                             signal_select_44,
                             signal_select_20,
                             signal_select_13,
                             signal_select_12,
                             signal_select_11,
                             signal_select_10,
                             signal_select_9,
                             signal_const_4 };
    assign signal_select_9 = packet_bits[63:0];
    assign signal_select_10 = packet_bits[64:64];
    assign signal_select_11 = packet_bits[96:65];
    assign signal_select_12 = packet_bits[160:97];
    assign signal_select_13 = packet_bits[161:161];
    assign signal_const_56 = 163'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_select_14 = signal_wire_21[65:2];
    assign signal_select_15 = signal_wire_21[66:66];
    assign signal_select_16 = signal_wire_21[98:67];
    assign signal_select_17 = signal_wire_21[162:99];
    assign signal_select_18 = signal_wire_21[163:163];
    assign signal_select_19 = signal_wire_21[164:164];
    assign signal_cat_14 = { signal_select_19,
                             signal_select_18,
                             signal_select_17,
                             signal_select_16,
                             signal_select_15,
                             signal_select_14 };
    assign signal_mux_52 = start ? signal_cat_14 : packet_bits;
    assign signal_wire_2 = signal_mux_52;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            packet_bits <= signal_const_56;
        else
            if (signal_and_231)
                packet_bits <= signal_wire_2;
    end
    assign signal_select_20 = packet_bits[162:162];
    assign signal_select_21 = message_bits[47:32];
    assign signal_select_22 = message_bits[80:80];
    assign signal_select_23 = root[63:0];
    assign signal_select_24 = signal_select_657[63:0];
    assign signal_select_25 = root[63:0];
    assign signal_eq_9 = collected == signal_const_22;
    assign signal_mux_53 = signal_eq_9 ? signal_select_24 : signal_select_25;
    assign signal_select_26 = root[63:0];
    assign signal_mux_54 = signal_and_211 ? signal_select_26 : transaction;
    assign signal_mux_55 = signal_and_202 ? signal_mux_53 : signal_mux_54;
    always @* begin
        case (state)
        5'b00010:
            signal_cases_2 <= signal_mux_55;
        5'b00011:
            signal_cases_2 <= signal_select_23;
        default:
            signal_cases_2 <= transaction;
        endcase
    end
    assign signal_mux_56 = start ? signal_const_26 : signal_cases_2;
    assign signal_wire_3 = signal_mux_56;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            transaction <= signal_const_26;
        else
            if (signal_and_231)
                transaction <= signal_wire_3;
    end
    assign signal_const_60 = 1'b0;
    assign signal_mux_57 = signal_and_211 ? vdd : transaction_present;
    assign signal_mux_58 = signal_and_202 ? vdd : signal_mux_57;
    always @* begin
        case (state)
        5'b00010:
            signal_cases_3 <= signal_mux_58;
        5'b00011:
            signal_cases_3 <= vdd;
        default:
            signal_cases_3 <= transaction_present;
        endcase
    end
    assign signal_mux_59 = start ? gnd : signal_cases_3;
    assign signal_wire_4 = signal_mux_59;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            transaction_present <= signal_const_60;
        else
            if (signal_and_231)
                transaction_present <= signal_wire_4;
    end
    assign signal_select_27 = message_bits[161:146];
    assign signal_add_16 = signal_select_27 + signal_const_9;
    assign signal_cat_15 = { signal_add_16,
                             signal_const_5,
                             signal_select_27,
                             transaction_present,
                             transaction,
                             signal_select_22,
                             signal_select_660,
                             signal_select_670,
                             signal_select_21,
                             signal_select_659,
                             signal_select_44,
                             signal_select_20,
                             signal_select_13,
                             signal_select_12,
                             signal_select_11,
                             signal_select_10,
                             signal_select_9,
                             signal_const_4 };
    assign signal_mux_60 = signal_lt_141 ? signal_cat_15 : event_bits;
    assign signal_mux_61 = signal_or_47 ? signal_cat_13 : signal_mux_60;
    assign signal_mux_62 = signal_lt_144 ? signal_cat_12 : signal_mux_61;
    assign signal_mux_63 = signal_not_116 ? signal_cat_11 : signal_mux_62;
    assign signal_mux_64 = event_space ? signal_mux_63 : event_bits;
    always @* begin
        case (state)
        5'b00001:
            signal_cases_4 <= signal_mux_64;
        5'b00100:
            signal_cases_4 <= signal_mux_51;
        5'b00110:
            signal_cases_4 <= signal_mux_48;
        5'b00111:
            signal_cases_4 <= signal_mux_42;
        5'b01000:
            signal_cases_4 <= signal_mux_20;
        5'b01001:
            signal_cases_4 <= signal_mux_17;
        5'b01010:
            signal_cases_4 <= signal_mux_13;
        5'b01011:
            signal_cases_4 <= signal_mux_11;
        5'b01100:
            signal_cases_4 <= signal_mux_7;
        5'b01101:
            signal_cases_4 <= signal_mux_4;
        5'b01110:
            signal_cases_4 <= signal_mux_2;
        default:
            signal_cases_4 <= event_bits;
        endcase
    end
    assign signal_mux_65 = signal_and_230 ? signal_cat : signal_cases_4;
    assign signal_wire_5 = signal_mux_65;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            event_bits <= signal_const_3;
        else
            if (signal_and_231)
                event_bits <= signal_wire_5;
    end
    assign signal_const_63 = 11'b00000000000;
    assign signal_cat_16 = { signal_const_63,
                             available };
    assign signal_lt_4 = signal_cat_16 < required;
    assign signal_not_1 = ~ signal_lt_4;
    assign signal_const_64 = 5'b00111;
    assign signal_eq_10 = state == signal_const_64;
    assign signal_and_5 = signal_eq_10 & signal_select_671;
    assign signal_and_6 = signal_and_5 & signal_not_1;
    assign signal_const_65 = 5'b01000;
    assign signal_eq_11 = state == signal_const_65;
    assign signal_or_4 = signal_eq_11 | signal_and_6;
    assign signal_not_2 = ~ signal_or_4;
    assign signal_wire_6 = signal_not_2;
    assign signal_select_28 = signal_inst[0:0];
    assign signal_or_5 = signal_select_676 | signal_select_28;
    assign signal_mux_66 = signal_eq_119 ? signal_wire_6 : signal_or_5;
    assign signal_not_3 = ~ input_done;
    assign signal_eq_12 = state == signal_const_2;
    assign signal_not_4 = ~ signal_eq_12;
    assign signal_and_7 = signal_not_4 & signal_not_3;
    assign signal_const_69 = 5'b01111;
    assign signal_const_71 = 5'b00010;
    assign signal_const_72 = 5'b00001;
    assign signal_mux_67 = signal_and_24 ? signal_const_71 : signal_const_72;
    assign signal_wire_7 = done_ready_i;
    assign signal_eq_13 = state == signal_const_2;
    assign signal_and_8 = signal_eq_13 & event_space;
    assign retiring = signal_and_8 & signal_wire_7;
    assign signal_mux_68 = retiring ? signal_const : signal_mux_110;
    assign signal_eq_14 = available == signal_const;
    assign signal_and_9 = input_done & signal_eq_14;
    assign signal_mux_69 = signal_and_9 ? signal_const_2 : signal_mux_110;
    assign signal_mux_70 = event_space ? signal_const_2 : signal_mux_110;
    assign signal_mux_71 = signal_and_26 ? signal_const_2 : signal_mux_110;
    assign signal_const_79 = 5'b01101;
    assign signal_mux_72 = signal_and_28 ? signal_const_2 : signal_const_79;
    assign signal_mux_73 = signal_or_8 ? signal_mux_72 : signal_mux_110;
    assign signal_const_81 = 5'b01100;
    assign signal_mux_74 = signal_and_42 ? signal_const_2 : signal_const_81;
    assign signal_mux_75 = signal_or_10 ? signal_const_69 : signal_mux_74;
    assign signal_mux_76 = event_space ? signal_mux_75 : signal_mux_110;
    assign signal_const_83 = 21'b000000000000000000000;
    assign signal_cat_17 = { signal_const_83,
                             consume_count };
    assign signal_lt_5 = headroom_live_orders < signal_cat_17;
    assign signal_not_5 = ~ signal_lt_5;
    assign signal_cat_18 = { gnd,
                             order_bytes_live_orders };
    assign headroom_live_orders = room - signal_cat_18;
    assign signal_select_29 = headroom_live_orders[24:24];
    assign signal_not_6 = ~ signal_select_29;
    assign fits_after_consume_live_orders = signal_not_6 & signal_not_5;
    assign signal_const_84 = 8'b00000000;
    assign signal_eq_15 = signal_select_47 == signal_const_84;
    assign signal_not_7 = ~ signal_eq_15;
    assign signal_const_85 = 16'b0000000000011000;
    assign signal_lt_6 = signal_select_48 < signal_const_85;
    assign signal_not_8 = ~ signal_lt_6;
    assign signal_and_10 = signal_not_8 & signal_not_7;
    assign signal_and_11 = signal_and_10 & fits_after_consume_live_orders;
    assign signal_mux_77 = signal_and_11 ? signal_const_81 : signal_mux_110;
    assign signal_mux_78 = collect ? signal_mux_77 : signal_mux_110;
    assign signal_mux_79 = final_order_dimension ? signal_const_2 : signal_mux_78;
    assign signal_const_88 = 5'b01011;
    assign signal_cat_19 = { signal_const_83,
                             consume_count };
    assign signal_lt_7 = headroom_prefetched_orders < signal_cat_19;
    assign signal_not_9 = ~ signal_lt_7;
    assign signal_cat_20 = { gnd,
                             order_bytes_prefetched_orders };
    assign headroom_prefetched_orders = room - signal_cat_20;
    assign signal_select_30 = headroom_prefetched_orders[24:24];
    assign signal_not_10 = ~ signal_select_30;
    assign fits_after_consume_prefetched_orders = signal_not_10 & signal_not_9;
    assign signal_eq_16 = signal_select_49 == signal_const_84;
    assign signal_not_11 = ~ signal_eq_16;
    assign signal_lt_8 = signal_select_50 < signal_const_85;
    assign signal_not_12 = ~ signal_lt_8;
    assign signal_and_12 = signal_not_12 & signal_not_11;
    assign signal_and_13 = signal_and_12 & fits_after_consume_prefetched_orders;
    assign signal_mux_80 = signal_and_13 ? signal_const_81 : signal_const_88;
    assign signal_mux_81 = signal_and_49 ? signal_const_2 : signal_mux_80;
    assign signal_mux_82 = next_is_order ? signal_mux_81 : signal_const_64;
    assign signal_mux_83 = signal_eq_23 ? signal_const_6 : signal_const_64;
    assign signal_mux_84 = signal_or_12 ? signal_mux_83 : signal_mux_110;
    assign signal_mux_85 = prefetch_next ? signal_mux_82 : signal_mux_84;
    assign signal_mux_86 = signal_eq_24 ? signal_const_6 : signal_const_64;
    assign signal_const_98 = 5'b01001;
    assign signal_mux_87 = signal_eq_50 ? signal_mux_86 : signal_const_98;
    assign signal_mux_88 = signal_or_13 ? signal_const_69 : signal_mux_87;
    assign signal_mux_89 = event_space ? signal_mux_88 : signal_mux_110;
    assign signal_mux_90 = signal_eq_25 ? signal_const_6 : signal_const_64;
    assign signal_mux_91 = signal_eq_51 ? signal_mux_90 : signal_const_98;
    assign signal_mux_92 = signal_or_40 ? signal_const_69 : signal_mux_91;
    assign signal_mux_93 = signal_and_193 ? signal_mux_92 : signal_mux_110;
    assign signal_mux_94 = signal_eq_26 ? signal_const_6 : signal_const_64;
    assign signal_mux_95 = signal_or_42 ? signal_const_69 : signal_mux_94;
    assign signal_mux_96 = event_space ? signal_mux_95 : signal_mux_110;
    assign signal_mux_97 = signal_eq_27 ? signal_const_6 : signal_const_64;
    assign signal_const_108 = 5'b00110;
    assign signal_mux_98 = signal_and_198 ? signal_mux_97 : signal_const_108;
    assign signal_const_109 = 5'b00101;
    assign signal_mux_99 = fits_dimensions ? signal_const_109 : signal_const_69;
    assign signal_mux_100 = signal_and_40 ? signal_mux_99 : signal_mux_110;
    assign signal_mux_101 = prefetch_root ? signal_mux_98 : signal_mux_100;
    assign signal_const_111 = 5'b00100;
    assign signal_mux_102 = signal_eq_28 ? signal_const_6 : signal_const_64;
    assign signal_mux_103 = signal_and_201 ? signal_mux_102 : signal_const_108;
    assign signal_mux_104 = signal_and_211 ? signal_const_111 : signal_mux_110;
    assign signal_mux_105 = signal_and_202 ? signal_mux_103 : signal_mux_104;
    assign signal_mux_106 = signal_or_47 ? signal_const_69 : signal_const_71;
    assign signal_mux_107 = signal_lt_144 ? signal_const_69 : signal_mux_106;
    assign signal_mux_108 = signal_not_116 ? signal_const_69 : signal_mux_107;
    assign signal_add_17 = state + signal_const_72;
    assign signal_lt_9 = signal_const_9 < required;
    assign signal_not_13 = ~ signal_lt_9;
    assign signal_eq_17 = state == signal_const_64;
    assign signal_not_14 = ~ signal_eq_17;
    assign signal_and_14 = signal_not_14 & signal_not_13;
    assign signal_mux_109 = signal_and_14 ? signal_add_17 : state;
    assign signal_mux_110 = collect ? signal_mux_109 : state;
    assign signal_mux_111 = event_space ? signal_mux_108 : signal_mux_110;
    always @* begin
        case (state)
        5'b00001:
            signal_cases_5 <= signal_mux_111;
        5'b00010:
            signal_cases_5 <= signal_mux_105;
        5'b00011:
            signal_cases_5 <= signal_const_111;
        5'b00100:
            signal_cases_5 <= signal_mux_101;
        5'b00110:
            signal_cases_5 <= signal_mux_96;
        5'b00111:
            signal_cases_5 <= signal_mux_93;
        5'b01000:
            signal_cases_5 <= signal_mux_89;
        5'b01001:
            signal_cases_5 <= signal_mux_85;
        5'b01010:
            signal_cases_5 <= signal_mux_79;
        5'b01011:
            signal_cases_5 <= signal_mux_76;
        5'b01100:
            signal_cases_5 <= signal_mux_73;
        5'b01101:
            signal_cases_5 <= signal_mux_71;
        5'b01110:
            signal_cases_5 <= signal_mux_70;
        5'b01111:
            signal_cases_5 <= signal_mux_69;
        5'b10000:
            signal_cases_5 <= signal_mux_68;
        default:
            signal_cases_5 <= signal_mux_110;
        endcase
    end
    assign signal_mux_112 = start ? signal_mux_67 : signal_cases_5;
    assign signal_cat_21 = { signal_const_63,
                             available };
    assign signal_lt_10 = signal_cat_21 < required;
    assign signal_eq_18 = state == signal_const_64;
    assign signal_and_15 = signal_eq_18 & signal_lt_10;
    assign signal_cat_22 = { signal_const_63,
                             count };
    assign signal_lt_11 = signal_cat_22 < required;
    assign signal_eq_19 = state == signal_const_64;
    assign signal_not_15 = ~ signal_eq_19;
    assign signal_or_6 = signal_not_15 | signal_lt_11;
    assign signal_or_7 = signal_or_6 | event_space;
    assign signal_eq_20 = count == signal_const;
    assign signal_not_16 = ~ signal_eq_20;
    assign signal_select_31 = tail_remaining[4:0];
    assign signal_lt_12 = available < signal_const_69;
    assign tail_available = signal_lt_12 ? available : signal_const_69;
    assign signal_cat_23 = { signal_const_63,
                             tail_available };
    assign tail_remaining = entry_block - collected;
    assign signal_lt_13 = tail_remaining < signal_cat_23;
    assign tail_count = signal_lt_13 ? signal_select_31 : tail_available;
    assign signal_select_32 = required[4:0];
    assign signal_lt_14 = required < signal_const_9;
    assign signal_and_16 = signal_and_231 & start;
    assign signal_const_134 = 16'b0000000000001101;
    assign signal_add_18 = signal_select_662 + signal_const_134;
    assign signal_lt_15 = signal_select_661 < signal_add_18;
    assign signal_not_17 = ~ signal_lt_15;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            hdr_dimensions_fit <= signal_const_60;
        else
            if (signal_and_16)
                hdr_dimensions_fit <= signal_not_17;
    end
    assign signal_and_17 = signal_and_231 & start;
    assign signal_const_136 = 16'b0000000000010100;
    assign signal_lt_16 = signal_const_136 < signal_select_662;
    assign signal_not_18 = ~ signal_lt_16;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            hdr_root_within_window <= signal_const_60;
        else
            if (signal_and_17)
                hdr_root_within_window <= signal_not_18;
    end
    assign signal_eq_21 = collected == signal_const_9;
    assign signal_and_18 = signal_eq_21 & hdr_root_within_window;
    assign signal_and_19 = signal_and_231 & start;
    assign signal_const_139 = 16'b0000000000001100;
    assign signal_lt_17 = signal_const_139 < signal_select_662;
    assign signal_not_19 = ~ signal_lt_17;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            hdr_root_within_head <= signal_const_60;
        else
            if (signal_and_19)
                hdr_root_within_head <= signal_not_19;
    end
    assign signal_sub_2 = signal_select_661 - signal_const_37;
    assign signal_lt_18 = signal_sub_2 < signal_select_662;
    assign signal_not_20 = ~ signal_lt_18;
    assign signal_lt_19 = signal_select_661 < signal_const_37;
    assign signal_not_21 = ~ signal_lt_19;
    assign signal_const_145 = 16'b0000000000001011;
    assign signal_lt_20 = signal_select_662 < signal_const_145;
    assign signal_not_22 = ~ signal_lt_20;
    assign signal_lt_21 = signal_const_134 < signal_select_665;
    assign signal_not_23 = ~ signal_lt_21;
    assign signal_lt_22 = signal_select_665 < signal_const_28;
    assign signal_not_24 = ~ signal_lt_22;
    assign signal_eq_22 = signal_select_664 == signal_const_38;
    assign signal_and_20 = signal_eq_22 & signal_not_24;
    assign signal_and_21 = signal_and_20 & signal_not_23;
    assign signal_and_22 = signal_and_21 & signal_not_22;
    assign signal_and_23 = signal_and_22 & signal_not_21;
    assign signal_and_24 = signal_and_23 & signal_not_20;
    assign signal_mux_113 = signal_and_24 ? signal_const_22 : signal_cases_12;
    assign signal_select_33 = prefetched_count[15:0];
    assign signal_mux_114 = next_is_order ? signal_const_9 : signal_select_33;
    assign signal_add_19 = entry_index + signal_const_38;
    assign signal_eq_23 = signal_add_19 == entry_count;
    assign signal_mux_115 = signal_eq_23 ? signal_const_22 : signal_const_22;
    assign signal_mux_116 = signal_or_12 ? signal_mux_115 : signal_mux_140;
    assign signal_mux_117 = prefetch_next ? signal_mux_114 : signal_mux_116;
    assign signal_add_20 = entry_index + signal_const_38;
    assign signal_eq_24 = signal_add_20 == entry_count;
    assign signal_mux_118 = signal_eq_24 ? signal_const_22 : signal_const_22;
    assign signal_mux_119 = signal_eq_50 ? signal_mux_118 : signal_mux_140;
    assign signal_mux_120 = signal_or_13 ? signal_mux_140 : signal_mux_119;
    assign signal_mux_121 = event_space ? signal_mux_120 : signal_mux_140;
    assign signal_add_21 = entry_index + signal_const_38;
    assign signal_eq_25 = signal_add_21 == entry_count;
    assign signal_mux_122 = signal_eq_25 ? signal_const_22 : signal_const_22;
    assign signal_mux_123 = signal_eq_51 ? signal_mux_122 : signal_mux_140;
    assign signal_mux_124 = signal_or_40 ? signal_mux_140 : signal_mux_123;
    assign signal_mux_125 = signal_and_193 ? signal_mux_124 : signal_mux_140;
    assign signal_eq_26 = count_entries == signal_const_22;
    assign signal_mux_126 = signal_eq_26 ? signal_const_22 : signal_const_22;
    assign signal_mux_127 = signal_or_42 ? signal_mux_140 : signal_mux_126;
    assign signal_mux_128 = event_space ? signal_mux_127 : signal_mux_140;
    assign signal_eq_27 = signal_cat_79 == signal_const_22;
    assign signal_mux_129 = signal_eq_27 ? signal_const_22 : signal_const_22;
    assign signal_mux_130 = signal_and_198 ? signal_mux_129 : signal_mux_140;
    assign signal_mux_131 = fits_dimensions ? signal_const_22 : signal_mux_140;
    assign signal_mux_132 = signal_and_40 ? signal_mux_131 : signal_mux_140;
    assign signal_mux_133 = prefetch_root ? signal_mux_130 : signal_mux_132;
    assign signal_eq_28 = combined_count == signal_const_22;
    assign signal_mux_134 = signal_eq_28 ? signal_const_22 : signal_const_22;
    assign signal_mux_135 = signal_and_201 ? signal_mux_134 : signal_mux_140;
    assign signal_mux_136 = signal_and_202 ? signal_mux_135 : signal_mux_140;
    assign signal_mux_137 = signal_or_47 ? signal_mux_140 : signal_const_22;
    assign signal_mux_138 = signal_lt_144 ? signal_mux_140 : signal_mux_137;
    assign signal_mux_139 = signal_not_116 ? signal_mux_140 : signal_mux_138;
    assign signal_cat_24 = { signal_const_63,
                             count };
    assign signal_add_22 = collected + signal_cat_24;
    assign signal_mux_140 = collect ? signal_add_22 : collected;
    assign signal_mux_141 = signal_and_39 ? vdd : signal_mux_315;
    assign signal_mux_142 = event_space ? signal_mux_141 : signal_mux_315;
    assign signal_mux_143 = signal_and_39 ? vdd : signal_mux_315;
    assign signal_eq_29 = available == signal_const;
    assign signal_and_25 = input_done & signal_eq_29;
    assign signal_and_26 = signal_and_25 & event_space;
    assign signal_mux_144 = signal_and_26 ? signal_mux_143 : signal_mux_315;
    assign signal_mux_145 = signal_and_39 ? vdd : signal_mux_315;
    assign signal_sub_3 = available - skip_count;
    assign signal_mux_146 = skip ? signal_sub_3 : available;
    assign signal_eq_30 = signal_mux_146 == signal_const;
    assign signal_and_27 = input_done & signal_eq_30;
    assign signal_and_28 = signal_and_27 & event_space;
    assign signal_mux_147 = signal_and_28 ? signal_mux_145 : signal_mux_315;
    assign signal_const_176 = 19'b0000000000000000000;
    assign signal_cat_25 = { signal_const_176,
                             skip_count };
    assign signal_eq_31 = skip_left == signal_cat_25;
    assign signal_and_29 = skip & signal_eq_31;
    assign signal_const_177 = 24'b000000000000000000000000;
    assign signal_eq_32 = skip_left == signal_const_177;
    assign signal_or_8 = signal_eq_32 | signal_and_29;
    assign signal_mux_148 = signal_or_8 ? signal_mux_147 : signal_mux_315;
    assign signal_mux_149 = signal_and_39 ? vdd : signal_mux_315;
    assign signal_mux_150 = signal_and_42 ? signal_mux_149 : signal_mux_315;
    assign signal_mux_151 = signal_or_10 ? vdd : signal_mux_150;
    assign signal_mux_152 = event_space ? signal_mux_151 : signal_mux_315;
    assign signal_mux_153 = signal_and_39 ? vdd : signal_mux_315;
    assign signal_select_34 = signal_select_657[63:56];
    assign signal_eq_33 = signal_select_34 == signal_const_84;
    assign signal_select_35 = signal_select_657[15:0];
    assign signal_lt_23 = signal_select_35 < signal_const_85;
    assign signal_not_25 = ~ signal_lt_23;
    assign signal_eq_34 = available == count;
    assign signal_eq_35 = state == signal_const_6;
    assign signal_and_30 = signal_eq_35 & collect;
    assign signal_and_31 = signal_and_30 & event_space;
    assign signal_and_32 = signal_and_31 & input_done;
    assign signal_and_33 = signal_and_32 & signal_eq_34;
    assign signal_and_34 = signal_and_33 & signal_not_25;
    assign final_order_dimension = signal_and_34 & signal_eq_33;
    assign signal_mux_154 = final_order_dimension ? signal_mux_153 : signal_mux_315;
    assign signal_not_26 = ~ aborted;
    assign signal_select_36 = root[71:64];
    assign signal_select_37 = signal_select_657[71:64];
    assign signal_select_38 = signal_select_657[7:0];
    assign signal_eq_36 = collected == signal_const_22;
    assign signal_mux_155 = signal_eq_36 ? signal_select_37 : signal_select_38;
    assign signal_select_39 = signal_select_657[63:0];
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg <= signal_const_26;
        else
            if (signal_and_36)
                signal_reg <= signal_select_39;
    end
    assign signal_eq_37 = collected == signal_const_22;
    assign signal_eq_38 = state == signal_const_71;
    assign signal_and_35 = collect & signal_eq_38;
    assign signal_and_36 = signal_and_35 & signal_eq_37;
    assign signal_mux_156 = signal_and_36 ? signal_select_39 : signal_reg;
    assign signal_select_40 = signal_select_657[23:0];
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_1 <= signal_const_177;
        else
            if (signal_and_38)
                signal_reg_1 <= signal_select_40;
    end
    assign signal_eq_39 = collected == signal_const_9;
    assign signal_eq_40 = state == signal_const_71;
    assign signal_and_37 = collect & signal_eq_40;
    assign signal_and_38 = signal_and_37 & signal_eq_39;
    assign signal_mux_157 = signal_and_38 ? signal_select_40 : signal_reg_1;
    assign root = { signal_mux_157,
                    signal_mux_156 };
    assign signal_select_41 = root[71:64];
    assign signal_mux_158 = signal_and_211 ? signal_select_41 : indicator;
    assign signal_mux_159 = signal_and_202 ? signal_mux_155 : signal_mux_158;
    always @* begin
        case (state)
        5'b00010:
            signal_cases_6 <= signal_mux_159;
        5'b00011:
            signal_cases_6 <= signal_select_36;
        default:
            signal_cases_6 <= indicator;
        endcase
    end
    assign signal_mux_160 = start ? signal_const_84 : signal_cases_6;
    assign signal_wire_8 = signal_mux_160;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            indicator <= signal_const_84;
        else
            if (signal_and_231)
                indicator <= signal_wire_8;
    end
    assign signal_select_42 = indicator[7:7];
    assign signal_and_39 = signal_select_42 & signal_not_26;
    assign signal_mux_161 = signal_and_39 ? vdd : signal_mux_315;
    assign signal_mux_162 = signal_and_49 ? signal_mux_161 : signal_mux_315;
    assign signal_mux_163 = next_is_order ? signal_mux_162 : signal_mux_315;
    assign signal_mux_164 = prefetch_next ? signal_mux_163 : signal_mux_315;
    assign signal_mux_165 = signal_or_13 ? vdd : vdd;
    assign signal_mux_166 = event_space ? signal_mux_165 : signal_mux_315;
    assign signal_mux_167 = signal_or_40 ? vdd : vdd;
    assign signal_mux_168 = signal_and_193 ? signal_mux_167 : signal_mux_315;
    assign signal_mux_169 = signal_or_42 ? vdd : signal_mux_315;
    assign signal_mux_170 = event_space ? signal_mux_169 : signal_mux_315;
    assign signal_const_191 = 25'b0000000000000000000000011;
    assign signal_lt_24 = room < signal_const_191;
    assign signal_not_27 = ~ signal_lt_24;
    assign signal_select_43 = room[24:24];
    assign signal_not_28 = ~ signal_select_43;
    assign fits_dimensions = signal_not_28 & signal_not_27;
    assign signal_mux_171 = fits_dimensions ? signal_mux_315 : vdd;
    assign signal_eq_41 = skip_left == signal_const_177;
    assign signal_and_40 = signal_eq_41 & event_space;
    assign signal_mux_172 = signal_and_40 ? signal_mux_171 : signal_mux_315;
    assign signal_const_193 = 24'b000000000000000000000011;
    assign signal_cat_26 = { signal_const_84,
                             position };
    assign signal_add_23 = signal_cat_26 + skip_left;
    assign signal_add_24 = signal_add_23 + signal_const_193;
    assign signal_select_44 = message_bits[15:0];
    assign signal_sub_4 = signal_select_44 - signal_const_37;
    assign signal_cat_27 = { signal_const_84,
                             signal_sub_4 };
    assign signal_lt_25 = signal_cat_27 < signal_add_24;
    assign signal_not_29 = ~ signal_lt_25;
    assign signal_add_25 = skip_left + signal_const_193;
    assign signal_cat_28 = { signal_const_176,
                             available };
    assign signal_lt_26 = signal_cat_28 < signal_add_25;
    assign signal_not_30 = ~ signal_lt_26;
    assign signal_eq_42 = available == signal_const;
    assign signal_eq_43 = orders_bytes == signal_const_177;
    assign signal_and_41 = signal_eq_43 & input_done;
    assign signal_and_42 = signal_and_41 & signal_eq_42;
    assign signal_mux_173 = signal_and_42 ? signal_mux_303 : orders_bytes;
    assign order_count = order_dimensions[63:56];
    assign orders_bytes = order_block * order_count;
    assign signal_cat_29 = { gnd,
                             orders_bytes };
    assign signal_lt_27 = room < signal_cat_29;
    assign signal_not_31 = ~ signal_lt_27;
    assign signal_select_45 = room[24:24];
    assign signal_not_32 = ~ signal_select_45;
    assign fits_orders = signal_not_32 & signal_not_31;
    assign signal_not_33 = ~ fits_orders;
    assign signal_eq_44 = collected == signal_const_22;
    assign signal_eq_45 = state == signal_const_6;
    assign signal_and_43 = collect & signal_eq_45;
    assign signal_and_44 = signal_and_43 & signal_eq_44;
    assign signal_or_9 = signal_and_44 | signal_and_45;
    assign signal_and_45 = prefetch_next & next_is_order;
    assign signal_mux_174 = signal_and_45 ? prefetched_data : signal_select_657;
    assign signal_select_46 = signal_mux_174[63:0];
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            order_dimensions <= signal_const_26;
        else
            if (signal_or_9)
                order_dimensions <= signal_select_46;
    end
    assign order_block = order_dimensions[15:0];
    assign signal_lt_28 = order_block < signal_const_85;
    assign signal_or_10 = signal_lt_28 | signal_not_33;
    assign signal_mux_175 = signal_or_10 ? signal_mux_303 : signal_mux_173;
    assign signal_mux_176 = event_space ? signal_mux_175 : signal_mux_303;
    assign signal_select_47 = signal_select_657[63:56];
    assign signal_select_48 = signal_select_657[15:0];
    assign order_bytes_live_orders = signal_select_48 * signal_select_47;
    assign signal_mux_177 = collect ? order_bytes_live_orders : signal_mux_303;
    assign signal_select_49 = prefetched_data[63:56];
    assign signal_select_50 = prefetched_data[15:0];
    assign order_bytes_prefetched_orders = signal_select_50 * signal_select_49;
    assign signal_select_51 = prefetched_data[63:56];
    assign signal_eq_46 = signal_select_51 == signal_const_84;
    assign signal_select_52 = prefetched_data[15:0];
    assign signal_lt_29 = signal_select_52 < signal_const_85;
    assign signal_not_34 = ~ signal_lt_29;
    assign signal_eq_47 = available == skip_count;
    assign signal_and_46 = event_space & input_done;
    assign signal_and_47 = signal_and_46 & signal_eq_47;
    assign signal_and_48 = signal_and_47 & signal_not_34;
    assign signal_and_49 = signal_and_48 & signal_eq_46;
    assign signal_mux_178 = signal_and_49 ? signal_mux_303 : order_bytes_prefetched_orders;
    assign signal_mux_179 = next_is_order ? signal_mux_178 : signal_mux_303;
    assign signal_mux_180 = prefetch_next ? signal_mux_179 : signal_mux_303;
    assign signal_cat_30 = { signal_const_23,
                             consume_count };
    assign signal_sub_5 = entry_block - collected;
    assign signal_sub_6 = signal_sub_5 - signal_cat_30;
    assign signal_cat_31 = { signal_const_84,
                             signal_sub_6 };
    assign signal_mux_181 = signal_eq_50 ? signal_mux_303 : signal_cat_31;
    assign signal_mux_182 = signal_or_13 ? signal_mux_303 : signal_mux_181;
    assign signal_mux_183 = event_space ? signal_mux_182 : signal_mux_303;
    assign signal_cat_32 = { signal_const_23,
                             consume_count };
    assign signal_sub_7 = entry_block - collected;
    assign signal_sub_8 = signal_sub_7 - signal_cat_32;
    assign signal_cat_33 = { signal_const_84,
                             signal_sub_8 };
    assign signal_mux_184 = signal_eq_51 ? signal_mux_303 : signal_cat_33;
    assign signal_mux_185 = signal_or_40 ? signal_mux_303 : signal_mux_184;
    assign signal_mux_186 = signal_and_193 ? signal_mux_185 : signal_mux_303;
    assign signal_cat_34 = { signal_const_84,
                             hdr_root_extension };
    assign signal_and_50 = signal_and_231 & start;
    assign signal_sub_9 = signal_select_662 - signal_const_145;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            hdr_root_extension <= signal_const_22;
        else
            if (signal_and_50)
                hdr_root_extension <= signal_sub_9;
    end
    assign signal_cat_35 = { signal_const_84,
                             hdr_root_extension };
    assign signal_cat_36 = { signal_const_176,
                             skip_count };
    assign signal_sub_10 = skip_left - signal_cat_36;
    assign signal_or_11 = prefetch_next | prefetch_root;
    assign signal_mux_187 = signal_or_11 ? signal_const_177 : signal_sub_10;
    assign signal_add_26 = skip_left + signal_const_193;
    assign signal_select_53 = signal_add_26[4:0];
    assign signal_const_222 = 24'b000000000000000000001000;
    assign signal_add_27 = skip_left + signal_const_222;
    assign signal_select_54 = signal_add_27[4:0];
    assign signal_mux_188 = next_is_order ? signal_select_54 : available_skip;
    assign signal_select_55 = skip_left[4:0];
    assign signal_lt_30 = available < signal_const_69;
    assign available_skip = signal_lt_30 ? available : signal_const_69;
    assign signal_cat_37 = { signal_const_176,
                             available_skip };
    assign signal_lt_31 = skip_left < signal_cat_37;
    assign signal_mux_189 = signal_lt_31 ? signal_select_55 : available_skip;
    assign signal_add_28 = skip_left + signal_const_222;
    assign signal_cat_38 = { signal_const_176,
                             available };
    assign signal_lt_32 = signal_cat_38 < signal_add_28;
    assign signal_not_35 = ~ signal_lt_32;
    assign signal_const_228 = 24'b000000000000000000000111;
    assign signal_lt_33 = signal_const_228 < skip_left;
    assign signal_not_36 = ~ signal_lt_33;
    assign signal_and_51 = signal_not_36 & signal_not_35;
    assign signal_cat_39 = { signal_const_176,
                             available };
    assign signal_lt_34 = skip_left < signal_cat_39;
    assign signal_const_230 = 24'b000000000000000000001111;
    assign signal_lt_35 = skip_left < signal_const_230;
    assign signal_and_52 = signal_lt_35 & signal_lt_34;
    assign signal_mux_190 = signal_or_42 ? entry_count : count_entries;
    assign signal_mux_191 = event_space ? signal_mux_190 : entry_count;
    assign signal_mux_192 = signal_and_198 ? signal_cat_79 : entry_count;
    assign signal_mux_193 = prefetch_root ? signal_mux_192 : entry_count;
    assign signal_mux_194 = signal_and_201 ? combined_count : entry_count;
    assign signal_mux_195 = signal_and_202 ? signal_mux_194 : entry_count;
    always @* begin
        case (state)
        5'b00010:
            signal_cases_7 <= signal_mux_195;
        5'b00100:
            signal_cases_7 <= signal_mux_193;
        5'b00110:
            signal_cases_7 <= signal_mux_191;
        default:
            signal_cases_7 <= entry_count;
        endcase
    end
    assign signal_wire_9 = signal_cases_7;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            entry_count <= signal_const_22;
        else
            if (signal_and_231)
                entry_count <= signal_wire_9;
    end
    assign signal_add_29 = entry_index + signal_const_38;
    assign signal_add_30 = entry_index + signal_const_38;
    assign signal_cat_40 = { signal_const_176,
                             skip_count };
    assign signal_eq_48 = skip_left == signal_cat_40;
    assign signal_and_53 = skip & signal_eq_48;
    assign signal_eq_49 = skip_left == signal_const_177;
    assign signal_or_12 = signal_eq_49 | signal_and_53;
    assign signal_mux_196 = signal_or_12 ? signal_add_30 : entry_index;
    assign signal_mux_197 = prefetch_next ? signal_add_29 : signal_mux_196;
    assign signal_add_31 = entry_index + signal_const_38;
    assign signal_cat_41 = { signal_const_23,
                             consume_count };
    assign signal_add_32 = collected + signal_cat_41;
    assign signal_eq_50 = entry_block == signal_add_32;
    assign signal_mux_198 = signal_eq_50 ? signal_add_31 : entry_index;
    assign signal_not_37 = ~ signal_or_19;
    assign signal_not_38 = ~ signal_or_39;
    assign signal_or_13 = signal_not_38 | signal_not_37;
    assign signal_mux_199 = signal_or_13 ? entry_index : signal_mux_198;
    assign signal_mux_200 = event_space ? signal_mux_199 : entry_index;
    assign signal_add_33 = entry_index + signal_const_38;
    assign signal_cat_42 = { signal_const_23,
                             consume_count };
    assign signal_add_34 = collected + signal_cat_42;
    assign signal_mux_201 = signal_or_42 ? entry_block : block;
    assign signal_mux_202 = event_space ? signal_mux_201 : entry_block;
    assign signal_mux_203 = signal_and_198 ? signal_select_638 : entry_block;
    assign signal_mux_204 = prefetch_root ? signal_mux_203 : entry_block;
    assign signal_mux_205 = signal_and_201 ? combined_block : entry_block;
    assign signal_mux_206 = signal_and_202 ? signal_mux_205 : entry_block;
    always @* begin
        case (state)
        5'b00010:
            signal_cases_8 <= signal_mux_206;
        5'b00100:
            signal_cases_8 <= signal_mux_204;
        5'b00110:
            signal_cases_8 <= signal_mux_202;
        default:
            signal_cases_8 <= entry_block;
        endcase
    end
    assign signal_wire_10 = signal_cases_8;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            entry_block <= signal_const_22;
        else
            if (signal_and_231)
                entry_block <= signal_wire_10;
    end
    assign signal_eq_51 = entry_block == signal_add_34;
    assign signal_mux_207 = signal_eq_51 ? signal_add_33 : entry_index;
    assign signal_lt_36 = signal_select_660 < signal_const_139;
    assign signal_not_39 = ~ signal_lt_36;
    assign signal_const_246 = 8'b01111000;
    assign signal_eq_52 = signal_select_56 == signal_const_246;
    assign signal_and_54 = signal_eq_52 & signal_not_39;
    assign signal_lt_37 = signal_select_660 < signal_const_139;
    assign signal_not_40 = ~ signal_lt_37;
    assign signal_const_248 = 8'b01110111;
    assign signal_eq_53 = signal_select_56 == signal_const_248;
    assign signal_and_55 = signal_eq_53 & signal_not_40;
    assign signal_lt_38 = signal_select_660 < signal_const_22;
    assign signal_not_41 = ~ signal_lt_38;
    assign signal_const_250 = 8'b01001010;
    assign signal_eq_54 = signal_select_56 == signal_const_250;
    assign signal_and_56 = signal_eq_54 & signal_not_41;
    assign signal_lt_39 = signal_select_660 < signal_const_22;
    assign signal_not_42 = ~ signal_lt_39;
    assign signal_const_252 = 8'b01000110;
    assign signal_eq_55 = signal_select_56 == signal_const_252;
    assign signal_and_57 = signal_eq_55 & signal_not_42;
    assign signal_lt_40 = signal_select_660 < signal_const_22;
    assign signal_not_43 = ~ signal_lt_40;
    assign signal_const_254 = 8'b01000101;
    assign signal_eq_56 = signal_select_56 == signal_const_254;
    assign signal_and_58 = signal_eq_56 & signal_not_43;
    assign signal_lt_41 = signal_select_660 < signal_const_22;
    assign signal_not_44 = ~ signal_lt_41;
    assign signal_const_256 = 8'b00110001;
    assign signal_eq_57 = signal_select_56 == signal_const_256;
    assign signal_and_59 = signal_eq_57 & signal_not_44;
    assign signal_lt_42 = signal_select_660 < signal_const_22;
    assign signal_not_45 = ~ signal_lt_42;
    assign signal_const_258 = 8'b00110000;
    assign signal_select_56 = entry[215:208];
    assign signal_eq_58 = signal_select_56 == signal_const_258;
    assign signal_and_60 = signal_eq_58 & signal_not_45;
    assign signal_or_14 = signal_and_60 | signal_and_59;
    assign signal_or_15 = signal_or_14 | signal_and_58;
    assign signal_or_16 = signal_or_15 | signal_and_57;
    assign signal_or_17 = signal_or_16 | signal_and_56;
    assign signal_or_18 = signal_or_17 | signal_and_55;
    assign signal_or_19 = signal_or_18 | signal_and_54;
    assign signal_not_46 = ~ signal_or_19;
    assign signal_lt_43 = signal_select_660 < signal_const_22;
    assign signal_not_47 = ~ signal_lt_43;
    assign signal_const_260 = 8'b00000101;
    assign signal_eq_59 = signal_select_616 == signal_const_260;
    assign signal_and_61 = signal_eq_59 & signal_not_47;
    assign signal_lt_44 = signal_select_660 < signal_const_22;
    assign signal_not_48 = ~ signal_lt_44;
    assign signal_const_262 = 8'b00000100;
    assign signal_eq_60 = signal_select_616 == signal_const_262;
    assign signal_and_62 = signal_eq_60 & signal_not_48;
    assign signal_lt_45 = signal_select_660 < signal_const_22;
    assign signal_not_49 = ~ signal_lt_45;
    assign signal_const_264 = 8'b00000011;
    assign signal_eq_61 = signal_select_616 == signal_const_264;
    assign signal_and_63 = signal_eq_61 & signal_not_49;
    assign signal_lt_46 = signal_select_660 < signal_const_22;
    assign signal_not_50 = ~ signal_lt_46;
    assign signal_const_266 = 8'b00000010;
    assign signal_eq_62 = signal_select_616 == signal_const_266;
    assign signal_and_64 = signal_eq_62 & signal_not_50;
    assign signal_lt_47 = signal_select_660 < signal_const_22;
    assign signal_not_51 = ~ signal_lt_47;
    assign signal_const_268 = 8'b00000001;
    assign signal_eq_63 = signal_select_616 == signal_const_268;
    assign signal_and_65 = signal_eq_63 & signal_not_51;
    assign signal_lt_48 = signal_select_660 < signal_const_22;
    assign signal_not_52 = ~ signal_lt_48;
    assign signal_select_57 = prefetched_data[7:0];
    assign signal_select_58 = signal_select_657[127:120];
    assign signal_select_59 = signal_select_657[119:112];
    assign signal_select_60 = signal_select_657[111:104];
    assign signal_select_61 = signal_select_657[103:96];
    assign signal_select_62 = signal_select_657[95:88];
    assign signal_select_63 = signal_select_657[87:80];
    assign signal_select_64 = signal_select_657[79:72];
    assign signal_select_65 = signal_select_657[71:64];
    assign signal_select_66 = signal_select_657[63:56];
    assign signal_select_67 = signal_select_657[55:48];
    assign signal_select_68 = signal_select_657[47:40];
    assign signal_select_69 = signal_select_657[39:32];
    assign signal_select_70 = signal_select_657[31:24];
    assign signal_select_71 = signal_select_657[23:16];
    assign signal_select_72 = signal_select_657[15:8];
    assign signal_select_73 = signal_select_657[7:0];
    assign signal_sub_11 = signal_const_22 - collected;
    assign signal_select_74 = signal_sub_11[3:0];
    always @* begin
        case (signal_select_74)
        0:
            signal_mux_208 <= signal_select_73;
        1:
            signal_mux_208 <= signal_select_72;
        2:
            signal_mux_208 <= signal_select_71;
        3:
            signal_mux_208 <= signal_select_70;
        4:
            signal_mux_208 <= signal_select_69;
        5:
            signal_mux_208 <= signal_select_68;
        6:
            signal_mux_208 <= signal_select_67;
        7:
            signal_mux_208 <= signal_select_66;
        8:
            signal_mux_208 <= signal_select_65;
        9:
            signal_mux_208 <= signal_select_64;
        10:
            signal_mux_208 <= signal_select_63;
        11:
            signal_mux_208 <= signal_select_62;
        12:
            signal_mux_208 <= signal_select_61;
        13:
            signal_mux_208 <= signal_select_60;
        14:
            signal_mux_208 <= signal_select_59;
        default:
            signal_mux_208 <= signal_select_58;
        endcase
    end
    assign signal_mux_209 = signal_and_67 ? signal_select_57 : signal_mux_208;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_2 <= signal_const_84;
        else
            if (signal_or_20)
                signal_reg_2 <= signal_mux_209;
    end
    assign signal_lt_49 = signal_const_177 < prefetched_count;
    assign signal_not_53 = ~ next_is_order;
    assign signal_and_66 = prefetch_next & signal_not_53;
    assign signal_and_67 = signal_and_66 & signal_lt_49;
    assign signal_cat_43 = { signal_const_63,
                             count };
    assign signal_add_35 = collected + signal_cat_43;
    assign signal_lt_50 = signal_const_22 < signal_add_35;
    assign signal_lt_51 = signal_const_22 < collected;
    assign signal_not_54 = ~ signal_lt_51;
    assign signal_eq_64 = state == signal_const_64;
    assign signal_and_68 = collect & signal_eq_64;
    assign signal_and_69 = signal_and_68 & signal_not_54;
    assign signal_and_70 = signal_and_69 & signal_lt_50;
    assign signal_or_20 = signal_and_70 | signal_and_67;
    assign signal_mux_210 = signal_or_20 ? signal_mux_209 : signal_reg_2;
    assign signal_select_75 = prefetched_data[15:8];
    assign signal_select_76 = signal_select_657[127:120];
    assign signal_select_77 = signal_select_657[119:112];
    assign signal_select_78 = signal_select_657[111:104];
    assign signal_select_79 = signal_select_657[103:96];
    assign signal_select_80 = signal_select_657[95:88];
    assign signal_select_81 = signal_select_657[87:80];
    assign signal_select_82 = signal_select_657[79:72];
    assign signal_select_83 = signal_select_657[71:64];
    assign signal_select_84 = signal_select_657[63:56];
    assign signal_select_85 = signal_select_657[55:48];
    assign signal_select_86 = signal_select_657[47:40];
    assign signal_select_87 = signal_select_657[39:32];
    assign signal_select_88 = signal_select_657[31:24];
    assign signal_select_89 = signal_select_657[23:16];
    assign signal_select_90 = signal_select_657[15:8];
    assign signal_select_91 = signal_select_657[7:0];
    assign signal_sub_12 = signal_const_38 - collected;
    assign signal_select_92 = signal_sub_12[3:0];
    always @* begin
        case (signal_select_92)
        0:
            signal_mux_211 <= signal_select_91;
        1:
            signal_mux_211 <= signal_select_90;
        2:
            signal_mux_211 <= signal_select_89;
        3:
            signal_mux_211 <= signal_select_88;
        4:
            signal_mux_211 <= signal_select_87;
        5:
            signal_mux_211 <= signal_select_86;
        6:
            signal_mux_211 <= signal_select_85;
        7:
            signal_mux_211 <= signal_select_84;
        8:
            signal_mux_211 <= signal_select_83;
        9:
            signal_mux_211 <= signal_select_82;
        10:
            signal_mux_211 <= signal_select_81;
        11:
            signal_mux_211 <= signal_select_80;
        12:
            signal_mux_211 <= signal_select_79;
        13:
            signal_mux_211 <= signal_select_78;
        14:
            signal_mux_211 <= signal_select_77;
        default:
            signal_mux_211 <= signal_select_76;
        endcase
    end
    assign signal_mux_212 = signal_and_72 ? signal_select_75 : signal_mux_211;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_3 <= signal_const_84;
        else
            if (signal_or_21)
                signal_reg_3 <= signal_mux_212;
    end
    assign signal_const_280 = 24'b000000000000000000000001;
    assign signal_lt_52 = signal_const_280 < prefetched_count;
    assign signal_not_55 = ~ next_is_order;
    assign signal_and_71 = prefetch_next & signal_not_55;
    assign signal_and_72 = signal_and_71 & signal_lt_52;
    assign signal_cat_44 = { signal_const_63,
                             count };
    assign signal_add_36 = collected + signal_cat_44;
    assign signal_lt_53 = signal_const_38 < signal_add_36;
    assign signal_lt_54 = signal_const_38 < collected;
    assign signal_not_56 = ~ signal_lt_54;
    assign signal_eq_65 = state == signal_const_64;
    assign signal_and_73 = collect & signal_eq_65;
    assign signal_and_74 = signal_and_73 & signal_not_56;
    assign signal_and_75 = signal_and_74 & signal_lt_53;
    assign signal_or_21 = signal_and_75 | signal_and_72;
    assign signal_mux_213 = signal_or_21 ? signal_mux_212 : signal_reg_3;
    assign signal_select_93 = prefetched_data[23:16];
    assign signal_select_94 = signal_select_657[127:120];
    assign signal_select_95 = signal_select_657[119:112];
    assign signal_select_96 = signal_select_657[111:104];
    assign signal_select_97 = signal_select_657[103:96];
    assign signal_select_98 = signal_select_657[95:88];
    assign signal_select_99 = signal_select_657[87:80];
    assign signal_select_100 = signal_select_657[79:72];
    assign signal_select_101 = signal_select_657[71:64];
    assign signal_select_102 = signal_select_657[63:56];
    assign signal_select_103 = signal_select_657[55:48];
    assign signal_select_104 = signal_select_657[47:40];
    assign signal_select_105 = signal_select_657[39:32];
    assign signal_select_106 = signal_select_657[31:24];
    assign signal_select_107 = signal_select_657[23:16];
    assign signal_select_108 = signal_select_657[15:8];
    assign signal_select_109 = signal_select_657[7:0];
    assign signal_sub_13 = signal_const_54 - collected;
    assign signal_select_110 = signal_sub_13[3:0];
    always @* begin
        case (signal_select_110)
        0:
            signal_mux_214 <= signal_select_109;
        1:
            signal_mux_214 <= signal_select_108;
        2:
            signal_mux_214 <= signal_select_107;
        3:
            signal_mux_214 <= signal_select_106;
        4:
            signal_mux_214 <= signal_select_105;
        5:
            signal_mux_214 <= signal_select_104;
        6:
            signal_mux_214 <= signal_select_103;
        7:
            signal_mux_214 <= signal_select_102;
        8:
            signal_mux_214 <= signal_select_101;
        9:
            signal_mux_214 <= signal_select_100;
        10:
            signal_mux_214 <= signal_select_99;
        11:
            signal_mux_214 <= signal_select_98;
        12:
            signal_mux_214 <= signal_select_97;
        13:
            signal_mux_214 <= signal_select_96;
        14:
            signal_mux_214 <= signal_select_95;
        default:
            signal_mux_214 <= signal_select_94;
        endcase
    end
    assign signal_mux_215 = signal_and_77 ? signal_select_93 : signal_mux_214;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_4 <= signal_const_84;
        else
            if (signal_or_22)
                signal_reg_4 <= signal_mux_215;
    end
    assign signal_const_287 = 24'b000000000000000000000010;
    assign signal_lt_55 = signal_const_287 < prefetched_count;
    assign signal_not_57 = ~ next_is_order;
    assign signal_and_76 = prefetch_next & signal_not_57;
    assign signal_and_77 = signal_and_76 & signal_lt_55;
    assign signal_cat_45 = { signal_const_63,
                             count };
    assign signal_add_37 = collected + signal_cat_45;
    assign signal_lt_56 = signal_const_54 < signal_add_37;
    assign signal_lt_57 = signal_const_54 < collected;
    assign signal_not_58 = ~ signal_lt_57;
    assign signal_eq_66 = state == signal_const_64;
    assign signal_and_78 = collect & signal_eq_66;
    assign signal_and_79 = signal_and_78 & signal_not_58;
    assign signal_and_80 = signal_and_79 & signal_lt_56;
    assign signal_or_22 = signal_and_80 | signal_and_77;
    assign signal_mux_216 = signal_or_22 ? signal_mux_215 : signal_reg_4;
    assign signal_select_111 = prefetched_data[31:24];
    assign signal_select_112 = signal_select_657[127:120];
    assign signal_select_113 = signal_select_657[119:112];
    assign signal_select_114 = signal_select_657[111:104];
    assign signal_select_115 = signal_select_657[103:96];
    assign signal_select_116 = signal_select_657[95:88];
    assign signal_select_117 = signal_select_657[87:80];
    assign signal_select_118 = signal_select_657[79:72];
    assign signal_select_119 = signal_select_657[71:64];
    assign signal_select_120 = signal_select_657[63:56];
    assign signal_select_121 = signal_select_657[55:48];
    assign signal_select_122 = signal_select_657[47:40];
    assign signal_select_123 = signal_select_657[39:32];
    assign signal_select_124 = signal_select_657[31:24];
    assign signal_select_125 = signal_select_657[23:16];
    assign signal_select_126 = signal_select_657[15:8];
    assign signal_select_127 = signal_select_657[7:0];
    assign signal_const_293 = 16'b0000000000000011;
    assign signal_sub_14 = signal_const_293 - collected;
    assign signal_select_128 = signal_sub_14[3:0];
    always @* begin
        case (signal_select_128)
        0:
            signal_mux_217 <= signal_select_127;
        1:
            signal_mux_217 <= signal_select_126;
        2:
            signal_mux_217 <= signal_select_125;
        3:
            signal_mux_217 <= signal_select_124;
        4:
            signal_mux_217 <= signal_select_123;
        5:
            signal_mux_217 <= signal_select_122;
        6:
            signal_mux_217 <= signal_select_121;
        7:
            signal_mux_217 <= signal_select_120;
        8:
            signal_mux_217 <= signal_select_119;
        9:
            signal_mux_217 <= signal_select_118;
        10:
            signal_mux_217 <= signal_select_117;
        11:
            signal_mux_217 <= signal_select_116;
        12:
            signal_mux_217 <= signal_select_115;
        13:
            signal_mux_217 <= signal_select_114;
        14:
            signal_mux_217 <= signal_select_113;
        default:
            signal_mux_217 <= signal_select_112;
        endcase
    end
    assign signal_mux_218 = signal_and_82 ? signal_select_111 : signal_mux_217;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_5 <= signal_const_84;
        else
            if (signal_or_23)
                signal_reg_5 <= signal_mux_218;
    end
    assign signal_lt_58 = signal_const_193 < prefetched_count;
    assign signal_not_59 = ~ next_is_order;
    assign signal_and_81 = prefetch_next & signal_not_59;
    assign signal_and_82 = signal_and_81 & signal_lt_58;
    assign signal_cat_46 = { signal_const_63,
                             count };
    assign signal_add_38 = collected + signal_cat_46;
    assign signal_lt_59 = signal_const_293 < signal_add_38;
    assign signal_lt_60 = signal_const_293 < collected;
    assign signal_not_60 = ~ signal_lt_60;
    assign signal_eq_67 = state == signal_const_64;
    assign signal_and_83 = collect & signal_eq_67;
    assign signal_and_84 = signal_and_83 & signal_not_60;
    assign signal_and_85 = signal_and_84 & signal_lt_59;
    assign signal_or_23 = signal_and_85 | signal_and_82;
    assign signal_mux_219 = signal_or_23 ? signal_mux_218 : signal_reg_5;
    assign signal_select_129 = prefetched_data[39:32];
    assign signal_select_130 = signal_select_657[127:120];
    assign signal_select_131 = signal_select_657[119:112];
    assign signal_select_132 = signal_select_657[111:104];
    assign signal_select_133 = signal_select_657[103:96];
    assign signal_select_134 = signal_select_657[95:88];
    assign signal_select_135 = signal_select_657[87:80];
    assign signal_select_136 = signal_select_657[79:72];
    assign signal_select_137 = signal_select_657[71:64];
    assign signal_select_138 = signal_select_657[63:56];
    assign signal_select_139 = signal_select_657[55:48];
    assign signal_select_140 = signal_select_657[47:40];
    assign signal_select_141 = signal_select_657[39:32];
    assign signal_select_142 = signal_select_657[31:24];
    assign signal_select_143 = signal_select_657[23:16];
    assign signal_select_144 = signal_select_657[15:8];
    assign signal_select_145 = signal_select_657[7:0];
    assign signal_const_300 = 16'b0000000000000100;
    assign signal_sub_15 = signal_const_300 - collected;
    assign signal_select_146 = signal_sub_15[3:0];
    always @* begin
        case (signal_select_146)
        0:
            signal_mux_220 <= signal_select_145;
        1:
            signal_mux_220 <= signal_select_144;
        2:
            signal_mux_220 <= signal_select_143;
        3:
            signal_mux_220 <= signal_select_142;
        4:
            signal_mux_220 <= signal_select_141;
        5:
            signal_mux_220 <= signal_select_140;
        6:
            signal_mux_220 <= signal_select_139;
        7:
            signal_mux_220 <= signal_select_138;
        8:
            signal_mux_220 <= signal_select_137;
        9:
            signal_mux_220 <= signal_select_136;
        10:
            signal_mux_220 <= signal_select_135;
        11:
            signal_mux_220 <= signal_select_134;
        12:
            signal_mux_220 <= signal_select_133;
        13:
            signal_mux_220 <= signal_select_132;
        14:
            signal_mux_220 <= signal_select_131;
        default:
            signal_mux_220 <= signal_select_130;
        endcase
    end
    assign signal_mux_221 = signal_and_87 ? signal_select_129 : signal_mux_220;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_6 <= signal_const_84;
        else
            if (signal_or_24)
                signal_reg_6 <= signal_mux_221;
    end
    assign signal_const_301 = 24'b000000000000000000000100;
    assign signal_lt_61 = signal_const_301 < prefetched_count;
    assign signal_not_61 = ~ next_is_order;
    assign signal_and_86 = prefetch_next & signal_not_61;
    assign signal_and_87 = signal_and_86 & signal_lt_61;
    assign signal_cat_47 = { signal_const_63,
                             count };
    assign signal_add_39 = collected + signal_cat_47;
    assign signal_lt_62 = signal_const_300 < signal_add_39;
    assign signal_lt_63 = signal_const_300 < collected;
    assign signal_not_62 = ~ signal_lt_63;
    assign signal_eq_68 = state == signal_const_64;
    assign signal_and_88 = collect & signal_eq_68;
    assign signal_and_89 = signal_and_88 & signal_not_62;
    assign signal_and_90 = signal_and_89 & signal_lt_62;
    assign signal_or_24 = signal_and_90 | signal_and_87;
    assign signal_mux_222 = signal_or_24 ? signal_mux_221 : signal_reg_6;
    assign signal_select_147 = prefetched_data[47:40];
    assign signal_select_148 = signal_select_657[127:120];
    assign signal_select_149 = signal_select_657[119:112];
    assign signal_select_150 = signal_select_657[111:104];
    assign signal_select_151 = signal_select_657[103:96];
    assign signal_select_152 = signal_select_657[95:88];
    assign signal_select_153 = signal_select_657[87:80];
    assign signal_select_154 = signal_select_657[79:72];
    assign signal_select_155 = signal_select_657[71:64];
    assign signal_select_156 = signal_select_657[63:56];
    assign signal_select_157 = signal_select_657[55:48];
    assign signal_select_158 = signal_select_657[47:40];
    assign signal_select_159 = signal_select_657[39:32];
    assign signal_select_160 = signal_select_657[31:24];
    assign signal_select_161 = signal_select_657[23:16];
    assign signal_select_162 = signal_select_657[15:8];
    assign signal_select_163 = signal_select_657[7:0];
    assign signal_const_307 = 16'b0000000000000101;
    assign signal_sub_16 = signal_const_307 - collected;
    assign signal_select_164 = signal_sub_16[3:0];
    always @* begin
        case (signal_select_164)
        0:
            signal_mux_223 <= signal_select_163;
        1:
            signal_mux_223 <= signal_select_162;
        2:
            signal_mux_223 <= signal_select_161;
        3:
            signal_mux_223 <= signal_select_160;
        4:
            signal_mux_223 <= signal_select_159;
        5:
            signal_mux_223 <= signal_select_158;
        6:
            signal_mux_223 <= signal_select_157;
        7:
            signal_mux_223 <= signal_select_156;
        8:
            signal_mux_223 <= signal_select_155;
        9:
            signal_mux_223 <= signal_select_154;
        10:
            signal_mux_223 <= signal_select_153;
        11:
            signal_mux_223 <= signal_select_152;
        12:
            signal_mux_223 <= signal_select_151;
        13:
            signal_mux_223 <= signal_select_150;
        14:
            signal_mux_223 <= signal_select_149;
        default:
            signal_mux_223 <= signal_select_148;
        endcase
    end
    assign signal_mux_224 = signal_and_92 ? signal_select_147 : signal_mux_223;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_7 <= signal_const_84;
        else
            if (signal_or_25)
                signal_reg_7 <= signal_mux_224;
    end
    assign signal_const_308 = 24'b000000000000000000000101;
    assign signal_lt_64 = signal_const_308 < prefetched_count;
    assign signal_not_63 = ~ next_is_order;
    assign signal_and_91 = prefetch_next & signal_not_63;
    assign signal_and_92 = signal_and_91 & signal_lt_64;
    assign signal_cat_48 = { signal_const_63,
                             count };
    assign signal_add_40 = collected + signal_cat_48;
    assign signal_lt_65 = signal_const_307 < signal_add_40;
    assign signal_lt_66 = signal_const_307 < collected;
    assign signal_not_64 = ~ signal_lt_66;
    assign signal_eq_69 = state == signal_const_64;
    assign signal_and_93 = collect & signal_eq_69;
    assign signal_and_94 = signal_and_93 & signal_not_64;
    assign signal_and_95 = signal_and_94 & signal_lt_65;
    assign signal_or_25 = signal_and_95 | signal_and_92;
    assign signal_mux_225 = signal_or_25 ? signal_mux_224 : signal_reg_7;
    assign signal_select_165 = prefetched_data[55:48];
    assign signal_select_166 = signal_select_657[127:120];
    assign signal_select_167 = signal_select_657[119:112];
    assign signal_select_168 = signal_select_657[111:104];
    assign signal_select_169 = signal_select_657[103:96];
    assign signal_select_170 = signal_select_657[95:88];
    assign signal_select_171 = signal_select_657[87:80];
    assign signal_select_172 = signal_select_657[79:72];
    assign signal_select_173 = signal_select_657[71:64];
    assign signal_select_174 = signal_select_657[63:56];
    assign signal_select_175 = signal_select_657[55:48];
    assign signal_select_176 = signal_select_657[47:40];
    assign signal_select_177 = signal_select_657[39:32];
    assign signal_select_178 = signal_select_657[31:24];
    assign signal_select_179 = signal_select_657[23:16];
    assign signal_select_180 = signal_select_657[15:8];
    assign signal_select_181 = signal_select_657[7:0];
    assign signal_sub_17 = signal_const_48 - collected;
    assign signal_select_182 = signal_sub_17[3:0];
    always @* begin
        case (signal_select_182)
        0:
            signal_mux_226 <= signal_select_181;
        1:
            signal_mux_226 <= signal_select_180;
        2:
            signal_mux_226 <= signal_select_179;
        3:
            signal_mux_226 <= signal_select_178;
        4:
            signal_mux_226 <= signal_select_177;
        5:
            signal_mux_226 <= signal_select_176;
        6:
            signal_mux_226 <= signal_select_175;
        7:
            signal_mux_226 <= signal_select_174;
        8:
            signal_mux_226 <= signal_select_173;
        9:
            signal_mux_226 <= signal_select_172;
        10:
            signal_mux_226 <= signal_select_171;
        11:
            signal_mux_226 <= signal_select_170;
        12:
            signal_mux_226 <= signal_select_169;
        13:
            signal_mux_226 <= signal_select_168;
        14:
            signal_mux_226 <= signal_select_167;
        default:
            signal_mux_226 <= signal_select_166;
        endcase
    end
    assign signal_mux_227 = signal_and_97 ? signal_select_165 : signal_mux_226;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_8 <= signal_const_84;
        else
            if (signal_or_26)
                signal_reg_8 <= signal_mux_227;
    end
    assign signal_const_315 = 24'b000000000000000000000110;
    assign signal_lt_67 = signal_const_315 < prefetched_count;
    assign signal_not_65 = ~ next_is_order;
    assign signal_and_96 = prefetch_next & signal_not_65;
    assign signal_and_97 = signal_and_96 & signal_lt_67;
    assign signal_cat_49 = { signal_const_63,
                             count };
    assign signal_add_41 = collected + signal_cat_49;
    assign signal_lt_68 = signal_const_48 < signal_add_41;
    assign signal_lt_69 = signal_const_48 < collected;
    assign signal_not_66 = ~ signal_lt_69;
    assign signal_eq_70 = state == signal_const_64;
    assign signal_and_98 = collect & signal_eq_70;
    assign signal_and_99 = signal_and_98 & signal_not_66;
    assign signal_and_100 = signal_and_99 & signal_lt_68;
    assign signal_or_26 = signal_and_100 | signal_and_97;
    assign signal_mux_228 = signal_or_26 ? signal_mux_227 : signal_reg_8;
    assign signal_select_183 = prefetched_data[63:56];
    assign signal_select_184 = signal_select_657[127:120];
    assign signal_select_185 = signal_select_657[119:112];
    assign signal_select_186 = signal_select_657[111:104];
    assign signal_select_187 = signal_select_657[103:96];
    assign signal_select_188 = signal_select_657[95:88];
    assign signal_select_189 = signal_select_657[87:80];
    assign signal_select_190 = signal_select_657[79:72];
    assign signal_select_191 = signal_select_657[71:64];
    assign signal_select_192 = signal_select_657[63:56];
    assign signal_select_193 = signal_select_657[55:48];
    assign signal_select_194 = signal_select_657[47:40];
    assign signal_select_195 = signal_select_657[39:32];
    assign signal_select_196 = signal_select_657[31:24];
    assign signal_select_197 = signal_select_657[23:16];
    assign signal_select_198 = signal_select_657[15:8];
    assign signal_select_199 = signal_select_657[7:0];
    assign signal_const_321 = 16'b0000000000000111;
    assign signal_sub_18 = signal_const_321 - collected;
    assign signal_select_200 = signal_sub_18[3:0];
    always @* begin
        case (signal_select_200)
        0:
            signal_mux_229 <= signal_select_199;
        1:
            signal_mux_229 <= signal_select_198;
        2:
            signal_mux_229 <= signal_select_197;
        3:
            signal_mux_229 <= signal_select_196;
        4:
            signal_mux_229 <= signal_select_195;
        5:
            signal_mux_229 <= signal_select_194;
        6:
            signal_mux_229 <= signal_select_193;
        7:
            signal_mux_229 <= signal_select_192;
        8:
            signal_mux_229 <= signal_select_191;
        9:
            signal_mux_229 <= signal_select_190;
        10:
            signal_mux_229 <= signal_select_189;
        11:
            signal_mux_229 <= signal_select_188;
        12:
            signal_mux_229 <= signal_select_187;
        13:
            signal_mux_229 <= signal_select_186;
        14:
            signal_mux_229 <= signal_select_185;
        default:
            signal_mux_229 <= signal_select_184;
        endcase
    end
    assign signal_mux_230 = signal_and_102 ? signal_select_183 : signal_mux_229;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_9 <= signal_const_84;
        else
            if (signal_or_27)
                signal_reg_9 <= signal_mux_230;
    end
    assign signal_lt_70 = signal_const_228 < prefetched_count;
    assign signal_not_67 = ~ next_is_order;
    assign signal_and_101 = prefetch_next & signal_not_67;
    assign signal_and_102 = signal_and_101 & signal_lt_70;
    assign signal_cat_50 = { signal_const_63,
                             count };
    assign signal_add_42 = collected + signal_cat_50;
    assign signal_lt_71 = signal_const_321 < signal_add_42;
    assign signal_lt_72 = signal_const_321 < collected;
    assign signal_not_68 = ~ signal_lt_72;
    assign signal_eq_71 = state == signal_const_64;
    assign signal_and_103 = collect & signal_eq_71;
    assign signal_and_104 = signal_and_103 & signal_not_68;
    assign signal_and_105 = signal_and_104 & signal_lt_71;
    assign signal_or_27 = signal_and_105 | signal_and_102;
    assign signal_mux_231 = signal_or_27 ? signal_mux_230 : signal_reg_9;
    assign signal_select_201 = prefetched_data[71:64];
    assign signal_select_202 = signal_select_657[127:120];
    assign signal_select_203 = signal_select_657[119:112];
    assign signal_select_204 = signal_select_657[111:104];
    assign signal_select_205 = signal_select_657[103:96];
    assign signal_select_206 = signal_select_657[95:88];
    assign signal_select_207 = signal_select_657[87:80];
    assign signal_select_208 = signal_select_657[79:72];
    assign signal_select_209 = signal_select_657[71:64];
    assign signal_select_210 = signal_select_657[63:56];
    assign signal_select_211 = signal_select_657[55:48];
    assign signal_select_212 = signal_select_657[47:40];
    assign signal_select_213 = signal_select_657[39:32];
    assign signal_select_214 = signal_select_657[31:24];
    assign signal_select_215 = signal_select_657[23:16];
    assign signal_select_216 = signal_select_657[15:8];
    assign signal_select_217 = signal_select_657[7:0];
    assign signal_sub_19 = signal_const_9 - collected;
    assign signal_select_218 = signal_sub_19[3:0];
    always @* begin
        case (signal_select_218)
        0:
            signal_mux_232 <= signal_select_217;
        1:
            signal_mux_232 <= signal_select_216;
        2:
            signal_mux_232 <= signal_select_215;
        3:
            signal_mux_232 <= signal_select_214;
        4:
            signal_mux_232 <= signal_select_213;
        5:
            signal_mux_232 <= signal_select_212;
        6:
            signal_mux_232 <= signal_select_211;
        7:
            signal_mux_232 <= signal_select_210;
        8:
            signal_mux_232 <= signal_select_209;
        9:
            signal_mux_232 <= signal_select_208;
        10:
            signal_mux_232 <= signal_select_207;
        11:
            signal_mux_232 <= signal_select_206;
        12:
            signal_mux_232 <= signal_select_205;
        13:
            signal_mux_232 <= signal_select_204;
        14:
            signal_mux_232 <= signal_select_203;
        default:
            signal_mux_232 <= signal_select_202;
        endcase
    end
    assign signal_mux_233 = signal_and_107 ? signal_select_201 : signal_mux_232;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_10 <= signal_const_84;
        else
            if (signal_or_28)
                signal_reg_10 <= signal_mux_233;
    end
    assign signal_lt_73 = signal_const_222 < prefetched_count;
    assign signal_not_69 = ~ next_is_order;
    assign signal_and_106 = prefetch_next & signal_not_69;
    assign signal_and_107 = signal_and_106 & signal_lt_73;
    assign signal_cat_51 = { signal_const_63,
                             count };
    assign signal_add_43 = collected + signal_cat_51;
    assign signal_lt_74 = signal_const_9 < signal_add_43;
    assign signal_lt_75 = signal_const_9 < collected;
    assign signal_not_70 = ~ signal_lt_75;
    assign signal_eq_72 = state == signal_const_64;
    assign signal_and_108 = collect & signal_eq_72;
    assign signal_and_109 = signal_and_108 & signal_not_70;
    assign signal_and_110 = signal_and_109 & signal_lt_74;
    assign signal_or_28 = signal_and_110 | signal_and_107;
    assign signal_mux_234 = signal_or_28 ? signal_mux_233 : signal_reg_10;
    assign signal_select_219 = prefetched_data[79:72];
    assign signal_select_220 = signal_select_657[127:120];
    assign signal_select_221 = signal_select_657[119:112];
    assign signal_select_222 = signal_select_657[111:104];
    assign signal_select_223 = signal_select_657[103:96];
    assign signal_select_224 = signal_select_657[95:88];
    assign signal_select_225 = signal_select_657[87:80];
    assign signal_select_226 = signal_select_657[79:72];
    assign signal_select_227 = signal_select_657[71:64];
    assign signal_select_228 = signal_select_657[63:56];
    assign signal_select_229 = signal_select_657[55:48];
    assign signal_select_230 = signal_select_657[47:40];
    assign signal_select_231 = signal_select_657[39:32];
    assign signal_select_232 = signal_select_657[31:24];
    assign signal_select_233 = signal_select_657[23:16];
    assign signal_select_234 = signal_select_657[15:8];
    assign signal_select_235 = signal_select_657[7:0];
    assign signal_sub_20 = signal_const_28 - collected;
    assign signal_select_236 = signal_sub_20[3:0];
    always @* begin
        case (signal_select_236)
        0:
            signal_mux_235 <= signal_select_235;
        1:
            signal_mux_235 <= signal_select_234;
        2:
            signal_mux_235 <= signal_select_233;
        3:
            signal_mux_235 <= signal_select_232;
        4:
            signal_mux_235 <= signal_select_231;
        5:
            signal_mux_235 <= signal_select_230;
        6:
            signal_mux_235 <= signal_select_229;
        7:
            signal_mux_235 <= signal_select_228;
        8:
            signal_mux_235 <= signal_select_227;
        9:
            signal_mux_235 <= signal_select_226;
        10:
            signal_mux_235 <= signal_select_225;
        11:
            signal_mux_235 <= signal_select_224;
        12:
            signal_mux_235 <= signal_select_223;
        13:
            signal_mux_235 <= signal_select_222;
        14:
            signal_mux_235 <= signal_select_221;
        default:
            signal_mux_235 <= signal_select_220;
        endcase
    end
    assign signal_mux_236 = signal_and_112 ? signal_select_219 : signal_mux_235;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_11 <= signal_const_84;
        else
            if (signal_or_29)
                signal_reg_11 <= signal_mux_236;
    end
    assign signal_const_336 = 24'b000000000000000000001001;
    assign signal_lt_76 = signal_const_336 < prefetched_count;
    assign signal_not_71 = ~ next_is_order;
    assign signal_and_111 = prefetch_next & signal_not_71;
    assign signal_and_112 = signal_and_111 & signal_lt_76;
    assign signal_cat_52 = { signal_const_63,
                             count };
    assign signal_add_44 = collected + signal_cat_52;
    assign signal_lt_77 = signal_const_28 < signal_add_44;
    assign signal_lt_78 = signal_const_28 < collected;
    assign signal_not_72 = ~ signal_lt_78;
    assign signal_eq_73 = state == signal_const_64;
    assign signal_and_113 = collect & signal_eq_73;
    assign signal_and_114 = signal_and_113 & signal_not_72;
    assign signal_and_115 = signal_and_114 & signal_lt_77;
    assign signal_or_29 = signal_and_115 | signal_and_112;
    assign signal_mux_237 = signal_or_29 ? signal_mux_236 : signal_reg_11;
    assign signal_select_237 = prefetched_data[87:80];
    assign signal_select_238 = signal_select_657[127:120];
    assign signal_select_239 = signal_select_657[119:112];
    assign signal_select_240 = signal_select_657[111:104];
    assign signal_select_241 = signal_select_657[103:96];
    assign signal_select_242 = signal_select_657[95:88];
    assign signal_select_243 = signal_select_657[87:80];
    assign signal_select_244 = signal_select_657[79:72];
    assign signal_select_245 = signal_select_657[71:64];
    assign signal_select_246 = signal_select_657[63:56];
    assign signal_select_247 = signal_select_657[55:48];
    assign signal_select_248 = signal_select_657[47:40];
    assign signal_select_249 = signal_select_657[39:32];
    assign signal_select_250 = signal_select_657[31:24];
    assign signal_select_251 = signal_select_657[23:16];
    assign signal_select_252 = signal_select_657[15:8];
    assign signal_select_253 = signal_select_657[7:0];
    assign signal_sub_21 = signal_const_37 - collected;
    assign signal_select_254 = signal_sub_21[3:0];
    always @* begin
        case (signal_select_254)
        0:
            signal_mux_238 <= signal_select_253;
        1:
            signal_mux_238 <= signal_select_252;
        2:
            signal_mux_238 <= signal_select_251;
        3:
            signal_mux_238 <= signal_select_250;
        4:
            signal_mux_238 <= signal_select_249;
        5:
            signal_mux_238 <= signal_select_248;
        6:
            signal_mux_238 <= signal_select_247;
        7:
            signal_mux_238 <= signal_select_246;
        8:
            signal_mux_238 <= signal_select_245;
        9:
            signal_mux_238 <= signal_select_244;
        10:
            signal_mux_238 <= signal_select_243;
        11:
            signal_mux_238 <= signal_select_242;
        12:
            signal_mux_238 <= signal_select_241;
        13:
            signal_mux_238 <= signal_select_240;
        14:
            signal_mux_238 <= signal_select_239;
        default:
            signal_mux_238 <= signal_select_238;
        endcase
    end
    assign signal_mux_239 = signal_and_117 ? signal_select_237 : signal_mux_238;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_12 <= signal_const_84;
        else
            if (signal_or_30)
                signal_reg_12 <= signal_mux_239;
    end
    assign signal_const_343 = 24'b000000000000000000001010;
    assign signal_lt_79 = signal_const_343 < prefetched_count;
    assign signal_not_73 = ~ next_is_order;
    assign signal_and_116 = prefetch_next & signal_not_73;
    assign signal_and_117 = signal_and_116 & signal_lt_79;
    assign signal_cat_53 = { signal_const_63,
                             count };
    assign signal_add_45 = collected + signal_cat_53;
    assign signal_lt_80 = signal_const_37 < signal_add_45;
    assign signal_lt_81 = signal_const_37 < collected;
    assign signal_not_74 = ~ signal_lt_81;
    assign signal_eq_74 = state == signal_const_64;
    assign signal_and_118 = collect & signal_eq_74;
    assign signal_and_119 = signal_and_118 & signal_not_74;
    assign signal_and_120 = signal_and_119 & signal_lt_80;
    assign signal_or_30 = signal_and_120 | signal_and_117;
    assign signal_mux_240 = signal_or_30 ? signal_mux_239 : signal_reg_12;
    assign signal_select_255 = prefetched_data[95:88];
    assign signal_select_256 = signal_select_657[127:120];
    assign signal_select_257 = signal_select_657[119:112];
    assign signal_select_258 = signal_select_657[111:104];
    assign signal_select_259 = signal_select_657[103:96];
    assign signal_select_260 = signal_select_657[95:88];
    assign signal_select_261 = signal_select_657[87:80];
    assign signal_select_262 = signal_select_657[79:72];
    assign signal_select_263 = signal_select_657[71:64];
    assign signal_select_264 = signal_select_657[63:56];
    assign signal_select_265 = signal_select_657[55:48];
    assign signal_select_266 = signal_select_657[47:40];
    assign signal_select_267 = signal_select_657[39:32];
    assign signal_select_268 = signal_select_657[31:24];
    assign signal_select_269 = signal_select_657[23:16];
    assign signal_select_270 = signal_select_657[15:8];
    assign signal_select_271 = signal_select_657[7:0];
    assign signal_sub_22 = signal_const_145 - collected;
    assign signal_select_272 = signal_sub_22[3:0];
    always @* begin
        case (signal_select_272)
        0:
            signal_mux_241 <= signal_select_271;
        1:
            signal_mux_241 <= signal_select_270;
        2:
            signal_mux_241 <= signal_select_269;
        3:
            signal_mux_241 <= signal_select_268;
        4:
            signal_mux_241 <= signal_select_267;
        5:
            signal_mux_241 <= signal_select_266;
        6:
            signal_mux_241 <= signal_select_265;
        7:
            signal_mux_241 <= signal_select_264;
        8:
            signal_mux_241 <= signal_select_263;
        9:
            signal_mux_241 <= signal_select_262;
        10:
            signal_mux_241 <= signal_select_261;
        11:
            signal_mux_241 <= signal_select_260;
        12:
            signal_mux_241 <= signal_select_259;
        13:
            signal_mux_241 <= signal_select_258;
        14:
            signal_mux_241 <= signal_select_257;
        default:
            signal_mux_241 <= signal_select_256;
        endcase
    end
    assign signal_mux_242 = signal_and_122 ? signal_select_255 : signal_mux_241;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_13 <= signal_const_84;
        else
            if (signal_or_31)
                signal_reg_13 <= signal_mux_242;
    end
    assign signal_const_350 = 24'b000000000000000000001011;
    assign signal_lt_82 = signal_const_350 < prefetched_count;
    assign signal_not_75 = ~ next_is_order;
    assign signal_and_121 = prefetch_next & signal_not_75;
    assign signal_and_122 = signal_and_121 & signal_lt_82;
    assign signal_cat_54 = { signal_const_63,
                             count };
    assign signal_add_46 = collected + signal_cat_54;
    assign signal_lt_83 = signal_const_145 < signal_add_46;
    assign signal_lt_84 = signal_const_145 < collected;
    assign signal_not_76 = ~ signal_lt_84;
    assign signal_eq_75 = state == signal_const_64;
    assign signal_and_123 = collect & signal_eq_75;
    assign signal_and_124 = signal_and_123 & signal_not_76;
    assign signal_and_125 = signal_and_124 & signal_lt_83;
    assign signal_or_31 = signal_and_125 | signal_and_122;
    assign signal_mux_243 = signal_or_31 ? signal_mux_242 : signal_reg_13;
    assign signal_select_273 = prefetched_data[103:96];
    assign signal_select_274 = signal_select_657[127:120];
    assign signal_select_275 = signal_select_657[119:112];
    assign signal_select_276 = signal_select_657[111:104];
    assign signal_select_277 = signal_select_657[103:96];
    assign signal_select_278 = signal_select_657[95:88];
    assign signal_select_279 = signal_select_657[87:80];
    assign signal_select_280 = signal_select_657[79:72];
    assign signal_select_281 = signal_select_657[71:64];
    assign signal_select_282 = signal_select_657[63:56];
    assign signal_select_283 = signal_select_657[55:48];
    assign signal_select_284 = signal_select_657[47:40];
    assign signal_select_285 = signal_select_657[39:32];
    assign signal_select_286 = signal_select_657[31:24];
    assign signal_select_287 = signal_select_657[23:16];
    assign signal_select_288 = signal_select_657[15:8];
    assign signal_select_289 = signal_select_657[7:0];
    assign signal_sub_23 = signal_const_139 - collected;
    assign signal_select_290 = signal_sub_23[3:0];
    always @* begin
        case (signal_select_290)
        0:
            signal_mux_244 <= signal_select_289;
        1:
            signal_mux_244 <= signal_select_288;
        2:
            signal_mux_244 <= signal_select_287;
        3:
            signal_mux_244 <= signal_select_286;
        4:
            signal_mux_244 <= signal_select_285;
        5:
            signal_mux_244 <= signal_select_284;
        6:
            signal_mux_244 <= signal_select_283;
        7:
            signal_mux_244 <= signal_select_282;
        8:
            signal_mux_244 <= signal_select_281;
        9:
            signal_mux_244 <= signal_select_280;
        10:
            signal_mux_244 <= signal_select_279;
        11:
            signal_mux_244 <= signal_select_278;
        12:
            signal_mux_244 <= signal_select_277;
        13:
            signal_mux_244 <= signal_select_276;
        14:
            signal_mux_244 <= signal_select_275;
        default:
            signal_mux_244 <= signal_select_274;
        endcase
    end
    assign signal_mux_245 = signal_and_127 ? signal_select_273 : signal_mux_244;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_14 <= signal_const_84;
        else
            if (signal_or_32)
                signal_reg_14 <= signal_mux_245;
    end
    assign signal_const_357 = 24'b000000000000000000001100;
    assign signal_lt_85 = signal_const_357 < prefetched_count;
    assign signal_not_77 = ~ next_is_order;
    assign signal_and_126 = prefetch_next & signal_not_77;
    assign signal_and_127 = signal_and_126 & signal_lt_85;
    assign signal_cat_55 = { signal_const_63,
                             count };
    assign signal_add_47 = collected + signal_cat_55;
    assign signal_lt_86 = signal_const_139 < signal_add_47;
    assign signal_lt_87 = signal_const_139 < collected;
    assign signal_not_78 = ~ signal_lt_87;
    assign signal_eq_76 = state == signal_const_64;
    assign signal_and_128 = collect & signal_eq_76;
    assign signal_and_129 = signal_and_128 & signal_not_78;
    assign signal_and_130 = signal_and_129 & signal_lt_86;
    assign signal_or_32 = signal_and_130 | signal_and_127;
    assign signal_mux_246 = signal_or_32 ? signal_mux_245 : signal_reg_14;
    assign signal_select_291 = prefetched_data[111:104];
    assign signal_select_292 = signal_select_657[127:120];
    assign signal_select_293 = signal_select_657[119:112];
    assign signal_select_294 = signal_select_657[111:104];
    assign signal_select_295 = signal_select_657[103:96];
    assign signal_select_296 = signal_select_657[95:88];
    assign signal_select_297 = signal_select_657[87:80];
    assign signal_select_298 = signal_select_657[79:72];
    assign signal_select_299 = signal_select_657[71:64];
    assign signal_select_300 = signal_select_657[63:56];
    assign signal_select_301 = signal_select_657[55:48];
    assign signal_select_302 = signal_select_657[47:40];
    assign signal_select_303 = signal_select_657[39:32];
    assign signal_select_304 = signal_select_657[31:24];
    assign signal_select_305 = signal_select_657[23:16];
    assign signal_select_306 = signal_select_657[15:8];
    assign signal_select_307 = signal_select_657[7:0];
    assign signal_sub_24 = signal_const_134 - collected;
    assign signal_select_308 = signal_sub_24[3:0];
    always @* begin
        case (signal_select_308)
        0:
            signal_mux_247 <= signal_select_307;
        1:
            signal_mux_247 <= signal_select_306;
        2:
            signal_mux_247 <= signal_select_305;
        3:
            signal_mux_247 <= signal_select_304;
        4:
            signal_mux_247 <= signal_select_303;
        5:
            signal_mux_247 <= signal_select_302;
        6:
            signal_mux_247 <= signal_select_301;
        7:
            signal_mux_247 <= signal_select_300;
        8:
            signal_mux_247 <= signal_select_299;
        9:
            signal_mux_247 <= signal_select_298;
        10:
            signal_mux_247 <= signal_select_297;
        11:
            signal_mux_247 <= signal_select_296;
        12:
            signal_mux_247 <= signal_select_295;
        13:
            signal_mux_247 <= signal_select_294;
        14:
            signal_mux_247 <= signal_select_293;
        default:
            signal_mux_247 <= signal_select_292;
        endcase
    end
    assign signal_mux_248 = signal_and_132 ? signal_select_291 : signal_mux_247;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_15 <= signal_const_84;
        else
            if (signal_or_33)
                signal_reg_15 <= signal_mux_248;
    end
    assign signal_const_364 = 24'b000000000000000000001101;
    assign signal_lt_88 = signal_const_364 < prefetched_count;
    assign signal_not_79 = ~ next_is_order;
    assign signal_and_131 = prefetch_next & signal_not_79;
    assign signal_and_132 = signal_and_131 & signal_lt_88;
    assign signal_cat_56 = { signal_const_63,
                             count };
    assign signal_add_48 = collected + signal_cat_56;
    assign signal_lt_89 = signal_const_134 < signal_add_48;
    assign signal_lt_90 = signal_const_134 < collected;
    assign signal_not_80 = ~ signal_lt_90;
    assign signal_eq_77 = state == signal_const_64;
    assign signal_and_133 = collect & signal_eq_77;
    assign signal_and_134 = signal_and_133 & signal_not_80;
    assign signal_and_135 = signal_and_134 & signal_lt_89;
    assign signal_or_33 = signal_and_135 | signal_and_132;
    assign signal_mux_249 = signal_or_33 ? signal_mux_248 : signal_reg_15;
    assign signal_select_309 = prefetched_data[119:112];
    assign signal_select_310 = signal_select_657[127:120];
    assign signal_select_311 = signal_select_657[119:112];
    assign signal_select_312 = signal_select_657[111:104];
    assign signal_select_313 = signal_select_657[103:96];
    assign signal_select_314 = signal_select_657[95:88];
    assign signal_select_315 = signal_select_657[87:80];
    assign signal_select_316 = signal_select_657[79:72];
    assign signal_select_317 = signal_select_657[71:64];
    assign signal_select_318 = signal_select_657[63:56];
    assign signal_select_319 = signal_select_657[55:48];
    assign signal_select_320 = signal_select_657[47:40];
    assign signal_select_321 = signal_select_657[39:32];
    assign signal_select_322 = signal_select_657[31:24];
    assign signal_select_323 = signal_select_657[23:16];
    assign signal_select_324 = signal_select_657[15:8];
    assign signal_select_325 = signal_select_657[7:0];
    assign signal_const_370 = 16'b0000000000001110;
    assign signal_sub_25 = signal_const_370 - collected;
    assign signal_select_326 = signal_sub_25[3:0];
    always @* begin
        case (signal_select_326)
        0:
            signal_mux_250 <= signal_select_325;
        1:
            signal_mux_250 <= signal_select_324;
        2:
            signal_mux_250 <= signal_select_323;
        3:
            signal_mux_250 <= signal_select_322;
        4:
            signal_mux_250 <= signal_select_321;
        5:
            signal_mux_250 <= signal_select_320;
        6:
            signal_mux_250 <= signal_select_319;
        7:
            signal_mux_250 <= signal_select_318;
        8:
            signal_mux_250 <= signal_select_317;
        9:
            signal_mux_250 <= signal_select_316;
        10:
            signal_mux_250 <= signal_select_315;
        11:
            signal_mux_250 <= signal_select_314;
        12:
            signal_mux_250 <= signal_select_313;
        13:
            signal_mux_250 <= signal_select_312;
        14:
            signal_mux_250 <= signal_select_311;
        default:
            signal_mux_250 <= signal_select_310;
        endcase
    end
    assign signal_mux_251 = signal_and_137 ? signal_select_309 : signal_mux_250;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_16 <= signal_const_84;
        else
            if (signal_or_34)
                signal_reg_16 <= signal_mux_251;
    end
    assign signal_cat_57 = { signal_const_176,
                             skip_count };
    assign prefetched_count = signal_cat_57 - skip_left;
    assign signal_const_372 = 24'b000000000000000000001110;
    assign signal_lt_91 = signal_const_372 < prefetched_count;
    assign signal_not_81 = ~ next_is_order;
    assign signal_and_136 = prefetch_next & signal_not_81;
    assign signal_and_137 = signal_and_136 & signal_lt_91;
    assign signal_cat_58 = { signal_const_63,
                             count };
    assign signal_add_49 = collected + signal_cat_58;
    assign signal_lt_92 = signal_const_370 < signal_add_49;
    assign signal_lt_93 = signal_const_370 < collected;
    assign signal_not_82 = ~ signal_lt_93;
    assign signal_eq_78 = state == signal_const_64;
    assign signal_and_138 = collect & signal_eq_78;
    assign signal_and_139 = signal_and_138 & signal_not_82;
    assign signal_and_140 = signal_and_139 & signal_lt_92;
    assign signal_or_34 = signal_and_140 | signal_and_137;
    assign signal_mux_252 = signal_or_34 ? signal_mux_251 : signal_reg_16;
    assign signal_select_327 = signal_select_657[127:120];
    assign signal_select_328 = signal_select_657[119:112];
    assign signal_select_329 = signal_select_657[111:104];
    assign signal_select_330 = signal_select_657[103:96];
    assign signal_select_331 = signal_select_657[95:88];
    assign signal_select_332 = signal_select_657[87:80];
    assign signal_select_333 = signal_select_657[79:72];
    assign signal_select_334 = signal_select_657[71:64];
    assign signal_select_335 = signal_select_657[63:56];
    assign signal_select_336 = signal_select_657[55:48];
    assign signal_select_337 = signal_select_657[47:40];
    assign signal_select_338 = signal_select_657[39:32];
    assign signal_select_339 = signal_select_657[31:24];
    assign signal_select_340 = signal_select_657[23:16];
    assign signal_select_341 = signal_select_657[15:8];
    assign signal_select_342 = signal_select_657[7:0];
    assign signal_const_378 = 16'b0000000000001111;
    assign signal_sub_26 = signal_const_378 - collected;
    assign signal_select_343 = signal_sub_26[3:0];
    always @* begin
        case (signal_select_343)
        0:
            signal_mux_253 <= signal_select_342;
        1:
            signal_mux_253 <= signal_select_341;
        2:
            signal_mux_253 <= signal_select_340;
        3:
            signal_mux_253 <= signal_select_339;
        4:
            signal_mux_253 <= signal_select_338;
        5:
            signal_mux_253 <= signal_select_337;
        6:
            signal_mux_253 <= signal_select_336;
        7:
            signal_mux_253 <= signal_select_335;
        8:
            signal_mux_253 <= signal_select_334;
        9:
            signal_mux_253 <= signal_select_333;
        10:
            signal_mux_253 <= signal_select_332;
        11:
            signal_mux_253 <= signal_select_331;
        12:
            signal_mux_253 <= signal_select_330;
        13:
            signal_mux_253 <= signal_select_329;
        14:
            signal_mux_253 <= signal_select_328;
        default:
            signal_mux_253 <= signal_select_327;
        endcase
    end
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_17 <= signal_const_84;
        else
            if (signal_and_143)
                signal_reg_17 <= signal_mux_253;
    end
    assign signal_cat_59 = { signal_const_63,
                             count };
    assign signal_add_50 = collected + signal_cat_59;
    assign signal_lt_94 = signal_const_378 < signal_add_50;
    assign signal_lt_95 = signal_const_378 < collected;
    assign signal_not_83 = ~ signal_lt_95;
    assign signal_eq_79 = state == signal_const_64;
    assign signal_and_141 = collect & signal_eq_79;
    assign signal_and_142 = signal_and_141 & signal_not_83;
    assign signal_and_143 = signal_and_142 & signal_lt_94;
    assign signal_mux_254 = signal_and_143 ? signal_mux_253 : signal_reg_17;
    assign signal_select_344 = signal_select_657[127:120];
    assign signal_select_345 = signal_select_657[119:112];
    assign signal_select_346 = signal_select_657[111:104];
    assign signal_select_347 = signal_select_657[103:96];
    assign signal_select_348 = signal_select_657[95:88];
    assign signal_select_349 = signal_select_657[87:80];
    assign signal_select_350 = signal_select_657[79:72];
    assign signal_select_351 = signal_select_657[71:64];
    assign signal_select_352 = signal_select_657[63:56];
    assign signal_select_353 = signal_select_657[55:48];
    assign signal_select_354 = signal_select_657[47:40];
    assign signal_select_355 = signal_select_657[39:32];
    assign signal_select_356 = signal_select_657[31:24];
    assign signal_select_357 = signal_select_657[23:16];
    assign signal_select_358 = signal_select_657[15:8];
    assign signal_select_359 = signal_select_657[7:0];
    assign signal_const_384 = 16'b0000000000010000;
    assign signal_sub_27 = signal_const_384 - collected;
    assign signal_select_360 = signal_sub_27[3:0];
    always @* begin
        case (signal_select_360)
        0:
            signal_mux_255 <= signal_select_359;
        1:
            signal_mux_255 <= signal_select_358;
        2:
            signal_mux_255 <= signal_select_357;
        3:
            signal_mux_255 <= signal_select_356;
        4:
            signal_mux_255 <= signal_select_355;
        5:
            signal_mux_255 <= signal_select_354;
        6:
            signal_mux_255 <= signal_select_353;
        7:
            signal_mux_255 <= signal_select_352;
        8:
            signal_mux_255 <= signal_select_351;
        9:
            signal_mux_255 <= signal_select_350;
        10:
            signal_mux_255 <= signal_select_349;
        11:
            signal_mux_255 <= signal_select_348;
        12:
            signal_mux_255 <= signal_select_347;
        13:
            signal_mux_255 <= signal_select_346;
        14:
            signal_mux_255 <= signal_select_345;
        default:
            signal_mux_255 <= signal_select_344;
        endcase
    end
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_18 <= signal_const_84;
        else
            if (signal_and_146)
                signal_reg_18 <= signal_mux_255;
    end
    assign signal_cat_60 = { signal_const_63,
                             count };
    assign signal_add_51 = collected + signal_cat_60;
    assign signal_lt_96 = signal_const_384 < signal_add_51;
    assign signal_lt_97 = signal_const_384 < collected;
    assign signal_not_84 = ~ signal_lt_97;
    assign signal_eq_80 = state == signal_const_64;
    assign signal_and_144 = collect & signal_eq_80;
    assign signal_and_145 = signal_and_144 & signal_not_84;
    assign signal_and_146 = signal_and_145 & signal_lt_96;
    assign signal_mux_256 = signal_and_146 ? signal_mux_255 : signal_reg_18;
    assign signal_select_361 = signal_select_657[127:120];
    assign signal_select_362 = signal_select_657[119:112];
    assign signal_select_363 = signal_select_657[111:104];
    assign signal_select_364 = signal_select_657[103:96];
    assign signal_select_365 = signal_select_657[95:88];
    assign signal_select_366 = signal_select_657[87:80];
    assign signal_select_367 = signal_select_657[79:72];
    assign signal_select_368 = signal_select_657[71:64];
    assign signal_select_369 = signal_select_657[63:56];
    assign signal_select_370 = signal_select_657[55:48];
    assign signal_select_371 = signal_select_657[47:40];
    assign signal_select_372 = signal_select_657[39:32];
    assign signal_select_373 = signal_select_657[31:24];
    assign signal_select_374 = signal_select_657[23:16];
    assign signal_select_375 = signal_select_657[15:8];
    assign signal_select_376 = signal_select_657[7:0];
    assign signal_const_390 = 16'b0000000000010001;
    assign signal_sub_28 = signal_const_390 - collected;
    assign signal_select_377 = signal_sub_28[3:0];
    always @* begin
        case (signal_select_377)
        0:
            signal_mux_257 <= signal_select_376;
        1:
            signal_mux_257 <= signal_select_375;
        2:
            signal_mux_257 <= signal_select_374;
        3:
            signal_mux_257 <= signal_select_373;
        4:
            signal_mux_257 <= signal_select_372;
        5:
            signal_mux_257 <= signal_select_371;
        6:
            signal_mux_257 <= signal_select_370;
        7:
            signal_mux_257 <= signal_select_369;
        8:
            signal_mux_257 <= signal_select_368;
        9:
            signal_mux_257 <= signal_select_367;
        10:
            signal_mux_257 <= signal_select_366;
        11:
            signal_mux_257 <= signal_select_365;
        12:
            signal_mux_257 <= signal_select_364;
        13:
            signal_mux_257 <= signal_select_363;
        14:
            signal_mux_257 <= signal_select_362;
        default:
            signal_mux_257 <= signal_select_361;
        endcase
    end
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_19 <= signal_const_84;
        else
            if (signal_and_149)
                signal_reg_19 <= signal_mux_257;
    end
    assign signal_cat_61 = { signal_const_63,
                             count };
    assign signal_add_52 = collected + signal_cat_61;
    assign signal_lt_98 = signal_const_390 < signal_add_52;
    assign signal_lt_99 = signal_const_390 < collected;
    assign signal_not_85 = ~ signal_lt_99;
    assign signal_eq_81 = state == signal_const_64;
    assign signal_and_147 = collect & signal_eq_81;
    assign signal_and_148 = signal_and_147 & signal_not_85;
    assign signal_and_149 = signal_and_148 & signal_lt_98;
    assign signal_mux_258 = signal_and_149 ? signal_mux_257 : signal_reg_19;
    assign signal_select_378 = signal_select_657[127:120];
    assign signal_select_379 = signal_select_657[119:112];
    assign signal_select_380 = signal_select_657[111:104];
    assign signal_select_381 = signal_select_657[103:96];
    assign signal_select_382 = signal_select_657[95:88];
    assign signal_select_383 = signal_select_657[87:80];
    assign signal_select_384 = signal_select_657[79:72];
    assign signal_select_385 = signal_select_657[71:64];
    assign signal_select_386 = signal_select_657[63:56];
    assign signal_select_387 = signal_select_657[55:48];
    assign signal_select_388 = signal_select_657[47:40];
    assign signal_select_389 = signal_select_657[39:32];
    assign signal_select_390 = signal_select_657[31:24];
    assign signal_select_391 = signal_select_657[23:16];
    assign signal_select_392 = signal_select_657[15:8];
    assign signal_select_393 = signal_select_657[7:0];
    assign signal_const_396 = 16'b0000000000010010;
    assign signal_sub_29 = signal_const_396 - collected;
    assign signal_select_394 = signal_sub_29[3:0];
    always @* begin
        case (signal_select_394)
        0:
            signal_mux_259 <= signal_select_393;
        1:
            signal_mux_259 <= signal_select_392;
        2:
            signal_mux_259 <= signal_select_391;
        3:
            signal_mux_259 <= signal_select_390;
        4:
            signal_mux_259 <= signal_select_389;
        5:
            signal_mux_259 <= signal_select_388;
        6:
            signal_mux_259 <= signal_select_387;
        7:
            signal_mux_259 <= signal_select_386;
        8:
            signal_mux_259 <= signal_select_385;
        9:
            signal_mux_259 <= signal_select_384;
        10:
            signal_mux_259 <= signal_select_383;
        11:
            signal_mux_259 <= signal_select_382;
        12:
            signal_mux_259 <= signal_select_381;
        13:
            signal_mux_259 <= signal_select_380;
        14:
            signal_mux_259 <= signal_select_379;
        default:
            signal_mux_259 <= signal_select_378;
        endcase
    end
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_20 <= signal_const_84;
        else
            if (signal_and_152)
                signal_reg_20 <= signal_mux_259;
    end
    assign signal_cat_62 = { signal_const_63,
                             count };
    assign signal_add_53 = collected + signal_cat_62;
    assign signal_lt_100 = signal_const_396 < signal_add_53;
    assign signal_lt_101 = signal_const_396 < collected;
    assign signal_not_86 = ~ signal_lt_101;
    assign signal_eq_82 = state == signal_const_64;
    assign signal_and_150 = collect & signal_eq_82;
    assign signal_and_151 = signal_and_150 & signal_not_86;
    assign signal_and_152 = signal_and_151 & signal_lt_100;
    assign signal_mux_260 = signal_and_152 ? signal_mux_259 : signal_reg_20;
    assign signal_select_395 = signal_select_657[127:120];
    assign signal_select_396 = signal_select_657[119:112];
    assign signal_select_397 = signal_select_657[111:104];
    assign signal_select_398 = signal_select_657[103:96];
    assign signal_select_399 = signal_select_657[95:88];
    assign signal_select_400 = signal_select_657[87:80];
    assign signal_select_401 = signal_select_657[79:72];
    assign signal_select_402 = signal_select_657[71:64];
    assign signal_select_403 = signal_select_657[63:56];
    assign signal_select_404 = signal_select_657[55:48];
    assign signal_select_405 = signal_select_657[47:40];
    assign signal_select_406 = signal_select_657[39:32];
    assign signal_select_407 = signal_select_657[31:24];
    assign signal_select_408 = signal_select_657[23:16];
    assign signal_select_409 = signal_select_657[15:8];
    assign signal_select_410 = signal_select_657[7:0];
    assign signal_const_402 = 16'b0000000000010011;
    assign signal_sub_30 = signal_const_402 - collected;
    assign signal_select_411 = signal_sub_30[3:0];
    always @* begin
        case (signal_select_411)
        0:
            signal_mux_261 <= signal_select_410;
        1:
            signal_mux_261 <= signal_select_409;
        2:
            signal_mux_261 <= signal_select_408;
        3:
            signal_mux_261 <= signal_select_407;
        4:
            signal_mux_261 <= signal_select_406;
        5:
            signal_mux_261 <= signal_select_405;
        6:
            signal_mux_261 <= signal_select_404;
        7:
            signal_mux_261 <= signal_select_403;
        8:
            signal_mux_261 <= signal_select_402;
        9:
            signal_mux_261 <= signal_select_401;
        10:
            signal_mux_261 <= signal_select_400;
        11:
            signal_mux_261 <= signal_select_399;
        12:
            signal_mux_261 <= signal_select_398;
        13:
            signal_mux_261 <= signal_select_397;
        14:
            signal_mux_261 <= signal_select_396;
        default:
            signal_mux_261 <= signal_select_395;
        endcase
    end
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_21 <= signal_const_84;
        else
            if (signal_and_155)
                signal_reg_21 <= signal_mux_261;
    end
    assign signal_cat_63 = { signal_const_63,
                             count };
    assign signal_add_54 = collected + signal_cat_63;
    assign signal_lt_102 = signal_const_402 < signal_add_54;
    assign signal_lt_103 = signal_const_402 < collected;
    assign signal_not_87 = ~ signal_lt_103;
    assign signal_eq_83 = state == signal_const_64;
    assign signal_and_153 = collect & signal_eq_83;
    assign signal_and_154 = signal_and_153 & signal_not_87;
    assign signal_and_155 = signal_and_154 & signal_lt_102;
    assign signal_mux_262 = signal_and_155 ? signal_mux_261 : signal_reg_21;
    assign signal_select_412 = signal_select_657[127:120];
    assign signal_select_413 = signal_select_657[119:112];
    assign signal_select_414 = signal_select_657[111:104];
    assign signal_select_415 = signal_select_657[103:96];
    assign signal_select_416 = signal_select_657[95:88];
    assign signal_select_417 = signal_select_657[87:80];
    assign signal_select_418 = signal_select_657[79:72];
    assign signal_select_419 = signal_select_657[71:64];
    assign signal_select_420 = signal_select_657[63:56];
    assign signal_select_421 = signal_select_657[55:48];
    assign signal_select_422 = signal_select_657[47:40];
    assign signal_select_423 = signal_select_657[39:32];
    assign signal_select_424 = signal_select_657[31:24];
    assign signal_select_425 = signal_select_657[23:16];
    assign signal_select_426 = signal_select_657[15:8];
    assign signal_select_427 = signal_select_657[7:0];
    assign signal_sub_31 = signal_const_136 - collected;
    assign signal_select_428 = signal_sub_31[3:0];
    always @* begin
        case (signal_select_428)
        0:
            signal_mux_263 <= signal_select_427;
        1:
            signal_mux_263 <= signal_select_426;
        2:
            signal_mux_263 <= signal_select_425;
        3:
            signal_mux_263 <= signal_select_424;
        4:
            signal_mux_263 <= signal_select_423;
        5:
            signal_mux_263 <= signal_select_422;
        6:
            signal_mux_263 <= signal_select_421;
        7:
            signal_mux_263 <= signal_select_420;
        8:
            signal_mux_263 <= signal_select_419;
        9:
            signal_mux_263 <= signal_select_418;
        10:
            signal_mux_263 <= signal_select_417;
        11:
            signal_mux_263 <= signal_select_416;
        12:
            signal_mux_263 <= signal_select_415;
        13:
            signal_mux_263 <= signal_select_414;
        14:
            signal_mux_263 <= signal_select_413;
        default:
            signal_mux_263 <= signal_select_412;
        endcase
    end
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_22 <= signal_const_84;
        else
            if (signal_and_158)
                signal_reg_22 <= signal_mux_263;
    end
    assign signal_cat_64 = { signal_const_63,
                             count };
    assign signal_add_55 = collected + signal_cat_64;
    assign signal_lt_104 = signal_const_136 < signal_add_55;
    assign signal_lt_105 = signal_const_136 < collected;
    assign signal_not_88 = ~ signal_lt_105;
    assign signal_eq_84 = state == signal_const_64;
    assign signal_and_156 = collect & signal_eq_84;
    assign signal_and_157 = signal_and_156 & signal_not_88;
    assign signal_and_158 = signal_and_157 & signal_lt_104;
    assign signal_mux_264 = signal_and_158 ? signal_mux_263 : signal_reg_22;
    assign signal_select_429 = signal_select_657[127:120];
    assign signal_select_430 = signal_select_657[119:112];
    assign signal_select_431 = signal_select_657[111:104];
    assign signal_select_432 = signal_select_657[103:96];
    assign signal_select_433 = signal_select_657[95:88];
    assign signal_select_434 = signal_select_657[87:80];
    assign signal_select_435 = signal_select_657[79:72];
    assign signal_select_436 = signal_select_657[71:64];
    assign signal_select_437 = signal_select_657[63:56];
    assign signal_select_438 = signal_select_657[55:48];
    assign signal_select_439 = signal_select_657[47:40];
    assign signal_select_440 = signal_select_657[39:32];
    assign signal_select_441 = signal_select_657[31:24];
    assign signal_select_442 = signal_select_657[23:16];
    assign signal_select_443 = signal_select_657[15:8];
    assign signal_select_444 = signal_select_657[7:0];
    assign signal_const_414 = 16'b0000000000010101;
    assign signal_sub_32 = signal_const_414 - collected;
    assign signal_select_445 = signal_sub_32[3:0];
    always @* begin
        case (signal_select_445)
        0:
            signal_mux_265 <= signal_select_444;
        1:
            signal_mux_265 <= signal_select_443;
        2:
            signal_mux_265 <= signal_select_442;
        3:
            signal_mux_265 <= signal_select_441;
        4:
            signal_mux_265 <= signal_select_440;
        5:
            signal_mux_265 <= signal_select_439;
        6:
            signal_mux_265 <= signal_select_438;
        7:
            signal_mux_265 <= signal_select_437;
        8:
            signal_mux_265 <= signal_select_436;
        9:
            signal_mux_265 <= signal_select_435;
        10:
            signal_mux_265 <= signal_select_434;
        11:
            signal_mux_265 <= signal_select_433;
        12:
            signal_mux_265 <= signal_select_432;
        13:
            signal_mux_265 <= signal_select_431;
        14:
            signal_mux_265 <= signal_select_430;
        default:
            signal_mux_265 <= signal_select_429;
        endcase
    end
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_23 <= signal_const_84;
        else
            if (signal_and_161)
                signal_reg_23 <= signal_mux_265;
    end
    assign signal_cat_65 = { signal_const_63,
                             count };
    assign signal_add_56 = collected + signal_cat_65;
    assign signal_lt_106 = signal_const_414 < signal_add_56;
    assign signal_lt_107 = signal_const_414 < collected;
    assign signal_not_89 = ~ signal_lt_107;
    assign signal_eq_85 = state == signal_const_64;
    assign signal_and_159 = collect & signal_eq_85;
    assign signal_and_160 = signal_and_159 & signal_not_89;
    assign signal_and_161 = signal_and_160 & signal_lt_106;
    assign signal_mux_266 = signal_and_161 ? signal_mux_265 : signal_reg_23;
    assign signal_select_446 = signal_select_657[127:120];
    assign signal_select_447 = signal_select_657[119:112];
    assign signal_select_448 = signal_select_657[111:104];
    assign signal_select_449 = signal_select_657[103:96];
    assign signal_select_450 = signal_select_657[95:88];
    assign signal_select_451 = signal_select_657[87:80];
    assign signal_select_452 = signal_select_657[79:72];
    assign signal_select_453 = signal_select_657[71:64];
    assign signal_select_454 = signal_select_657[63:56];
    assign signal_select_455 = signal_select_657[55:48];
    assign signal_select_456 = signal_select_657[47:40];
    assign signal_select_457 = signal_select_657[39:32];
    assign signal_select_458 = signal_select_657[31:24];
    assign signal_select_459 = signal_select_657[23:16];
    assign signal_select_460 = signal_select_657[15:8];
    assign signal_select_461 = signal_select_657[7:0];
    assign signal_const_420 = 16'b0000000000010110;
    assign signal_sub_33 = signal_const_420 - collected;
    assign signal_select_462 = signal_sub_33[3:0];
    always @* begin
        case (signal_select_462)
        0:
            signal_mux_267 <= signal_select_461;
        1:
            signal_mux_267 <= signal_select_460;
        2:
            signal_mux_267 <= signal_select_459;
        3:
            signal_mux_267 <= signal_select_458;
        4:
            signal_mux_267 <= signal_select_457;
        5:
            signal_mux_267 <= signal_select_456;
        6:
            signal_mux_267 <= signal_select_455;
        7:
            signal_mux_267 <= signal_select_454;
        8:
            signal_mux_267 <= signal_select_453;
        9:
            signal_mux_267 <= signal_select_452;
        10:
            signal_mux_267 <= signal_select_451;
        11:
            signal_mux_267 <= signal_select_450;
        12:
            signal_mux_267 <= signal_select_449;
        13:
            signal_mux_267 <= signal_select_448;
        14:
            signal_mux_267 <= signal_select_447;
        default:
            signal_mux_267 <= signal_select_446;
        endcase
    end
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_24 <= signal_const_84;
        else
            if (signal_and_164)
                signal_reg_24 <= signal_mux_267;
    end
    assign signal_cat_66 = { signal_const_63,
                             count };
    assign signal_add_57 = collected + signal_cat_66;
    assign signal_lt_108 = signal_const_420 < signal_add_57;
    assign signal_lt_109 = signal_const_420 < collected;
    assign signal_not_90 = ~ signal_lt_109;
    assign signal_eq_86 = state == signal_const_64;
    assign signal_and_162 = collect & signal_eq_86;
    assign signal_and_163 = signal_and_162 & signal_not_90;
    assign signal_and_164 = signal_and_163 & signal_lt_108;
    assign signal_mux_268 = signal_and_164 ? signal_mux_267 : signal_reg_24;
    assign signal_select_463 = signal_select_657[127:120];
    assign signal_select_464 = signal_select_657[119:112];
    assign signal_select_465 = signal_select_657[111:104];
    assign signal_select_466 = signal_select_657[103:96];
    assign signal_select_467 = signal_select_657[95:88];
    assign signal_select_468 = signal_select_657[87:80];
    assign signal_select_469 = signal_select_657[79:72];
    assign signal_select_470 = signal_select_657[71:64];
    assign signal_select_471 = signal_select_657[63:56];
    assign signal_select_472 = signal_select_657[55:48];
    assign signal_select_473 = signal_select_657[47:40];
    assign signal_select_474 = signal_select_657[39:32];
    assign signal_select_475 = signal_select_657[31:24];
    assign signal_select_476 = signal_select_657[23:16];
    assign signal_select_477 = signal_select_657[15:8];
    assign signal_select_478 = signal_select_657[7:0];
    assign signal_const_426 = 16'b0000000000010111;
    assign signal_sub_34 = signal_const_426 - collected;
    assign signal_select_479 = signal_sub_34[3:0];
    always @* begin
        case (signal_select_479)
        0:
            signal_mux_269 <= signal_select_478;
        1:
            signal_mux_269 <= signal_select_477;
        2:
            signal_mux_269 <= signal_select_476;
        3:
            signal_mux_269 <= signal_select_475;
        4:
            signal_mux_269 <= signal_select_474;
        5:
            signal_mux_269 <= signal_select_473;
        6:
            signal_mux_269 <= signal_select_472;
        7:
            signal_mux_269 <= signal_select_471;
        8:
            signal_mux_269 <= signal_select_470;
        9:
            signal_mux_269 <= signal_select_469;
        10:
            signal_mux_269 <= signal_select_468;
        11:
            signal_mux_269 <= signal_select_467;
        12:
            signal_mux_269 <= signal_select_466;
        13:
            signal_mux_269 <= signal_select_465;
        14:
            signal_mux_269 <= signal_select_464;
        default:
            signal_mux_269 <= signal_select_463;
        endcase
    end
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_25 <= signal_const_84;
        else
            if (signal_and_167)
                signal_reg_25 <= signal_mux_269;
    end
    assign signal_cat_67 = { signal_const_63,
                             count };
    assign signal_add_58 = collected + signal_cat_67;
    assign signal_lt_110 = signal_const_426 < signal_add_58;
    assign signal_lt_111 = signal_const_426 < collected;
    assign signal_not_91 = ~ signal_lt_111;
    assign signal_eq_87 = state == signal_const_64;
    assign signal_and_165 = collect & signal_eq_87;
    assign signal_and_166 = signal_and_165 & signal_not_91;
    assign signal_and_167 = signal_and_166 & signal_lt_110;
    assign signal_mux_270 = signal_and_167 ? signal_mux_269 : signal_reg_25;
    assign signal_select_480 = signal_select_657[127:120];
    assign signal_select_481 = signal_select_657[119:112];
    assign signal_select_482 = signal_select_657[111:104];
    assign signal_select_483 = signal_select_657[103:96];
    assign signal_select_484 = signal_select_657[95:88];
    assign signal_select_485 = signal_select_657[87:80];
    assign signal_select_486 = signal_select_657[79:72];
    assign signal_select_487 = signal_select_657[71:64];
    assign signal_select_488 = signal_select_657[63:56];
    assign signal_select_489 = signal_select_657[55:48];
    assign signal_select_490 = signal_select_657[47:40];
    assign signal_select_491 = signal_select_657[39:32];
    assign signal_select_492 = signal_select_657[31:24];
    assign signal_select_493 = signal_select_657[23:16];
    assign signal_select_494 = signal_select_657[15:8];
    assign signal_select_495 = signal_select_657[7:0];
    assign signal_sub_35 = signal_const_85 - collected;
    assign signal_select_496 = signal_sub_35[3:0];
    always @* begin
        case (signal_select_496)
        0:
            signal_mux_271 <= signal_select_495;
        1:
            signal_mux_271 <= signal_select_494;
        2:
            signal_mux_271 <= signal_select_493;
        3:
            signal_mux_271 <= signal_select_492;
        4:
            signal_mux_271 <= signal_select_491;
        5:
            signal_mux_271 <= signal_select_490;
        6:
            signal_mux_271 <= signal_select_489;
        7:
            signal_mux_271 <= signal_select_488;
        8:
            signal_mux_271 <= signal_select_487;
        9:
            signal_mux_271 <= signal_select_486;
        10:
            signal_mux_271 <= signal_select_485;
        11:
            signal_mux_271 <= signal_select_484;
        12:
            signal_mux_271 <= signal_select_483;
        13:
            signal_mux_271 <= signal_select_482;
        14:
            signal_mux_271 <= signal_select_481;
        default:
            signal_mux_271 <= signal_select_480;
        endcase
    end
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_26 <= signal_const_84;
        else
            if (signal_and_170)
                signal_reg_26 <= signal_mux_271;
    end
    assign signal_cat_68 = { signal_const_63,
                             count };
    assign signal_add_59 = collected + signal_cat_68;
    assign signal_lt_112 = signal_const_85 < signal_add_59;
    assign signal_lt_113 = signal_const_85 < collected;
    assign signal_not_92 = ~ signal_lt_113;
    assign signal_eq_88 = state == signal_const_64;
    assign signal_and_168 = collect & signal_eq_88;
    assign signal_and_169 = signal_and_168 & signal_not_92;
    assign signal_and_170 = signal_and_169 & signal_lt_112;
    assign signal_mux_272 = signal_and_170 ? signal_mux_271 : signal_reg_26;
    assign signal_select_497 = signal_select_657[127:120];
    assign signal_select_498 = signal_select_657[119:112];
    assign signal_select_499 = signal_select_657[111:104];
    assign signal_select_500 = signal_select_657[103:96];
    assign signal_select_501 = signal_select_657[95:88];
    assign signal_select_502 = signal_select_657[87:80];
    assign signal_select_503 = signal_select_657[79:72];
    assign signal_select_504 = signal_select_657[71:64];
    assign signal_select_505 = signal_select_657[63:56];
    assign signal_select_506 = signal_select_657[55:48];
    assign signal_select_507 = signal_select_657[47:40];
    assign signal_select_508 = signal_select_657[39:32];
    assign signal_select_509 = signal_select_657[31:24];
    assign signal_select_510 = signal_select_657[23:16];
    assign signal_select_511 = signal_select_657[15:8];
    assign signal_select_512 = signal_select_657[7:0];
    assign signal_sub_36 = signal_const_16 - collected;
    assign signal_select_513 = signal_sub_36[3:0];
    always @* begin
        case (signal_select_513)
        0:
            signal_mux_273 <= signal_select_512;
        1:
            signal_mux_273 <= signal_select_511;
        2:
            signal_mux_273 <= signal_select_510;
        3:
            signal_mux_273 <= signal_select_509;
        4:
            signal_mux_273 <= signal_select_508;
        5:
            signal_mux_273 <= signal_select_507;
        6:
            signal_mux_273 <= signal_select_506;
        7:
            signal_mux_273 <= signal_select_505;
        8:
            signal_mux_273 <= signal_select_504;
        9:
            signal_mux_273 <= signal_select_503;
        10:
            signal_mux_273 <= signal_select_502;
        11:
            signal_mux_273 <= signal_select_501;
        12:
            signal_mux_273 <= signal_select_500;
        13:
            signal_mux_273 <= signal_select_499;
        14:
            signal_mux_273 <= signal_select_498;
        default:
            signal_mux_273 <= signal_select_497;
        endcase
    end
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_27 <= signal_const_84;
        else
            if (signal_and_173)
                signal_reg_27 <= signal_mux_273;
    end
    assign signal_cat_69 = { signal_const_63,
                             count };
    assign signal_add_60 = collected + signal_cat_69;
    assign signal_lt_114 = signal_const_16 < signal_add_60;
    assign signal_lt_115 = signal_const_16 < collected;
    assign signal_not_93 = ~ signal_lt_115;
    assign signal_eq_89 = state == signal_const_64;
    assign signal_and_171 = collect & signal_eq_89;
    assign signal_and_172 = signal_and_171 & signal_not_93;
    assign signal_and_173 = signal_and_172 & signal_lt_114;
    assign signal_mux_274 = signal_and_173 ? signal_mux_273 : signal_reg_27;
    assign signal_select_514 = signal_select_657[127:120];
    assign signal_select_515 = signal_select_657[119:112];
    assign signal_select_516 = signal_select_657[111:104];
    assign signal_select_517 = signal_select_657[103:96];
    assign signal_select_518 = signal_select_657[95:88];
    assign signal_select_519 = signal_select_657[87:80];
    assign signal_select_520 = signal_select_657[79:72];
    assign signal_select_521 = signal_select_657[71:64];
    assign signal_select_522 = signal_select_657[63:56];
    assign signal_select_523 = signal_select_657[55:48];
    assign signal_select_524 = signal_select_657[47:40];
    assign signal_select_525 = signal_select_657[39:32];
    assign signal_select_526 = signal_select_657[31:24];
    assign signal_select_527 = signal_select_657[23:16];
    assign signal_select_528 = signal_select_657[15:8];
    assign signal_select_529 = signal_select_657[7:0];
    assign signal_sub_37 = signal_const_15 - collected;
    assign signal_select_530 = signal_sub_37[3:0];
    always @* begin
        case (signal_select_530)
        0:
            signal_mux_275 <= signal_select_529;
        1:
            signal_mux_275 <= signal_select_528;
        2:
            signal_mux_275 <= signal_select_527;
        3:
            signal_mux_275 <= signal_select_526;
        4:
            signal_mux_275 <= signal_select_525;
        5:
            signal_mux_275 <= signal_select_524;
        6:
            signal_mux_275 <= signal_select_523;
        7:
            signal_mux_275 <= signal_select_522;
        8:
            signal_mux_275 <= signal_select_521;
        9:
            signal_mux_275 <= signal_select_520;
        10:
            signal_mux_275 <= signal_select_519;
        11:
            signal_mux_275 <= signal_select_518;
        12:
            signal_mux_275 <= signal_select_517;
        13:
            signal_mux_275 <= signal_select_516;
        14:
            signal_mux_275 <= signal_select_515;
        default:
            signal_mux_275 <= signal_select_514;
        endcase
    end
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_28 <= signal_const_84;
        else
            if (signal_and_176)
                signal_reg_28 <= signal_mux_275;
    end
    assign signal_cat_70 = { signal_const_63,
                             count };
    assign signal_add_61 = collected + signal_cat_70;
    assign signal_lt_116 = signal_const_15 < signal_add_61;
    assign signal_lt_117 = signal_const_15 < collected;
    assign signal_not_94 = ~ signal_lt_117;
    assign signal_eq_90 = state == signal_const_64;
    assign signal_and_174 = collect & signal_eq_90;
    assign signal_and_175 = signal_and_174 & signal_not_94;
    assign signal_and_176 = signal_and_175 & signal_lt_116;
    assign signal_mux_276 = signal_and_176 ? signal_mux_275 : signal_reg_28;
    assign signal_select_531 = signal_select_657[127:120];
    assign signal_select_532 = signal_select_657[119:112];
    assign signal_select_533 = signal_select_657[111:104];
    assign signal_select_534 = signal_select_657[103:96];
    assign signal_select_535 = signal_select_657[95:88];
    assign signal_select_536 = signal_select_657[87:80];
    assign signal_select_537 = signal_select_657[79:72];
    assign signal_select_538 = signal_select_657[71:64];
    assign signal_select_539 = signal_select_657[63:56];
    assign signal_select_540 = signal_select_657[55:48];
    assign signal_select_541 = signal_select_657[47:40];
    assign signal_select_542 = signal_select_657[39:32];
    assign signal_select_543 = signal_select_657[31:24];
    assign signal_select_544 = signal_select_657[23:16];
    assign signal_select_545 = signal_select_657[15:8];
    assign signal_select_546 = signal_select_657[7:0];
    assign signal_const_450 = 16'b0000000000011011;
    assign signal_sub_38 = signal_const_450 - collected;
    assign signal_select_547 = signal_sub_38[3:0];
    always @* begin
        case (signal_select_547)
        0:
            signal_mux_277 <= signal_select_546;
        1:
            signal_mux_277 <= signal_select_545;
        2:
            signal_mux_277 <= signal_select_544;
        3:
            signal_mux_277 <= signal_select_543;
        4:
            signal_mux_277 <= signal_select_542;
        5:
            signal_mux_277 <= signal_select_541;
        6:
            signal_mux_277 <= signal_select_540;
        7:
            signal_mux_277 <= signal_select_539;
        8:
            signal_mux_277 <= signal_select_538;
        9:
            signal_mux_277 <= signal_select_537;
        10:
            signal_mux_277 <= signal_select_536;
        11:
            signal_mux_277 <= signal_select_535;
        12:
            signal_mux_277 <= signal_select_534;
        13:
            signal_mux_277 <= signal_select_533;
        14:
            signal_mux_277 <= signal_select_532;
        default:
            signal_mux_277 <= signal_select_531;
        endcase
    end
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_29 <= signal_const_84;
        else
            if (signal_and_179)
                signal_reg_29 <= signal_mux_277;
    end
    assign signal_cat_71 = { signal_const_63,
                             count };
    assign signal_add_62 = collected + signal_cat_71;
    assign signal_lt_118 = signal_const_450 < signal_add_62;
    assign signal_lt_119 = signal_const_450 < collected;
    assign signal_not_95 = ~ signal_lt_119;
    assign signal_eq_91 = state == signal_const_64;
    assign signal_and_177 = collect & signal_eq_91;
    assign signal_and_178 = signal_and_177 & signal_not_95;
    assign signal_and_179 = signal_and_178 & signal_lt_118;
    assign signal_mux_278 = signal_and_179 ? signal_mux_277 : signal_reg_29;
    assign signal_select_548 = signal_select_657[127:120];
    assign signal_select_549 = signal_select_657[119:112];
    assign signal_select_550 = signal_select_657[111:104];
    assign signal_select_551 = signal_select_657[103:96];
    assign signal_select_552 = signal_select_657[95:88];
    assign signal_select_553 = signal_select_657[87:80];
    assign signal_select_554 = signal_select_657[79:72];
    assign signal_select_555 = signal_select_657[71:64];
    assign signal_select_556 = signal_select_657[63:56];
    assign signal_select_557 = signal_select_657[55:48];
    assign signal_select_558 = signal_select_657[47:40];
    assign signal_select_559 = signal_select_657[39:32];
    assign signal_select_560 = signal_select_657[31:24];
    assign signal_select_561 = signal_select_657[23:16];
    assign signal_select_562 = signal_select_657[15:8];
    assign signal_select_563 = signal_select_657[7:0];
    assign signal_const_456 = 16'b0000000000011100;
    assign signal_sub_39 = signal_const_456 - collected;
    assign signal_select_564 = signal_sub_39[3:0];
    always @* begin
        case (signal_select_564)
        0:
            signal_mux_279 <= signal_select_563;
        1:
            signal_mux_279 <= signal_select_562;
        2:
            signal_mux_279 <= signal_select_561;
        3:
            signal_mux_279 <= signal_select_560;
        4:
            signal_mux_279 <= signal_select_559;
        5:
            signal_mux_279 <= signal_select_558;
        6:
            signal_mux_279 <= signal_select_557;
        7:
            signal_mux_279 <= signal_select_556;
        8:
            signal_mux_279 <= signal_select_555;
        9:
            signal_mux_279 <= signal_select_554;
        10:
            signal_mux_279 <= signal_select_553;
        11:
            signal_mux_279 <= signal_select_552;
        12:
            signal_mux_279 <= signal_select_551;
        13:
            signal_mux_279 <= signal_select_550;
        14:
            signal_mux_279 <= signal_select_549;
        default:
            signal_mux_279 <= signal_select_548;
        endcase
    end
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_30 <= signal_const_84;
        else
            if (signal_and_182)
                signal_reg_30 <= signal_mux_279;
    end
    assign signal_cat_72 = { signal_const_63,
                             count };
    assign signal_add_63 = collected + signal_cat_72;
    assign signal_lt_120 = signal_const_456 < signal_add_63;
    assign signal_lt_121 = signal_const_456 < collected;
    assign signal_not_96 = ~ signal_lt_121;
    assign signal_eq_92 = state == signal_const_64;
    assign signal_and_180 = collect & signal_eq_92;
    assign signal_and_181 = signal_and_180 & signal_not_96;
    assign signal_and_182 = signal_and_181 & signal_lt_120;
    assign signal_mux_280 = signal_and_182 ? signal_mux_279 : signal_reg_30;
    assign signal_select_565 = signal_select_657[127:120];
    assign signal_select_566 = signal_select_657[119:112];
    assign signal_select_567 = signal_select_657[111:104];
    assign signal_select_568 = signal_select_657[103:96];
    assign signal_select_569 = signal_select_657[95:88];
    assign signal_select_570 = signal_select_657[87:80];
    assign signal_select_571 = signal_select_657[79:72];
    assign signal_select_572 = signal_select_657[71:64];
    assign signal_select_573 = signal_select_657[63:56];
    assign signal_select_574 = signal_select_657[55:48];
    assign signal_select_575 = signal_select_657[47:40];
    assign signal_select_576 = signal_select_657[39:32];
    assign signal_select_577 = signal_select_657[31:24];
    assign signal_select_578 = signal_select_657[23:16];
    assign signal_select_579 = signal_select_657[15:8];
    assign signal_select_580 = signal_select_657[7:0];
    assign signal_const_462 = 16'b0000000000011101;
    assign signal_sub_40 = signal_const_462 - collected;
    assign signal_select_581 = signal_sub_40[3:0];
    always @* begin
        case (signal_select_581)
        0:
            signal_mux_281 <= signal_select_580;
        1:
            signal_mux_281 <= signal_select_579;
        2:
            signal_mux_281 <= signal_select_578;
        3:
            signal_mux_281 <= signal_select_577;
        4:
            signal_mux_281 <= signal_select_576;
        5:
            signal_mux_281 <= signal_select_575;
        6:
            signal_mux_281 <= signal_select_574;
        7:
            signal_mux_281 <= signal_select_573;
        8:
            signal_mux_281 <= signal_select_572;
        9:
            signal_mux_281 <= signal_select_571;
        10:
            signal_mux_281 <= signal_select_570;
        11:
            signal_mux_281 <= signal_select_569;
        12:
            signal_mux_281 <= signal_select_568;
        13:
            signal_mux_281 <= signal_select_567;
        14:
            signal_mux_281 <= signal_select_566;
        default:
            signal_mux_281 <= signal_select_565;
        endcase
    end
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_31 <= signal_const_84;
        else
            if (signal_and_185)
                signal_reg_31 <= signal_mux_281;
    end
    assign signal_cat_73 = { signal_const_63,
                             count };
    assign signal_add_64 = collected + signal_cat_73;
    assign signal_lt_122 = signal_const_462 < signal_add_64;
    assign signal_lt_123 = signal_const_462 < collected;
    assign signal_not_97 = ~ signal_lt_123;
    assign signal_eq_93 = state == signal_const_64;
    assign signal_and_183 = collect & signal_eq_93;
    assign signal_and_184 = signal_and_183 & signal_not_97;
    assign signal_and_185 = signal_and_184 & signal_lt_122;
    assign signal_mux_282 = signal_and_185 ? signal_mux_281 : signal_reg_31;
    assign signal_select_582 = signal_select_657[127:120];
    assign signal_select_583 = signal_select_657[119:112];
    assign signal_select_584 = signal_select_657[111:104];
    assign signal_select_585 = signal_select_657[103:96];
    assign signal_select_586 = signal_select_657[95:88];
    assign signal_select_587 = signal_select_657[87:80];
    assign signal_select_588 = signal_select_657[79:72];
    assign signal_select_589 = signal_select_657[71:64];
    assign signal_select_590 = signal_select_657[63:56];
    assign signal_select_591 = signal_select_657[55:48];
    assign signal_select_592 = signal_select_657[47:40];
    assign signal_select_593 = signal_select_657[39:32];
    assign signal_select_594 = signal_select_657[31:24];
    assign signal_select_595 = signal_select_657[23:16];
    assign signal_select_596 = signal_select_657[15:8];
    assign signal_select_597 = signal_select_657[7:0];
    assign signal_const_468 = 16'b0000000000011110;
    assign signal_sub_41 = signal_const_468 - collected;
    assign signal_select_598 = signal_sub_41[3:0];
    always @* begin
        case (signal_select_598)
        0:
            signal_mux_283 <= signal_select_597;
        1:
            signal_mux_283 <= signal_select_596;
        2:
            signal_mux_283 <= signal_select_595;
        3:
            signal_mux_283 <= signal_select_594;
        4:
            signal_mux_283 <= signal_select_593;
        5:
            signal_mux_283 <= signal_select_592;
        6:
            signal_mux_283 <= signal_select_591;
        7:
            signal_mux_283 <= signal_select_590;
        8:
            signal_mux_283 <= signal_select_589;
        9:
            signal_mux_283 <= signal_select_588;
        10:
            signal_mux_283 <= signal_select_587;
        11:
            signal_mux_283 <= signal_select_586;
        12:
            signal_mux_283 <= signal_select_585;
        13:
            signal_mux_283 <= signal_select_584;
        14:
            signal_mux_283 <= signal_select_583;
        default:
            signal_mux_283 <= signal_select_582;
        endcase
    end
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_32 <= signal_const_84;
        else
            if (signal_and_188)
                signal_reg_32 <= signal_mux_283;
    end
    assign signal_cat_74 = { signal_const_63,
                             count };
    assign signal_add_65 = collected + signal_cat_74;
    assign signal_lt_124 = signal_const_468 < signal_add_65;
    assign signal_lt_125 = signal_const_468 < collected;
    assign signal_not_98 = ~ signal_lt_125;
    assign signal_eq_94 = state == signal_const_64;
    assign signal_and_186 = collect & signal_eq_94;
    assign signal_and_187 = signal_and_186 & signal_not_98;
    assign signal_and_188 = signal_and_187 & signal_lt_124;
    assign signal_mux_284 = signal_and_188 ? signal_mux_283 : signal_reg_32;
    assign signal_select_599 = signal_select_657[127:120];
    assign signal_select_600 = signal_select_657[119:112];
    assign signal_select_601 = signal_select_657[111:104];
    assign signal_select_602 = signal_select_657[103:96];
    assign signal_select_603 = signal_select_657[95:88];
    assign signal_select_604 = signal_select_657[87:80];
    assign signal_select_605 = signal_select_657[79:72];
    assign signal_select_606 = signal_select_657[71:64];
    assign signal_select_607 = signal_select_657[63:56];
    assign signal_select_608 = signal_select_657[55:48];
    assign signal_select_609 = signal_select_657[47:40];
    assign signal_select_610 = signal_select_657[39:32];
    assign signal_select_611 = signal_select_657[31:24];
    assign signal_select_612 = signal_select_657[23:16];
    assign signal_select_613 = signal_select_657[15:8];
    assign signal_select_614 = signal_select_657[7:0];
    assign signal_const_474 = 16'b0000000000011111;
    assign signal_sub_42 = signal_const_474 - collected;
    assign signal_select_615 = signal_sub_42[3:0];
    always @* begin
        case (signal_select_615)
        0:
            signal_mux_285 <= signal_select_614;
        1:
            signal_mux_285 <= signal_select_613;
        2:
            signal_mux_285 <= signal_select_612;
        3:
            signal_mux_285 <= signal_select_611;
        4:
            signal_mux_285 <= signal_select_610;
        5:
            signal_mux_285 <= signal_select_609;
        6:
            signal_mux_285 <= signal_select_608;
        7:
            signal_mux_285 <= signal_select_607;
        8:
            signal_mux_285 <= signal_select_606;
        9:
            signal_mux_285 <= signal_select_605;
        10:
            signal_mux_285 <= signal_select_604;
        11:
            signal_mux_285 <= signal_select_603;
        12:
            signal_mux_285 <= signal_select_602;
        13:
            signal_mux_285 <= signal_select_601;
        14:
            signal_mux_285 <= signal_select_600;
        default:
            signal_mux_285 <= signal_select_599;
        endcase
    end
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            signal_reg_33 <= signal_const_84;
        else
            if (signal_and_191)
                signal_reg_33 <= signal_mux_285;
    end
    assign signal_cat_75 = { signal_const_63,
                             count };
    assign signal_add_66 = collected + signal_cat_75;
    assign signal_lt_126 = signal_const_474 < signal_add_66;
    assign signal_lt_127 = signal_const_474 < collected;
    assign signal_not_99 = ~ signal_lt_127;
    assign signal_eq_95 = state == signal_const_64;
    assign signal_and_189 = collect & signal_eq_95;
    assign signal_and_190 = signal_and_189 & signal_not_99;
    assign signal_and_191 = signal_and_190 & signal_lt_126;
    assign signal_mux_286 = signal_and_191 ? signal_mux_285 : signal_reg_33;
    assign entry = { signal_mux_286,
                     signal_mux_284,
                     signal_mux_282,
                     signal_mux_280,
                     signal_mux_278,
                     signal_mux_276,
                     signal_mux_274,
                     signal_mux_272,
                     signal_mux_270,
                     signal_mux_268,
                     signal_mux_266,
                     signal_mux_264,
                     signal_mux_262,
                     signal_mux_260,
                     signal_mux_258,
                     signal_mux_256,
                     signal_mux_254,
                     signal_mux_252,
                     signal_mux_249,
                     signal_mux_246,
                     signal_mux_243,
                     signal_mux_240,
                     signal_mux_237,
                     signal_mux_234,
                     signal_mux_231,
                     signal_mux_228,
                     signal_mux_225,
                     signal_mux_222,
                     signal_mux_219,
                     signal_mux_216,
                     signal_mux_213,
                     signal_mux_210 };
    assign signal_select_616 = entry[207:200];
    assign signal_eq_96 = signal_select_616 == signal_const_84;
    assign signal_and_192 = signal_eq_96 & signal_not_52;
    assign signal_or_35 = signal_and_192 | signal_and_65;
    assign signal_or_36 = signal_or_35 | signal_and_64;
    assign signal_or_37 = signal_or_36 | signal_and_63;
    assign signal_or_38 = signal_or_37 | signal_and_62;
    assign signal_or_39 = signal_or_38 | signal_and_61;
    assign signal_not_100 = ~ signal_or_39;
    assign signal_or_40 = signal_not_100 | signal_not_46;
    assign signal_mux_287 = signal_or_40 ? entry_index : signal_mux_207;
    assign signal_cat_76 = { signal_const_63,
                             count };
    assign signal_lt_128 = signal_cat_76 < required;
    assign signal_not_101 = ~ signal_lt_128;
    assign signal_and_193 = collect & signal_not_101;
    assign signal_mux_288 = signal_and_193 ? signal_mux_287 : entry_index;
    assign signal_select_617 = dimensions[23:16];
    assign count_entries = { signal_const_84,
                             signal_select_617 };
    assign signal_mulu = block * count_entries;
    assign entries_bytes = signal_mulu[23:0];
    assign signal_cat_77 = { gnd,
                             entries_bytes };
    assign signal_lt_129 = room < signal_cat_77;
    assign signal_not_102 = ~ signal_lt_129;
    assign signal_select_618 = room[24:24];
    assign signal_not_103 = ~ signal_select_618;
    assign fits_entries = signal_not_103 & signal_not_102;
    assign signal_not_104 = ~ fits_entries;
    assign signal_const_483 = 16'b0000000000100000;
    assign signal_and_194 = collect & combined_root;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            combined_dimensions <= signal_const_177;
        else
            if (signal_and_194)
                combined_dimensions <= combined_dimension_data;
    end
    assign signal_eq_97 = collected == signal_const_22;
    assign signal_eq_98 = state == signal_const_109;
    assign signal_and_195 = collect & signal_eq_98;
    assign signal_and_196 = signal_and_195 & signal_eq_97;
    assign signal_or_41 = signal_and_196 | prefetch_root;
    assign signal_mux_289 = prefetch_root ? prefetched_data : signal_select_657;
    assign signal_select_619 = signal_mux_289[23:0];
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            ordinary_dimensions <= signal_const_177;
        else
            if (signal_or_41)
                ordinary_dimensions <= signal_select_619;
    end
    assign signal_eq_99 = state == signal_const_71;
    assign signal_and_197 = collect & signal_eq_99;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            used_combined_root <= signal_const_60;
        else
            if (signal_and_197)
                used_combined_root <= combined_root;
    end
    assign dimensions = used_combined_root ? combined_dimensions : ordinary_dimensions;
    assign block = dimensions[15:0];
    assign signal_lt_130 = block < signal_const_483;
    assign signal_or_42 = signal_lt_130 | signal_not_104;
    assign signal_mux_290 = signal_or_42 ? entry_index : signal_const_22;
    assign signal_mux_291 = event_space ? signal_mux_290 : entry_index;
    assign signal_cat_78 = { signal_const_83,
                             consume_count };
    assign signal_lt_131 = headroom_prefetch_root < signal_cat_78;
    assign signal_not_105 = ~ signal_lt_131;
    assign signal_select_620 = prefetched_data[23:16];
    assign signal_cat_79 = { signal_const_84,
                             signal_select_620 };
    assign signal_mulu_1 = signal_select_638 * signal_cat_79;
    assign prefetch_root_bytes = signal_mulu_1[23:0];
    assign signal_cat_80 = { gnd,
                             prefetch_root_bytes };
    assign headroom_prefetch_root = room - signal_cat_80;
    assign signal_select_621 = headroom_prefetch_root[24:24];
    assign signal_not_106 = ~ signal_select_621;
    assign fits_after_consume_prefetch_root = signal_not_106 & signal_not_105;
    assign signal_select_622 = signal_select_657[127:120];
    assign signal_const_495 = 120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_cat_81 = { signal_const_495,
                             signal_select_622 };
    assign signal_select_623 = signal_select_657[127:112];
    assign signal_const_496 = 112'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_cat_82 = { signal_const_496,
                             signal_select_623 };
    assign signal_select_624 = signal_select_657[127:104];
    assign signal_const_497 = 104'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_cat_83 = { signal_const_497,
                             signal_select_624 };
    assign signal_select_625 = signal_select_657[127:96];
    assign signal_const_498 = 96'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_cat_84 = { signal_const_498,
                             signal_select_625 };
    assign signal_select_626 = signal_select_657[127:88];
    assign signal_const_499 = 88'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_cat_85 = { signal_const_499,
                             signal_select_626 };
    assign signal_select_627 = signal_select_657[127:80];
    assign signal_const_500 = 80'b00000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_cat_86 = { signal_const_500,
                             signal_select_627 };
    assign signal_select_628 = signal_select_657[127:72];
    assign signal_const_501 = 72'b000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_cat_87 = { signal_const_501,
                             signal_select_628 };
    assign signal_select_629 = signal_select_657[127:64];
    assign signal_cat_88 = { signal_const_26,
                             signal_select_629 };
    assign signal_select_630 = signal_select_657[127:56];
    assign signal_const_503 = 56'b00000000000000000000000000000000000000000000000000000000;
    assign signal_cat_89 = { signal_const_503,
                             signal_select_630 };
    assign signal_select_631 = signal_select_657[127:48];
    assign signal_const_504 = 48'b000000000000000000000000000000000000000000000000;
    assign signal_cat_90 = { signal_const_504,
                             signal_select_631 };
    assign signal_select_632 = signal_select_657[127:40];
    assign signal_const_505 = 40'b0000000000000000000000000000000000000000;
    assign signal_cat_91 = { signal_const_505,
                             signal_select_632 };
    assign signal_select_633 = signal_select_657[127:32];
    assign signal_cat_92 = { signal_const_29,
                             signal_select_633 };
    assign signal_select_634 = signal_select_657[127:24];
    assign signal_cat_93 = { signal_const_177,
                             signal_select_634 };
    assign signal_select_635 = signal_select_657[127:16];
    assign signal_cat_94 = { signal_const_22,
                             signal_select_635 };
    assign signal_select_636 = signal_select_657[127:8];
    assign signal_cat_95 = { signal_const_84,
                             signal_select_636 };
    assign signal_select_637 = skip_left[3:0];
    always @* begin
        case (signal_select_637)
        0:
            prefetched_data <= signal_select_657;
        1:
            prefetched_data <= signal_cat_95;
        2:
            prefetched_data <= signal_cat_94;
        3:
            prefetched_data <= signal_cat_93;
        4:
            prefetched_data <= signal_cat_92;
        5:
            prefetched_data <= signal_cat_91;
        6:
            prefetched_data <= signal_cat_90;
        7:
            prefetched_data <= signal_cat_89;
        8:
            prefetched_data <= signal_cat_88;
        9:
            prefetched_data <= signal_cat_87;
        10:
            prefetched_data <= signal_cat_86;
        11:
            prefetched_data <= signal_cat_85;
        12:
            prefetched_data <= signal_cat_84;
        13:
            prefetched_data <= signal_cat_83;
        14:
            prefetched_data <= signal_cat_82;
        default:
            prefetched_data <= signal_cat_81;
        endcase
    end
    assign signal_select_638 = prefetched_data[15:0];
    assign signal_lt_132 = signal_select_638 < signal_const_483;
    assign signal_not_107 = ~ signal_lt_132;
    assign signal_and_198 = signal_not_107 & fits_after_consume_prefetch_root;
    assign signal_mux_292 = signal_and_198 ? signal_const_22 : entry_index;
    assign signal_mux_293 = prefetch_root ? signal_mux_292 : entry_index;
    assign signal_cat_96 = { signal_const_83,
                             consume_count };
    assign signal_lt_133 = headroom_combined < signal_cat_96;
    assign signal_not_108 = ~ signal_lt_133;
    assign signal_select_639 = combined_dimension_data[23:16];
    assign combined_count = { signal_const_84,
                              signal_select_639 };
    assign signal_mulu_2 = combined_block * combined_count;
    assign combined_entries_bytes = signal_mulu_2[23:0];
    assign signal_cat_97 = { gnd,
                             combined_entries_bytes };
    assign signal_lt_134 = available < signal_const_65;
    assign drain_count = signal_lt_134 ? available : signal_const_65;
    assign signal_mux_294 = skipping ? skip_count : drain_count;
    assign signal_mux_295 = collecting ? count : signal_mux_294;
    assign signal_select_640 = signal_mux_295[3:0];
    assign consume_count = signal_select_640;
    assign signal_cat_98 = { signal_const_23,
                             consume_count };
    assign signal_add_67 = position + signal_cat_98;
    assign signal_eq_100 = state == signal_const_69;
    assign signal_eq_101 = state == signal_const_79;
    assign draining = signal_eq_101 | signal_eq_100;
    assign signal_and_199 = signal_and_231 & draining;
    assign drain = signal_and_199 & signal_select_671;
    assign signal_or_43 = collect | skip;
    assign signal_or_44 = signal_or_43 | drain;
    assign signal_mux_296 = signal_or_44 ? signal_add_67 : position;
    assign signal_mux_297 = start ? signal_const_22 : signal_mux_296;
    assign signal_wire_11 = signal_mux_297;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            position <= signal_const_22;
        else
            if (signal_and_231)
                position <= signal_wire_11;
    end
    assign signal_const_520 = 9'b000000000;
    assign signal_cat_99 = { signal_const_520,
                             position };
    assign signal_and_200 = signal_and_231 & start;
    assign signal_sub_43 = signal_select_661 - signal_const_37;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            hdr_body_size <= signal_const_22;
        else
            if (signal_and_200)
                hdr_body_size <= signal_sub_43;
    end
    assign signal_cat_100 = { signal_const_520,
                              hdr_body_size };
    assign room = signal_cat_100 - signal_cat_99;
    assign headroom_combined = room - signal_cat_97;
    assign signal_select_641 = headroom_combined[24:24];
    assign signal_not_109 = ~ signal_select_641;
    assign combined_fits = signal_not_109 & signal_not_108;
    assign signal_select_642 = signal_select_657[127:120];
    assign signal_cat_101 = { signal_const_495,
                              signal_select_642 };
    assign signal_select_643 = signal_select_657[127:112];
    assign signal_cat_102 = { signal_const_496,
                              signal_select_643 };
    assign signal_select_644 = signal_select_657[127:104];
    assign signal_cat_103 = { signal_const_497,
                              signal_select_644 };
    assign signal_select_645 = signal_select_657[127:96];
    assign signal_cat_104 = { signal_const_498,
                              signal_select_645 };
    assign signal_select_646 = signal_select_657[127:88];
    assign signal_cat_105 = { signal_const_499,
                              signal_select_646 };
    assign signal_select_647 = signal_select_657[127:80];
    assign signal_cat_106 = { signal_const_500,
                              signal_select_647 };
    assign signal_select_648 = signal_select_657[127:72];
    assign signal_cat_107 = { signal_const_501,
                              signal_select_648 };
    assign signal_select_649 = signal_select_657[127:64];
    assign signal_cat_108 = { signal_const_26,
                              signal_select_649 };
    assign signal_select_650 = signal_select_657[127:56];
    assign signal_cat_109 = { signal_const_503,
                              signal_select_650 };
    assign signal_select_651 = signal_select_657[127:48];
    assign signal_cat_110 = { signal_const_504,
                              signal_select_651 };
    assign signal_select_652 = signal_select_657[127:40];
    assign signal_cat_111 = { signal_const_505,
                              signal_select_652 };
    assign signal_select_653 = signal_select_657[127:32];
    assign signal_cat_112 = { signal_const_29,
                              signal_select_653 };
    assign signal_select_654 = signal_select_657[127:24];
    assign signal_cat_113 = { signal_const_177,
                              signal_select_654 };
    assign signal_select_655 = signal_select_657[127:16];
    assign signal_cat_114 = { signal_const_22,
                              signal_select_655 };
    assign signal_select_656 = signal_select_657[127:8];
    assign signal_cat_115 = { signal_const_84,
                              signal_select_656 };
    assign signal_select_657 = signal_inst[129:2];
    assign signal_sub_44 = signal_select_659 - collected;
    assign signal_select_658 = signal_sub_44[3:0];
    always @* begin
        case (signal_select_658)
        0:
            signal_mux_298 <= signal_select_657;
        1:
            signal_mux_298 <= signal_cat_115;
        2:
            signal_mux_298 <= signal_cat_114;
        3:
            signal_mux_298 <= signal_cat_113;
        4:
            signal_mux_298 <= signal_cat_112;
        5:
            signal_mux_298 <= signal_cat_111;
        6:
            signal_mux_298 <= signal_cat_110;
        7:
            signal_mux_298 <= signal_cat_109;
        8:
            signal_mux_298 <= signal_cat_108;
        9:
            signal_mux_298 <= signal_cat_107;
        10:
            signal_mux_298 <= signal_cat_106;
        11:
            signal_mux_298 <= signal_cat_105;
        12:
            signal_mux_298 <= signal_cat_104;
        13:
            signal_mux_298 <= signal_cat_103;
        14:
            signal_mux_298 <= signal_cat_102;
        default:
            signal_mux_298 <= signal_cat_101;
        endcase
    end
    assign combined_dimension_data = signal_mux_298[23:0];
    assign combined_block = combined_dimension_data[15:0];
    assign signal_lt_135 = combined_block < signal_const_483;
    assign signal_not_110 = ~ signal_lt_135;
    assign signal_and_201 = signal_not_110 & combined_fits;
    assign signal_mux_299 = signal_and_201 ? signal_const_22 : entry_index;
    assign signal_and_202 = collect & combined_root;
    assign signal_mux_300 = signal_and_202 ? signal_mux_299 : entry_index;
    always @* begin
        case (state)
        5'b00010:
            signal_cases_9 <= signal_mux_300;
        5'b00100:
            signal_cases_9 <= signal_mux_293;
        5'b00110:
            signal_cases_9 <= signal_mux_291;
        5'b00111:
            signal_cases_9 <= signal_mux_288;
        5'b01000:
            signal_cases_9 <= signal_mux_200;
        5'b01001:
            signal_cases_9 <= signal_mux_197;
        default:
            signal_cases_9 <= entry_index;
        endcase
    end
    assign signal_wire_12 = signal_cases_9;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            entry_index <= signal_const_22;
        else
            if (signal_and_231)
                entry_index <= signal_wire_12;
    end
    assign signal_add_68 = entry_index + signal_const_38;
    assign next_is_order = signal_add_68 == entry_count;
    assign signal_mux_301 = next_is_order ? signal_and_51 : signal_and_52;
    assign signal_lt_136 = signal_const_177 < skip_left;
    assign signal_eq_102 = state == signal_const_98;
    assign signal_and_203 = signal_and_231 & signal_eq_102;
    assign signal_and_204 = signal_and_203 & signal_lt_136;
    assign signal_and_205 = signal_and_204 & signal_select_671;
    assign prefetch_next = signal_and_205 & signal_mux_301;
    assign signal_mux_302 = prefetch_next ? signal_mux_188 : signal_mux_189;
    assign skip_count = prefetch_root ? signal_select_53 : signal_mux_302;
    assign signal_lt_137 = available < skip_count;
    assign signal_not_111 = ~ signal_lt_137;
    assign signal_eq_103 = skip_left == signal_const_177;
    assign signal_not_112 = ~ signal_eq_103;
    assign signal_or_45 = signal_not_112 | prefetch_root;
    assign signal_eq_104 = state == signal_const_81;
    assign signal_eq_105 = state == signal_const_98;
    assign signal_eq_106 = state == signal_const_111;
    assign signal_or_46 = signal_eq_106 | signal_eq_105;
    assign skipping = signal_or_46 | signal_eq_104;
    assign signal_and_206 = signal_and_231 & skipping;
    assign signal_and_207 = signal_and_206 & signal_or_45;
    assign signal_and_208 = signal_and_207 & signal_select_671;
    assign skip = signal_and_208 & signal_not_111;
    assign signal_mux_303 = skip ? signal_mux_187 : skip_left;
    assign signal_and_209 = signal_and_231 & start;
    assign signal_add_69 = signal_select_662 + signal_const_293;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            hdr_root_plus_dimensions <= signal_const_22;
        else
            if (signal_and_209)
                hdr_root_plus_dimensions <= signal_add_69;
    end
    assign signal_mux_304 = combined_root ? hdr_root_plus_dimensions : signal_const_145;
    assign signal_lt_138 = signal_select_660 < signal_const_37;
    assign signal_mux_305 = signal_lt_138 ? signal_const_450 : signal_const_483;
    assign signal_eq_107 = state == signal_const_64;
    assign signal_mux_306 = signal_eq_107 ? signal_mux_305 : signal_const_9;
    assign signal_eq_108 = state == signal_const_109;
    assign signal_mux_307 = signal_eq_108 ? signal_const_293 : signal_mux_306;
    assign signal_eq_109 = state == signal_const_71;
    assign target = signal_eq_109 ? signal_mux_304 : signal_mux_307;
    assign required = target - collected;
    assign signal_lt_139 = signal_const_9 < required;
    assign signal_not_113 = ~ signal_lt_139;
    assign signal_not_114 = ~ combined_root;
    assign signal_and_210 = collect & signal_not_114;
    assign signal_and_211 = signal_and_210 & signal_not_113;
    assign signal_mux_308 = signal_and_211 ? signal_cat_35 : signal_mux_303;
    always @* begin
        case (state)
        5'b00010:
            signal_cases_10 <= signal_mux_308;
        5'b00011:
            signal_cases_10 <= signal_cat_34;
        5'b00111:
            signal_cases_10 <= signal_mux_186;
        5'b01000:
            signal_cases_10 <= signal_mux_183;
        5'b01001:
            signal_cases_10 <= signal_mux_180;
        5'b01010:
            signal_cases_10 <= signal_mux_177;
        5'b01011:
            signal_cases_10 <= signal_mux_176;
        default:
            signal_cases_10 <= signal_mux_303;
        endcase
    end
    assign signal_wire_13 = signal_cases_10;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            skip_left <= signal_const_177;
        else
            if (signal_and_231)
                skip_left <= signal_wire_13;
    end
    assign signal_lt_140 = signal_const_357 < skip_left;
    assign signal_not_115 = ~ signal_lt_140;
    assign signal_eq_110 = state == signal_const_111;
    assign signal_and_212 = signal_and_231 & signal_eq_110;
    assign signal_and_213 = signal_and_212 & signal_not_115;
    assign signal_and_214 = signal_and_213 & signal_select_671;
    assign signal_and_215 = signal_and_214 & signal_not_30;
    assign prefetch_root = signal_and_215 & signal_not_29;
    assign signal_mux_309 = prefetch_root ? signal_mux_315 : signal_mux_172;
    assign signal_lt_141 = signal_const_134 < signal_select_660;
    assign signal_mux_310 = signal_lt_141 ? vdd : signal_mux_315;
    assign signal_and_216 = signal_and_231 & start;
    assign signal_sub_45 = signal_select_661 - signal_const_37;
    assign signal_lt_142 = signal_sub_45 < signal_select_662;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            hdr_root_over_body <= signal_const_60;
        else
            if (signal_and_216)
                hdr_root_over_body <= signal_lt_142;
    end
    assign signal_select_659 = message_bits[31:16];
    assign signal_lt_143 = signal_select_659 < signal_const_145;
    assign signal_or_47 = signal_lt_143 | hdr_root_over_body;
    assign signal_mux_311 = signal_or_47 ? vdd : signal_mux_310;
    assign signal_select_660 = message_bits[79:64];
    assign signal_lt_144 = signal_select_660 < signal_const_28;
    assign signal_mux_312 = signal_lt_144 ? vdd : signal_mux_311;
    assign signal_const_568 = 162'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign signal_select_661 = signal_wire_21[180:165];
    assign signal_select_662 = signal_wire_21[196:181];
    assign signal_select_663 = signal_wire_21[212:197];
    assign signal_select_664 = signal_wire_21[228:213];
    assign signal_select_665 = signal_wire_21[244:229];
    assign signal_select_666 = signal_wire_21[245:245];
    assign signal_select_667 = signal_wire_21[309:246];
    assign signal_select_668 = signal_wire_21[310:310];
    assign signal_select_669 = signal_wire_21[326:311];
    assign signal_cat_116 = { signal_select_669,
                              signal_select_668,
                              signal_select_667,
                              signal_select_666,
                              signal_select_665,
                              signal_select_664,
                              signal_select_663,
                              signal_select_662,
                              signal_select_661 };
    assign signal_mux_313 = start ? signal_cat_116 : message_bits;
    assign signal_wire_14 = signal_mux_313;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            message_bits <= signal_const_568;
        else
            if (signal_and_231)
                message_bits <= signal_wire_14;
    end
    assign signal_select_670 = message_bits[63:48];
    assign signal_eq_111 = signal_select_670 == signal_const_38;
    assign signal_not_116 = ~ signal_eq_111;
    assign signal_mux_314 = signal_not_116 ? vdd : signal_mux_312;
    assign signal_wire_15 = event_ready_i;
    assign signal_and_217 = event_pending & signal_wire_15;
    assign signal_mux_315 = signal_and_217 ? gnd : event_pending;
    assign signal_mux_316 = event_space ? signal_mux_314 : signal_mux_315;
    always @* begin
        case (state)
        5'b00001:
            signal_cases_11 <= signal_mux_316;
        5'b00100:
            signal_cases_11 <= signal_mux_309;
        5'b00110:
            signal_cases_11 <= signal_mux_170;
        5'b00111:
            signal_cases_11 <= signal_mux_168;
        5'b01000:
            signal_cases_11 <= signal_mux_166;
        5'b01001:
            signal_cases_11 <= signal_mux_164;
        5'b01010:
            signal_cases_11 <= signal_mux_154;
        5'b01011:
            signal_cases_11 <= signal_mux_152;
        5'b01100:
            signal_cases_11 <= signal_mux_148;
        5'b01101:
            signal_cases_11 <= signal_mux_144;
        5'b01110:
            signal_cases_11 <= signal_mux_142;
        default:
            signal_cases_11 <= signal_mux_315;
        endcase
    end
    assign signal_mux_317 = signal_and_230 ? vdd : signal_cases_11;
    assign signal_wire_16 = signal_mux_317;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            event_pending <= signal_const_60;
        else
            if (signal_and_231)
                event_pending <= signal_wire_16;
    end
    assign signal_not_117 = ~ event_pending;
    assign event_space = signal_not_117 | signal_wire_15;
    assign signal_mux_318 = event_space ? signal_mux_139 : signal_mux_140;
    always @* begin
        case (state)
        5'b00001:
            signal_cases_12 <= signal_mux_318;
        5'b00010:
            signal_cases_12 <= signal_mux_136;
        5'b00100:
            signal_cases_12 <= signal_mux_133;
        5'b00110:
            signal_cases_12 <= signal_mux_128;
        5'b00111:
            signal_cases_12 <= signal_mux_125;
        5'b01000:
            signal_cases_12 <= signal_mux_121;
        5'b01001:
            signal_cases_12 <= signal_mux_117;
        default:
            signal_cases_12 <= signal_mux_140;
        endcase
    end
    assign signal_mux_319 = start ? signal_mux_113 : signal_cases_12;
    assign signal_wire_17 = signal_mux_319;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            collected <= signal_const_22;
        else
            if (signal_and_231)
                collected <= signal_wire_17;
    end
    assign signal_eq_112 = collected == signal_const_22;
    assign signal_and_218 = signal_eq_112 & hdr_root_within_head;
    assign signal_or_48 = signal_and_218 | signal_and_18;
    assign signal_eq_113 = state == signal_const_71;
    assign signal_and_219 = signal_eq_113 & signal_or_48;
    assign combined_root = signal_and_219 & hdr_dimensions_fit;
    assign signal_or_49 = combined_root | signal_lt_14;
    assign signal_mux_320 = signal_or_49 ? signal_select_32 : signal_const_65;
    assign signal_eq_114 = state == signal_const_64;
    assign count = signal_eq_114 ? tail_count : signal_mux_320;
    assign signal_lt_145 = available < count;
    assign signal_not_118 = ~ signal_lt_145;
    assign signal_select_671 = signal_inst[1:1];
    assign signal_and_220 = signal_and_231 & collecting;
    assign signal_and_221 = signal_and_220 & signal_select_671;
    assign signal_and_222 = signal_and_221 & signal_not_118;
    assign signal_and_223 = signal_and_222 & signal_not_16;
    assign collect = signal_and_223 & signal_or_7;
    assign signal_or_50 = collect | skip;
    assign signal_or_51 = signal_or_50 | drain;
    assign consume_valid = signal_or_51;
    assign signal_not_119 = ~ signal_select_676;
    assign signal_not_120 = ~ signal_eq_119;
    assign signal_and_224 = signal_wire_22 & signal_or_58;
    assign signal_and_225 = signal_and_224 & signal_not_120;
    assign signal_and_226 = signal_and_225 & signal_not_119;
    assign signal_select_672 = signal_wire_21[400:400];
    assign signal_select_673 = signal_wire_21[399:392];
    assign signal_select_674 = signal_wire_21[391:328];
    cme_byte_aligner
        cme_byte_aligner
        ( .clock_i(signal_wire_19),
          .reset_i(signal_wire_24),
          .en_i(signal_wire_25),
          .data_i(signal_select_674),
          .keep_i(signal_select_673),
          .first_i(signal_select_672),
          .last_i(signal_select_675),
          .ingress_timestamp_i(signal_const_26),
          .valid_i(signal_and_226),
          .consume_valid_i(consume_valid),
          .consume_count_i(consume_count),
          .ready_o(signal_inst[0:0]),
          .valid_o(signal_inst[1:1]),
          .data_o(signal_inst[129:2]),
          .available_o(signal_inst[134:130]),
          .boundary_o(signal_inst[135:135]),
          .first_o(signal_inst[136:136]),
          .ingress_timestamp_o(signal_inst[200:137]),
          .packet_byte_offset_o(signal_inst[216:201]),
          .consume_ready_o(signal_inst[217:217]) );
    assign available = signal_inst[134:130];
    assign signal_lt_146 = available < count;
    assign signal_or_52 = signal_lt_146 | signal_and_15;
    assign vdd = 1'b1;
    assign gnd = 1'b0;
    assign start = transfer & signal_or_57;
    assign signal_mux_321 = start ? gnd : aborted;
    assign signal_mux_322 = abort ? vdd : signal_mux_321;
    assign signal_wire_18 = signal_mux_322;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            aborted <= signal_const_60;
        else
            if (signal_and_231)
                aborted <= signal_wire_18;
    end
    assign signal_not_121 = ~ aborted;
    assign signal_wire_19 = clock_i;
    assign signal_select_675 = signal_wire_21[401:401];
    assign signal_select_676 = signal_wire_21[327:327];
    assign signal_or_53 = signal_eq_119 | signal_select_676;
    assign signal_or_54 = signal_or_53 | signal_select_675;
    assign signal_mux_323 = transfer ? signal_or_54 : input_done;
    assign signal_wire_20 = signal_mux_323;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            input_done <= signal_const_60;
        else
            if (signal_and_231)
                input_done <= signal_wire_20;
    end
    assign signal_eq_115 = state == signal_const_6;
    assign signal_eq_116 = state == signal_const_64;
    assign signal_eq_117 = state == signal_const_109;
    assign signal_eq_118 = state == signal_const_71;
    assign signal_or_55 = signal_eq_118 | signal_eq_117;
    assign signal_or_56 = signal_or_55 | signal_eq_116;
    assign collecting = signal_or_56 | signal_eq_115;
    assign signal_and_227 = collecting & input_done;
    assign signal_and_228 = signal_and_227 & signal_not_121;
    assign signal_and_229 = signal_and_228 & signal_or_52;
    assign signal_and_230 = signal_and_229 & event_space;
    assign signal_mux_324 = signal_and_230 ? signal_const_69 : signal_mux_112;
    assign signal_wire_21 = item_i;
    assign signal_select_677 = signal_wire_21[1:0];
    assign signal_eq_119 = signal_select_677 == signal_const_4;
    assign signal_wire_22 = valid_i;
    assign transfer = ready & signal_wire_22;
    assign abort = transfer & signal_eq_119;
    assign signal_mux_325 = abort ? signal_const_69 : signal_mux_324;
    assign signal_wire_23 = signal_mux_325;
    always @(posedge signal_wire_19) begin
        if (signal_wire_24)
            state <= signal_const;
        else
            if (signal_and_231)
                state <= signal_wire_23;
    end
    assign signal_eq_120 = state == signal_const;
    assign signal_or_57 = signal_eq_120 | retiring;
    assign signal_or_58 = signal_or_57 | signal_and_7;
    assign signal_wire_24 = reset_i;
    assign signal_not_122 = ~ signal_wire_24;
    assign signal_wire_25 = en_i;
    assign signal_and_231 = signal_wire_25 & signal_not_122;
    assign signal_and_232 = signal_and_231 & signal_or_58;
    assign ready = signal_and_232 & signal_mux_66;
    assign room_1 = room;
    assign fits_after_consume_combined = combined_fits;
    assign ready_o = ready;
    assign event_o = event_bits;
    assign event_valid_o = signal_and_4;
    assign done_o = signal_and_3;
    assign idle_o = signal_and_1;

endmodule
module cme_event_fifo (
    clock_i,
    reset_i,
    en_i,
    event_i,
    event_valid_i,
    event_ready_i,
    event_ready_o,
    event_valid_o,
    event_o
);

    input clock_i;
    input reset_i;
    input en_i;
    input [676:0] event_i;
    input event_valid_i;
    input event_ready_i;
    output event_ready_o;
    output event_valid_o;
    output [676:0] event_o;

    wire signal_or;
    wire [676:0] signal_const;
    reg [676:0] data_before_collision;
    wire [676:0] signal_wire;
    (* RAM_STYLE="block" *)
    reg [676:0] signal_multiport_mem[0:14];
    wire [676:0] signal_mem_read_port;
    reg [676:0] ram_rbw_data;
    wire [3:0] signal_const_1;
    wire [3:0] signal_const_3;
    wire [3:0] signal_add;
    wire [3:0] signal_const_4;
    wire signal_eq;
    wire [3:0] READ_ADDRESS_NEXT;
    (* extract_reset="FALSE" *)
    reg [3:0] READ_ADDRESS;
    wire [3:0] signal_wire_1;
    wire signal_and;
    wire [3:0] RA;
    wire [3:0] signal_add_1;
    wire signal_eq_1;
    wire [3:0] WRITE_ADDRESS_NEXT;
    (* extract_reset="FALSE" *)
    reg [3:0] WRITE_ADDRESS;
    wire [3:0] signal_wire_2;
    wire signal_eq_2;
    wire signal_not;
    wire signal_and_1;
    wire signal_xor;
    wire signal_const_9;
    wire [4:0] signal_const_10;
    wire signal_lt;
    reg used_gt_one;
    wire signal_or_1;
    wire signal_and_2;
    wire signal_and_3;
    reg collision;
    wire [676:0] memory;
    wire signal_xor_1;
    wire signal_eq_3;
    reg used_is_one;
    wire signal_and_4;
    wire signal_and_5;
    wire signal_and_6;
    wire bypass_cond;
    wire [676:0] signal_mux;
    reg [676:0] signal_reg;
    wire [676:0] signal_mux_1;
    wire signal_and_7;
    wire signal_not_1;
    wire signal_or_2;
    wire signal_and_8;
    wire [4:0] signal_const_14;
    wire [4:0] signal_const_15;
    wire [4:0] signal_sub;
    reg [4:0] USED_MINUS_1 = 5'b11111;
    wire [4:0] signal_wire_3;
    wire [4:0] signal_add_2;
    reg [4:0] USED_PLUS_1 = 5'b00001;
    wire [4:0] signal_wire_4;
    wire [4:0] signal_mux_2;
    wire [4:0] signal_const_19;
    reg [4:0] USED;
    wire [4:0] signal_wire_5;
    wire signal_and_9;
    wire signal_not_2;
    wire signal_wire_6;
    wire signal_and_10;
    wire signal_and_11;
    wire signal_wire_7;
    wire signal_wire_8;
    wire signal_wire_9;
    wire signal_eq_4;
    wire signal_not_3;
    reg not_empty;
    wire signal_wire_10;
    wire signal_not_4;
    wire signal_not_5;
    wire signal_and_12;
    wire signal_and_13;
    wire signal_wire_11;
    wire signal_xor_2;
    wire [4:0] USED_NEXT;
    wire signal_eq_5;
    reg full;
    wire signal_wire_12;
    wire signal_not_6;
    wire signal_wire_13;
    wire signal_not_7;
    wire signal_wire_14;
    wire signal_and_14;
    wire signal_and_15;
    assign signal_or = bypass_cond | signal_wire_11;
    assign signal_const = 677'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    always @(posedge signal_wire_9) begin
        data_before_collision <= signal_wire;
    end
    assign signal_wire = event_i;
    always @(posedge signal_wire_9) begin
        if (signal_and_2)
            signal_multiport_mem[signal_wire_2] <= signal_wire;
    end
    assign signal_mem_read_port = signal_multiport_mem[RA];
    always @(posedge signal_wire_9) begin
        ram_rbw_data <= signal_mem_read_port;
    end
    assign signal_const_1 = 4'b0000;
    assign signal_const_3 = 4'b0001;
    assign signal_add = signal_wire_1 + signal_const_3;
    assign signal_const_4 = 4'b1110;
    assign signal_eq = signal_wire_1 == signal_const_4;
    assign READ_ADDRESS_NEXT = signal_eq ? signal_const_1 : signal_add;
    always @(posedge signal_wire_9) begin
        if (signal_wire_13)
            READ_ADDRESS <= signal_const_1;
        else
            if (signal_and)
                READ_ADDRESS <= READ_ADDRESS_NEXT;
    end
    assign signal_wire_1 = READ_ADDRESS;
    assign signal_and = signal_wire_11 & used_gt_one;
    assign RA = signal_and ? READ_ADDRESS_NEXT : signal_wire_1;
    assign signal_add_1 = signal_wire_2 + signal_const_3;
    assign signal_eq_1 = signal_wire_2 == signal_const_4;
    assign WRITE_ADDRESS_NEXT = signal_eq_1 ? signal_const_1 : signal_add_1;
    always @(posedge signal_wire_9) begin
        if (signal_wire_13)
            WRITE_ADDRESS <= signal_const_1;
        else
            if (signal_and_2)
                WRITE_ADDRESS <= WRITE_ADDRESS_NEXT;
    end
    assign signal_wire_2 = WRITE_ADDRESS;
    assign signal_eq_2 = signal_wire_2 == RA;
    assign signal_not = ~ signal_wire_11;
    assign signal_and_1 = used_is_one & signal_not;
    assign signal_xor = signal_wire_11 ^ signal_wire_7;
    assign signal_const_9 = 1'b0;
    assign signal_const_10 = 5'b00001;
    assign signal_lt = signal_const_10 < USED_NEXT;
    always @(posedge signal_wire_9) begin
        if (signal_wire_13)
            used_gt_one <= signal_const_9;
        else
            if (signal_xor)
                used_gt_one <= signal_lt;
    end
    assign signal_or_1 = used_gt_one | signal_and_1;
    assign signal_and_2 = signal_wire_7 & signal_or_1;
    assign signal_and_3 = signal_and_2 & signal_eq_2;
    always @(posedge signal_wire_9) begin
        collision <= signal_and_3;
    end
    assign memory = collision ? data_before_collision : ram_rbw_data;
    assign signal_xor_1 = signal_wire_11 ^ signal_wire_7;
    assign signal_eq_3 = USED_NEXT == signal_const_10;
    always @(posedge signal_wire_9) begin
        if (signal_wire_13)
            used_is_one <= signal_const_9;
        else
            if (signal_xor_1)
                used_is_one <= signal_eq_3;
    end
    assign signal_and_4 = used_is_one & signal_wire_7;
    assign signal_and_5 = signal_and_4 & signal_wire_11;
    assign signal_and_6 = signal_not_4 & signal_wire_7;
    assign bypass_cond = signal_and_6 | signal_and_5;
    assign signal_mux = bypass_cond ? signal_wire : memory;
    always @(posedge signal_wire_9) begin
        if (signal_wire_13)
            signal_reg <= signal_const;
        else
            if (signal_or)
                signal_reg <= signal_mux;
    end
    assign signal_mux_1 = signal_not_4 ? signal_wire : signal_reg;
    assign signal_and_7 = signal_not_4 & signal_wire_6;
    assign signal_not_1 = ~ signal_not_4;
    assign signal_or_2 = signal_not_1 | signal_and_7;
    assign signal_and_8 = signal_and_14 & signal_or_2;
    assign signal_const_14 = 5'b10000;
    assign signal_const_15 = 5'b11111;
    assign signal_sub = USED_NEXT - signal_const_10;
    always @(posedge signal_wire_9) begin
        if (signal_wire_13)
            USED_MINUS_1 <= signal_const_15;
        else
            if (signal_xor_2)
                USED_MINUS_1 <= signal_sub;
    end
    assign signal_wire_3 = USED_MINUS_1;
    assign signal_add_2 = USED_NEXT + signal_const_10;
    always @(posedge signal_wire_9) begin
        if (signal_wire_13)
            USED_PLUS_1 <= signal_const_10;
        else
            if (signal_xor_2)
                USED_PLUS_1 <= signal_add_2;
    end
    assign signal_wire_4 = USED_PLUS_1;
    assign signal_mux_2 = signal_wire_11 ? signal_wire_3 : signal_wire_4;
    assign signal_const_19 = 5'b00000;
    always @(posedge signal_wire_9) begin
        if (signal_wire_13)
            USED <= signal_const_19;
        else
            if (signal_xor_2)
                USED <= USED_NEXT;
    end
    assign signal_wire_5 = USED;
    assign signal_and_9 = signal_not_4 & signal_wire_8;
    assign signal_not_2 = ~ signal_and_9;
    assign signal_wire_6 = event_valid_i;
    assign signal_and_10 = signal_wire_6 & signal_and_15;
    assign signal_and_11 = signal_and_10 & signal_not_2;
    assign signal_wire_7 = signal_and_11;
    assign signal_wire_8 = event_ready_i;
    assign signal_wire_9 = clock_i;
    assign signal_eq_4 = USED_NEXT == signal_const_19;
    assign signal_not_3 = ~ signal_eq_4;
    always @(posedge signal_wire_9) begin
        if (signal_wire_13)
            not_empty <= signal_const_9;
        else
            if (signal_xor_2)
                not_empty <= signal_not_3;
    end
    assign signal_wire_10 = not_empty;
    assign signal_not_4 = ~ signal_wire_10;
    assign signal_not_5 = ~ signal_not_4;
    assign signal_and_12 = signal_and_14 & signal_not_5;
    assign signal_and_13 = signal_and_12 & signal_wire_8;
    assign signal_wire_11 = signal_and_13;
    assign signal_xor_2 = signal_wire_11 ^ signal_wire_7;
    assign USED_NEXT = signal_xor_2 ? signal_mux_2 : signal_wire_5;
    assign signal_eq_5 = USED_NEXT == signal_const_14;
    always @(posedge signal_wire_9) begin
        if (signal_wire_13)
            full <= signal_const_9;
        else
            if (signal_xor_2)
                full <= signal_eq_5;
    end
    assign signal_wire_12 = full;
    assign signal_not_6 = ~ signal_wire_12;
    assign signal_wire_13 = reset_i;
    assign signal_not_7 = ~ signal_wire_13;
    assign signal_wire_14 = en_i;
    assign signal_and_14 = signal_wire_14 & signal_not_7;
    assign signal_and_15 = signal_and_14 & signal_not_6;
    assign event_ready_o = signal_and_15;
    assign event_valid_o = signal_and_8;
    assign event_o = signal_mux_1;

endmodule
module cme_feed_parser (
    clock_i,
    reset_i,
    en_i,
    data_i,
    keep_i,
    valid_i,
    first_i,
    last_i,
    ingress_timestamp_i,
    session_reset_i,
    resync_valid_i,
    resync_next_seq_i,
    event_ready_i,
    ready_o,
    control_ready_o,
    event_valid_o,
    event_o
);

    input clock_i;
    input reset_i;
    input en_i;
    input [63:0] data_i;
    input [7:0] keep_i;
    input valid_i;
    input first_i;
    input last_i;
    input [63:0] ingress_timestamp_i;
    input session_reset_i;
    input resync_valid_i;
    input [31:0] resync_next_seq_i;
    input event_ready_i;
    output ready_o;
    output control_ready_o;
    output event_valid_o;
    output [676:0] event_o;

    wire [676:0] signal_select;
    wire signal_select_1;
    wire [31:0] signal_wire;
    wire signal_wire_1;
    wire signal_wire_2;
    wire signal_select_2;
    wire signal_not;
    wire signal_select_3;
    wire signal_select_4;
    wire signal_and;
    wire signal_and_1;
    wire signal_wire_3;
    wire signal_wire_4;
    wire signal_select_5;
    wire [676:0] signal_select_6;
    wire [678:0] signal_inst;
    wire signal_select_7;
    wire signal_wire_5;
    wire signal_select_8;
    wire signal_wire_6;
    wire signal_select_9;
    wire signal_wire_7;
    wire [676:0] signal_select_10;
    wire [676:0] signal_wire_8;
    wire signal_select_11;
    wire signal_select_12;
    wire signal_select_13;
    wire [1078:0] signal_select_14;
    wire [680:0] signal_inst_1;
    wire signal_select_15;
    wire signal_wire_9;
    wire signal_select_16;
    wire [1078:0] signal_select_17;
    wire [1761:0] signal_inst_2;
    wire signal_select_18;
    wire signal_wire_10;
    wire signal_wire_11;
    wire [63:0] signal_wire_12;
    wire signal_wire_13;
    wire signal_wire_14;
    wire [7:0] signal_wire_15;
    wire [63:0] signal_wire_16;
    wire signal_wire_17;
    wire signal_wire_18;
    wire signal_wire_19;
    wire [1081:0] signal_inst_3;
    wire signal_select_19;
    assign signal_select = signal_inst[678:2];
    assign signal_select_1 = signal_inst_3[1081:1081];
    assign signal_wire = resync_next_seq_i;
    assign signal_wire_1 = resync_valid_i;
    assign signal_wire_2 = session_reset_i;
    assign signal_select_2 = signal_inst[1:1];
    assign signal_not = ~ signal_select_2;
    assign signal_select_3 = signal_inst_1[680:680];
    assign signal_select_4 = signal_inst_2[1761:1761];
    assign signal_and = signal_select_4 & signal_select_3;
    assign signal_and_1 = signal_and & signal_not;
    assign signal_wire_3 = signal_and_1;
    assign signal_wire_4 = event_ready_i;
    assign signal_select_5 = signal_inst_2[1760:1760];
    assign signal_select_6 = signal_inst_2[1759:1083];
    cme_event_fifo
        cme_event_fifo
        ( .clock_i(signal_wire_19),
          .reset_i(signal_wire_18),
          .en_i(signal_wire_17),
          .event_i(signal_select_6),
          .event_valid_i(signal_select_5),
          .event_ready_i(signal_wire_4),
          .event_ready_o(signal_inst[0:0]),
          .event_valid_o(signal_inst[1:1]),
          .event_o(signal_inst[678:2]) );
    assign signal_select_7 = signal_inst[0:0];
    assign signal_wire_5 = signal_select_7;
    assign signal_select_8 = signal_inst_1[679:679];
    assign signal_wire_6 = signal_select_8;
    assign signal_select_9 = signal_inst_1[678:678];
    assign signal_wire_7 = signal_select_9;
    assign signal_select_10 = signal_inst_1[677:1];
    assign signal_wire_8 = signal_select_10;
    assign signal_select_11 = signal_inst_2[1082:1082];
    assign signal_select_12 = signal_inst_2[1081:1081];
    assign signal_select_13 = signal_inst_2[1080:1080];
    assign signal_select_14 = signal_inst_2[1079:1];
    cme_mbp_decoder
        cme_mbp_decoder
        ( .clock_i(signal_wire_19),
          .reset_i(signal_wire_18),
          .en_i(signal_wire_17),
          .item_i(signal_select_14),
          .valid_i(signal_select_13),
          .event_ready_i(signal_select_12),
          .done_ready_i(signal_select_11),
          .ready_o(signal_inst_1[0:0]),
          .event_o(signal_inst_1[677:1]),
          .event_valid_o(signal_inst_1[678:678]),
          .done_o(signal_inst_1[679:679]),
          .idle_o(signal_inst_1[680:680]) );
    assign signal_select_15 = signal_inst_1[0:0];
    assign signal_wire_9 = signal_select_15;
    assign signal_select_16 = signal_inst_3[1:1];
    assign signal_select_17 = signal_inst_3[1080:2];
    cme_event_orderer
        cme_event_orderer
        ( .clock_i(signal_wire_19),
          .reset_i(signal_wire_18),
          .en_i(signal_wire_17),
          .item_i(signal_select_17),
          .valid_i(signal_select_16),
          .decoder_ready_i(signal_wire_9),
          .decoder_event_i(signal_wire_8),
          .decoder_event_valid_i(signal_wire_7),
          .decoder_done_i(signal_wire_6),
          .event_ready_i(signal_wire_5),
          .ready_o(signal_inst_2[0:0]),
          .decoder_item_o(signal_inst_2[1079:1]),
          .decoder_valid_o(signal_inst_2[1080:1080]),
          .decoder_event_ready_o(signal_inst_2[1081:1081]),
          .decoder_done_ready_o(signal_inst_2[1082:1082]),
          .event_o(signal_inst_2[1759:1083]),
          .event_valid_o(signal_inst_2[1760:1760]),
          .idle_o(signal_inst_2[1761:1761]) );
    assign signal_select_18 = signal_inst_2[0:0];
    assign signal_wire_10 = signal_select_18;
    assign signal_wire_11 = valid_i;
    assign signal_wire_12 = ingress_timestamp_i;
    assign signal_wire_13 = last_i;
    assign signal_wire_14 = first_i;
    assign signal_wire_15 = keep_i;
    assign signal_wire_16 = data_i;
    assign signal_wire_17 = en_i;
    assign signal_wire_18 = reset_i;
    assign signal_wire_19 = clock_i;
    cme_message_pipeline
        cme_message_pipeline
        ( .clock_i(signal_wire_19),
          .reset_i(signal_wire_18),
          .en_i(signal_wire_17),
          .data_i(signal_wire_16),
          .keep_i(signal_wire_15),
          .first_i(signal_wire_14),
          .last_i(signal_wire_13),
          .ingress_timestamp_i(signal_wire_12),
          .valid_i(signal_wire_11),
          .ready_i(signal_wire_10),
          .downstream_idle_i(signal_wire_3),
          .session_reset_i(signal_wire_2),
          .resync_valid_i(signal_wire_1),
          .resync_next_seq_i(signal_wire),
          .ready_o(signal_inst_3[0:0]),
          .valid_o(signal_inst_3[1:1]),
          .item_o(signal_inst_3[1080:2]),
          .control_ready_o(signal_inst_3[1081:1081]) );
    assign signal_select_19 = signal_inst_3[0:0];
    assign ready_o = signal_select_19;
    assign control_ready_o = signal_select_1;
    assign event_valid_o = signal_select_2;
    assign event_o = signal_select;

endmodule
