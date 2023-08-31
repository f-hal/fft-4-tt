`include "sys_defs.vh"

module tt_um_f_hal_fft (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    localparam FFT_MAX_SIZE = 16;
    localparam MODE_NUM = 3;
    localparam BIT_WIDTH = 4;

    wire reset;
    reg restart;
    assign reset = ~rst_n || ~ena || restart;
    
    assign uio_oe = 8'b0_00000_00;  // DEBUG_UNASSIGNED_ASSIGNED
    
    // Verilog req
    reg [7:0] uio_out_pass, uo_out_pass;
    assign uio_out = 0;
    assign uo_out = uo_out_pass;
    
    reg [2:0] main_state;
    reg [2:0] mode_sel_state;
    reg [2:0] mem_ld_state;
    wire [7:0] fft_uo_out;
    
    wire norm_btn_mode_change, btn_mode_change;
    wire norm_btn_mode_fin, btn_mode_fin;
    
    reg [2*BIT_WIDTH-1:0] usr_data_in;
    wire [2*BIT_WIDTH-1:0] fft_data_in;
    reg cu_wr_en, bit_rev_en; 
    reg fft_init;
    wire fft_wr_en, fft_fin, wr_en;
    
    assign btn_mode_change = uio_in[0];
    assign btn_mode_fin = uio_in[1];
    
    //////////////////////
    //                  //
    //   Control Unit   //
    //   ----------->   //
    //////////////////////
    
	always @(posedge clk) begin
		if (reset) begin
			main_state <= `S_RST;
            fft_init <= 0;
            restart <= 0;
		end else begin
			case (main_state) 
				`S_RST: main_state <= `S_MODESEL;
				`S_MODESEL: begin
					if (mode_sel_state == `SM_FIN)
						    main_state <= `S_DATA_IN;  
				        end
				`S_DATA_IN: if (mem_ld_state == `SML_RD_STNBY) begin
						    main_state <= `S_COMPUTE; 
                            fft_init <= 1;
				        end
				`S_COMPUTE: if (fft_fin) begin
                             main_state <= `S_DATA_OUT;
                             fft_init <= 0;
                         end
				`S_DATA_OUT: begin if (mem_ld_state == `SML_FIN)
				            main_state <= `S_FIN; 
                        end
                `S_FIN: restart <= 1;
                default: main_state <= `S_RST;  
			endcase
        end
    end
    //   <-----------   //      
    //^^^^^^^^^^^^^^^^^^//
        
    reg [$clog2(MODE_NUM)-1:0] mode;
    reg [$clog2(FFT_MAX_SIZE)-1:0] ld_address;
    wire [$clog2(FFT_MAX_SIZE)-1:0] rd_address, fin_address;
    wire [2*BIT_WIDTH-1:0] data_in, data_out;
    
    assign data_in = (main_state == `S_COMPUTE) ? fft_data_in : usr_data_in;
        
        
    shuffler #(.BIT_WIDTH(BIT_WIDTH), .MODE_NUM(MODE_NUM), .FFT_SIZE(FFT_MAX_SIZE)) fft
        (.clk(clk),
         .rst(reset),
         .data_in(data_out),
         
         .mode(mode),
         .init(fft_init),
                       
         .ready(fft_fin),
         .wr_en(fft_wr_en),
         .address_out(rd_address), 
         .data_out(fft_data_in));
                          
    
    edge_detector mode_chg_edg(.clk(clk), .rst(reset), .in(btn_mode_change), .out(norm_btn_mode_change));        
    edge_detector mode_fin_edg(.clk(clk), .rst(reset), .in(btn_mode_fin), .out(norm_btn_mode_fin));        
            
            
	always @(posedge clk)
		if (reset) begin
			mode_sel_state <= `SM_STNBY;
            mode <= 0;
		end else 
			case (mode_sel_state) 
				`SM_STNBY: if (main_state == `S_MODESEL)
						mode_sel_state <= `SM_M0;
				`SM_M0:
					if (norm_btn_mode_fin) begin
						mode_sel_state <= `SM_FIN;
                        mode <= 0;				
					end else if (norm_btn_mode_change)
						mode_sel_state <= `SM_M1;
				`SM_M1: 
					if (norm_btn_mode_fin) begin
						mode_sel_state <= `SM_FIN;	
                        mode <= 1;				    			
					end else if (norm_btn_mode_change)
						mode_sel_state <= `SM_M2;
				`SM_M2:
					if (norm_btn_mode_fin) begin
						mode_sel_state <= `SM_FIN;		
                        mode <= 2;						
					end else if (norm_btn_mode_change)
						mode_sel_state <= `SM_M0;
                `SM_FIN: mode_sel_state <= `SM_FIN;
				default: mode_sel_state <= `SM_STNBY;
			endcase            
            
    // Display mode on 7-segment LCD         
    always @(posedge clk) begin
	    if (reset) begin
	        uo_out_pass <= 0;
	    end else begin
            if(main_state == `S_MODESEL)
    			case (mode_sel_state) 
    				`SM_M0: uo_out_pass <= 8'b00111111;  // Displays number 0 in output screen (no dot)
    				`SM_M1: uo_out_pass <= 8'b00000110;  // Displays number 1 in output screen (no dot)
    				`SM_M2: uo_out_pass <= 8'b01011011;  // Displays number 2 in output screen (no dot)
                    default: uo_out_pass <= 8'b00000000;
    			endcase
            else if (main_state == `S_DATA_IN) begin
                uo_out_pass[6:0] <= 7'b0111000;  // Displays L (flashing dot)
                if (norm_btn_mode_fin)
                    uo_out_pass[7] <= ~uo_out_pass[7];
                else 
                    uo_out_pass[7] <= uo_out_pass[7];
            end
            else if (main_state == `S_COMPUTE)
                uo_out_pass <= 8'b00111001;  // Displays C (no dot)
            else if (main_state == `S_DATA_OUT && mem_ld_state == `SML_DSP_F)
                uo_out_pass <= 8'b01110001;  // Displays F (no dot)
            else if (main_state == `S_DATA_OUT && mem_ld_state == `SML_READ)
                uo_out_pass <= fft_uo_out; 
            else
                uo_out_pass <= 8'b00000000; 
        end
    end

    
    fft_memory #(.BIT_WIDTH(BIT_WIDTH), .MODE_NUM(MODE_NUM), .FFT_SIZE(FFT_MAX_SIZE)) memory_test (
        .clk(clk), .rst(reset),
        .wr_en(wr_en), .bit_rev_en(bit_rev_en),
        .data_in(data_in), .address_in(fin_address),   
        .mode(mode), .data_out(data_out));         


    assign fft_uo_out = data_out;
    assign wr_en = cu_wr_en || fft_wr_en;
    
    // Memory control FSM
    reg [$clog2(FFT_MAX_SIZE):0] mem_ld_max_counter, mem_ld_counter;
    
	always @(posedge clk)
		if (reset) begin
            cu_wr_en <= 0;
            bit_rev_en <= 0;
            usr_data_in <= 0;
            ld_address <= 0;
            
			mem_ld_state <= `SML_STNBY;
            mem_ld_max_counter <= 0;
            mem_ld_counter <= 0;
		end else begin
			case (mem_ld_state) 
				`SML_STNBY: if (main_state == `S_DATA_IN) begin
					mem_ld_state <= `SML_INPUT;
                    mem_ld_counter <= 0;
                    mem_ld_max_counter <= 4 << mode;
                end
                `SML_INPUT: if (mem_ld_counter == mem_ld_max_counter) begin
					mem_ld_state <= `SML_RD_STNBY;
                    bit_rev_en <= 0;
                    cu_wr_en <= 0;
                    mem_ld_counter <= 0;
                end else if (norm_btn_mode_fin) begin
                    mem_ld_counter <= mem_ld_counter+1;
                    bit_rev_en <= 1;
                    cu_wr_en <= 1;
                    ld_address <= mem_ld_counter;
                    usr_data_in <= ui_in;
                end else begin
                    cu_wr_en <= 0;
                end
                `SML_RD_STNBY: if (main_state == `S_DATA_OUT) begin
                    mem_ld_state <= `SML_READ;
                    mem_ld_counter <= 0;
                end
                `SML_READ: if (mem_ld_counter == mem_ld_max_counter) begin
					mem_ld_state <= `SML_DSP_F;
                end else if (norm_btn_mode_fin) begin
                    mem_ld_counter <= mem_ld_counter+1;
                    ld_address <= mem_ld_counter;
                end else
                    ld_address <= mem_ld_counter;
                `SML_DSP_F: if (norm_btn_mode_fin) 
                    mem_ld_state <= `SML_FIN;
                `SML_FIN: mem_ld_state <= `SML_FIN;
				default: mem_ld_state <= `SML_STNBY;
			endcase     
        end    
        
    assign fin_address = (main_state == `S_COMPUTE) ? rd_address : ld_address;    
    
endmodule 
