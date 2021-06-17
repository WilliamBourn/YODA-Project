`timescale 1ns / 1ps

//Offset module
//  Perform a negative offset on an unsigned int value.
module Offset(
        input clk,              //Clock input
        input next_available,   //Indicates new data is available at the input
        input rqst_pipeline,    //Request from the output for next value
        input [31:0] n, offset, //Decimal inputs
        output reg [31:0] out,  //Decimal output
        output reg rqst_next,   //Indicates the module wants new data from the input
        output reg ready        //indicates the output data is available for sampling
    );
    
    //Delay register
    reg hold;
    
    //Initial register values
    initial begin
        rqst_next = 1'b1;
        hold = 1'b0;
    end
    
    //Clock synchronized
    always@ (posedge clk) begin
        //Hold for one clock cycle and set the output and ready
        if (hold) begin
            hold = 1'b0;
            out = n - offset;
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
