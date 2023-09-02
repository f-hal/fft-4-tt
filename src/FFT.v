`include "sys_defs.vh"

module shuffler #(parameter BIT_WIDTH = 8, parameter MODE_NUM = 3, parameter FFT_SIZE = 16)
					  (input clk,
                       input rst,
                       input [2*BIT_WIDTH-1:0] data_in,
                       //input logic [BIT_WIDTH-1:0] imag,
                       input [$clog2(MODE_NUM)-1:0] mode,
                       input init,
                       
                       output reg ready,
                       output reg wr_en,
                       output [$clog2(FFT_SIZE)-1:0] address_out, 
                       output wire [2*BIT_WIDTH-1:0] data_out
                       //output logic [BIT_WIDTH-1:0] im
                      );
    
    reg [2*BIT_WIDTH-1:0] even_in, odd_in;
    wire [2*BIT_WIDTH-1:0] even_out, odd_out;
    
    wire [BIT_WIDTH-1:0] twin4_re, twin4_im;
    wire [BIT_WIDTH-1:0] twin8_re, twin8_im;
    wire [BIT_WIDTH-1:0] twin16_re, twin16_im;
    
    wire [BIT_WIDTH-1:0] weight_re, weight_im;
    reg [BIT_WIDTH-1:0] fin_weight_re, fin_weight_im;
    
    reg [$clog2(FFT_SIZE)-1:0] wei_adr;  //, wei_jmp;
    
    assign weight_re = (mode == 0) ? twin4_re : (mode == 1) ? twin8_re : twin16_re;
    assign weight_im = (mode == 0) ? twin4_im : (mode == 1) ? twin8_im : twin16_im;
                                
    reg [$clog2(FFT_SIZE)-1:0] cnt_gen;
    assign address_out = cnt_gen;                        

                     
    butterfly #(.BIT_WIDTH(BIT_WIDTH)) butt(
        .a_plus_re(even_in[2*BIT_WIDTH-1:BIT_WIDTH]),
        .b_plus_re(odd_in[2*BIT_WIDTH-1:BIT_WIDTH]),
        .a_minus_im(even_in[BIT_WIDTH-1:0]),
        .b_minus_im(odd_in[BIT_WIDTH-1:0]),
        .weight_re(fin_weight_re),
        .weight_im(fin_weight_im),
                       
        .out_a_re(even_out[2*BIT_WIDTH-1:BIT_WIDTH]),
        .out_a_im(even_out[BIT_WIDTH-1:0]),
        .out_b_re(odd_out[2*BIT_WIDTH-1:BIT_WIDTH]),
        .out_b_im(odd_out[BIT_WIDTH-1:0]));
                                            
     
    twiddle_4 #(.BIT_WIDTH(BIT_WIDTH), .FFT_SIZE(FFT_SIZE)) twi_4(
        .address(wei_adr),
        .weight_re_out(twin4_re),
        .weight_im_out(twin4_im));
    
    
    twiddle_8 #(.BIT_WIDTH(BIT_WIDTH), .FFT_SIZE(FFT_SIZE)) twi_8(
        .address(wei_adr),
        .weight_re_out(twin8_re),
        .weight_im_out(twin8_im));
         
                      
    twiddle_16 #(.BIT_WIDTH(BIT_WIDTH), .FFT_SIZE(FFT_SIZE)) twi_16(
        .address(wei_adr),
        .weight_re_out(twin16_re),
        .weight_im_out(twin16_im));
                      
                      
    reg [$clog2(FFT_SIZE):0] max_cnt_set, cnt_set;
    reg [$clog2(FFT_SIZE):0] max_cnt_im_jump, im_jump, cnt_im_jump;
    reg [$clog2(FFT_SIZE):0] max_cnt_skip, cnt_skip;    
    
    reg [3:0] fft_state;
    
    assign data_out = (fft_state == `SSH_ST_EVN) ? even_out : odd_out;
    
	always @(posedge clk) begin
		if (rst) begin
            fft_state <= `SSH_STNBY;
			//max_cnt_gen <= 0;
            max_cnt_set <= 0;
            max_cnt_im_jump <= 0;        
            max_cnt_skip <= 0;
            
            ready <= 0;
            cnt_im_jump <= 0;        
            cnt_gen <= 0;        cnt_set <= 0;
            cnt_skip <= 0;       im_jump <= 0;
            wr_en <= 0;          //data_out <= 0;
            fin_weight_re <= 0;  fin_weight_im <= 0;
            odd_in <= 0;         even_in <= 0;
            wei_adr <= 0;        // wei_jmp <= 0;
		end else begin
			case (fft_state) 
				`SSH_STNBY: begin 
                    if (init) fft_state <= `SSH_MODE;
                    cnt_gen <= 0;       
                    cnt_set <= 0;
                    cnt_skip <= 0;   
                    cnt_im_jump <= 0;
                    wei_adr <= 0;
                    ready <= 0;
                end
                `SSH_MODE: begin 

                    im_jump <= 1;
                    //max_cnt_gen <= 4 << mode;
                    max_cnt_im_jump <= 1;
                    max_cnt_set <= 2 << mode;
                    max_cnt_skip <= 2;
                    fft_state <= `SSH_LD_EVN;
                    //wei_jmp <= 2 << mode;
                end
                `SSH_LD_EVN: begin 
                    fft_state <= `SSH_LD_ODD;
                    even_in <= data_in;
                    cnt_gen <= cnt_gen + im_jump;
                    fin_weight_re <= weight_re; 
                    fin_weight_im <= weight_im; 
                    wr_en <= 0;
                end
                `SSH_LD_ODD: begin fft_state <= `SSH_ST_ODD; odd_in <= data_in; wr_en <= 1; end
                `SSH_ST_ODD: begin fft_state <= `SSH_ST_EVN;
                    wr_en <=1; 
                    //data_out <= odd_out;
                    cnt_gen <= cnt_gen - im_jump;
                end
                `SSH_ST_EVN: begin wr_en <=1; 
                    //data_out <= even_out;
                    wr_en <= 0;
                    if (cnt_im_jump == max_cnt_im_jump - 1 && max_cnt_skip == 4 << mode) fft_state <= `SSH_FIN;
                    else fft_state <= `SSH_LD_EVN;
                    if (cnt_im_jump == max_cnt_im_jump - 1) begin 
                        cnt_im_jump <= 0; 
                        cnt_gen <= cnt_skip + max_cnt_skip;
                        cnt_skip <= cnt_skip + max_cnt_skip;
                        cnt_set <= cnt_set + 1;
                        wei_adr <= 0;
                        if (cnt_set == max_cnt_set-1) begin
                            max_cnt_im_jump <= max_cnt_im_jump << 1;
                            max_cnt_skip <= max_cnt_skip << 1;
                            max_cnt_set <= max_cnt_set >> 1;
                            im_jump <= im_jump << 1;
                            cnt_skip <= 0;
                            cnt_set <= 0;
                            cnt_gen <= 0;
                        end
                    end else begin 
                        cnt_gen <= cnt_gen + 1;
                        cnt_im_jump <= cnt_im_jump + 1;
                        wei_adr <= wei_adr + max_cnt_set;
                    end
                end
                `SSH_FIN: begin 
                    wr_en <= 0;
                    ready <= 1;
                end
                default: fft_state <= `SSH_STNBY;  
			endcase
        end
    end
endmodule 
