module uart_frame_parser (
    clock,
    reset,
    uart_byte,
    bruh
);

    input clock;
    input reset;
    input [7:0] uart_byte;
    output bruh;

    wire signal_const;
    assign signal_const = 1'b0;
    assign bruh = signal_const;

endmodule
