module twiddle_4 #(parameter BIT_WIDTH = 8, parameter FFT_SIZE = 16)(
    input [$clog2(FFT_SIZE)-1:0]    address,
    output [BIT_WIDTH-1:0]          weight_re_out,
    output [BIT_WIDTH-1:0]          weight_im_out
);

    wire [BIT_WIDTH-1:0]  weight_re[15:0];
    wire [BIT_WIDTH-1:0]  weight_im[15:0];

    assign  weight_re_out = weight_re[address];
    assign  weight_im_out = weight_im[address];

    //      wn_re = cos(-2pi*n/4)              wn_im = sin(-2pi*n/4)
    assign weight_re[ 0] = 4'b0111;    assign weight_im[ 0] = 4'b0000;   //  0  1.000 -0.000
    assign weight_re[ 1] = 4'b0000;    assign weight_im[ 1] = 4'b1000;   //  1  0.995 -0.098
    assign weight_re[ 2] = 4'b1000;    assign weight_im[ 2] = 4'b0000;   //  2  0.981 -0.195
    assign weight_re[ 3] = 4'b0000;    assign weight_im[ 3] = 4'b0111;   //  3  0.957 -0.290

    assign weight_re[ 4] = 4'b0000;    assign weight_im[ 4] = 4'b0000;   //  4  0.924 -0.383
    assign weight_re[ 5] = 4'b0000;    assign weight_im[ 5] = 4'b0000;   //  5  0.882 -0.471
    assign weight_re[ 6] = 4'b0000;    assign weight_im[ 6] = 4'b0000;   //  6  0.831 -0.556
    assign weight_re[ 7] = 4'b0000;    assign weight_im[ 7] = 4'b0000;   //  7  0.773 -0.634
    assign weight_re[ 8] = 4'b0000;    assign weight_im[ 8] = 4'b0000;   //  8  0.707 -0.707
    assign weight_re[ 9] = 4'b0000;    assign weight_im[ 9] = 4'b0000;   //  9  0.634 -0.773
    assign weight_re[10] = 4'b0000;    assign weight_im[10] = 4'b0000;   // 10  0.556 -0.831
    assign weight_re[11] = 4'b0000;    assign weight_im[11] = 4'b0000;   // 11  0.471 -0.882
    assign weight_re[12] = 4'b0000;    assign weight_im[12] = 4'b0000;   // 12  0.383 -0.924
    assign weight_re[13] = 4'b0000;    assign weight_im[13] = 4'b0000;   // 13  0.290 -0.957
    assign weight_re[14] = 4'b0000;    assign weight_im[14] = 4'b0000;   // 14  0.195 -0.981
    assign weight_re[15] = 4'b0000;    assign weight_im[15] = 4'b0000;   // 15  0.098 -0.995
endmodule