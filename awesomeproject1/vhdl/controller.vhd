library ieee;
use ieee.std_logic_1164.all;

entity controller is
    port(
        clk        : in  std_logic;
        reset_n    : in  std_logic;
        -- instruction opcode
        op         : in  std_logic_vector(5 downto 0);
        opx        : in  std_logic_vector(5 downto 0);
        -- activates branch condition
        branch_op  : out std_logic;
        -- immediate value sign extention
        imm_signed : out std_logic;
        -- instruction register enable
        ir_en      : out std_logic;
        -- PC control signals
        pc_add_imm : out std_logic;
        pc_en      : out std_logic;
        pc_sel_a   : out std_logic;
        pc_sel_imm : out std_logic;
        -- register file enable
        rf_wren    : out std_logic;
        -- multiplexers selections
        sel_addr   : out std_logic;
        sel_b      : out std_logic;
        sel_mem    : out std_logic;
        sel_pc     : out std_logic;
        sel_ra     : out std_logic;
        sel_rC     : out std_logic;
        -- write memory output
        read       : out std_logic;
        write      : out std_logic;
        -- alu op
        op_alu     : out std_logic_vector(5 downto 0)
    );
end controller;

architecture synth of controller is
	type state_type is (FETCH1, FETCH2, DECODE, I_OP, I_OPU, R_OP, R_OPI, STORE, BREAK, LOAD1, LOAD2, BRANCH, CALL, CALLR, JMP, JMPI);
	signal state, next_state : state_type;

begin

-- FSM States :
	-- reset_n initializes FSM to FETCH1 (async)
state_p : process(clk, reset_n)
begin
	if (reset_n = '0') then
		state <= FETCH1;
	elsif(rising_edge(clk)) then
		state <= next_state;
	end if;
end process;

fsm_p : process(state, op)
begin

branch_op 	<= '0';
imm_signed 	<= '0';
ir_en 		<= '0';
pc_add_imm 	<= '0';
pc_en   	<= '0';
pc_sel_a   	<= '0';
pc_sel_imm 	<= '0';
rf_wren    	<= '0';
sel_addr   	<= '0';
sel_b     	<= '0';
sel_mem   	<= '0';
sel_pc     	<= '0';
sel_ra   	<= '0';
sel_rC   	<= '0';
read      	<= '0';
write     	<= '0';

next_state 	<= state;

case state is
-- FETCH1 :
	-- set address
	-- set read
	when FETCH1 =>
		read <= '1';
		next_state <= FETCH2;

-- FETCH2 :
	-- get rddata (instruction word is read)
	-- it is saved in IR => need to set ir_en
	-- set en_pc to enable PC
	when FETCH2 => 
		pc_en <= '1';
		ir_en <= '1';
		next_state <= DECODE;

-- DECODE :
	-- read opcode of current instruction (in IR) to identify the current instruction
	-- This is used to determine next Execute state (R_OP/I_OP/STORE/BREAK/LOAD1)
	when DECODE =>
		if(op = "111010") then -- 0x3A
			if(opx = "110100") then -- 0x34
				next_state <= BREAK;
			elsif(opx = "011101") then -- 0x1D --callr
				next_state <= CALLR;
			elsif(opx = "001101" or opx = "000101") then -- 0x0D-jmp or 0x05-ret
				next_state <= JMP;
			elsif(opx = "010010" or opx = "011010" or opx = "111010" or opx = "000010") then
				next_state <= R_OPI;
			else
				next_state <= R_OP;
			end if;
		elsif(op = "010111") then -- 0x17
			next_state <= LOAD1;
		elsif(op = "010101") then -- 0x15
			next_state <= STORE;

		-- 0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x36
		elsif(op = "000110" or op = "001110" or op = "010110" or op = "011110"
			or op = "100110" or op = "101110" or op = "110110") then 
			next_state <= BRANCH;

		elsif(op = "000000") then -- 0x00 call
			next_state <= CALL;

		elsif(op = "000001") then -- 0x01 jmpi
			next_state <= JMPI;
		
		elsif(op = "001100" or op = "010100" or op = "011100" or op = "101000" or op = "110000") then
			next_state <= I_OPU;
		else
			next_state <= I_OP;
		end if;

