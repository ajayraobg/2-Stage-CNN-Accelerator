//*************************************************//
/*Project: Computational Neural Network Accelerator*/
/*Author: Ajay Rao                   		   */
/*Affiliation: NCSU                   		   */
/*Version: 1.0									*/
/*E-mail:abrao2@ncsu.edu                       */
//*************************************************//


/*Top module that interfaces with SRAM and instantiates 4 Quadrant manipulation modules, 1 Control module and 1 Output nodule*/
module MyDesign(clk,reset,xxx__dut__go,dim__dut__data,bvm__dut__data,dut__dim__write,dut__dim__enable,dut__dim__address,dut__dim__data,dut__bvm__write ,dut__bvm__enable,dut__bvm__address,dut__bvm__data,dut__dom__write,dut__dom__enable,dut__dom__address,dut__dom__data,dut__xxx__finish);

/*Input and output ports as defined by the project specifications*/
input clk;
input reset;
input xxx__dut__go;
input [15:0] dim__dut__data;
input [15:0] bvm__dut__data;
output dut__dim__write;
output dut__dim__enable;
output [8:0] dut__dim__address;
output [15:0] dut__dim__data;
output dut__bvm__write ;
output dut__bvm__enable;
output [9:0] dut__bvm__address;
output [15:0] dut__bvm__data;
output dut__dom__write;
output dut__dom__enable;
output [2:0] dut__dom__address;
output [15:0] dut__dom__data;
output dut__xxx__finish;

/*Nets and Register declarations*/
wire [15:0] top_A;
wire [15:0] top_B;
wire [15:0] top_M;
wire [15:0] top_Z1;
wire [15:0] top_Z2;
wire [15:0] top_Z3;
wire [15:0] top_Z4;
wire top_q1start;
wire top_q2start;
wire top_q3start;
wire top_q4start;
wire top_ostart;
wire [10:0] top_total_count;
wire [3:0] top_count1;
wire [3:0] top_count2;
wire [3:0] top_count3;
wire [3:0] top_count4;

/*Instantiation of control module*/
control u1_control(
.clk(clk),
.reset(reset),
.control_start(xxx__dut__go),
.SRAM_0_readbus(dim__dut__data), //Input data of matrix A read from SRAM
.SRAM_1_readbus(bvm__dut__data), //Input data of matrix B/M read from SRAM
.SRAM_0_WE(dut__dim__write),
.SRAM_0_enable(dut__dim__enable),
.SRAM_0_address(dut__dim__address), //Input matrix A address 
.SRAM_0_writebus(dut__dim__data),
.SRAM_1_WE(dut__bvm__write),
.SRAM_1_enable(dut__bvm__enable),
.SRAM_1_address(dut__bvm__address), //Input matrix B/M address 
.SRAM_1_writebus(dut__bvm__data),
.A_control(top_A), //Input data A that needs to be passed to Q module
.B_control(top_B), //Input data B that needs to be passed to Q module
.M_control(top_M), //Input data M that needs to be passed to O module
.Q1_Start(top_q1start), //Start signal for Q module from Control Module
.Q2_Start(top_q2start), //Start signal for Q module from Control Module
.Q3_Start(top_q3start), //Start signal for Q module from Control Module
.Q4_Start(top_q4start), //Start signal for Q module from Control Module
.O_Start(top_ostart), //Start signal for O module from Control Module
.finish(dut__xxx__finish), //Finish signal from Control Module that signals the end of computation 
.total_element_count(top_total_count));

/*4 instantiations of Q module that work on one quadrant each to produce the Z output (Step 1 of the problem)*/
Q u_q1(.clk(clk),.reset(reset),.Q_Start(top_q1start),.A(top_A),.B(top_B),.Z(top_Z1),.count(top_count1));
Q u_q2(.clk(clk),.reset(reset),.Q_Start(top_q2start),.A(top_A),.B(top_B),.Z(top_Z2),.count(top_count2));
Q u_q3(.clk(clk),.reset(reset),.Q_Start(top_q3start),.A(top_A),.B(top_B),.Z(top_Z3),.count(top_count3));
Q u_q4(.clk(clk),.reset(reset),.Q_Start(top_q4start),.A(top_A),.B(top_B),.Z(top_Z4),.count(top_count4));

