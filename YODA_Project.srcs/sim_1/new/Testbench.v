`timescale 1ns / 1ps

//Testbench for the Arithmetic Series Generator Modules
module Testbench;
    
    //Define the time period in upper timescale units between clock toggles (i.e. half the clock period)
    parameter clkrate = 0.5; //Frequency of 1 GHz
    
    //System clock
    reg clk;
    
    //Reset tesetbench
    reg rst;
    
    //Indicate start of test
    reg start;
    
    //Input data & address
    reg [63:0] a1_in, d_in;
    reg [31:0] n_in;
    reg [31:0] saddr_in;
    
    //Output data and address
    wire [63:0] out;
    wire [31:0] out_addr;
    
    //Indicate output ready to be sampled
    wire ready;
    
    //Indicate end of module running
    wire done;
    
    //Arithmetic Series Generator module instantiation
    ASG asg(    .clk(clk),
                .a1(a1_in),
                .d(d_in),
                .n(n_in), 
                .saddr(saddr_in),
                .activate(rst),
                .out(out),
                .out_addr(out_addr),
                .ready(ready),
                .done(done)   
    );
    
    //Initial register values
    initial begin
        //Control
        clk = 1'b0;
        rst = 1'b0;
        start = 1'b1;
        
        //Data
        a1_in = 64'h4025000000000000;   // 10.5 double prescision float
        d_in = 64'h4012000000000000;    // 4.5 double prescision float
        n_in = 32'd50;                  // 50 decimal
        
        saddr_in = 32'h40000000;
    end
    
    //Toggle clock
    always #clkrate begin
        clk = ~clk;
        
        //Equivalent to always@ (posedge clk)
        if(clk) begin
            //Trigger starting reset
            if(start) begin
                rst = 1'b1;
                start = 1'b0;
            end
            //Disable reset
            else if(rst) begin
                rst = 1'b0;
            end
        end
    end
endmodule