-- I_OP :
	-- I-Type instruction
	-- A : (31 downto 27), register operand
	-- B : (26 downto 22), destination register
	-- IMM16 : (21 downto 6), 16-bit immediate value
	-- OP : opcode of instruction

	-- set op_alu signal to perform required operation in ALU (depends on current instruction)
	-- result of ALU saved in Register File
	when I_OP =>
		imm_signed <= '1';
		rf_wren <= '1';
		next_state <= FETCH1;

	when I_OPU =>
		rf_wren <= '1';
		next_state <= FETCH1;

-- R_OP :
	-- R-Type instruction
	-- A : (31 downto 27), register operand 1
	-- B : (26 downto 22), register operand 2
	-- C : (21 downto 17), destination register
	-- OPX : (16 downto 11), actual opcode
	-- IMM5 : (10 downto 6), 5-bit immediate value only used in some instructions
	-- OP : (5 downto 0), always set to 0x3A, identifies the R-Type instruction
	-- 0x3A = 0b0011'1010

	-- set op_alu to perform required operation
	-- register b is selected as 2nd operand 
	-- result of ALU saved in Register File
	-- set sel_b to control multiplexer output
	-- set sel_rC to select the write address (aw)
	when R_OP =>
		sel_b <= '1';
		sel_rC <= '1';
		rf_wren <= '1';
		next_state <= FETCH1;

	when R_OPI =>
		--sel_b <= '1';
		sel_rC <= '1';
		rf_wren <= '1';
		next_state <= FETCH1;

-- STORE :
	-- I-Type instruction with OP = 0x15
	-- ALU computes memory address
	-- set write signal to start write process
	-- data to write is in register b (an output of the register file)
	when STORE =>
		write <= '1';
		sel_addr <= '1';
		imm_signed <= '1';
		next_state <= FETCH1;

-- BREAK :
	-- R-Type instruction, OPX = 0x34
	-- Must stop the whole CPU execution (dead end state)
	when BREAK =>
		next_state <= BREAK;
	
-- LOAD1 :
	-- I-type instruction
	-- OP = 0x17

	-- address to read is computed by ALU
	-- set read signal to start a read process
	-- set sel_addr signal to select memory address (from either PC or result of ALU)
	when LOAD1 =>
		read <= '1';
		sel_addr <= '1';
		imm_signed <= '1';
		next_state <= LOAD2;

-- LOAD2 :
	-- memory data is writte to register file at address specified by B (26 downto 22)
	-- sel_mem is set to write to register file from either result of ALU or rddata input
	when LOAD2 =>
		sel_mem <= '1';
		rf_wren <= '1';
		next_state <= FETCH1;

-- BRANCH :
	when BRANCH =>
		sel_b <= '1';
		branch_op <= '1';
		pc_add_imm <= '1';
		next_state <= FETCH1;	
		if(op = "000110") then -- 0x06 [br label] (I-type)
			pc_en <= '1';
		end if;

-- CALL :
	when CALL =>
		rf_wren <= '1';
		pc_en <= '1';
		sel_pc <= '1';
		sel_ra <= '1';
		pc_sel_imm <= '1';
		next_state <= FETCH1;

-- CALLR :
	when CALLR =>
		rf_wren <= '1';
		pc_en <= '1';
		sel_pc <= '1';
		sel_ra <= '1';
		pc_sel_a <= '1';
		next_state <= FETCH1;

-- JMP :
	when JMP =>
		pc_en <= '1';
		pc_sel_a <= '1';
		next_state <= FETCH1;