/*Instantiation of O_Compute module that works on Z and M vectors to produce the final output O (Step 2 of the problem)*/
O_Compute u1_O(
.clk(clk),
.reset(reset),
.O_start(top_ostart), //Signal to start module O
.Z1(top_Z1),
.Z2(top_Z2),
.Z3(top_Z3),
.Z4(top_Z4),
.M(top_M),
.SRAM_2_WE(dut__dom__write), 
.SRAM_2_enable(dut__dom__enable),
.SRAM_2_address(dut__dom__address), //Output O address to be written
.SRAM_2_writebus(dut__dom__data), //Output O data to be written
.element_cnt(top_total_count),
.cnt(top_count1));

endmodule

/***************************************************************************************************************************************************************************************************************************************************************************************/

/*Control module*/

module control(clk,reset,control_start,SRAM_0_readbus,SRAM_1_readbus,SRAM_0_WE,SRAM_0_enable,SRAM_0_address,SRAM_0_writebus,SRAM_1_WE,SRAM_1_enable,SRAM_1_address,SRAM_1_writebus,A_control,B_control,M_control,Q1_Start,Q2_Start,Q3_Start,Q4_Start,O_Start,finish,total_element_count);

/****As per design control module interface with Input memory and B/M vector memory for reading the SRAM contents.
	 The control module is responsible for the address determination logic, data fetching and passing of data to top
	 module. It is also responsible for signalling the end of computation by setting the 'finish' signal high.*****/


/*Input and output ports*/	 
input clk;
input reset;
input control_start;
input [15:0] SRAM_0_readbus;
input [15:0] SRAM_1_readbus;
output reg SRAM_0_WE;
output reg SRAM_0_enable;
output reg [8:0] SRAM_0_address;
output [15:0] SRAM_0_writebus;
output reg SRAM_1_WE;
output reg SRAM_1_enable;
output reg [9:0] SRAM_1_address;
output [15:0] SRAM_1_writebus;
output reg [15:0] A_control;
output reg [15:0] B_control;
output reg [15:0] M_control;
output  Q1_Start;
output  Q2_Start;
output  Q3_Start;
output  Q4_Start;
output  O_Start;
output reg finish;
output reg [10:0] total_element_count;

/*Nets and Register declarations*/
reg [15:0] B_reg [0:35]; //36 16-bit registers to store the B vector
reg [6:0] element_counter; //0-35 element count for one quadrant
reg [3:0] im_base_count; //Counter for selecting base address for input matrix A
reg [6:0] b_counter; //Counters for selecting address for B vector
reg [4:0] mbase_counter; //Counters for selecting base address of M vector 
reg [7:0] moffset_counter; //Counters for selecting offset address of M vector 
reg[1:0] control_CurrentState, control_NextState; //State variables
reg start_counter; //Signal to start the counter
reg start_a; //Signal to start fetching A matrix values
reg [6:0] i;
/*Registers to hold the offset and base address of A,B and M vectors*/
reg [8:0] im_offset; 
reg [9:0] m_base;
reg [9:0] m_offset;
reg [8:0] im_base;
reg [9:0] b_base;
reg [9:0] b_offset;

assign SRAM_0_writebus = 0; //Set write bus of SRAM0 and 1 to 0 as we are not writing any values to these SRAMs.
assign SRAM_1_writebus = 0;

parameter [1:0] //synopsys enum states
Idle = 2'b01,
Q1 = 2'b10;

/***Combinational block that selects the offset address for A matrix elements based on the counter values***/
always@(element_counter)
begin
 case(element_counter)
  7'd0:im_offset = 9'h00;
  7'd1:im_offset = 9'h01;
  7'd2:im_offset = 9'h02;
  7'd3:im_offset = 9'h10;
  7'd4:im_offset = 9'h11;
  7'd5:im_offset = 9'h12;
  7'd6:im_offset = 9'h20;
  7'd7:im_offset = 9'h21;
  7'd8:im_offset = 9'h22;
  7'd9:im_offset = 9'h03;
  7'd10:im_offset = 9'h04;
  7'd11:im_offset = 9'h05;
  7'd12:im_offset = 9'h13;
  7'd13:im_offset = 9'h14;
  7'd14:im_offset = 9'h15;
  7'd15:im_offset = 9'h23;
  7'd16:im_offset = 9'h24;
  7'd17:im_offset = 9'h25;
  7'd18:im_offset = 9'h30;
  7'd19:im_offset = 9'h31;
  7'd20:im_offset = 9'h32;
  7'd21:im_offset = 9'h40;
  7'd22:im_offset = 9'h41;
  7'd23:im_offset = 9'h42;
  7'd24:im_offset = 9'h50;
  7'd25:im_offset = 9'h51;
  7'd26:im_offset = 9'h52;
  7'd27:im_offset = 9'h33;
  7'd28:im_offset = 9'h34;
  7'd29:im_offset = 9'h35;
  7'd30:im_offset = 9'h43;
  7'd31:im_offset = 9'h44;
  7'd32:im_offset = 9'h45;
  7'd33:im_offset = 9'h53;
  7'd34:im_offset = 9'h54;
  7'd35:im_offset = 9'h55;
  default im_offset = 9'h00;
 endcase
