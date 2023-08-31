module butterfly #(parameter BIT_WIDTH = 8)
					  (input [BIT_WIDTH-1:0] a_plus_re,
                       input [BIT_WIDTH-1:0] b_plus_re,
                       input [BIT_WIDTH-1:0] a_minus_im,
                       input [BIT_WIDTH-1:0] b_minus_im,
                       input [BIT_WIDTH-1:0] weight_re,
                       input [BIT_WIDTH-1:0] weight_im,
                       
                       output [BIT_WIDTH-1:0] out_a_re,
                       output [BIT_WIDTH-1:0] out_a_im,
                       output [BIT_WIDTH-1:0] out_b_re,
                       output [BIT_WIDTH-1:0] out_b_im
                      );

    wire signed [4*BIT_WIDTH+1:0] weight_mul;
    wire signed [2*BIT_WIDTH:0] weight_mul_re, weight_mul_im;
    

// Function for Q1.(n-1) Multiplications for n-bits
function reg [4*BIT_WIDTH+1:0] cprod (input reg signed [2*BIT_WIDTH-1:0] a_re,
                                     input reg signed [2*BIT_WIDTH-1:0] b_re,
                                     input reg signed [2*BIT_WIDTH-1:0] a_im,
                                     input reg signed [2*BIT_WIDTH-1:0] b_im);
    begin :cprod_block
        reg signed [2*BIT_WIDTH-1:0] mul_re_re, mul_im_im;                   
        reg signed [2*BIT_WIDTH-1:0] mul_re_im, mul_im_re;                                  
        //reg signed [2*BIT_WIDTH-1:0] temp_re_re, temp_im_im;                    
        //reg signed [2*BIT_WIDTH-1:0] temp_re_im, temp_im_re;                                              
        reg signed [2*BIT_WIDTH:0] re, im;
    
        mul_re_re = a_re[2*BIT_WIDTH-2:BIT_WIDTH-1]*b_re[2*BIT_WIDTH-2:BIT_WIDTH-1];
        mul_im_im = a_im[2*BIT_WIDTH-2:BIT_WIDTH-1]*b_im[2*BIT_WIDTH-2:BIT_WIDTH-1];
        mul_re_im = a_re[2*BIT_WIDTH-2:BIT_WIDTH-1]*b_im[2*BIT_WIDTH-2:BIT_WIDTH-1];
        mul_im_re = a_im[2*BIT_WIDTH-2:BIT_WIDTH-1]*b_re[2*BIT_WIDTH-2:BIT_WIDTH-1];
        
        // temp_re_re = mul_re_re >> BIT_WIDTH;
        // temp_im_im = mul_im_im >> BIT_WIDTH;
        // temp_re_im = mul_re_im >> BIT_WIDTH;
        // temp_im_re = mul_im_re >> BIT_WIDTH;
        
        //re =  a_re*b_re - a_im*b_im;
        //im =  a_re*b_im + a_im*b_re;
        re = mul_re_re - mul_im_im;
        im = mul_re_im + mul_im_re;
        cprod = {re, im};
    end
endfunction
    
    wire signed [2*BIT_WIDTH-1:0] aug_evn_re, aug_evn_im;
    wire signed [2*BIT_WIDTH-1:0] aug_odd_re, aug_odd_im;
    wire signed [2*BIT_WIDTH-1:0] aug_wei_re, aug_wei_im;
    
    assign aug_evn_re = {a_plus_re[BIT_WIDTH-1], a_plus_re[BIT_WIDTH-1:0], {BIT_WIDTH-1{1'b0}}};
    assign aug_evn_im = {a_minus_im[BIT_WIDTH-1], a_minus_im[BIT_WIDTH-1:0], {BIT_WIDTH-1{1'b0}}};
    assign aug_odd_re = {b_plus_re[BIT_WIDTH-1], b_plus_re[BIT_WIDTH-1:0], {BIT_WIDTH-1{1'b0}}};
    assign aug_odd_im = {b_minus_im[BIT_WIDTH-1], b_minus_im[BIT_WIDTH-1:0], {BIT_WIDTH-1{1'b0}}};
    assign aug_wei_re = {weight_re[BIT_WIDTH-1], weight_re[BIT_WIDTH-1:0], {BIT_WIDTH-1{1'b0}}};
    assign aug_wei_im = {weight_im[BIT_WIDTH-1], weight_im[BIT_WIDTH-1:0], {BIT_WIDTH-1{1'b0}}};
    
    assign weight_mul = cprod(aug_odd_re, aug_wei_re, aug_odd_im, aug_wei_im);
    assign weight_mul_re = weight_mul[4*BIT_WIDTH+1:2*BIT_WIDTH+1];
    assign weight_mul_im = weight_mul[2*BIT_WIDTH:0];
    
    // Perfoms additions/subtractions
    wire signed [2*BIT_WIDTH:0] tmp_out_a_re;
    wire signed [2*BIT_WIDTH:0] tmp_out_a_im;
    wire signed [2*BIT_WIDTH:0] tmp_out_b_re;
    wire signed [2*BIT_WIDTH:0] tmp_out_b_im;
    
    assign tmp_out_a_re = {a_plus_re[BIT_WIDTH-1], aug_evn_re} + weight_mul_re;
    assign tmp_out_a_im = {a_minus_im[BIT_WIDTH-1], aug_evn_im} + weight_mul_im;
    assign tmp_out_b_re = {a_plus_re[BIT_WIDTH-1], aug_evn_re} - weight_mul_re;
    assign tmp_out_b_im = {a_minus_im[BIT_WIDTH-1], aug_evn_im} - weight_mul_im;
    
    // Fixed-Point version output
    assign out_a_re = tmp_out_a_re[2*BIT_WIDTH-2:BIT_WIDTH-1];
    assign out_a_im = tmp_out_a_im[2*BIT_WIDTH-2:BIT_WIDTH-1];
    assign out_b_re = tmp_out_b_re[2*BIT_WIDTH-2:BIT_WIDTH-1];
    assign out_b_im = tmp_out_b_im[2*BIT_WIDTH-2:BIT_WIDTH-1];
    
endmodule 
