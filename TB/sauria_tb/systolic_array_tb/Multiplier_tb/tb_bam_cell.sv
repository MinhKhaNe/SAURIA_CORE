module tb_bam_cell;
  
  logic A, B, pre_OUT, Carry, Carry_out, OUT;
  
  Bam_cell dut(
    .A(A),
    .B(B),
    .pre_OUT(pre_OUT),
    .Carry(Carry),
    .Carry_out(Carry_out),
    .OUT(OUT)
  );
  
  initial begin
    $dumpfile("bam_cell.vcd");
  	$dumpvars(0, tb_bam_cell);
    
    for(int i=0; i<2; i++) begin
      for(int j=0; j<2; j++) begin
        for(int k=0; k<2; k++) begin
          for(int l=0; l<2; l++) begin
        	A=i;B=j;Carry=k;pre_OUT=l;
        	#1;
        	$display("A=%b B=%b pre_OUT=%b Carry=%b | AND=%b SUM=%0d | OUT=%b COUT=%b", A, B, pre_OUT, Carry, (A & B), (A & B) + pre_OUT + Carry, OUT, Carry_out);
          end
        end
      end
    end
    
    #1 $finish;
  end
  
endmodule