end

/***Combinational block that selects the base address for A matrix elements based on the counter values***/
always@(im_base_count)
begin 
  case(im_base_count)
	4'b0000: im_base = 9'h00;
	4'b0001: im_base = 9'h06;
	4'b0010: im_base = 9'h60;
	4'b0011: im_base = 9'h66;
	default: im_base = 9'h00;
  endcase
end

/***Combinational block that selects the address for B matrix elements based on the counter values***/
always@(b_counter)
begin
 case(b_counter)
	7'd0: b_base = 10'h00;
	7'd1: b_base = 10'h01;
	7'd2: b_base = 10'h02;
	7'd3: b_base = 10'h03;
	7'd4: b_base = 10'h04;
	7'd5: b_base = 10'h05;
	7'd6: b_base = 10'h06;
	7'd7: b_base = 10'h07;
	7'd8: b_base = 10'h08;
	7'd9: b_base = 10'h10;
	7'd10: b_base = 10'h11;
	7'd11: b_base = 10'h12;
	7'd12: b_base = 10'h13;
	7'd13: b_base = 10'h14;
	7'd14: b_base = 10'h15;
	7'd15: b_base = 10'h16;
	7'd16: b_base = 10'h17;
	7'd17: b_base = 10'h18;
	7'd18: b_base = 10'h20;
	7'd19: b_base = 10'h21;
	7'd20: b_base = 10'h22;
	7'd21: b_base = 10'h23;
	7'd22: b_base = 10'h24;
	7'd23: b_base = 10'h25;
	7'd24: b_base = 10'h26;
	7'd25: b_base = 10'h27;
	7'd26: b_base = 10'h28;
	7'd27: b_base = 10'h30;
	7'd28: b_base = 10'h31;
	7'd29: b_base = 10'h32;
	7'd30: b_base = 10'h33;
	7'd31: b_base = 10'h34;
	7'd32: b_base = 10'h35;
	7'd33: b_base = 10'h36;
	7'd34: b_base = 10'h37;
	7'd35: b_base = 10'h38;
	default: b_base = 10'h00;
 endcase
end

