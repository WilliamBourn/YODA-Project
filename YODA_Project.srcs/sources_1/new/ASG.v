`timescale 1ns / 1ps

//Arithmetic Series Generator Module
/*  Generate an arithmetic series based on the inputs values a1, d and n and assign the results to a contiguous
    block of memory starting at saddr. The module outputs the data and address simulataneously and the the values
    are ok to sample when ready goes high. When there are no more values left to assign to addresses, done will go
    high when the last output is given and remain high until the module is reset.
*/
module ASG(
    input clk,                  //Clock input
    input [63:0] a1, d,         //Double precision floating point inputs
    input [31:0] n,             //Decimal inputs
    input [31:0] saddr,         //32-bit address input
    input activate,             //Activation control, functions like a reset
    output [63:0] out,          //Double precision floating point output
    output reg [31:0] out_addr, //32-bit address output
    output reg ready,           //Indicates output data and address available for sampling
    output reg done             //Indicates last data and address have been outputted
    );
    
    //Input data registers
    reg [63:0] a1_reg, d_reg;
    reg [31:0] n_reg, saddr_reg;
    
    //Combined input registers
    reg [31:0] n_count;
    
    //Address pipeline registers
    reg [31:0] offset;
    reg [31:0] n_addr [0:3];
    
    wire [31:0] n_offset;
    
    //Controls the module so it doesn't run until activate goes high for the first time
    reg start;
    reg [2:0] pipe_drain;
    
    //Address pipeline control
    reg rqst_addr;
    reg addr_ready;
    reg [2:0] n_addr_cap; //Number of valid addresses in address pipeline
    
    wire offset_ready;
    wire next_addr;
    
    //Data pipeline control
    reg rqst_data;
    
    wire data_ready;
    wire next_data;
    
    //Combined pipeline control
    reg next_available;
    
    //Specific Purpose Floating Point Arithmetic Unit module instantiation
    SPFPAU proc(.clk(clk),
                .rst(activate),
                .next_available(next_available),
                .rqst_pipeline(rqst_data),
                .a1(a1_reg),
                .d(d_reg),
                .n(n_count),
                .out(out),
                .rqst_next(next_data),
                .ready(data_ready)
    );
    
    //Offset module for address pipeline
    //Offset module instantiation
    Offset n_Count_Offset(  .clk(clk),
                            .next_available(next_available),
                            .rqst_pipeline(rqst_addr),
                            .n(n_count),
                            .offset(offset),
                            .out(n_offset),
                            .rqst_next(next_addr),
                            .ready(offset_ready)
    );
    
    //Initial register values
    initial begin
        //Permanent registers
        offset = 1'b1;
        
        //Output registers
        ready = 1'b0;
        done = 1'b0;
        
        //Control registers
        start = 1'b0;
        
        //Pipeline control registers
        next_available = 1'b0;
        
        rqst_data = 1'b1;
        
        rqst_addr = 1'b1;
        addr_ready = 1'b0;
        n_addr_cap = 3'b0;
        pipe_drain = 3'd4;
    end
    
    //Perform reset when activate goes high
    always@ (posedge activate) begin
        //Capture data and address inputs in registers
        a1_reg = a1;
        d_reg = d;
        n_reg = n;
        saddr_reg = saddr;
        
        //Reset adress pipeline capacity
        n_addr_cap = 3'b0;
        
        //Set counter to 1
        n_count = 32'b1;
        
        //Reset control signals
        done = 1'b0;
        start = 1'b1;
        ready = 1'b0;
        next_available = 1'b1;
        pipe_drain = 3'd0;
    end
    
    //Clock synchronized
    always@ (posedge clk) begin
        if(!start & pipe_drain == 0) begin
            done = 1'b1;
        end
        else begin
            //Reset ready after one clock cycle
            if (ready) begin
                ready = 1'b0;
            end
            //Indicate next address is ready to output when pipeline is full and stop requesting a new address
            if (n_addr_cap == 4) begin
                addr_ready = 1'b1;
                rqst_addr = 1'b0;
            end
            //While the address offset has a new value and the address pipeline isn't full, fill up the address pipeline
            if (offset_ready & !addr_ready) begin
                //Shift addresses up by one
                n_addr[1:3] = {{n_addr[0]},{n_addr[1]},{n_addr[2]}};
                //Override first place in buffer
                n_addr[0] = saddr_reg + n_offset*8;
                //Indicate capacity change
                n_addr_cap = n_addr_cap + 1;
            end
            //If both the address and data outputs are ready, indicate the output in ready and remove them from the pipeline
            if (addr_ready & data_ready) begin
                //Raise ready output
                ready = 1'b1;
                //Set address to be not ready, retireve the last item in the buffer
                addr_ready = 1'b0;
                out_addr = n_addr[3];
                //Indicate item has been removed from buffer
                n_addr_cap = n_addr_cap - 1;

                //Request a new address for pipeline
                rqst_addr = 1'b1; 
                if (!start) begin
                    pipe_drain = pipe_drain - 1;
                end
            end 
            //Only run when start is high
            if (start) begin
                //Run while the counter is lower than n
                if (n_count < n_reg) begin
                    //Reset next_available after once clock cycle
                    if (next_available) begin
                        next_available = 1'b0;
                    end
                    //If both the data and address pipeline request a new item, set next_avalable and increment the counter
                    else if (next_addr & next_data) begin
                        next_available = 1'b1;
                        n_count = n_count + 1;
                    end
                end
                //Once the counter has reached the value of n, disable start
                else begin
                    start = 1'b0;
                    pipe_drain = 3'd4;
                    next_available = 1'b1;            
                end
            end
        end  
    end
endmodule
