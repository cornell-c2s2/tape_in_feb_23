module SPI_minion_components_ShiftReg (
	clk,
	in_,
	load_data,
	load_en,
	out,
	reset,
	shift_en
);
	parameter nbits = 8;
	parameter reset_value = 1'b0;
	input wire clk;
	input wire in_;
	input wire [nbits - 1:0] load_data;
	input wire load_en;
	output reg [nbits - 1:0] out;
	input wire reset;
	input wire shift_en;
	always @(posedge clk)
		if (reset)
			out <= {nbits {reset_value}};
		else if (load_en)
			out <= load_data;
		else if (~load_en & shift_en)
			out <= {out[nbits - 2:0], in_};
endmodule
module SPI_minion_components_Synchronizer (
	clk,
	in_,
	negedge_,
	out,
	posedge_,
	reset
);
	parameter reset_value = 1'b0;
	input wire clk;
	input wire in_;
	output reg negedge_;
	output wire out;
	output reg posedge_;
	input wire reset;
	reg [2:0] shreg;
	always @(*) begin
		negedge_ = shreg[2] & ~shreg[1];
		posedge_ = ~shreg[2] & shreg[1];
	end
	always @(posedge clk)
		if (reset)
			shreg <= {3 {reset_value}};
		else
			shreg <= {shreg[1:0], in_};
	assign out = shreg[1];
