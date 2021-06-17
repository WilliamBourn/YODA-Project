`timescale 1ns / 1ps

//Floating Point Addition shell module
//  Perform an addition operation on two double precision floating point numbers
module FP_Adder_Shell(  input clk,              //Clock input
                        input next_available,   //Indicates new data is available at the input 
                        input rqst_pipeline,    //Request from the output for next value
                        input [63:0] a, b,      //Double precision floating point inputs
                        output reg [63:0] out,  //Double precision floating point output
                        output reg rqst_next,   //Indicates the module wants new data from the input
                        output reg ready        //indicates the output data is available for sampling

    );
    
    //Delay register
    reg hold;
    //Valid input register
    reg valid;
    
    //Submodule ready wire
    wire adder_ready;
    //Submodule data output
    wire[63:0] adder_out;
    
    //Submodule
    FP_Adder add (
            .aclk(clk),                         // input wire aclk
            .s_axis_a_tvalid(valid),            // input wire s_axis_a_tvalid
            .s_axis_a_tdata(a),                 // input wire [63 : 0] s_axis_a_tdata
            .s_axis_b_tvalid(valid),            // input wire s_axis_b_tvalid 
            .s_axis_b_tdata(b),                 // input wire [63 : 0] s_axis_b_tdata
            .m_axis_result_tvalid(adder_ready), // output wire m_axis_result_tvalid
            .m_axis_result_tdata(adder_out)     // output wire [63 : 0] m_axis_result_tdata
    );
    
    //Initial register values
    initial begin
        valid = 1'b0;
        hold = 1'b0;
        rqst_next = 1'b1;
    end
    
    //Prepare to set submodule output to shell output when submodule ready goes high
    always@ (posedge adder_ready) begin
        hold = 1'b1;
        valid = 1'b0;
    end
    
    //Clock synchronized
    always@ (posedge clk) begin    
        //Set output of shell to output of submodule and set ready high
        if (hold) begin
            hold = 1'b0;
            ready = 1'b1;
            out = adder_out;
        end
        else begin
            //Reset ready if output is requesting data and request new data from input
            if (ready & rqst_pipeline) begin
                ready = 1'b0;
                rqst_next = 1'b1;
            end
            //Prepare to process next data and stop requesting new data
            if (rqst_next & next_available) begin
                valid = 1'b1;
                rqst_next = 1'b0;
            end
        end
    end 
endmodule

