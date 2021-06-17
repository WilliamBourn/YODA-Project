`timescale 1ns / 1ps

//Integer to Double Precision Floating Point Conversion Module
//  Convert a 32-bit integer input into a 64-bit double precision float 
module Int_To_FP(   input clk,                  //Clock input
                    input next_available,       //Indicates new data is available at the input             
                    input rqst_pipeline,        //Request from the output for next value
                    input [31:0] decimal_in,    //Decimal input
                    output reg [63:0] float_out,//Double precision float output
                    output reg rqst_next,       //Indicates the module wants new data from the input
                    output reg ready            //indicates the output data is available for sampling
    );
    
    //This module uses SystemVerilog conversion features
    
    //Variable declaration
    integer decimal;
    real float;
    
    //Delay register
    reg hold;
    
    //Initial register values
    initial begin
        rqst_next = 1'b1;
        hold = 1'b0;
    end
    
    //Clock synchronized
    always@ (posedge clk) begin
        //Hold for one clock cycle and perform the conversion to floating point before setting ready high
        if (hold) begin
            hold = 1'b0;
            
            //Cast 32-bit int to integer variable
            decimal = decimal_in;
            //Cast integer to real
            float = real'(decimal);
            //Cast real to 64-bit float
            float_out = $realtobits(float);
            ready = 1'b1;
        end
        else begin
            //Reset ready if output is requesting data and request new data from input
            if (ready & rqst_pipeline) begin
                ready = 1'b0;
                rqst_next = 1'b1;
            end
            //Prepare to process next data and stop requesting new data
            else if (rqst_next & next_available) begin
                hold = 1'b1;
                rqst_next = 1'b0;
            end
        end
    end   
endmodule