endmodule
module SPI_minion_components_SPIMinionVRTL (
	clk,
	cs,
	miso,
	mosi,
	reset,
	sclk,
	pull_en,
	pull_msg,
	push_en,
	push_msg,
	parity
);
	parameter nbits = 8;
	input wire clk;
	input wire cs;
	output wire miso;
	input wire mosi;
	input wire reset;
	input wire sclk;
	output wire pull_en;
	input wire [nbits - 1:0] pull_msg;
	output wire push_en;
	output wire [nbits - 1:0] push_msg;
	output wire parity;
	wire cs_sync_clk;
	wire cs_sync_in_;
	wire cs_sync_negedge_;
	wire cs_sync_out;
	wire cs_sync_posedge_;
	wire cs_sync_reset;
	SPI_minion_components_Synchronizer #(.reset_value(1'b1)) cs_sync(
		.clk(cs_sync_clk),
		.in_(cs_sync_in_),
		.negedge_(cs_sync_negedge_),
		.out(cs_sync_out),
		.posedge_(cs_sync_posedge_),
		.reset(cs_sync_reset)
	);
	wire mosi_sync_clk;
	wire mosi_sync_in_;
	wire mosi_sync_negedge_;
	wire mosi_sync_out;
	wire mosi_sync_posedge_;
	wire mosi_sync_reset;
	SPI_minion_components_Synchronizer #(.reset_value(1'b0)) mosi_sync(
		.clk(mosi_sync_clk),
		.in_(mosi_sync_in_),
		.negedge_(mosi_sync_negedge_),
		.out(mosi_sync_out),
		.posedge_(mosi_sync_posedge_),
		.reset(mosi_sync_reset)
	);
	wire sclk_sync_clk;
	wire sclk_sync_in_;
	wire sclk_sync_negedge_;
	wire sclk_sync_out;
	wire sclk_sync_posedge_;
	wire sclk_sync_reset;
	SPI_minion_components_Synchronizer #(.reset_value(1'b0)) sclk_sync(
		.clk(sclk_sync_clk),
		.in_(sclk_sync_in_),
		.negedge_(sclk_sync_negedge_),
		.out(sclk_sync_out),
		.posedge_(sclk_sync_posedge_),
		.reset(sclk_sync_reset)
	);
	wire shreg_in_clk;
	wire shreg_in_in_;
	wire [nbits - 1:0] shreg_in_load_data;
	wire shreg_in_load_en;
	wire [nbits - 1:0] shreg_in_out;
	wire shreg_in_reset;
	reg shreg_in_shift_en;
	SPI_minion_components_ShiftReg #(.nbits(nbits)) shreg_in(
		.clk(shreg_in_clk),
		.in_(shreg_in_in_),
		.load_data(shreg_in_load_data),
		.load_en(shreg_in_load_en),
		.out(shreg_in_out),
		.reset(shreg_in_reset),
		.shift_en(shreg_in_shift_en)
	);
	wire shreg_out_clk;
	wire shreg_out_in_;
	wire [nbits - 1:0] shreg_out_load_data;
	wire shreg_out_load_en;
	wire [nbits - 1:0] shreg_out_out;
	wire shreg_out_reset;
	reg shreg_out_shift_en;
	SPI_minion_components_ShiftReg #(.nbits(nbits)) shreg_out(
		.clk(shreg_out_clk),
		.in_(shreg_out_in_),
		.load_data(shreg_out_load_data),
		.load_en(shreg_out_load_en),
		.out(shreg_out_out),
		.reset(shreg_out_reset),
		.shift_en(shreg_out_shift_en)
	);
	always @(*) begin
		shreg_in_shift_en = ~cs_sync_out & sclk_sync_posedge_;
		shreg_out_shift_en = ~cs_sync_out & sclk_sync_negedge_;
	end
	assign cs_sync_clk = clk;
	assign cs_sync_reset = reset;
	assign cs_sync_in_ = cs;
	assign sclk_sync_clk = clk;
	assign sclk_sync_reset = reset;
	assign sclk_sync_in_ = sclk;
	assign mosi_sync_clk = clk;
	assign mosi_sync_reset = reset;
	assign mosi_sync_in_ = mosi;
	assign shreg_in_clk = clk;
	assign shreg_in_reset = reset;
	assign shreg_in_in_ = mosi_sync_out;
	assign shreg_in_load_en = 1'b0;
	assign shreg_in_load_data = {nbits {1'b0}};
	assign shreg_out_clk = clk;
	assign shreg_out_reset = reset;
	assign shreg_out_in_ = 1'b0;
	assign shreg_out_load_en = pull_en;
	assign shreg_out_load_data = pull_msg;
	assign miso = shreg_out_out[nbits - 1];
	assign pull_en = cs_sync_negedge_;
	assign push_en = cs_sync_posedge_;
	assign push_msg = shreg_in_out;
	assign parity = ^push_msg[nbits - 3:0] & push_en;
endmodule
module vc_Reg (
	clk,
	q,
	d
);
	parameter p_nbits = 1;
	input wire clk;
	output reg [p_nbits - 1:0] q;
	input wire [p_nbits - 1:0] d;
	always @(posedge clk) q <= d;
endmodule
module vc_ResetReg (
	clk,
	reset,
	q,
	d
);
	parameter p_nbits = 1;
	parameter p_reset_value = 0;
	input wire clk;
	input wire reset;
	output reg [p_nbits - 1:0] q;
	input wire [p_nbits - 1:0] d;
	always @(posedge clk) q <= (reset ? p_reset_value : d);
endmodule
module vc_EnReg (
	clk,
	reset,
	q,
	d,
	en
);
	parameter p_nbits = 1;
	input wire clk;
	input wire reset;
	output reg [p_nbits - 1:0] q;
	input wire [p_nbits - 1:0] d;
	input wire en;
	always @(posedge clk)
		if (en)
			q <= d;
endmodule
module vc_EnResetReg (
	clk,
	reset,
	q,
	d,
	en
);
	parameter p_nbits = 1;
	parameter p_reset_value = 0;
	input wire clk;
	input wire reset;
	output reg [p_nbits - 1:0] q;
	input wire [p_nbits - 1:0] d;
	input wire en;
	always @(posedge clk)
		if (reset || en)
			q <= (reset ? p_reset_value : d);
endmodule
module vc_Mux2 (
	in0,
	in1,
	sel,
	out
);
	parameter p_nbits = 1;
	input wire [p_nbits - 1:0] in0;
	input wire [p_nbits - 1:0] in1;
	input wire sel;
	output reg [p_nbits - 1:0] out;
	always @(*)
		case (sel)
			1'd0: out = in0;
			1'd1: out = in1;
			default: out = {p_nbits {1'bx}};
		endcase
endmodule
module vc_Mux3 (
	in0,
	in1,
	in2,
	sel,
	out
);
	parameter p_nbits = 1;
	input wire [p_nbits - 1:0] in0;
	input wire [p_nbits - 1:0] in1;
	input wire [p_nbits - 1:0] in2;
	input wire [1:0] sel;
	output reg [p_nbits - 1:0] out;
	always @(*)
		case (sel)
			2'd0: out = in0;
			2'd1: out = in1;
			2'd2: out = in2;
			default: out = {p_nbits {1'bx}};
		endcase
endmodule
module vc_Mux4 (
	in0,
	in1,
	in2,
	in3,
	sel,
	out
);
	parameter p_nbits = 1;
	input wire [p_nbits - 1:0] in0;
	input wire [p_nbits - 1:0] in1;
	input wire [p_nbits - 1:0] in2;
	input wire [p_nbits - 1:0] in3;
	input wire [1:0] sel;
	output reg [p_nbits - 1:0] out;
	always @(*)
		case (sel)
			2'd0: out = in0;
			2'd1: out = in1;
			2'd2: out = in2;
			2'd3: out = in3;
			default: out = {p_nbits {1'bx}};
		endcase
endmodule
module vc_Mux5 (
	in0,
	in1,
	in2,
	in3,
	in4,
	sel,
	out
);
	parameter p_nbits = 1;
	input wire [p_nbits - 1:0] in0;
	input wire [p_nbits - 1:0] in1;
	input wire [p_nbits - 1:0] in2;
	input wire [p_nbits - 1:0] in3;
	input wire [p_nbits - 1:0] in4;
	input wire [2:0] sel;
	output reg [p_nbits - 1:0] out;
	always @(*)
		case (sel)
			3'd0: out = in0;
			3'd1: out = in1;
			3'd2: out = in2;
			3'd3: out = in3;
			3'd4: out = in4;
			default: out = {p_nbits {1'bx}};
		endcase
endmodule
module vc_Mux6 (
	in0,
	in1,
	in2,
	in3,
	in4,
	in5,
	sel,
	out
);
	parameter p_nbits = 1;
	input wire [p_nbits - 1:0] in0;
	input wire [p_nbits - 1:0] in1;
	input wire [p_nbits - 1:0] in2;
	input wire [p_nbits - 1:0] in3;
	input wire [p_nbits - 1:0] in4;
	input wire [p_nbits - 1:0] in5;
	input wire [2:0] sel;
	output reg [p_nbits - 1:0] out;
	always @(*)
		case (sel)
			3'd0: out = in0;
			3'd1: out = in1;
			3'd2: out = in2;
			3'd3: out = in3;
			3'd4: out = in4;
			3'd5: out = in5;
			default: out = {p_nbits {1'bx}};
		endcase
endmodule
module vc_Mux7 (
	in0,
	in1,
	in2,
	in3,
	in4,
	in5,
	in6,
	sel,
	out
);
	parameter p_nbits = 1;
	input wire [p_nbits - 1:0] in0;
	input wire [p_nbits - 1:0] in1;
	input wire [p_nbits - 1:0] in2;
	input wire [p_nbits - 1:0] in3;
	input wire [p_nbits - 1:0] in4;
	input wire [p_nbits - 1:0] in5;
	input wire [p_nbits - 1:0] in6;
	input wire [2:0] sel;
	output reg [p_nbits - 1:0] out;
	always @(*)
		case (sel)
			3'd0: out = in0;
			3'd1: out = in1;
			3'd2: out = in2;
			3'd3: out = in3;
			3'd4: out = in4;
			3'd5: out = in5;
			3'd6: out = in6;
			default: out = {p_nbits {1'bx}};
		endcase
endmodule
module vc_Mux8 (
	in0,
	in1,
	in2,
	in3,
	in4,
	in5,
	in6,
	in7,
	sel,
	out
);
	parameter p_nbits = 1;
	input wire [p_nbits - 1:0] in0;
	input wire [p_nbits - 1:0] in1;
	input wire [p_nbits - 1:0] in2;
	input wire [p_nbits - 1:0] in3;
	input wire [p_nbits - 1:0] in4;
	input wire [p_nbits - 1:0] in5;
	input wire [p_nbits - 1:0] in6;
	input wire [p_nbits - 1:0] in7;
	input wire [2:0] sel;
	output reg [p_nbits - 1:0] out;
	always @(*)
		case (sel)
			3'd0: out = in0;
			3'd1: out = in1;
			3'd2: out = in2;
			3'd3: out = in3;
			3'd4: out = in4;
			3'd5: out = in5;
			3'd6: out = in6;
			3'd7: out = in7;
			default: out = {p_nbits {1'bx}};
		endcase
endmodule
module vc_MuxN (
	in,
	sel,
	out
);
	parameter p_nbits = 1;
	parameter p_ninputs = 2;
	input wire [(p_ninputs * p_nbits) - 1:0] in;
	input wire [$clog2(p_ninputs) - 1:0] sel;
	output wire [p_nbits - 1:0] out;
	assign out = in[sel * p_nbits+:p_nbits];
endmodule
module vc_Regfile_1r1w (
	clk,
	reset,
	read_addr,
	read_data,
	write_en,
	write_addr,
	write_data
);
	parameter p_data_nbits = 1;
	parameter p_num_entries = 2;
	parameter c_addr_nbits = $clog2(p_num_entries);
	input wire clk;
	input wire reset;
	input wire [c_addr_nbits - 1:0] read_addr;
	output wire [p_data_nbits - 1:0] read_data;
	input wire write_en;
	input wire [c_addr_nbits - 1:0] write_addr;
	input wire [p_data_nbits - 1:0] write_data;
	reg [p_data_nbits - 1:0] rfile [p_num_entries - 1:0];
	assign read_data = rfile[read_addr];
	always @(posedge clk)
		if (write_en)
			rfile[write_addr] <= write_data;
endmodule
module vc_ResetRegfile_1r1w (
	clk,
	reset,
	read_addr,
	read_data,
	write_en,
	write_addr,
	write_data
);
	parameter p_data_nbits = 1;
	parameter p_num_entries = 2;
	parameter p_reset_value = 0;
	parameter c_addr_nbits = $clog2(p_num_entries);
	input wire clk;
	input wire reset;
	input wire [c_addr_nbits - 1:0] read_addr;
	output wire [p_data_nbits - 1:0] read_data;
	input wire write_en;
	input wire [c_addr_nbits - 1:0] write_addr;
	input wire [p_data_nbits - 1:0] write_data;
	reg [p_data_nbits - 1:0] rfile [p_num_entries - 1:0];
	assign read_data = rfile[read_addr];
	genvar i;
	generate
		for (i = 0; i < p_num_entries; i = i + 1) begin : wport
			always @(posedge clk)
				if (reset)
					rfile[i] <= p_reset_value;
				else if (write_en && (i[c_addr_nbits - 1:0] == write_addr))
					rfile[i] <= write_data;
		end
	endgenerate
endmodule
module vc_Regfile_2r1w (
	clk,
	reset,
	read_addr0,
	read_data0,
	read_addr1,
	read_data1,
	write_en,
	write_addr,
	write_data
);
	parameter p_data_nbits = 1;
	parameter p_num_entries = 2;
	parameter c_addr_nbits = $clog2(p_num_entries);
	input wire clk;
	input wire reset;
	input wire [c_addr_nbits - 1:0] read_addr0;
	output wire [p_data_nbits - 1:0] read_data0;
	input wire [c_addr_nbits - 1:0] read_addr1;
	output wire [p_data_nbits - 1:0] read_data1;
	input wire write_en;
	input wire [c_addr_nbits - 1:0] write_addr;
	input wire [p_data_nbits - 1:0] write_data;
	reg [p_data_nbits - 1:0] rfile [p_num_entries - 1:0];
	assign read_data0 = rfile[read_addr0];
	assign read_data1 = rfile[read_addr1];
	always @(posedge clk)
		if (write_en)
			rfile[write_addr] <= write_data;
endmodule
module vc_Regfile_2r2w (
	clk,
	reset,
	read_addr0,
	read_data0,
	read_addr1,
	read_data1,
	write_en0,
	write_addr0,
	write_data0,
	write_en1,
	write_addr1,
	write_data1
);
	parameter p_data_nbits = 1;
	parameter p_num_entries = 2;
	parameter c_addr_nbits = $clog2(p_num_entries);
	input wire clk;
	input wire reset;
	input wire [c_addr_nbits - 1:0] read_addr0;
	output wire [p_data_nbits - 1:0] read_data0;
	input wire [c_addr_nbits - 1:0] read_addr1;
	output wire [p_data_nbits - 1:0] read_data1;
	input wire write_en0;
	input wire [c_addr_nbits - 1:0] write_addr0;
	input wire [p_data_nbits - 1:0] write_data0;
	input wire write_en1;
	input wire [c_addr_nbits - 1:0] write_addr1;
	input wire [p_data_nbits - 1:0] write_data1;
	reg [p_data_nbits - 1:0] rfile [p_num_entries - 1:0];
	assign read_data0 = rfile[read_addr0];
	assign read_data1 = rfile[read_addr1];
	always @(posedge clk) begin
		if (write_en0)
			rfile[write_addr0] <= write_data0;
		if (write_en1)
			rfile[write_addr1] <= write_data1;
	end
endmodule
module vc_Regfile_2r1w_zero (
	clk,
	reset,
	rd_addr0,
	rd_data0,
	rd_addr1,
	rd_data1,
	wr_en,
	wr_addr,
	wr_data
);
	input wire clk;
	input wire reset;
	input wire [4:0] rd_addr0;
	output wire [31:0] rd_data0;
	input wire [4:0] rd_addr1;
	output wire [31:0] rd_data1;
	input wire wr_en;
	input wire [4:0] wr_addr;
	input wire [31:0] wr_data;
	wire [31:0] rf_read_data0;
	wire [31:0] rf_read_data1;
	vc_Regfile_2r1w #(
		.p_data_nbits(32),
		.p_num_entries(32)
	) rfile(
		.clk(clk),
		.reset(reset),
		.read_addr0(rd_addr0),
		.read_data0(rf_read_data0),
		.read_addr1(rd_addr1),
		.read_data1(rf_read_data1),
		.write_en(wr_en),
		.write_addr(wr_addr),
		.write_data(wr_data)
	);
	assign rd_data0 = (rd_addr0 == 5'd0 ? 32'd0 : rf_read_data0);
	assign rd_data1 = (rd_addr1 == 5'd0 ? 32'd0 : rf_read_data1);
endmodule

module vc_QueueCtrl1 (
	clk,
	reset,
	recv_val,
	recv_rdy,
	send_val,
	send_rdy,
	write_en,
	bypass_mux_sel,
	num_free_entries
);
	parameter p_type = 4'b0000;
	input wire clk;
	input wire reset;
	input wire recv_val;
	output wire recv_rdy;
	output wire send_val;
	input wire send_rdy;
	output wire write_en;
	output wire bypass_mux_sel;
	output wire num_free_entries;
	reg full;
	wire full_next;
	always @(posedge clk) full <= (reset ? 1'b0 : full_next);
	assign num_free_entries = (full ? 1'b0 : 1'b1);
	localparam c_pipe_en = |(p_type & 4'b0001);
	localparam c_bypass_en = |(p_type & 4'b0010);
	wire do_enq;
	assign do_enq = recv_rdy && recv_val;
	wire do_deq;
	assign do_deq = send_rdy && send_val;
	wire empty;
	assign empty = ~full;
	wire do_pipe;
	assign do_pipe = ((c_pipe_en && full) && do_enq) && do_deq;
	wire do_bypass;
	assign do_bypass = ((c_bypass_en && empty) && do_enq) && do_deq;
	assign write_en = do_enq && ~do_bypass;
	assign bypass_mux_sel = empty;
	assign recv_rdy = ~full || ((c_pipe_en && full) && send_rdy);
	assign send_val = ~empty || ((c_bypass_en && empty) && recv_val);
	assign full_next = (do_deq && ~do_pipe ? 1'b0 : (do_enq && ~do_bypass ? 1'b1 : full));
endmodule
module vc_QueueDpath1 (
	clk,
	reset,
	write_en,
	bypass_mux_sel,
	recv_msg,
	send_msg
);
	parameter p_type = 4'b0000;
	parameter p_msg_nbits = 1;
	input wire clk;
	input wire reset;
	input wire write_en;
	input wire bypass_mux_sel;
	input wire [p_msg_nbits - 1:0] recv_msg;
	output wire [p_msg_nbits - 1:0] send_msg;
	wire [p_msg_nbits - 1:0] qstore;
	vc_EnReg #(.p_nbits(p_msg_nbits)) qstore_reg(
		.clk(clk),
		.reset(reset),
		.en(write_en),
		.d(recv_msg),
		.q(qstore)
	);
	generate
		if (|(p_type & 4'b0010)) begin : genblk1
			vc_Mux2 #(.p_nbits(p_msg_nbits)) bypass_mux(
				.in0(qstore),
				.in1(recv_msg),
				.sel(bypass_mux_sel),
				.out(send_msg)
			);
		end
		else begin : genblk1
			assign send_msg = qstore;
		end
	endgenerate
endmodule
module vc_QueueCtrl (
	clk,
	reset,
	recv_val,
	recv_rdy,
	send_val,
	send_rdy,
	write_en,
	write_addr,
	read_addr,
	bypass_mux_sel,
	num_free_entries
);
	parameter p_type = 4'b0000;
	parameter p_num_msgs = 2;
	parameter c_addr_nbits = $clog2(p_num_msgs);
	input wire clk;
	input wire reset;
	input wire recv_val;
	output wire recv_rdy;
	output wire send_val;
	input wire send_rdy;
	output wire write_en;
	output wire [c_addr_nbits - 1:0] write_addr;
	output wire [c_addr_nbits - 1:0] read_addr;
	output wire bypass_mux_sel;
	output wire [c_addr_nbits:0] num_free_entries;
	wire [c_addr_nbits - 1:0] enq_ptr;
	wire [c_addr_nbits - 1:0] enq_ptr_next;
	vc_ResetReg #(.p_nbits(c_addr_nbits)) enq_ptr_reg(
		.clk(clk),
		.reset(reset),
		.d(enq_ptr_next),
		.q(enq_ptr)
	);
	wire [c_addr_nbits - 1:0] deq_ptr;
	wire [c_addr_nbits - 1:0] deq_ptr_next;
	vc_ResetReg #(.p_nbits(c_addr_nbits)) deq_ptr_reg(
		.clk(clk),
		.reset(reset),
		.d(deq_ptr_next),
		.q(deq_ptr)
	);
	assign write_addr = enq_ptr;
	assign read_addr = deq_ptr;
	wire full;
	wire full_next;
	vc_ResetReg #(.p_nbits(1)) full_reg(
		.clk(clk),
		.reset(reset),
		.d(full_next),
		.q(full)
	);
	localparam c_pipe_en = |(p_type & 4'b0001);
	localparam c_bypass_en = |(p_type & 4'b0010);
	wire do_enq;
	assign do_enq = recv_rdy && recv_val;
	wire do_deq;
	assign do_deq = send_rdy && send_val;
	wire empty;
	assign empty = ~full && (enq_ptr == deq_ptr);
	wire do_pipe;
	assign do_pipe = ((c_pipe_en && full) && do_enq) && do_deq;
	wire do_bypass;
	assign do_bypass = ((c_bypass_en && empty) && do_enq) && do_deq;
	assign write_en = do_enq && ~do_bypass;
	assign bypass_mux_sel = empty;
	assign recv_rdy = ~full || ((c_pipe_en && full) && send_rdy);
	assign send_val = ~empty || ((c_bypass_en && empty) && recv_val);
	wire [c_addr_nbits - 1:0] deq_ptr_plus1;
	assign deq_ptr_plus1 = deq_ptr + 1'b1;
	wire [c_addr_nbits - 1:0] deq_ptr_inc;
	assign deq_ptr_inc = (deq_ptr_plus1 == p_num_msgs ? {c_addr_nbits {1'b0}} : deq_ptr_plus1);
	wire [c_addr_nbits - 1:0] enq_ptr_plus1;
	assign enq_ptr_plus1 = enq_ptr + 1'b1;
	wire [c_addr_nbits - 1:0] enq_ptr_inc;
	assign enq_ptr_inc = (enq_ptr_plus1 == p_num_msgs ? {c_addr_nbits {1'b0}} : enq_ptr_plus1);
	assign deq_ptr_next = (do_deq && ~do_bypass ? deq_ptr_inc : deq_ptr);
	assign enq_ptr_next = (do_enq && ~do_bypass ? enq_ptr_inc : enq_ptr);
	assign full_next = ((do_enq && ~do_deq) && (enq_ptr_inc == deq_ptr) ? 1'b1 : ((do_deq && full) && ~do_pipe ? 1'b0 : full));
	assign num_free_entries = (full ? {c_addr_nbits + 1 {1'b0}} : (empty ? p_num_msgs[c_addr_nbits:0] : (enq_ptr > deq_ptr ? p_num_msgs[c_addr_nbits:0] - (enq_ptr - deq_ptr) : (deq_ptr > enq_ptr ? deq_ptr - enq_ptr : {c_addr_nbits + 1 {1'bx}}))));
endmodule
module vc_QueueDpath (
	clk,
	reset,
	write_en,
	bypass_mux_sel,
	write_addr,
	read_addr,
	recv_msg,
	send_msg
);
	parameter p_type = 4'b0000;
	parameter p_msg_nbits = 4;
	parameter p_num_msgs = 2;
	parameter c_addr_nbits = $clog2(p_num_msgs);
	input wire clk;
	input wire reset;
	input wire write_en;
	input wire bypass_mux_sel;
	input wire [c_addr_nbits - 1:0] write_addr;
	input wire [c_addr_nbits - 1:0] read_addr;
	input wire [p_msg_nbits - 1:0] recv_msg;
	output wire [p_msg_nbits - 1:0] send_msg;
	wire [p_msg_nbits - 1:0] read_data;
	vc_Regfile_1r1w #(
		.p_data_nbits(p_msg_nbits),
		.p_num_entries(p_num_msgs)
	) qstore(
		.clk(clk),
		.reset(reset),
		.read_addr(read_addr),
		.read_data(read_data),
		.write_en(write_en),
		.write_addr(write_addr),
		.write_data(recv_msg)
	);
	generate
		if (|(p_type & 4'b0010)) begin : genblk1
			vc_Mux2 #(.p_nbits(p_msg_nbits)) bypass_mux(
				.in0(read_data),
				.in1(recv_msg),
				.sel(bypass_mux_sel),
				.out(send_msg)
			);
		end
		else begin : genblk1
			assign send_msg = read_data;
		end
	endgenerate
endmodule
module vc_Queue (
	clk,
	reset,
	recv_val,
	recv_rdy,
	recv_msg,
	send_val,
	send_rdy,
	send_msg,
	num_free_entries
);
	parameter p_type = 4'b0000;
	parameter p_msg_nbits = 1;
	parameter p_num_msgs = 2;
	parameter c_addr_nbits = $clog2(p_num_msgs);
	input wire clk;
	input wire reset;
	input wire recv_val;
	output wire recv_rdy;
	input wire [p_msg_nbits - 1:0] recv_msg;
	output wire send_val;
	input wire send_rdy;
	output wire [p_msg_nbits - 1:0] send_msg;
	output wire [c_addr_nbits:0] num_free_entries;
	generate
		if (p_num_msgs == 1) begin : genblk1
			wire write_en;
			wire bypass_mux_sel;
			vc_QueueCtrl1 #(.p_type(p_type)) ctrl(
				.clk(clk),
				.reset(reset),
				.recv_val(recv_val),
				.recv_rdy(recv_rdy),
				.send_val(send_val),
				.send_rdy(send_rdy),
				.write_en(write_en),
				.bypass_mux_sel(bypass_mux_sel),
				.num_free_entries(num_free_entries)
			);
			vc_QueueDpath1 #(
				.p_type(p_type),
				.p_msg_nbits(p_msg_nbits)
			) dpath(
				.clk(clk),
				.reset(reset),
				.write_en(write_en),
				.bypass_mux_sel(bypass_mux_sel),
				.recv_msg(recv_msg),
				.send_msg(send_msg)
			);
		end
		else begin : genblk1
			wire write_en;
			wire bypass_mux_sel;
			wire [c_addr_nbits - 1:0] write_addr;
			wire [c_addr_nbits - 1:0] read_addr;
			vc_QueueCtrl #(
				.p_type(p_type),
				.p_num_msgs(p_num_msgs)
			) ctrl(
				.clk(clk),
				.reset(reset),
				.recv_val(recv_val),
				.recv_rdy(recv_rdy),
				.send_val(send_val),
				.send_rdy(send_rdy),
				.write_en(write_en),
				.write_addr(write_addr),
				.read_addr(read_addr),
				.bypass_mux_sel(bypass_mux_sel),
				.num_free_entries(num_free_entries)
			);
			vc_QueueDpath #(
				.p_type(p_type),
				.p_msg_nbits(p_msg_nbits),
				.p_num_msgs(p_num_msgs)
			) dpath(
				.clk(clk),
				.reset(reset),
				.write_en(write_en),
				.bypass_mux_sel(bypass_mux_sel),
				.write_addr(write_addr),
				.read_addr(read_addr),
				.recv_msg(recv_msg),
				.send_msg(send_msg)
			);
		end
	endgenerate
endmodule
module SPI_minion_components_SPIMinionAdapterVRTL (
	clk,
	reset,
	pull_en,
	pull_msg_val,
	pull_msg_spc,
	pull_msg_data,
	push_en,
	push_msg_val_wrt,
	push_msg_val_rd,
	push_msg_data,
	recv_msg,
	recv_rdy,
	recv_val,
	send_msg,
	send_rdy,
	send_val,
	parity
);
	parameter nbits = 8;
	parameter num_entries = 1;
	input wire clk;
	input wire reset;
	input wire pull_en;
	output reg pull_msg_val;
	output reg pull_msg_spc;
	output reg [nbits - 3:0] pull_msg_data;
	input wire push_en;
	input wire push_msg_val_wrt;
	input wire push_msg_val_rd;
	input wire [nbits - 3:0] push_msg_data;
	input wire [nbits - 3:0] recv_msg;
	output wire recv_rdy;
	input wire recv_val;
	output wire [nbits - 3:0] send_msg;
	input wire send_rdy;
	output wire send_val;
	output wire parity;
	reg open_entries;
	wire [nbits - 3:0] cm_q_send_msg;
	reg cm_q_send_rdy;
	wire cm_q_send_val;
	vc_Queue #(
		.p_type(4'b0000),
		.p_msg_nbits(nbits - 2),
		.p_num_msgs(num_entries)
	) cm_q(
		.clk(clk),
		.reset(reset),
		.recv_msg(recv_msg),
		.recv_rdy(recv_rdy),
		.recv_val(recv_val),
		.send_msg(cm_q_send_msg),
		.send_rdy(cm_q_send_rdy),
		.send_val(cm_q_send_val)
	);
	wire [$clog2(num_entries):0] mc_q_num_free;
	wire mc_q_recv_rdy;
	reg mc_q_recv_val;
	vc_Queue #(
		.p_type(4'b0000),
		.p_msg_nbits(nbits - 2),
		.p_num_msgs(num_entries)
	) mc_q(
		.clk(clk),
		.num_free_entries(mc_q_num_free),
		.reset(reset),
		.recv_msg(push_msg_data),
		.recv_rdy(mc_q_recv_rdy),
		.recv_val(mc_q_recv_val),
		.send_msg(send_msg),
		.send_rdy(send_rdy),
		.send_val(send_val)
	);
	assign parity = ^send_msg & send_val;
	always @(*) begin : comb_block
		open_entries = mc_q_num_free > 1;
		mc_q_recv_val = push_msg_val_wrt & push_en;
		pull_msg_spc = mc_q_recv_rdy & (~mc_q_recv_val | open_entries);
		cm_q_send_rdy = push_msg_val_rd & pull_en;
		pull_msg_val = cm_q_send_rdy & cm_q_send_val;
		pull_msg_data = cm_q_send_msg & {nbits - 2 {pull_msg_val}};
	end
endmodule
module vc_Adder (
	in0,
	in1,
	cin,
	out,
	cout
);
	parameter p_nbits = 1;
	input wire [p_nbits - 1:0] in0;
	input wire [p_nbits - 1:0] in1;
	input wire cin;
	output wire [p_nbits - 1:0] out;
	output wire cout;
	assign {cout, out} = (in0 + in1) + {{p_nbits - 1 {1'b0}}, cin};
endmodule
module vc_SimpleAdder (
	in0,
	in1,
	out
);
	parameter p_nbits = 1;
	input wire [p_nbits - 1:0] in0;
	input wire [p_nbits - 1:0] in1;
	output wire [p_nbits - 1:0] out;
	assign out = in0 + in1;
endmodule
module vc_Subtractor (
	in0,
	in1,
	out
);
	parameter p_nbits = 1;
	input wire [p_nbits - 1:0] in0;
	input wire [p_nbits - 1:0] in1;
	output wire [p_nbits - 1:0] out;
	assign out = in0 - in1;
endmodule
module vc_Incrementer (
	in,
	out
);
	parameter p_nbits = 1;
	parameter p_inc_value = 1;
	input wire [p_nbits - 1:0] in;
	output wire [p_nbits - 1:0] out;
	assign out = in + p_inc_value;
endmodule
module vc_ZeroExtender (
	in,
	out
);
	parameter p_in_nbits = 1;
	parameter p_out_nbits = 8;
	input wire [p_in_nbits - 1:0] in;
	output wire [p_out_nbits - 1:0] out;
	assign out = {{p_out_nbits - p_in_nbits {1'b0}}, in};
endmodule
module vc_SignExtender (
	in,
	out
);
	parameter p_in_nbits = 1;
	parameter p_out_nbits = 8;
	input wire [p_in_nbits - 1:0] in;
	output wire [p_out_nbits - 1:0] out;
	assign out = {{p_out_nbits - p_in_nbits {in[p_in_nbits - 1]}}, in};
endmodule
module vc_ZeroComparator (
	in,
	out
);
	parameter p_nbits = 1;
	input wire [p_nbits - 1:0] in;
	output wire out;
	assign out = in == {p_nbits {1'b0}};
endmodule
module vc_EqComparator (
	in0,
	in1,
	out
);
	parameter p_nbits = 1;
	input wire [p_nbits - 1:0] in0;
	input wire [p_nbits - 1:0] in1;
	output wire out;
	assign out = in0 == in1;
endmodule
module vc_LtComparator (
	in0,
	in1,
	out
);
	parameter p_nbits = 1;
	input wire [p_nbits - 1:0] in0;
	input wire [p_nbits - 1:0] in1;
	output wire out;
	assign out = in0 < in1;
endmodule
module vc_GtComparator (
	in0,
	in1,
	out
);
	parameter p_nbits = 1;
	input wire [p_nbits - 1:0] in0;
	input wire [p_nbits - 1:0] in1;
	output wire out;
	assign out = in0 > in1;
endmodule
module vc_LeftLogicalShifter (
	in,
	shamt,
	out
);
	parameter p_nbits = 1;
	parameter p_shamt_nbits = 1;
	input wire [p_nbits - 1:0] in;
	input wire [p_shamt_nbits - 1:0] shamt;
	output wire [p_nbits - 1:0] out;
	assign out = in << shamt;
endmodule
module vc_RightLogicalShifter (
	in,
	shamt,
	out
);
	parameter p_nbits = 1;
	parameter p_shamt_nbits = 1;
	input wire [p_nbits - 1:0] in;
	input wire [p_shamt_nbits - 1:0] shamt;
	output wire [p_nbits - 1:0] out;
	assign out = in >> shamt;
endmodule
module tut3_verilog_gcd_GcdUnitDpath (
	clk,
	reset,
	istream_msg,
	ostream_msg,
	a_reg_en,
	b_reg_en,
	a_mux_sel,
	b_mux_sel,
	is_b_zero,
	is_a_lt_b
);
	input wire clk;
	input wire reset;
	input wire [31:0] istream_msg;
	output wire [15:0] ostream_msg;
	input wire a_reg_en;
	input wire b_reg_en;
	input wire [1:0] a_mux_sel;
	input wire b_mux_sel;
	output wire is_b_zero;
	output wire is_a_lt_b;
	localparam c_nbits = 16;
	wire [15:0] istream_msg_a;
	assign istream_msg_a = istream_msg[31:16];
	wire [15:0] istream_msg_b;
	assign istream_msg_b = istream_msg[15:0];
	wire [15:0] b_reg_out;
	wire [15:0] sub_out;
	wire [15:0] a_mux_out;
	vc_Mux3 #(.p_nbits(c_nbits)) a_mux(
		.sel(a_mux_sel),
		.in0(istream_msg_a),
		.in1(b_reg_out),
		.in2(sub_out),
		.out(a_mux_out)
	);
	wire [15:0] a_reg_out;
	vc_EnReg #(.p_nbits(c_nbits)) a_reg(
		.clk(clk),
		.reset(reset),
		.en(a_reg_en),
		.d(a_mux_out),
		.q(a_reg_out)
	);
	wire [15:0] b_mux_out;
	vc_Mux2 #(.p_nbits(c_nbits)) b_mux(
		.sel(b_mux_sel),
		.in0(istream_msg_b),
		.in1(a_reg_out),
		.out(b_mux_out)
	);
	vc_EnReg #(.p_nbits(c_nbits)) b_reg(
		.clk(clk),
		.reset(reset),
		.en(b_reg_en),
		.d(b_mux_out),
		.q(b_reg_out)
	);
	vc_LtComparator #(.p_nbits(c_nbits)) a_lt_b(
		.in0(a_reg_out),
		.in1(b_reg_out),
		.out(is_a_lt_b)
	);
	vc_ZeroComparator #(.p_nbits(c_nbits)) b_zero(
		.in(b_reg_out),
		.out(is_b_zero)
	);
	vc_Subtractor #(.p_nbits(c_nbits)) sub(
		.in0(a_reg_out),
		.in1(b_reg_out),
		.out(sub_out)
	);
	assign ostream_msg = sub_out;
endmodule
module tut3_verilog_gcd_GcdUnitCtrl (
	clk,
	reset,
	istream_val,
	istream_rdy,
	ostream_val,
	ostream_rdy,
	a_reg_en,
	b_reg_en,
	a_mux_sel,
	b_mux_sel,
	is_b_zero,
	is_a_lt_b
);
	input wire clk;
	input wire reset;
	input wire istream_val;
	output reg istream_rdy;
	output reg ostream_val;
	input wire ostream_rdy;
	output reg a_reg_en;
	output reg b_reg_en;
	output reg [1:0] a_mux_sel;
	output reg b_mux_sel;
	input wire is_b_zero;
	input wire is_a_lt_b;
	localparam STATE_IDLE = 2'd0;
	localparam STATE_CALC = 2'd1;
	localparam STATE_DONE = 2'd2;
	reg [1:0] state_reg;
	reg [1:0] state_next;
	always @(posedge clk)
		if (reset)
			state_reg <= STATE_IDLE;
		else
			state_reg <= state_next;
	wire req_go;
	wire resp_go;
	wire is_calc_done;
	assign req_go = istream_val && istream_rdy;
	assign resp_go = ostream_val && ostream_rdy;
	assign is_calc_done = !is_a_lt_b && is_b_zero;
	always @(*) begin
		state_next = state_reg;
		case (state_reg)
			STATE_IDLE:
				if (req_go)
					state_next = STATE_CALC;
			STATE_CALC:
				if (is_calc_done)
					state_next = STATE_DONE;
			STATE_DONE:
				if (resp_go)
					state_next = STATE_IDLE;
			default: state_next = 1'sbx;
		endcase
	end
	localparam a_x = 2'bxx;
	localparam a_ld = 2'd0;
	localparam a_b = 2'd1;
	localparam a_sub = 2'd2;
	localparam b_x = 1'bx;
	localparam b_ld = 1'd0;
	localparam b_a = 1'd1;
	task cs;
		input reg cs_istream_rdy;
		input reg cs_ostream_val;
		input reg [1:0] cs_a_mux_sel;
		input reg cs_a_reg_en;
		input reg cs_b_mux_sel;
		input reg cs_b_reg_en;
		begin
			istream_rdy = cs_istream_rdy;
			ostream_val = cs_ostream_val;
			a_reg_en = cs_a_reg_en;
			b_reg_en = cs_b_reg_en;
			a_mux_sel = cs_a_mux_sel;
			b_mux_sel = cs_b_mux_sel;
		end
	endtask
	wire do_swap;
	wire do_sub;
	assign do_swap = is_a_lt_b;
	assign do_sub = !is_b_zero;
	always @(*) begin
		cs(0, 0, a_x, 0, b_x, 0);
		case (state_reg)
			STATE_IDLE:
				cs(1, 0, a_ld, 1, b_ld, 1);
			STATE_CALC:
				if (do_swap)
					cs(0, 0, a_b, 1, b_a, 1);
				else if (do_sub)
					cs(0, 0, a_sub, 1, b_x, 0);
			STATE_DONE:
				cs(0, 1, a_x, 0, b_x, 0);
			default:
				cs(1'sbx, 1'sbx, a_x, 1'sbx, b_x, 1'sbx);
		endcase
	end
endmodule
module GcdUnit (
	clk,
	reset,
	istream_val,
	istream_rdy,
	istream_msg,
	ostream_val,
	ostream_rdy,
	ostream_msg
);
	input wire clk;
	input wire reset;
	input wire istream_val;
	output wire istream_rdy;
	input wire [31:0] istream_msg;
	output wire ostream_val;
	input wire ostream_rdy;
	output wire [15:0] ostream_msg;
	wire a_reg_en;
	wire b_reg_en;
	wire [1:0] a_mux_sel;
	wire b_mux_sel;
	wire is_b_zero;
	wire is_a_lt_b;
	tut3_verilog_gcd_GcdUnitCtrl ctrl(
		.clk(clk),
		.reset(reset),
		.istream_val(istream_val),
		.istream_rdy(istream_rdy),
		.ostream_val(ostream_val),
		.ostream_rdy(ostream_rdy),
		.a_reg_en(a_reg_en),
		.b_reg_en(b_reg_en),
		.a_mux_sel(a_mux_sel),
		.b_mux_sel(b_mux_sel),
		.is_b_zero(is_b_zero),
		.is_a_lt_b(is_a_lt_b)
	);
	tut3_verilog_gcd_GcdUnitDpath dpath(
		.clk(clk),
		.reset(reset),
		.istream_msg(istream_msg),
		.ostream_msg(ostream_msg),
		.a_reg_en(a_reg_en),
		.b_reg_en(b_reg_en),
		.a_mux_sel(a_mux_sel),
		.b_mux_sel(b_mux_sel),
		.is_b_zero(is_b_zero),
		.is_a_lt_b(is_a_lt_b)
	);
	wire [4095:0] str;
	vc_Trace vc_trace(
		.clk(clk),
		.reset(reset)
	);
	task line_trace;
		output reg [4095:0] trace_str;
		begin
			$sformat(str, "%x:%x", istream_msg[31:16], istream_msg[15:0]);
			vc_trace.append_val_rdy_str(trace_str, istream_val, istream_rdy, str);
			vc_trace.append_str(trace_str, "(");
			$sformat(str, "%x", dpath.a_reg_out);
			vc_trace.append_str(trace_str, str);
			vc_trace.append_str(trace_str, " ");
			$sformat(str, "%x", dpath.b_reg_out);
			vc_trace.append_str(trace_str, str);
			vc_trace.append_str(trace_str, " ");
			case (ctrl.state_reg)
				ctrl.STATE_IDLE:
					vc_trace.append_str(trace_str, "I ");
				ctrl.STATE_CALC:
					if (ctrl.do_swap)
						vc_trace.append_str(trace_str, "Cs");
					else if (ctrl.do_sub)
						vc_trace.append_str(trace_str, "C-");
					else
						vc_trace.append_str(trace_str, "C ");
				ctrl.STATE_DONE:
					vc_trace.append_str(trace_str, "D ");
				default:
					vc_trace.append_str(trace_str, "? ");
			endcase
			vc_trace.append_str(trace_str, ")");
			$sformat(str, "%x", ostream_msg);
			vc_trace.append_val_rdy_str(trace_str, ostream_val, ostream_rdy, str);
		end
	endtask
	task display_trace;
		begin
			if (vc_trace.level > 0) begin
				vc_trace.storage[15:0] = vc_trace.nchars - 1;
				line_trace(vc_trace.storage);
				$write("%4d: ", vc_trace.cycles);
				vc_trace.idx0 = vc_trace.storage[15:0];
				for (vc_trace.idx1 = vc_trace.nchars - 1; vc_trace.idx1 > vc_trace.idx0; vc_trace.idx1 = vc_trace.idx1 - 1)
					$write("%s", vc_trace.storage[vc_trace.idx1 * 8+:8]);
				$write("\n");
			end
			vc_trace.cycles_next = vc_trace.cycles + 1;
		end
	endtask
endmodule
module TwiddleGeneratorVRTL (
	sine_wave_in,
	twiddle_real,
	twiddle_imaginary
);
	parameter BIT_WIDTH = 4;
	parameter DECIMAL_PT = 2;
	parameter SIZE_FFT = 8;
	parameter STAGE_FFT = 0;
	input wire [(SIZE_FFT * BIT_WIDTH) - 1:0] sine_wave_in;
	output wire [((SIZE_FFT / 2) * BIT_WIDTH) - 1:0] twiddle_real;
	output wire [((SIZE_FFT / 2) * BIT_WIDTH) - 1:0] twiddle_imaginary;
	wire signed [31:0] trace;
	assign trace = 1'd1 << DECIMAL_PT;
	wire signed [31:0] trace2;
	assign trace2 = (1 * (SIZE_FFT / (2 * (2 ** STAGE_FFT)))) % SIZE_FFT;
	wire signed [31:0] trace3;
	assign trace3 = (2 * (SIZE_FFT / (2 * (2 ** STAGE_FFT)))) % SIZE_FFT;
	wire signed [31:0] trace4;
	assign trace4 = (3 * (SIZE_FFT / (2 * (2 ** STAGE_FFT)))) % SIZE_FFT;
	genvar m;
	generate
		for (m = 0; m < (2 ** STAGE_FFT); m = m + 1) begin : genblk1
			genvar i;
			for (i = 0; i < SIZE_FFT; i = i + (2 ** (STAGE_FFT + 1))) begin : genblk1
				if (m == 0) begin : genblk1
					assign twiddle_real[((i / 2) + m) * BIT_WIDTH+:BIT_WIDTH] = 1'b1 << DECIMAL_PT;
					assign twiddle_imaginary[((i / 2) + m) * BIT_WIDTH+:BIT_WIDTH] = 0;
				end
				else begin : genblk1
					assign twiddle_real[((i / 2) + m) * BIT_WIDTH+:BIT_WIDTH] = sine_wave_in[((SIZE_FFT - 1) - (((m * (SIZE_FFT / (2 * (2 ** STAGE_FFT)))) % SIZE_FFT) + (SIZE_FFT / 4))) * BIT_WIDTH+:BIT_WIDTH];
					assign twiddle_imaginary[((i / 2) + m) * BIT_WIDTH+:BIT_WIDTH] = -sine_wave_in[((SIZE_FFT - 1) - ((m * (SIZE_FFT / (2 * (2 ** STAGE_FFT)))) % SIZE_FFT)) * BIT_WIDTH+:BIT_WIDTH];
				end
			end
		end
	endgenerate
endmodule
module SineWave__BIT_WIDTH_32__DECIMAL_POINT_16__SIZE_FFT_16VRTL (sine_wave_out);
	output wire [511:0] sine_wave_out;
	assign sine_wave_out[480+:32] = 0;
	assign sine_wave_out[448+:32] = 25079;
	assign sine_wave_out[416+:32] = 46340;
	assign sine_wave_out[384+:32] = 60547;
	assign sine_wave_out[352+:32] = 65536;
	assign sine_wave_out[320+:32] = 60547;
	assign sine_wave_out[288+:32] = 46340;
	assign sine_wave_out[256+:32] = 25079;
	assign sine_wave_out[224+:32] = 0;
	assign sine_wave_out[192+:32] = -25079;
	assign sine_wave_out[160+:32] = -46340;
	assign sine_wave_out[128+:32] = -60547;
	assign sine_wave_out[96+:32] = -65536;
	assign sine_wave_out[64+:32] = -60547;
	assign sine_wave_out[32+:32] = -46340;
	assign sine_wave_out[0+:32] = -25079;
endmodule
module SineWave__BIT_WIDTH_32__DECIMAL_POINT_16__SIZE_FFT_8VRTL (sine_wave_out);
	output wire [255:0] sine_wave_out;
	assign sine_wave_out[224+:32] = 0;
	assign sine_wave_out[192+:32] = 46340;
	assign sine_wave_out[160+:32] = 65536;
	assign sine_wave_out[128+:32] = 46340;
	assign sine_wave_out[96+:32] = 0;
	assign sine_wave_out[64+:32] = -46340;
	assign sine_wave_out[32+:32] = -65536;
	assign sine_wave_out[0+:32] = -46340;
endmodule
module SineWave__BIT_WIDTH_32__DECIMAL_POINT_16__SIZE_FFT_2VRTL (sine_wave_out);
	output wire [63:0] sine_wave_out;
	assign sine_wave_out[32+:32] = 0;
	assign sine_wave_out[0+:32] = 0;
endmodule
module SineWave__BIT_WIDTH_32__DECIMAL_POINT_16__SIZE_FFT_4VRTL (sine_wave_out);
	output wire [127:0] sine_wave_out;
	assign sine_wave_out[96+:32] = 0;
	assign sine_wave_out[64+:32] = 65536;
	assign sine_wave_out[32+:32] = 0;
	assign sine_wave_out[0+:32] = -65536;
endmodule
module CombinationalFFTCrossbarVRTl (
	recv_real,
	recv_imaginary,
	recv_val,
	recv_rdy,
	send_real,
	send_imaginary,
	send_val,
	send_rdy
);
	parameter BIT_WIDTH = 32;
	parameter SIZE_FFT = 8;
	parameter STAGE_FFT = 0;
	parameter FRONT = 1;
	input wire [(SIZE_FFT * BIT_WIDTH) - 1:0] recv_real;
	input wire [(SIZE_FFT * BIT_WIDTH) - 1:0] recv_imaginary;
	input wire [SIZE_FFT - 1:0] recv_val;
	output wire [SIZE_FFT - 1:0] recv_rdy;
	output wire [(SIZE_FFT * BIT_WIDTH) - 1:0] send_real;
	output wire [(SIZE_FFT * BIT_WIDTH) - 1:0] send_imaginary;
	output wire [SIZE_FFT - 1:0] send_val;
	input wire [SIZE_FFT - 1:0] send_rdy;
	genvar m;
	generate
		for (m = 0; m < (2 ** STAGE_FFT); m = m + 1) begin : genblk1
			genvar i;
			for (i = m; i < SIZE_FFT; i = i + (2 ** (STAGE_FFT + 1))) begin : genblk1
				if (FRONT == 1) begin : genblk1
					assign send_real[(i + m) * BIT_WIDTH+:BIT_WIDTH] = recv_real[i * BIT_WIDTH+:BIT_WIDTH];
					assign send_imaginary[(i + m) * BIT_WIDTH+:BIT_WIDTH] = recv_imaginary[i * BIT_WIDTH+:BIT_WIDTH];
					assign send_val[i + m] = recv_val[i];
					assign recv_rdy[i + m] = send_rdy[i];
					assign send_real[((i + m) + 1) * BIT_WIDTH+:BIT_WIDTH] = recv_real[(i + (2 ** STAGE_FFT)) * BIT_WIDTH+:BIT_WIDTH];
					assign send_imaginary[((i + m) + 1) * BIT_WIDTH+:BIT_WIDTH] = recv_imaginary[(i + (2 ** STAGE_FFT)) * BIT_WIDTH+:BIT_WIDTH];
					assign send_val[(i + m) + 1] = recv_val[i + (2 ** STAGE_FFT)];
					assign recv_rdy[(i + m) + 1] = send_rdy[i + (2 ** STAGE_FFT)];
				end
				else begin : genblk1
					assign send_real[i * BIT_WIDTH+:BIT_WIDTH] = recv_real[(i + m) * BIT_WIDTH+:BIT_WIDTH];
					assign send_imaginary[i * BIT_WIDTH+:BIT_WIDTH] = recv_imaginary[(i + m) * BIT_WIDTH+:BIT_WIDTH];
					assign send_val[i] = recv_val[i + m];
					assign recv_rdy[i] = send_rdy[i + m];
					assign send_real[(i + (2 ** STAGE_FFT)) * BIT_WIDTH+:BIT_WIDTH] = recv_real[((i + m) + 1) * BIT_WIDTH+:BIT_WIDTH];
					assign send_imaginary[(i + (2 ** STAGE_FFT)) * BIT_WIDTH+:BIT_WIDTH] = recv_imaginary[((i + m) + 1) * BIT_WIDTH+:BIT_WIDTH];
					assign send_val[i + (2 ** STAGE_FFT)] = recv_val[(i + m) + 1];
					assign recv_rdy[i + (2 ** STAGE_FFT)] = send_rdy[(i + m) + 1];
				end
			end
		end
	endgenerate
endmodule
module RegisterV_Reset (
	clk,
	reset,
	w,
	d,
	q
);
	parameter N = 8;
	input wire clk;
	input wire reset;
	input wire w;
	input wire [N - 1:0] d;
	output wire [N - 1:0] q;
	reg [N - 1:0] regout;
	assign q = regout;
	always @(posedge clk)
		if (reset)
			regout <= 0;
		else if (w)
			regout <= d;
endmodule
module FpmultVRTL (
	clk,
	reset,
	recv_val,
	recv_rdy,
	send_val,
	send_rdy,
	a,
	b,
	c
);
	parameter n = 32;
	parameter d = 16;
	parameter sign = 1;
	input wire clk;
	input wire reset;
	input wire recv_val;
	input wire send_rdy;
	input wire [n - 1:0] a;
	input wire [n - 1:0] b;
	output wire [n - 1:0] c;
	output wire send_val;
	output wire recv_rdy;
	wire do_carry;
	wire do_add;
	wire in_wait;
	fpmult_control #(
		.n(n),
		.d(d)
	) control(
		.clk(clk),
		.reset(reset),
		.recv_val(recv_val),
		.recv_rdy(recv_rdy),
		.send_val(send_val),
		.send_rdy(send_rdy),
		.in_wait(in_wait),
		.do_add(do_add),
		.do_carry(do_carry)
	);
	fpmult_datapath #(
		.n(n),
		.d(d)
	) datapath(
		.clk(clk),
		.reset(reset),
		.in_wait(in_wait),
		.do_add(do_add),
		.do_carry((sign != 0) & do_carry),
		.a({{d {(sign != 0) & a[n - 1]}}, a}),
		.b(b),
		.c(c)
	);
endmodule
module fpmult_control (
	clk,
	reset,
	recv_val,
	recv_rdy,
	send_val,
	send_rdy,
	in_wait,
	do_add,
	do_carry
);
	parameter n = 0;
	parameter d = 0;
	input wire clk;
	input wire reset;
	input wire recv_val;
	output reg recv_rdy;
	output reg send_val;
	input wire send_rdy;
	output reg in_wait;
	output reg do_add;
	output reg do_carry;
	localparam [1:0] IDLE = 2'd0;
	localparam [1:0] CALC = 2'd1;
	localparam [1:0] DONE = 2'd2;
	reg [1:0] state;
	reg [1:0] next_state;
	reg [$clog2(n) - 1:0] counter;
	reg counter_reset;
	function automatic signed [$clog2(n) - 1:0] sv2v_cast_2A747_signed;
		input reg signed [$clog2(n) - 1:0] inp;
		sv2v_cast_2A747_signed = inp;
	endfunction
	always @(*)
		case (state)
			IDLE:
				if (recv_val)
					next_state = CALC;
				else
					next_state = IDLE;
			CALC:
				if (counter == sv2v_cast_2A747_signed(n - 1))
					next_state = DONE;
				else
					next_state = CALC;
			DONE:
				if (send_rdy)
					next_state = IDLE;
				else
					next_state = DONE;
			default: next_state = IDLE;
		endcase
	always @(*)
		case (state)
			IDLE: begin
				in_wait = 1;
				do_add = 0;
				do_carry = 0;
				counter_reset = 0;
				recv_rdy = 1;
				send_val = 0;
			end
			CALC: begin
				in_wait = 0;
				do_add = 1;
				do_carry = counter == sv2v_cast_2A747_signed(n - 1);
				counter_reset = 0;
				recv_rdy = 0;
				send_val = 0;
			end
			DONE: begin
				in_wait = 0;
				do_add = 0;
				do_carry = 0;
				counter_reset = 1;
				recv_rdy = 0;
				send_val = 1;
			end
			default:
				;
		endcase
	always @(posedge clk)
		if (reset)
			state <= IDLE;
		else
			state <= next_state;
	always @(posedge clk)
		if (reset || counter_reset)
			counter <= 0;
		else if (state == CALC)
			counter <= counter + 1;
		else
			counter <= counter;
endmodule
module fpmult_datapath (
	clk,
	reset,
	in_wait,
	do_add,
	do_carry,
	a,
	b,
	c
);
	parameter n = 0;
	parameter d = 0;
	input wire clk;
	input wire reset;
	input wire in_wait;
	input wire do_add;
	input wire do_carry;
	input wire [(n + d) - 1:0] a;
	input wire [n - 1:0] b;
	output wire [n - 1:0] c;
	wire [(n + d) - 1:0] acc_in;
	wire [(n + d) - 1:0] acc_out;
	RegisterV_Reset #(.N(n + d)) acc_reg(
		.clk(clk),
		.reset(in_wait | reset),
		.w(1),
		.d(acc_in),
		.q(acc_out)
	);
	wire [(n + d) - 1:0] a_const_out;
	RegisterV_Reset #(.N(n + d)) a_const_reg(
		.clk(clk),
		.reset(reset),
		.w(in_wait),
		.d(a),
		.q(a_const_out)
	);
	wire [(n + d) - 1:0] a_in;
	wire [(n + d) - 1:0] a_out;
	RegisterV_Reset #(.N(n + d)) a_reg(
		.clk(clk),
		.reset(reset),
		.w(1),
		.d(a_in),
		.q(a_out)
	);
	wire [(n + d) - 1:0] b_in;
	wire [(n + d) - 1:0] b_out;
	RegisterV_Reset #(.N(n)) b_reg(
		.clk(clk),
		.reset(reset),
		.w(1),
		.d(b_in),
		.q(b_out)
	);
	vc_Mux2 #(.p_nbits(n + d)) a_sel(
		.in0(a_out << 1),
		.in1(a),
		.sel(in_wait),
		.out(a_in)
	);
	vc_Mux2 #(.p_nbits(n)) b_sel(
		.in0(b_out >> 1),
		.in1(b),
		.sel(in_wait),
		.out(b_in)
	);
	wire [(n + d) - 1:0] add_tmp;
	wire [(n + d) - 1:0] carry;
	wire [(2 * n) - 1:0] carry_tmp;
	wire [(2 * n) - 1:0] carry_tmp2;
	assign carry_tmp = {{n - d {a_const_out[(n + d) - 1]}}, a_const_out};
	assign carry_tmp2 = ((carry_tmp << n) - carry_tmp) << (n - 1);
	vc_Mux2 #(.p_nbits(n + d)) carry_sel(
		.in0(a_out),
		.in1(carry_tmp2[(n + d) - 1:0]),
		.sel(do_carry),
		.out(add_tmp)
	);
	vc_Mux2 #(.p_nbits(n + d)) add_sel(
		.in0(acc_out),
		.in1(acc_out + add_tmp),
		.sel(do_add & b_out[0]),
		.out(acc_in)
	);
	assign c = acc_out[(n + d) - 1:d];
endmodule
module FpcmultVRTL (
	clk,
	reset,
	recv_val,
	recv_rdy,
	send_val,
	send_rdy,
	ar,
	ac,
	br,
	bc,
	cr,
	cc
);
	parameter n = 32;
	parameter d = 16;
	input wire clk;
	input wire reset;
	input wire recv_val;
	output wire recv_rdy;
	output wire send_val;
	input wire send_rdy;
	input wire [n - 1:0] ar;
	input wire [n - 1:0] ac;
	input wire [n - 1:0] br;
	input wire [n - 1:0] bc;
	output wire [n - 1:0] cr;
	output wire [n - 1:0] cc;
	wire [n - 1:0] arbr;
	wire [n - 1:0] acbc;
	wire [n - 1:0] ar_plus_ac;
	wire [n - 1:0] br_plus_bc;
	wire [n - 1:0] ab;
	assign ar_plus_ac = ar + ac;
	assign br_plus_bc = br + bc;
	wire recv_rdy_imm [2:0];
	assign recv_rdy = (recv_rdy_imm[0] & recv_rdy_imm[1]) & recv_rdy_imm[2];
	wire send_val_imm [2:0];
	assign send_val = (send_val_imm[0] & send_val_imm[1]) & send_val_imm[2];
	FpmultVRTL #(
		.n(n),
		.d(d),
		.sign(1)
	) m1(
		.clk(clk),
		.reset(reset),
		.a(ar),
		.b(br),
		.c(arbr),
		.recv_val(recv_val),
		.recv_rdy(recv_rdy_imm[0]),
		.send_val(send_val_imm[0]),
		.send_rdy(send_rdy)
	);
	FpmultVRTL #(
		.n(n),
		.d(d),
		.sign(1)
	) m2(
		.clk(clk),
		.reset(reset),
		.a(ac),
		.b(bc),
		.c(acbc),
		.recv_val(recv_val),
		.recv_rdy(recv_rdy_imm[1]),
		.send_val(send_val_imm[1]),
		.send_rdy(send_rdy)
	);
	FpmultVRTL #(
		.n(n),
		.d(d),
		.sign(1)
	) m3(
		.clk(clk),
		.reset(reset),
		.a(ar_plus_ac),
		.b(br_plus_bc),
		.c(ab),
		.recv_val(recv_val),
		.recv_rdy(recv_rdy_imm[2]),
		.send_val(send_val_imm[2]),
		.send_rdy(send_rdy)
	);
	assign cr = arbr - acbc;
	assign cc = (ab - arbr) - acbc;
endmodule
module ButterflyVRTL (
	clk,
	reset,
	recv_val,
	recv_rdy,
	send_val,
	send_rdy,
	ar,
	ac,
	br,
	bc,
	wr,
	wc,
	cr,
	cc,
	dr,
	dc
);
	parameter n = 32;
	parameter d = 16;
	parameter mult = 1;
	input wire clk;
	input wire reset;
	input wire recv_val;
	input wire send_rdy;
	input wire [n - 1:0] ar;
	input wire [n - 1:0] ac;
	input wire [n - 1:0] br;
	input wire [n - 1:0] bc;
	input wire [n - 1:0] wr;
	input wire [n - 1:0] wc;
	output wire send_val;
	output wire recv_rdy;
	output wire [n - 1:0] cr;
	output wire [n - 1:0] cc;
	output wire [n - 1:0] dr;
	output wire [n - 1:0] dc;
	reg [n - 1:0] ar_reg;
	reg [n - 1:0] ac_reg;
	wire mul_rdy;
	wire [n - 1:0] tr;
	wire [n - 1:0] tc;
	FpcmultVRTL #(
		.n(n),
		.d(d)
	) mul(
		.clk(clk),
		.reset(reset),
		.ar(br),
		.ac(bc),
		.br(wr),
		.bc(wc),
		.cr(tr),
		.cc(tc),
		.recv_val(recv_val),
		.recv_rdy(recv_rdy),
		.send_val(send_val),
		.send_rdy(send_rdy)
	);
	always @(posedge clk)
		if (reset) begin
			ar_reg = 0;
			ac_reg = 0;
		end
		else if (recv_rdy) begin
			ar_reg = ar;
			ac_reg = ac;
		end
		else begin
			ar_reg = ar_reg;
			ac_reg = ac_reg;
		end
	assign cr = ar_reg + tr;
	assign cc = ac_reg + tc;
	assign dr = ar_reg - tr;
	assign dc = ac_reg - tc;
endmodule
module FFT_StageVRTL (
	recv_msg_real,
	recv_msg_imag,
	recv_val,
	recv_rdy,
	send_msg_real,
	send_msg_imag,
	send_val,
	send_rdy,
	sine_wave_out,
	reset,
	clk
);
	parameter BIT_WIDTH = 32;
	parameter DECIMAL_PT = 16;
	parameter N_SAMPLES = 8;
	parameter STAGE_FFT = 0;
	input wire [(N_SAMPLES * BIT_WIDTH) - 1:0] recv_msg_real;
	input wire [(N_SAMPLES * BIT_WIDTH) - 1:0] recv_msg_imag;
	input wire recv_val;
	output reg recv_rdy;
	output wire [(N_SAMPLES * BIT_WIDTH) - 1:0] send_msg_real;
	output wire [(N_SAMPLES * BIT_WIDTH) - 1:0] send_msg_imag;
	output reg send_val;
	input wire send_rdy;
	input wire [(N_SAMPLES * BIT_WIDTH) - 1:0] sine_wave_out;
	input wire reset;
	input wire clk;
	reg [N_SAMPLES - 1:0] val_in;
	wire [N_SAMPLES - 1:0] rdy_in;
	wire [N_SAMPLES - 1:0] val_out;
	reg [N_SAMPLES - 1:0] rdy_out;
	reg [N_SAMPLES - 1:0] imm;
	always @(*) begin : sv2v_autoblock_1
		reg signed [31:0] i;
		for (i = 0; i < N_SAMPLES; i = i + 1)
			begin
				val_in[i] = recv_val;
				imm[i] = rdy_in[i];
			end
		recv_rdy = &imm;
	end
	wire [(N_SAMPLES * BIT_WIDTH) - 1:0] butterfly_in_real;
	wire [(N_SAMPLES * BIT_WIDTH) - 1:0] butterfly_out_real;
	wire [(N_SAMPLES * BIT_WIDTH) - 1:0] butterfly_in_imaginary;
	wire [(N_SAMPLES * BIT_WIDTH) - 1:0] butterfly_out_imaginary;
	wire [N_SAMPLES - 1:0] val_interior_in;
	wire [N_SAMPLES - 1:0] rdy_interior_in;
	wire [N_SAMPLES - 1:0] val_interior_out;
	wire [N_SAMPLES - 1:0] rdy_interior_out;
	wire [((N_SAMPLES / 2) * BIT_WIDTH) - 1:0] twiddle_real;
	wire [((N_SAMPLES / 2) * BIT_WIDTH) - 1:0] twiddle_imaginary;
	wire val_interior_mini [(N_SAMPLES / 2) - 1:0];
	wire rdy_interior_mini [(N_SAMPLES / 2) - 1:0];
	CombinationalFFTCrossbarVRTl #(
		.BIT_WIDTH(BIT_WIDTH),
		.SIZE_FFT(N_SAMPLES),
		.STAGE_FFT(STAGE_FFT),
		.FRONT(1)
	) xbar_in_1(
		.recv_real(recv_msg_real),
		.recv_imaginary(recv_msg_imag),
		.recv_val(val_in),
		.recv_rdy(rdy_in),
		.send_real(butterfly_in_real[BIT_WIDTH * ((N_SAMPLES - 1) - (N_SAMPLES - 1))+:BIT_WIDTH * N_SAMPLES]),
		.send_imaginary(butterfly_in_imaginary[BIT_WIDTH * ((N_SAMPLES - 1) - (N_SAMPLES - 1))+:BIT_WIDTH * N_SAMPLES]),
		.send_val(val_interior_in),
		.send_rdy(rdy_interior_in)
	);
	genvar b;
	generate
		for (b = 0; b < (N_SAMPLES / 2); b = b + 1) begin : genblk1
			ButterflyVRTL #(
				.n(BIT_WIDTH),
				.d(DECIMAL_PT)
			) bfu_in(
				.ar(butterfly_in_real[(b * 2) * BIT_WIDTH+:BIT_WIDTH]),
				.ac(butterfly_in_imaginary[(b * 2) * BIT_WIDTH+:BIT_WIDTH]),
				.br(butterfly_in_real[((b * 2) + 1) * BIT_WIDTH+:BIT_WIDTH]),
				.bc(butterfly_in_imaginary[((b * 2) + 1) * BIT_WIDTH+:BIT_WIDTH]),
				.wr(twiddle_real[b * BIT_WIDTH+:BIT_WIDTH]),
				.wc(twiddle_imaginary[b * BIT_WIDTH+:BIT_WIDTH]),
				.recv_val(val_interior_in[b * 2] && val_interior_in[(b * 2) + 1]),
				.recv_rdy(rdy_interior_mini[b]),
				.cr(butterfly_out_real[(b * 2) * BIT_WIDTH+:BIT_WIDTH]),
				.cc(butterfly_out_imaginary[(b * 2) * BIT_WIDTH+:BIT_WIDTH]),
				.dr(butterfly_out_real[((b * 2) + 1) * BIT_WIDTH+:BIT_WIDTH]),
				.dc(butterfly_out_imaginary[((b * 2) + 1) * BIT_WIDTH+:BIT_WIDTH]),
				.send_rdy(rdy_interior_out[b * 2] && rdy_interior_out[(b * 2) + 1]),
				.send_val(val_interior_mini[b]),
				.reset(reset),
				.clk(clk)
			);
			assign val_interior_out[(b * 2) + 1] = val_interior_mini[b];
			assign val_interior_out[b * 2] = val_interior_mini[b];
			assign rdy_interior_in[(b * 2) + 1] = rdy_interior_mini[b];
			assign rdy_interior_in[b * 2] = rdy_interior_mini[b];
		end
	endgenerate
	CombinationalFFTCrossbarVRTl #(
		.BIT_WIDTH(BIT_WIDTH),
		.SIZE_FFT(N_SAMPLES),
		.STAGE_FFT(STAGE_FFT),
		.FRONT(0)
	) xbar_out_1(
		.recv_real(butterfly_out_real),
		.recv_imaginary(butterfly_out_imaginary),
		.recv_val(val_interior_out),
		.recv_rdy(rdy_interior_out),
		.send_real(send_msg_real),
		.send_imaginary(send_msg_imag),
		.send_val(val_out),
		.send_rdy(rdy_out)
	);
	TwiddleGeneratorVRTL #(
		.BIT_WIDTH(BIT_WIDTH),
		.DECIMAL_PT(DECIMAL_PT),
		.SIZE_FFT(N_SAMPLES),
		.STAGE_FFT(STAGE_FFT)
	) twiddle_generator(
		.sine_wave_in(sine_wave_out),
		.twiddle_real(twiddle_real),
		.twiddle_imaginary(twiddle_imaginary)
	);
	reg [N_SAMPLES - 1:0] imm2;
	always @(*) begin : sv2v_autoblock_2
		reg signed [31:0] i;
		for (i = 0; i < N_SAMPLES; i = i + 1)
			begin
				imm2[i] = val_out[i];
				rdy_out[i] = send_rdy;
			end
		send_val = &imm2;
	end
