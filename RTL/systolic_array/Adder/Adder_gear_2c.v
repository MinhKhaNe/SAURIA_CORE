//Return with max number between a and b
`define max(a,b) ((a) > (b) ? (a) : (b))

module Adder_gear_2c #(
    parameter   R = 4,				//Number of shifted bit
    parameter   P = 4,				//Overlap bit
    parameter   WIDTH_A = 16,
    parameter   WIDTH_B = 16
)(
    input   wire    [WIDTH_A-1:0]                   A,
    input   wire    [WIDTH_B-1:0]                   B,
    input   wire                                    Carry, 	//do not use carry

    output  wire    [`max(WIDTH_A, WIDTH_B)-1:0]    OUT		
);
	//Derived Parameters
    parameter           BITS    = `max(WIDTH_A, WIDTH_B);
    parameter           L       = R + P;			//Sub adder length
    parameter   integer k       = (BITS > L) ? (1 + (BITS - L + R - 1) / R) : 1; //number of loops
    parameter           N       = L + (k-1)*R;		//Internal width of sum

	//Internal Signals
    wire    [BITS-1:0]      a, b;
    wire    [L-1:0]         subadd_A [k-1:0]; 
    wire    [L-1:0]         subadd_B [k-1:0]; 
    wire    [L:0]           subadd_sum [k-1:0];
    wire    [k-1:0]         subadd_one;     
    wire    [k-1:0]         carry;
    wire    [N-1:0]         final_sum;
    wire    [L-1:0]         corrected [k-1:0];
    
	//Sign Extend
    assign  a = (WIDTH_A < BITS) ? {{(BITS-WIDTH_A){A[WIDTH_A-1]}}, A} : A;
    assign  b = (WIDTH_B < BITS) ? {{(BITS-WIDTH_B){B[WIDTH_B-1]}}, B} : B;

    genvar i, j;
    generate
        for (i = 0; i < k; i = i + 1) begin

            //Create Sub-Adder by slit inputs
            assign subadd_A[i] = a[i*R +: L];
            assign subadd_B[i] = b[i*R +: L];

            //Sum the sub-adder
            assign subadd_sum[i] = subadd_A[i] + subadd_B[i];

            if (i == 0) begin 
                //First carry is the highest bit of first sub-adder
                assign carry[0] = subadd_sum[0][L];
                //Take the first L bit from the sum of sub-adders A and B
                assign final_sum[L-1:0] = subadd_sum[0][L-1:0];
				//First sub do not need carry
                assign subadd_one[0] = 1'b0; 
            end  
            else begin 
                // Calulate for 1st stage
                assign subadd_one[i] = &subadd_sum[i][L-1:0];
                 //Predict carry from data of previous stage
                assign carry[i] = subadd_sum[i][L] | (carry[i-1] & subadd_one[i]);

                //For loop to write bit to sum 
                for (j = 0; j < R; j = j + 1) begin 
                    assign corrected[i][P+j] =  (subadd_sum[i][P+j] & (!subadd_one[i])) | ((!carry[i-1]) & subadd_one[i]);
                end

                //Discard overlap
                assign corrected[i][P-1:0] = 0;

                //Calculate result
                assign final_sum[P + i*R +: R] = corrected[i][L-1:P];
            end
        end
    endgenerate

    assign OUT = final_sum[BITS-1:0];

endmodule

