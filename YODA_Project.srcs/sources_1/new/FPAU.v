`timescale 1ns / 1ps

//Specific Purpose Floating Point Arithmetic Unit Module
/*  This module performs the following operation using a pipeline: It takes the value of n and offsets it by -1,
    it then converts the offset value into a double precision floating point value and multiplies it by d. The
    multiplication is then added to the value of a1 to produce the output. This function is used for determining
    the nth term of an arithmetic series, where a1 is the first term and d is the difference between consecutive
    terms (a1 = (n-1)d). The module has a 4 stage pipeline, where each stage corresponds to one of the steps above.
*/
module SPFPAU(  input clk,              //Clock input
                input rst,              //Reset
                input next_available,   //Indicates new data is available at the input of the pipeline
                input rqst_pipeline,    //Request from the output of the pipeline for next value
                input [63:0] a1, d,     //Double precision floating point inputs
                input [31:0] n,         //Decimal inputs
                output reg [63:0] out,  //Double precision floating point output
                output rqst_next,       //Indicates the pipeline wants new data from the input
                output reg ready        //Indicates the output data is available for sampling
    );
    
    //Input data registers
    reg [63:0] a1_reg, d_reg;
    reg [31:0] n_reg;
    
    //Offset value
    reg [31:0] offset = 32'b1;
    
    //Pipeline data registers
    reg [31:0] s2_data_in;
    reg [63:0] s3_data_in;
    reg [63:0] s4_data_in;
    
    //Pipeline data wires
    wire [31:0] s1_data_out;
    wire [63:0] s2_data_out, s3_data_out;
    wire [63:0] s4_data_out;
    
    //Pipeline control
    wire s1_ready, s2_ready, s3_ready, s4_ready;
    wire s2_rqst, s3_rqst, s4_rqst;
    
    //Stage 1: Offset n by -1
    //Offset module instantiation
    Offset Stage_1( .clk(clk),
                    .next_available(next_available),
                    .rqst_pipeline(s2_rqst),
                    .n(n_reg),
                    .offset(offset),
                    .out(s1_data_out),
                    .rqst_next(rqst_next),
                    .ready(s1_ready)
    );
    
    //Stage 2: Convert offset to double precision float
    //Int To Float Converter module instantiation
    Int_To_FP Stage_2(  .clk(clk),
                        .next_available(s1_ready),
                        .rqst_pipeline(s3_rqst),
                        .decimal_in(s2_data_in),
                        .float_out(s2_data_out),
                        .rqst_next(s2_rqst),
                        .ready(s2_ready)
    );
    
    //Stage 3: Multiply offset by d
    //Floating Point Multiplication module instantiation
    FP_Multiplier_Shell Stage_3(.clk(clk),
                                .next_available(s2_ready),
                                .rqst_pipeline(s4_rqst),
                                .a(d_reg),
                                .b(s3_data_in),
                                .out(s3_data_out),
                                .rqst_next(s3_rqst),
                                .ready(s3_ready)
    );
    
    //Stage 4: Add a1 to multiplication
    
    FP_Adder_Shell Stage_4( .clk(clk),
                            .next_available(s3_ready),
                            .rqst_pipeline(rqst_pipeline),
                            .a(a1_reg),
                            .b(s4_data_in),
                            .out(s4_data_out),
                            .rqst_next(s4_rqst),
                            .ready(s4_ready)
    );
    
    //Sample inputs when reset goes high
    always@ (posedge rst) begin
        a1_reg = a1;
        d_reg = d;
        n_reg = n;
    end
    
    //Clock synchronized
    always@ (posedge clk) begin
        //Sample inputs when next data is available and pipeline is requesting data
        if (next_available & rqst_next) begin
            a1_reg = a1;
            d_reg = d;
            n_reg = n;
        end
        //Reset ready if the pipeline if data is being requested from the pipeline
        if (ready & rqst_pipeline) begin
            ready = 1'b0;
        end
        //Set output of pipeline to output of stage 4 and set ready high if data is being requested from the
        //pipeline and data is available from stage 4
        if (s4_ready & rqst_pipeline) begin
            out = s4_data_out;
            ready = 1'b1;
        end
        
        //Set stage input to previous stage output whenever data is available and requested
        if (s3_ready & s4_rqst) begin
            s4_data_in = s3_data_out;
        end 
        if (s2_ready & s3_rqst) begin
            s3_data_in = s2_data_out;      
        end
        if (s1_ready & s2_rqst) begin
            s2_data_in = s1_data_out;
        end
    end
endmodule