endmodule
module FFTVRTL (
	recv_msg,
	recv_val,
	recv_rdy,
	send_msg,
	send_val,
	send_rdy,
	reset,
	clk
);
	parameter BIT_WIDTH = 32;
	parameter DECIMAL_PT = 16;
	parameter N_SAMPLES = 8;
	input wire [(N_SAMPLES * BIT_WIDTH) - 1:0] recv_msg;
	input wire recv_val;
	output wire recv_rdy;
	output reg [(N_SAMPLES * BIT_WIDTH) - 1:0] send_msg;
	output wire send_val;
	input wire send_rdy;
	input wire reset;
	input wire clk;
	wire [(N_SAMPLES * BIT_WIDTH) - 1:0] real_msg [$clog2(N_SAMPLES):0];
	reg [(N_SAMPLES * BIT_WIDTH) - 1:0] complex_msg [$clog2(N_SAMPLES):0];
	wire val_in [$clog2(N_SAMPLES):0];
	wire rdy_in [$clog2(N_SAMPLES):0];
	wire [(N_SAMPLES * BIT_WIDTH) - 1:0] sine_wave_out;
	assign val_in[0] = recv_val;
	assign recv_rdy = rdy_in[0];
	assign send_val = val_in[$clog2(N_SAMPLES)];
	assign rdy_in[$clog2(N_SAMPLES)] = send_rdy;
	always @(*) begin : sv2v_autoblock_1
		reg signed [31:0] i;
		for (i = 0; i < N_SAMPLES; i = i + 1)
			complex_msg[0][i * BIT_WIDTH+:BIT_WIDTH] = 0;
	end
	generate
		if (N_SAMPLES == 16) begin : genblk1
			assign real_msg[0][0+:BIT_WIDTH] = recv_msg[0+:BIT_WIDTH];
			assign real_msg[0][8 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][4 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[2 * BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][12 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[3 * BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][2 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[4 * BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][10 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[5 * BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][6 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[6 * BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][14 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[7 * BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][BIT_WIDTH+:BIT_WIDTH] = recv_msg[8 * BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][9 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[9 * BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][5 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[10 * BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][13 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[11 * BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][3 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[12 * BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][11 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[13 * BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][7 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[14 * BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][15 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[15 * BIT_WIDTH+:BIT_WIDTH];
			SineWave__BIT_WIDTH_32__DECIMAL_POINT_16__SIZE_FFT_16VRTL SineWave(.sine_wave_out(sine_wave_out));
		end
		else if (N_SAMPLES == 8) begin : genblk1
			assign real_msg[0][0+:BIT_WIDTH] = recv_msg[0+:BIT_WIDTH];
			assign real_msg[0][4 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][2 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[2 * BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][6 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[3 * BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][BIT_WIDTH+:BIT_WIDTH] = recv_msg[4 * BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][5 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[5 * BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][3 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[6 * BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][7 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[7 * BIT_WIDTH+:BIT_WIDTH];
			SineWave__BIT_WIDTH_32__DECIMAL_POINT_16__SIZE_FFT_8VRTL SineWave(.sine_wave_out(sine_wave_out));
		end
		else if (N_SAMPLES == 4) begin : genblk1
			assign real_msg[0][0+:BIT_WIDTH] = recv_msg[0+:BIT_WIDTH];
			assign real_msg[0][2 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][BIT_WIDTH+:BIT_WIDTH] = recv_msg[2 * BIT_WIDTH+:BIT_WIDTH];
			assign real_msg[0][3 * BIT_WIDTH+:BIT_WIDTH] = recv_msg[3 * BIT_WIDTH+:BIT_WIDTH];
			SineWave__BIT_WIDTH_32__DECIMAL_POINT_16__SIZE_FFT_4VRTL SineWave(.sine_wave_out(sine_wave_out));
		end
		else if (N_SAMPLES == 2) begin : genblk1
			assign real_msg[0][0+:BIT_WIDTH] = recv_msg[0+:BIT_WIDTH];
			assign real_msg[0][BIT_WIDTH+:BIT_WIDTH] = recv_msg[BIT_WIDTH+:BIT_WIDTH];
			SineWave__BIT_WIDTH_32__DECIMAL_POINT_16__SIZE_FFT_2VRTL SineWave(.sine_wave_out(sine_wave_out));
		end
	endgenerate
	genvar i;
	genvar b;
	generate
		for (i = 0; i < $clog2(N_SAMPLES); i = i + 1) begin : genblk2
			wire [N_SAMPLES * BIT_WIDTH:1] sv2v_tmp_fft_stage_send_msg_imag;
			always @(*) complex_msg[i + 1] = sv2v_tmp_fft_stage_send_msg_imag;
			FFT_StageVRTL #(
				.BIT_WIDTH(BIT_WIDTH),
				.DECIMAL_PT(DECIMAL_PT),
				.N_SAMPLES(N_SAMPLES),
				.STAGE_FFT(i)
			) fft_stage(
				.recv_msg_real(real_msg[i]),
				.recv_msg_imag(complex_msg[i]),
				.recv_val(val_in[i]),
				.recv_rdy(rdy_in[i]),
				.send_msg_real(real_msg[i + 1]),
				.send_msg_imag(sv2v_tmp_fft_stage_send_msg_imag),
				.send_val(val_in[i + 1]),
				.send_rdy(rdy_in[i + 1]),
				.sine_wave_out(sine_wave_out),
				.reset(reset),
				.clk(clk)
			);
		end
	endgenerate
	always @(*) begin : sv2v_autoblock_2
		reg signed [31:0] i;
		for (i = 0; i < N_SAMPLES; i = i + 1)
			send_msg[i * BIT_WIDTH+:BIT_WIDTH] = real_msg[$clog2(N_SAMPLES)][i * BIT_WIDTH+:BIT_WIDTH];
	end
endmodule
module SerializerVRTL (
	recv_msg,
	recv_val,
	recv_rdy,
	send_msg,
	send_val,
	send_rdy,
	reset,
	clk
);
	parameter BIT_WIDTH = 32;
	parameter N_SAMPLES = 8;
	input wire [(N_SAMPLES * BIT_WIDTH) - 1:0] recv_msg;
	input wire recv_val;
	output wire recv_rdy;
	output reg [BIT_WIDTH - 1:0] send_msg;
	output wire send_val;
	input wire send_rdy;
	input wire reset;
	input wire clk;
	wire [$clog2(N_SAMPLES) - 1:0] mux_sel;
	wire reg_en;
	wire [BIT_WIDTH - 1:0] reg_out [N_SAMPLES - 1:0];
	genvar i;
	generate
		for (i = 0; i < N_SAMPLES; i = i + 1) begin : genblk1
			RegisterV_Reset #(.N(BIT_WIDTH)) register(
				.clk(clk),
				.reset(reset),
				.w(reg_en),
				.d(recv_msg[i * BIT_WIDTH+:BIT_WIDTH]),
				.q(reg_out[i])
			);
		end
	endgenerate
	always @(*) send_msg = reg_out[mux_sel];
	SerializerControl #(.N_SAMPLES(N_SAMPLES)) ctrl(
		.clk(clk),
		.reset(reset),
		.recv_val(recv_val),
		.recv_rdy(recv_rdy),
		.send_val(send_val),
		.send_rdy(send_rdy),
		.mux_sel(mux_sel),
		.reg_en(reg_en)
	);
endmodule
module SerializerControl (
	recv_val,
	recv_rdy,
	send_val,
	send_rdy,
	mux_sel,
	reg_en,
	clk,
	reset
);
	parameter N_SAMPLES = 8;
	input wire recv_val;
	output reg recv_rdy;
	output reg send_val;
	input wire send_rdy;
	output reg [$clog2(N_SAMPLES) - 1:0] mux_sel;
	output reg reg_en;
	input wire clk;
	input wire reset;
	parameter INIT = 0;
	parameter OUTPUT_START = 1;
	parameter ADD = 2;
	reg next_state;
	reg state;
	reg [$clog2(N_SAMPLES):0] mux_sel_next;
	always @(*)
		case (state)
			INIT: begin
				if (reset == 1)
					next_state = INIT;
				if (recv_val == 1)
					next_state = OUTPUT_START;
				else
					next_state = INIT;
			end
			OUTPUT_START:
				if (mux_sel_next != N_SAMPLES)
					next_state = OUTPUT_START;
				else
					next_state = INIT;
			default: next_state = INIT;
		endcase
	always @(*)
		case (state)
			INIT: begin
				reg_en = 1;
				send_val = 0;
				recv_rdy = 1;
				mux_sel_next = 0;
			end
			OUTPUT_START: begin
				reg_en = 0;
				send_val = 1;
				recv_rdy = 0;
				if (send_rdy == 1)
					mux_sel_next = mux_sel + 1;
				else
					mux_sel_next = mux_sel;
			end
		endcase
	always @(posedge clk) begin
		mux_sel <= mux_sel_next;
		state <= next_state;
	end
endmodule
module ControlVRTL (
	recv_val,
	send_rdy,
	send_val,
	recv_rdy,
	en_sel,
	reset,
	clk
);
	parameter N_SAMPLES = 8;
	input wire recv_val;
	input wire send_rdy;
	output reg send_val;
	output reg recv_rdy;
	output wire [N_SAMPLES - 1:0] en_sel;
	input wire reset;
	input wire clk;
	parameter [1:0] INIT = 2'b00;
	parameter [1:0] STATE1 = 2'b01;
	parameter [1:0] STATE2 = 2'b10;
	reg [$clog2(N_SAMPLES) + 1:0] count;
	reg [$clog2(N_SAMPLES) + 1:0] count_next;
	reg [1:0] next_state;
	reg [1:0] state;
	DecoderVRTL #(.BIT_WIDTH($clog2(N_SAMPLES))) decoder(
		.in(count),
		.out(en_sel)
	);
	always @(*)
		case (state)
			INIT:
				if (count_next == N_SAMPLES)
					next_state = STATE1;
				else
					next_state = INIT;
			STATE1:
				if (send_rdy == 1)
					next_state = INIT;
				else
					next_state = STATE1;
			default: next_state = INIT;
		endcase
	always @(*)
		case (state)
			INIT: begin
				if (recv_val == 1)
					count_next = count + 1;
				else
					count_next = count;
				recv_rdy = 1'b1;
				send_val = 1'b0;
			end
			STATE1: begin
				count_next = 0;
				recv_rdy = 1'b0;
				send_val = 1'b1;
			end
			default: begin
				count_next = 0;
				recv_rdy = 1'b1;
				send_val = 1'b0;
			end
		endcase
	always @(posedge clk)
		if (reset) begin
			count <= 0;
			state <= INIT;
		end
		else begin
			count <= count_next;
			state <= next_state;
		end
endmodule
module DecoderVRTL (
	in,
	out
);
	parameter BIT_WIDTH = 3;
	input wire [BIT_WIDTH - 1:0] in;
	output reg [(1 << BIT_WIDTH) - 1:0] out;
	always @(*) out = {{1 << (BIT_WIDTH - 1) {1'b0}}, 1'b1} << in;
endmodule
module RegisterV (
	clk,
	reset,
	w,
	d,
	q
);
	parameter BIT_WIDTH = 32;
	input wire clk;
	input wire reset;
	input wire w;
	input wire [BIT_WIDTH - 1:0] d;
	output wire [BIT_WIDTH - 1:0] q;
	reg [BIT_WIDTH - 1:0] regout;
	assign q = regout;
	always @(posedge clk)
		if (reset)
			regout <= 0;
		else if (w)
			regout <= d;
endmodule
module DeserializerVRTL (
	recv_val,
	recv_rdy,
	recv_msg,
	send_val,
	send_rdy,
	send_msg,
	clk,
	reset
);
	parameter N_SAMPLES = 8;
	parameter BIT_WIDTH = 32;
	input wire recv_val;
	output wire recv_rdy;
	input wire [BIT_WIDTH - 1:0] recv_msg;
	output wire send_val;
	input wire send_rdy;
	output wire [(N_SAMPLES * BIT_WIDTH) - 1:0] send_msg;
	input wire clk;
	input wire reset;
	wire [N_SAMPLES - 1:0] en_sel;
	ControlVRTL #(.N_SAMPLES(N_SAMPLES)) c(
		.recv_val(recv_val),
		.send_rdy(send_rdy),
		.send_val(send_val),
		.recv_rdy(recv_rdy),
		.reset(reset),
		.clk(clk),
		.en_sel(en_sel)
	);
	genvar i;
	generate
		for (i = 0; i < N_SAMPLES; i = i + 1) begin : genblk1
			RegisterV #(.BIT_WIDTH(BIT_WIDTH)) register(
				.clk(clk),
				.reset(reset),
				.w(en_sel[i]),
				.d(recv_msg),
				.q(send_msg[i * BIT_WIDTH+:BIT_WIDTH])
			);
		end
	endgenerate
endmodule
module minion_FFT_FFTSPIMinionVRTL (
	clk,
	reset,
	cs,
	sclk,
	mosi,
	miso,
	cs_2,
	sclk_2,
	mosi_2,
	miso_2
);
	parameter BIT_WIDTH = 32;
	parameter DECIMAL_PT = 16;
	parameter N_SAMPLES = 8;
	input wire clk;
	input wire reset;
	input wire cs;
	input wire sclk;
	input wire mosi;
	output wire miso;
	input wire cs_2;
	input wire sclk_2;
	input wire mosi_2;
	output wire miso_2;
	wire push_en_1;
	wire pull_en_1;
	wire [BIT_WIDTH + 1:0] push_msg_1;
	wire [BIT_WIDTH - 1:0] pull_msg_1;
	wire pull_msg_val_1;
	wire pull_msg_spc_1;
	wire push_en_2;
	wire pull_en_2;
	wire [BIT_WIDTH + 1:0] push_msg_2;
	wire [BIT_WIDTH - 1:0] pull_msg_2;
	wire pull_msg_val_2;
	wire pull_msg_spc_2;
	wire [BIT_WIDTH - 1:0] recv_msg_a_1;
	wire recv_rdy_a_1;
	wire recv_val_a_1;
	wire [BIT_WIDTH - 1:0] send_msg_a_2;
	wire send_rdy_a_2;
	wire send_val_a_2;
	wire [(N_SAMPLES * BIT_WIDTH) - 1:0] recv_msg_s;
	wire recv_rdy_s;
	wire recv_val_s;
	wire [BIT_WIDTH - 1:0] send_msg_s;
	wire send_rdy_s;
	wire send_val_s;
	wire [BIT_WIDTH - 1:0] recv_msg_d;
	wire recv_rdy_d;
	wire recv_val_d;
	wire [(N_SAMPLES * BIT_WIDTH) - 1:0] send_msg_d;
	wire send_rdy_d;
	wire send_val_d;
	wire minion1_parity;
	wire minion2_parity;
	wire adapter1_parity;
	wire adapter2_parity;
	SPI_minion_components_SPIMinionVRTL #(.nbits(BIT_WIDTH + 2)) minion1(
		.clk(clk),
		.cs(cs),
		.miso(miso),
		.mosi(mosi),
		.reset(reset),
		.sclk(sclk),
		.pull_en(pull_en_1),
		.pull_msg({pull_msg_val_1, pull_msg_spc_1, pull_msg_1}),
		.push_en(push_en_1),
		.push_msg(push_msg_1),
		.parity(minion1_parity)
	);
	SPI_minion_components_SPIMinionAdapterVRTL #(
		.nbits(BIT_WIDTH + 2),
		.num_entries(N_SAMPLES)
	) adapter1(
		.clk(clk),
		.reset(reset),
		.pull_en(pull_en_1),
		.pull_msg_val(pull_msg_val_1),
		.pull_msg_spc(pull_msg_spc_1),
		.pull_msg_data(pull_msg_1),
		.push_en(push_en_1),
		.push_msg_val_wrt(push_msg_1[BIT_WIDTH + 1]),
		.push_msg_val_rd(push_msg_1[BIT_WIDTH]),
		.push_msg_data(push_msg_1[BIT_WIDTH - 1:0]),
		.recv_msg(recv_msg_a_1),
		.recv_val(recv_val_a_1),
		.recv_rdy(recv_rdy_a_1),
		.send_msg(recv_msg_d),
		.send_val(recv_val_d),
		.send_rdy(recv_rdy_d),
		.parity(adapter1_parity)
	);
	DeserializerVRTL #(
		.BIT_WIDTH(BIT_WIDTH),
		.N_SAMPLES(N_SAMPLES)
	) deserializer(
		.clk(clk),
		.reset(reset),
		.recv_msg(recv_msg_d),
		.recv_val(recv_val_d),
		.recv_rdy(recv_rdy_d),
		.send_msg(send_msg_d),
		.send_val(send_val_d),
		.send_rdy(send_rdy_d)
	);
	FFTVRTL #(
		.BIT_WIDTH(BIT_WIDTH),
		.DECIMAL_PT(DECIMAL_PT),
		.N_SAMPLES(N_SAMPLES)
	) FFT(
		.clk(clk),
		.reset(reset),
		.recv_msg(send_msg_d),
		.recv_val(send_val_d),
		.recv_rdy(send_rdy_d),
		.send_msg(recv_msg_s),
		.send_val(recv_val_s),
		.send_rdy(recv_rdy_s)
	);
	SerializerVRTL #(
		.BIT_WIDTH(BIT_WIDTH),
		.N_SAMPLES(N_SAMPLES)
	) serializer(
		.clk(clk),
		.reset(reset),
		.recv_msg(recv_msg_s),
		.recv_val(recv_val_s),
		.recv_rdy(recv_rdy_s),
		.send_msg(send_msg_s),
		.send_val(send_val_s),
		.send_rdy(send_rdy_s)
	);
	SPI_minion_components_SPIMinionAdapterVRTL #(
		.nbits(BIT_WIDTH + 2),
		.num_entries(N_SAMPLES)
	) adapter2(
		.clk(clk),
		.reset(reset),
		.pull_en(pull_en_2),
		.pull_msg_val(pull_msg_val_2),
		.pull_msg_spc(pull_msg_spc_2),
		.pull_msg_data(pull_msg_2),
		.push_en(push_en_2),
		.push_msg_val_wrt(push_msg_2[BIT_WIDTH + 1]),
		.push_msg_val_rd(push_msg_2[BIT_WIDTH]),
		.push_msg_data(push_msg_2[BIT_WIDTH - 1:0]),
		.recv_msg(send_msg_s),
		.recv_val(send_val_s),
		.recv_rdy(send_rdy_s),
		.send_msg(send_msg_a_2),
		.send_val(send_val_a_2),
		.send_rdy(send_rdy_a_2),
		.parity(adapter2_parity)
	);
	SPI_minion_components_SPIMinionVRTL #(.nbits(BIT_WIDTH + 2)) minion2(
		.clk(clk),
		.cs(cs_2),
		.miso(miso_2),
		.mosi(mosi_2),
		.reset(reset),
		.sclk(sclk_2),
		.pull_en(pull_en_2),
		.pull_msg({pull_msg_val_2, pull_msg_spc_2, pull_msg_2}),
		.push_en(push_en_2),
		.push_msg(push_msg_2),
		.parity(minion2_parity)
	);
	assign recv_val_a_1 = 0;
	assign recv_msg_a_1 = 0;
	assign send_rdy_a_2 = 0;
endmodule
module FFTSPIMinionRTL (
	clk,
	reset,
	cs,
	cs_2,
	miso,
	miso_2,
	mosi,
	mosi_2,
	sclk,
	sclk_2,
	io_oeb

);


	input wire [0:0] clk;
	input wire [0:0] reset;
	input wire [0:0] cs;
	input wire [0:0] cs_2;
	output wire [0:0] miso;
	output wire [0:0] miso_2;
	input wire [0:0] mosi;
	input wire [0:0] mosi_2;
	input wire [0:0] sclk;
	input wire [0:0] sclk_2;
	output wire [1:0] io_oeb;
	assign io_oeb = 2'b00;
	minion_FFT_FFTSPIMinionVRTL v(
		.clk(clk),
		.reset(reset),
		.cs(cs),
		.cs_2(cs_2),
		.miso(miso),
		.miso_2(miso_2),
		.mosi(mosi),
		.mosi_2(mosi_2),
		.sclk(sclk),
		.sclk_2(sclk_2)
	);
endmodule
