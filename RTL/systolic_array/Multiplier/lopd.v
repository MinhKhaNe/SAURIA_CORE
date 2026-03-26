module lopd #(
    parameter WIDTH_I = 16,
    parameter WIDTH_L = clog2(WIDTH_I)
)(
    input  wire [WIDTH_I-1:0] in,
    output reg  [WIDTH_L-1:0] out
);

    function automatic integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value - 1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

    integer i;

    always @(*) begin
        out = {WIDTH_L{1'b0}};
        for (i = 0; i < WIDTH_I; i = i + 1) begin
            if (in[i])
                out = i;
        end
    end

endmodule