/***Combinational block that selects the base and offset address for M matrix elements based on the counter values***/
always@(mbase_counter or moffset_counter)
begin
 case(moffset_counter)
	8'd0: m_offset = 10'h00;
	8'd1: m_offset = 10'h01;
	8'd2: m_offset = 10'h04;
	8'd3: m_offset = 10'h05;
	8'd4: m_offset = 10'h02;
	8'd5: m_offset = 10'h03;
	8'd6: m_offset = 10'h06;
	8'd7: m_offset = 10'h07;
	8'd8: m_offset = 10'h08;
	8'd9: m_offset = 10'h09;
	8'd10: m_offset = 10'h0C;
	8'd11: m_offset = 10'h0D;
	8'd12: m_offset = 10'h0A;
	8'd13: m_offset = 10'h0B;
	8'd14: m_offset = 10'h0E;
	8'd15: m_offset = 10'h0F;
	8'd16: m_offset = 10'h010;
	8'd17: m_offset = 10'h011;
	8'd18: m_offset = 10'h014;
	8'd19: m_offset = 10'h015;
	8'd20: m_offset = 10'h012;
	8'd21: m_offset = 10'h013;
	8'd22: m_offset = 10'h016;
	8'd23: m_offset = 10'h017;
	8'd24: m_offset = 10'h018;
	8'd25: m_offset = 10'h019;
	8'd26: m_offset = 10'h01C;
	8'd27: m_offset = 10'h01D;
	8'd28: m_offset = 10'h01A;
	8'd29: m_offset = 10'h01B;
	8'd30: m_offset = 10'h01E;
	8'd31: m_offset = 10'h01F;
	8'd32: m_offset = 10'h020;
	8'd33: m_offset = 10'h021;
	8'd34: m_offset = 10'h024;
	8'd35: m_offset = 10'h025;
	8'd36: m_offset = 10'h022;
	8'd37: m_offset = 10'h023;
	8'd38: m_offset = 10'h026;
	8'd39: m_offset = 10'h027;
	8'd40: m_offset = 10'h028;
	8'd41: m_offset = 10'h029;
	8'd42: m_offset = 10'h02C;
	8'd43: m_offset = 10'h02D;
	8'd44: m_offset = 10'h02A;
	8'd45: m_offset = 10'h02B;
	8'd46: m_offset = 10'h02E;
	8'd47: m_offset = 10'h02F;
	8'd48: m_offset = 10'h030;
	8'd49: m_offset = 10'h031;
	8'd50: m_offset = 10'h034;
	8'd51: m_offset = 10'h035;
	8'd52: m_offset = 10'h032;
	8'd53: m_offset = 10'h033;
	8'd54: m_offset = 10'h036;
	8'd55: m_offset = 10'h037;
	8'd56: m_offset = 10'h038;
	8'd57: m_offset = 10'h039;
	8'd58: m_offset = 10'h03C;
	8'd59: m_offset = 10'h03D;
	8'd60: m_offset = 10'h03A;
	8'd61: m_offset = 10'h03B;
	8'd62: m_offset = 10'h03E;
	8'd63: m_offset = 10'h03F;
	default: m_offset = 10'h00;	
 endcase
 
 case(mbase_counter)
	5'd0: m_base = 10'h40;
	5'd1: m_base = 10'h80;
	5'd2: m_base = 10'hC0;
	5'd3: m_base = 10'h100;
	5'd4: m_base = 10'h140;
	5'd5: m_base = 10'h180;
	5'd6: m_base = 10'h1C0;
	5'd7: m_base = 10'h200;
	default: m_base = 10'h40;
 endcase	
end

/*------------State register (sequential logic)-------------*/
always@(posedge clk or posedge reset)
begin
 if(reset) control_CurrentState <= Idle;
 else control_CurrentState <= control_NextState;
end


