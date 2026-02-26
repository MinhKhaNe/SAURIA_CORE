module lopd(
	parameter WIDTH_I = 16,
	parameter WIDTH_L = clog2(WIDTH_I)
)(
	input	wire	[WIDTH_I-1:0]	in,

	output	reg		[WIDTH_L-1:0]	out
);
	integer			i;

	//Log2 function for finding width of input
	function automatic integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value - 1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

	//When bit 1 is detected, stop at that position and print output
	always @(*) begin
		for(i=0; i<WIDTH_I; i=i+1) begin
			if(in[i]) 
				out = i;
		end
	end

endmodule
