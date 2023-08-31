module fft_memory #(parameter BIT_WIDTH = 8, parameter MODE_NUM = 3, parameter FFT_SIZE = 16)
					  (input wire clk,
                       input wire rst,
                       input wire wr_en,
                       input wire bit_rev_en,
                       input wire [2*BIT_WIDTH-1:0] data_in,
                       input wire [$clog2(FFT_SIZE)-1:0] address_in,   
                       input wire [$clog2(MODE_NUM)-1:0] mode,   
                       
                       output wire [2*BIT_WIDTH-1:0] data_out
                      );               

    reg [2*BIT_WIDTH-1:0] mem [FFT_SIZE-1:0];
    wire [$clog2(FFT_SIZE)-1:0] rev_address, norm_rev_address;
    
    assign norm_rev_address = (mode == 0) ? rev_address[$clog2(FFT_SIZE)-1:2] : (mode == 1) ? rev_address[$clog2(FFT_SIZE)-1:1] : (mode == 2) ?  rev_address[$clog2(FFT_SIZE)-1:0] : rev_address;
    
    bit_reverse #(.BIT_WIDTH(4)) bit_rev (.orig(address_in), .rev(rev_address));
    
    
    // WRITE LOGIC
    always @(posedge clk)   
    if (wr_en && bit_rev_en)
        mem[norm_rev_address] <= data_in; 
    else if(wr_en && !bit_rev_en)
        mem[address_in] <= data_in; 
    else
        mem[address_in] <= mem[address_in]; 
        
    // READ LOGIC    
    assign data_out = mem[address_in];
    
endmodule 