-- JMPI :
	when JMPI =>
		pc_en <= '1';
		pc_sel_imm <= '1';
		next_state <= FETCH1;

	end case;
end process;

op_alu_gen_p : process(opx, op)
begin

-- generate op-alu signals 
case op is
	when "010111" => -- 0x17 (load)
		op_alu <= "000000"; -- ADD A and signed immediate value
	when "010101" => -- 0x15 (store)
		op_alu <= "000000"; -- ADD A and signed immediate value
	when "111010" => -- 0x3A (R-Type)
		case opx is
			when "001110" => -- and op (0x0E)
				op_alu <= "100001"; -- AND opcode
			when "011011" => -- srl op (0x1B)
				op_alu <= "110011"; -- SRL opcode
			when "110001" =>--0x31
				op_alu <="000000"; -- add
			when "111001" =>--0x39
				op_alu <="001000"; -- substraction
			when "001000" =>--0x08
				op_alu <="011001"; -- less or equal 
			when "010000" =>--0x10
				op_alu <="011010"; -- greater than
			when "000110" =>--0x06
				op_alu <="100000"; -- nor
			when "010110" =>--0x16
				op_alu <="100010"; -- or
			when "011110" =>--0x1E
				op_alu <="100011"; -- xnor
			when "010011" =>--0x13
				op_alu <="110010"; -- shift left
			when "111011" =>--0x3B
				op_alu <="110111"; -- sra

			--Register Operations
			when "010010" => -- slli (0x12)
				op_alu <= "110010";
			when "011010" => -- srli (0x1A)
				op_alu <= "110011";
			when "111010" => -- srai (0x3A)
				op_alu <= "110111";

			when "011000" => -- cmpne (0x18)
				op_alu <= "011011";
			when "100000" => -- cmpeq (0x20)
				op_alu <= "011100";
			when "101000" => -- cmpleu (0x28)
				op_alu <= "011101";
			when "110000" => -- cmpgtu (0x30)
				op_alu <= "011110";
			when "000011" => -- rol (0x03)
				op_alu <= "110000";
			when "001011" => -- ror (0x0B)
				op_alu <= "110001";

			when "000010" => -- roli (0x02)
				op_alu <= "110000";

			when others =>
		end case;
	when "001100" => --0x0C
		op_alu <="100001"; -- AND immediate value
	when "010100" =>--0x14
		op_alu <="100010"; -- OR immediate value
	when "011100" =>--0x1C
		op_alu <="100011"; -- XNOR immediate value
	when "001000" =>--0x08
		op_alu <="011001"; -- less or equal signed immediate value
	when "010000" =>--0x10
		op_alu <="011010"; -- greater than signed immediate value
	when "011000" =>--0x18
		op_alu <="011011"; -- not equal to immediate value
	when "100000" =>--0x20
		op_alu <="011100"; -- equal to immediate value
	when "101000" =>--0x28
		op_alu <="011101"; -- less or equal than unsigned
	when "110000" =>--0x30
		op_alu <="011110"; -- greater than unsigned

	--BRANCH
	-- /!\ [br label] is implemented in the BRANCH State /!\
    
    when "000100" => -- 0x04 [addi rB, rA, imm] (I-type)
		op_alu <= "000000"; -- ADD opcode
	when "001110" => --0x0E [ble rA, rB, label]
		op_alu <= "011001";
	when "010110" => --0x16 [bgt rA, rB, label]
		op_alu <= "011010";
	when "011110" => --0x1E [bne rA, rB, label]
		op_alu <= "011011";
	when "100110" => --0x26 [beq rA, rB, label]
		op_alu <= "011100";
	when "101110" => --0x2E [bleu rA, rB, label]
		op_alu <= "011101";
	when "110110" => --0x36 [bgtu rA, rB, label]
		op_alu <= "011110";

	when others =>
		-- do something? default value?
end case;

end process;


end synth;