/**Master Counter that gets trigerred when the 'Go' signal arrives and is reset after the outputs are written to SRAM**/
always@(posedge clk or posedge reset) 
begin 
 if(reset) //Set counter values to 0 when Reset is high
 begin 
	total_element_count<= 11'b00000000000;	
 end
 else if (start_counter) //Start incrementing count when 'Go' signal arrives (start_counter is set in Idle state upon arrival of 'Go')
 begin
	if(total_element_count == 11'b01001101111) total_element_count <= 11'b00000000000; //Reset counter after finishing writing output
	else total_element_count<= total_element_count + 1'b1; //Increment the counter at every clock edge
 end
end


/**Input matrix A address calculation counters**/
always@(posedge clk or posedge reset) 
begin
 if(reset) //Set counter values to 0 when Reset is high
 begin
	element_counter <= 7'b0000000;
	im_base_count <= 4'b0000;
 end
 else if (start_a) //Start incrementing counters when 'start_a' signal goes high.
  begin
	/**** element_counter is used for calculating the offset value for matrix A address.
		  element_counter is a up-counter, that counts from 0 to 35 (basically the number of elements 
		  in a quadrant). im_base_count is used for calculating the base address for input matrix A.
		  im_base_count also is a up-counter that counts from 0 to 3 (giving us the count for 4 quadrants)
		  Both the counters reset to 0 after reaching the max value.
		  Also both the counters are reset to 0 after the computations are finished and output values 
		  are written to SRAM.****/
   	if(element_counter == 7'b0100011)
        begin
		element_counter <= 7'b0000000;
		if(im_base_count == 4'b0011) im_base_count <= 4'b0000;
		else im_base_count <= im_base_count + 4'b0001;
	end
	else  element_counter <= element_counter+ 7'b0000001;
	if (total_element_count == 11'b01001101111) 
	 begin 
		element_counter <= 7'b0000000;
		im_base_count <= 4'b0000;
	 end
 end
end


/**Input matrix B address calculation counters**/
always@(posedge clk or posedge reset) 
begin 
 if(reset) //Set counter values to 0 when Reset is high
 begin 
	b_counter<= 7'b0000000;
 end
 else if (start_counter) //Start incrementing count when 'Go' signal arrives (start_counter is set in Idle state upon arrival of 'Go')
 begin
 	/**** b_counter is used for calculating the address for matrix B elements.
		  b_counter is a up-counter, that counts from 0 to 36 (basically the number of elements 
		  in Matrix B). 
		  Also the counter is reset to 0 after the computations are finished and output values 
		  are written to SRAM.****/
	if(b_counter == 7'b0100100) b_counter <= 7'b0000000;	
	else if(total_element_count == 11'b01001101111) b_counter<= 7'b0000000;
	else b_counter<= b_counter + 1'b1;
 end
end


/**Input matrix M address calculation counters*/
always@(posedge clk or posedge reset) 
begin
 if(reset) //Set counter values to 0 when Reset is high
  begin
	mbase_counter <= 5'b00000;
	moffset_counter <= 8'b00000000;
  end
  else if(total_element_count == 11'b01001101111) //Set counter values to 0 when computations are finished and outputs are written to SRAM.
  begin
	mbase_counter <= 5'b00000;
	moffset_counter <= 8'b00000000;
  end
 else
  begin
  	/**** moffset_counter is used for calculating the offset value for vector M address.
		  moffset_counter is a up-counter, that counts from 0 to 63 (basically the number of elements 
		  in one M vector). mbase_counter is used for calculating the base address for vector M.
		  mbase_counter also is a up-counter that counts from 0 to 7 (giving us the count for 8 M vectors)
		  moffset_counter increments after 8 counts of mbase_counter giving us the elements that are present in that 
		  particular offset value of all M vectors (ex: The following code first gives the address for the 1st element	
		  of all M vectors, next 2ns element of all M Vectors and so on until 64th element of all M vectors).
		  Both the counters reset to 0 after reaching the max value.****/
	if(total_element_count>11'b00000101100)
	 begin
		if(mbase_counter == 5'b01000) 
		 begin
			moffset_counter <= moffset_counter+8'b00000001;
			mbase_counter <= 5'b00000;
		 end		
		else mbase_counter<=mbase_counter+5'b00001;
	 end
  end
end


/**Input matrix A fetching**/
always@(posedge clk or posedge reset) 
begin 
 if(reset) //Set register values to 0 when Reset is high
 begin 
	SRAM_0_address <= 9'h00;
	SRAM_0_enable <= 0;
	SRAM_0_WE <= 0;
 end
 /* After start_a sign goes high write the SRAM_0_address register with the address
	calculated by the matrix A address counters and address registers. Also set the 
	SRAM enable pin to 1*/
 else if (start_a) 
  begin
  	SRAM_0_address <= im_base + im_offset;
	SRAM_0_enable <= 1;
	SRAM_0_WE <= 0;
  end
end

/**Vectors B and M fetching**/
always@(posedge clk or posedge reset) 
begin 
 if(reset) //Set register values to 0 when Reset is high
 begin 
	SRAM_1_address <= 10'h00;
	SRAM_1_enable <= 0;
	SRAM_1_WE <= 0;
 end
else if (start_counter)
  begin
   /**After start_counter sign goes high write the SRAM_01_address register with the address
	  calculated by the vector B address counters and address registers. When all the elements of
	  vector B are accessed, start sending the address of vector M. Since there are only 8 elements in one vector M 
	  send a dont care value in the 9th cycle for the SRAM_01_address register. Also set the SRAM enable pin to 1.**/
	if(total_element_count<11'b00000101101)
	 begin	
		SRAM_1_address <= b_base;
	 end
	else
	 begin
		if(mbase_counter == 5'b01000) SRAM_1_address <= 10'hxx;		
		else SRAM_1_address <= m_base + m_offset;
	 end
	SRAM_1_enable <= 1;
	SRAM_1_WE <= 0;		
  end
end


//Matrix A read
always@(posedge clk or posedge reset) 
begin 
  if(reset) A_control<= 16'h00; //Set register value to 0 when Reset is high
  else A_control<= SRAM_0_readbus; //Copy the contents on the SRAM_0_readbus to A_control register
end


//Matrix B read
always@(posedge clk or posedge reset) 
begin 
  if(reset) //Set register values to 0 when Reset is high
   begin
	B_control<= 16'h00;
	i <= 7'b000000;	
   end
  else
   begin
   /** Copy the contents of SRAM_1_readbus for the first 36 cycles to 36 B_reg registers to store the value of vector B.
	   After storing all elements of vector B start sending the stored values on B_control register. The values of one B
	   vector are sent in a loop until one sweep of the input matrix A is done (i.e 144 elements of matrix are fetched). So
	   the entire matrix A is first multiplied with corresponding elements of B0 vector, followed by B1 and so on till B3**/
	if(total_element_count == 11'b01001101111) i <= 7'b000000;		
	else if(total_element_count>11'b00000000000 && total_element_count<11'b00000100101) B_reg[b_counter-1]<= SRAM_1_readbus;
	else if(total_element_count>11'b00000100100 && total_element_count<11'b00010110101)
	 begin
		B_control<= B_reg[i];
		if (i == 7'b0001000) 
		 begin
			i <= 7'b0000000;
		        if(total_element_count == 11'b00010110100) i <= 7'b0001001;
		 end
		else i <= i+7'b0000001;
	 end	 
	else if(total_element_count>11'b00010110100 && total_element_count<11'b00101000101) 	 
	 begin 
		B_control<= B_reg[i];
		if(i == 7'b0010001) 
		 begin
			i <= 7'b0001001;
		 	if(total_element_count == 11'b00101000100) i <= 7'b0010010;
		 end
		else i <= i+7'b0000001;
 	 end
	else if(total_element_count>11'b00101000100 && total_element_count<11'b00111010101) 	 
	 begin 
		B_control<= B_reg[i];
		if(i == 7'b0011010) 
		 begin
			i <= 7'b0010010;
			if(total_element_count == 11'b00111010100) i <= 7'b0011011;
		 end
		else i <= i+7'b0000001;
 	 end
	else if(total_element_count>11'b00111010100 && total_element_count<11'b01001100101) 	 
	 begin 
		B_control<= B_reg[i];
		if(i == 7'b100011) i <= 7'b0011011;
		else i <= i+7'b0000001;
 	 end	 
   end
end


//Matrix M Read
always@(posedge clk or posedge reset) 
begin
 if(reset) M_control<=16'h00; //Set register values to 0 when Reset is high
 else if(total_element_count>11'b00000101101 && mbase_counter != 5'b00000) M_control<= SRAM_1_readbus; //Copy the contents on the SRAM_1_readbus to M_control register
end

/*----------------Next state logic------------------*/
always@(total_element_count)
begin
	if(total_element_count < 11'b00000100100) start_a = 1'b0;
	else start_a = 1'b1;
end

always@(*) //Control FSM
begin
 case(control_CurrentState)
  Idle: begin     
     	if(!control_start) //Stay in idle state until 'Go' signal is recieved.
          begin 
			control_NextState = Idle;
			finish = 1'b1; //Set finish to 1 in the idle state
			start_counter = 1'b0; //Reset the start_counter
          end
     	else 
	begin 
		/*If 'Go' signal is recieved transition to next state, start_counter signal is made high and finish is de-asserted*/
		control_NextState = Q1; 
		start_counter = 1'b1;
		finish = 1'b0;
	end
       end
  Q1: begin
		finish = 1'b0;
		start_counter = 1'b1;
		/**When the outputs are written to the SRAM, transition to Idle state to set finish as 1 and wait for next 'Go' signal**/
		if (total_element_count == 11'b01001101111) control_NextState = Idle;  
		else control_NextState = Q1; //Until computations are finished, stay in this state.		
      end
  default: begin 
		finish = 1'b0;
		start_counter = 1'b0;
		control_NextState = Idle;
	   end
 endcase

end

/*Set the start signals for each quadrant and output module high based on the cycle count*/
assign Q1_Start = (total_element_count == 37); 
assign Q2_Start = (total_element_count == 73); 
assign Q3_Start = (total_element_count == 109); 
assign Q4_Start = (total_element_count == 145); 
assign O_Start = (total_element_count > 46);

endmodule


/***************************************************************************************************************************************************************************************************************************************************************************************/

//Q module

module Q(clk,reset,Q_Start,A,B,Z,count);

/*Input and output ports*/	 
input clk;
input reset;
input Q_Start;
input signed [15:0] A;
input signed [15:0] B;
output reg signed [15:0] Z;
output reg [3:0] count;

/*Nets and Register declarations*/
wire signed [31:0] c_q;
reg [31:0] z_q;
wire signed [31:0] mac_q;


assign c_q = (count == 8) ? 0 : z_q;  //Clear the contents of c_q when count is 8 or else assign it with z_q
assign mac_q = A*B + c_q; //Multiply the current values of A and B and accumulate the result with the contents of c_q

/* Implemet a counter that down counts from 8 to 0 (for the 9 count of each Z value */
always @(posedge clk)
begin
   if(reset || Q_Start || count == 0) //Clear count to 0 whenever reset is high, or the counter expires or Q_Start is high	
      count <= 8;
   else
      count <= count -1;
end

/*Assign z_q with the contents of mac_q. Clear z_q when reset is high or Q_start is high*/
always @(posedge clk)
begin
   if(reset || Q_Start)
      z_q <= 0;
   else
      z_q <= mac_q;
end

/**Truncate the values of z_q before assigning it to Z register. If the value is negative, truncate the value to 0
   else if the value is positive, assign the 16 MSB bits for the Z register.**/
always@(*)
begin 	 
      if(z_q[31] == 1'b1)
         Z <= 0;
      else
         Z <= z_q[31:16];
end

endmodule


/***************************************************************************************************************************************************************************************************************************************************************************************/
/**O module -  The Output module calculates the output by multiplying the new Z value passed by Q module with vector M values.
   It has 8 internal registers that keep accumulatingthese products until 64 products are computed**/

module O_Compute(clk,reset,O_start,Z1,Z2,Z3,Z4,M,SRAM_2_WE,SRAM_2_enable,SRAM_2_address,SRAM_2_writebus,element_cnt,cnt);

/*Input and output ports*/	 
input clk;
input reset;
input O_start;
input signed [15:0] Z1;
input signed [15:0] Z2;
input signed [15:0] Z3;
input signed [15:0] Z4;
input signed [15:0] M;
output reg SRAM_2_WE;
output reg SRAM_2_enable;
output reg [2:0] SRAM_2_address;
output reg [15:0] SRAM_2_writebus;
input [10:0] element_cnt;
input [3:0] cnt;

/*Nets and Register declarations*/
reg [15:0] O_reg [0:7]; //8 16 bit registers to hold the 8 output elements
/*8 32 bit registers to store the intermediate values of the output elements*/
reg signed [31:0] R1;
reg signed [31:0] R2;
reg signed [31:0] R3;
reg signed [31:0] R4;
reg signed [31:0] R5;
reg signed [31:0] R6;
reg signed [31:0] R7;
reg signed [31:0] R8;
/*32 bit register to hold the Z value for 8 cycles*/
reg signed [31:0] O_int;

always@(posedge clk)
 begin
 if(reset || element_cnt == 11'b01001101111)
  begin
  	R1 <= 0;
	O_int <= 0;
  end
 else
  begin
  /**Calculate the product of Z and first element of M and store that value in R1 register.Also store the value of Z in O_int register so that it can be used for the
	 next 7 cycles to caluclate the other products. Z values are taken from the appropriate quadrants depending upon the global
	 counter. **/
   if(O_start == 1)
    begin
	if(element_cnt<11'd82 || (element_cnt>11'd189 && element_cnt<11'd226)|| (element_cnt>11'd333 && element_cnt<11'd370) || (element_cnt>11'd477 && element_cnt<11'd514))
	begin
		if(cnt == 8)
		begin
			O_int <= Z1;
			R1 <= Z1*M + R1;
		end
	end
	else if ((element_cnt>11'd81 && element_cnt<11'd118) || (element_cnt>11'd225 && element_cnt<11'd262)|| (element_cnt>11'd369 && element_cnt<11'd406)|| (element_cnt>11'd513 && element_cnt<11'd550) )
	 begin
	 	if(cnt == 8)
	 	begin
	 		O_int <= Z2;
			R1 <= Z2*M + R1;	
	 	end
	 end
	 else if ((element_cnt>11'd117 && element_cnt<11'd154) || (element_cnt>11'd261 && element_cnt<11'd298) || (element_cnt>11'd405 && element_cnt<11'd442)|| (element_cnt>11'd549 && element_cnt<11'd586))
	 begin
	 	if(cnt == 8)
	 	begin
	 		O_int <= Z3;
			R1 <= Z3*M + R1;	
	 	end
	 end
  	else if ((element_cnt>11'd153 && element_cnt<11'd190)|| (element_cnt>11'd297 && element_cnt<11'd334)|| (element_cnt>11'd441 && element_cnt<11'd478)|| (element_cnt>11'd585 && element_cnt<11'd622))
	 begin
	 	if(cnt == 8)
	 	begin
	 		O_int <= Z4;
			R1 <= Z4*M + R1;	
	 	end		
     end 
   end
  end 	
 end
 
 
always@(posedge clk)
 begin
	 if(reset || element_cnt == 11'b01001101111) //Clear all the registers once computation is finished for the given set of input elements
		begin
			R2 <= 0;
			R3 <= 0;
			R4 <= 0;
			R5 <= 0;
			R6 <= 0;
			R7 <= 0;
			R8 <= 0;
		end
	else
   	 begin
	 /**For the next 7 cycles use the Z value stored in O_int register to multiply with new M values. Accumulate all the 
	    produt until we have finished accumulating 64 products.**/
		if(cnt == 7) R2 <= O_int*M + R2;
	   	else if(cnt == 6) R3 <= O_int*M + R3;
		else if(cnt == 5) R4 <= O_int*M + R4;
		else if(cnt == 4) R5 <= O_int*M + R5;
		else if(cnt == 3) R6 <= O_int*M + R6;
		else if(cnt == 2) R7 <= O_int*M + R7;
		else if(cnt == 1) R8 <= O_int*M + R8;
	end
 end

/*Writing output values to SRAM 2*/ 
always @(posedge clk)
  begin
	if(reset || element_cnt == 11'd623) //Set register values to 0 when Reset is high or the computation cycle is finished
	begin
		SRAM_2_WE <= 0;
		SRAM_2_enable <= 0;
		SRAM_2_address <= 0;
		SRAM_2_writebus <= 0;
	end
	else
	begin
		if(element_cnt == 11'd615) //Write the output value of first element to SRAM 2
		begin
			SRAM_2_address <= 0;
			SRAM_2_writebus <= O_reg[0];
			SRAM_2_WE <= 1'b1; //Set write enable as high for SRAM 2
			SRAM_2_enable <= 1'b1; //Enable SRAM 2
		end
		else if(element_cnt == 11'd616) //Write the output value of second element to SRAM 2
		begin
			SRAM_2_address <= 1;
			SRAM_2_writebus <= O_reg[1];
		end
		else if(element_cnt == 11'd617) //Write the output value of third element to SRAM 2
		begin
			SRAM_2_address <= 2;
			SRAM_2_writebus <= O_reg[2];
		end
		else if(element_cnt == 11'd618) //Write the output value of fourth element to SRAM 2
		begin
			SRAM_2_address <= 3;
			SRAM_2_writebus <= O_reg[3];
		end
		else if(element_cnt == 11'd619) //Write the output value of fifth element to SRAM 2
		begin
			SRAM_2_address <= 4;
			SRAM_2_writebus <= O_reg[4];
		end
		else if(element_cnt == 11'd620) //Write the output value of sixth element to SRAM 2
		begin
			SRAM_2_address <= 5;
			SRAM_2_writebus <= O_reg[5];
		end
		else if(element_cnt == 11'd621) //Write the output value of seventh element to SRAM 2
		begin
			SRAM_2_address <= 6;
			SRAM_2_writebus <= O_reg[6];
		end
		else if(element_cnt == 11'd622) //Write the output value of eigth element to SRAM 2
		begin
			SRAM_2_address <= 7;
			SRAM_2_writebus <= O_reg[7];
		end		
	end
  end
  
  /**Truncate the values of the R registers. If the value is negative, truncate it to 0. If the value is 
     positive assign the 16 MSB bits to the corresponding O_reg registers.**/
  always@(*)
   begin
   	if (R1[31] == 1'b1) O_reg[0] = 0;
   	else O_reg[0] = R1[31:16];
   	if (R2[31] == 1'b1) O_reg[1] = 0;
   	else O_reg[1] = R2[31:16];
   	if (R3[31] == 1'b1) O_reg[2] = 0;
   	else O_reg[2] = R3[31:16];
   	if (R4[31] == 1'b1) O_reg[3] = 0;
   	else O_reg[3] = R4[31:16];
   	if (R5[31] == 1'b1) O_reg[4] = 0;
   	else O_reg[4] = R5[31:16];
   	if (R6[31] == 1'b1) O_reg[5] = 0;
   	else O_reg[5] = R6[31:16];
   	if (R7[31] == 1'b1) O_reg[6] = 0;
   	else O_reg[6] = R7[31:16]; 
   	if (R8[31] == 1'b1) O_reg[7] = 0;
   	else O_reg[7] = R8[31:16];   
   end
 
 endmodule

 /***************************************************************************************************************************************************************************************************************************************************************************************/
