//////////////////////////////////////////////
//                                          //
//        FSM attribute definitions.        //
//                                          //
//////////////////////////////////////////////

// main_state states
`define S_RST           3'b000
`define S_MODESEL       3'b001
`define S_DATA_IN       3'b010
`define S_COMPUTE       3'b011
`define S_DATA_OUT      3'b100
`define S_FIN           3'b101


// mode_sel_state states
`define SM_STNBY        3'b000
`define SM_M0           3'b001
`define SM_M1           3'b010
`define SM_M2           3'b011
`define SM_FIN          3'b100


// mem_control_state states
`define SML_STNBY       3'b000
`define SML_INPUT       3'b001
`define SML_RD_STNBY    3'b010
`define SML_READ        3'b011
`define SML_DSP_F       3'b100
`define SML_FIN         3'b101


// fft_state states
`define SSH_STNBY       4'b0000
`define SSH_MODE        4'b0001
`define SSH_LD_EVN      4'b0010
`define SSH_LD_ODD      4'b0011
`define SSH_ST_ODD      4'b0100
`define SSH_ST_EVN      4'b0101
`define SSH_FIN         4'b0110





// NOT USED //
//
// useful boolean single-bit definitions
//`define MEM_SIZE_IN_BYTES      (32768)
//`define MEM_32BIT_LINES        (`MEM_SIZE_IN_BYTES/4)
//`define FALSE  	1'h0
//`define TRUE  	1'h1
//