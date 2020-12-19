library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PC is
    port(
        clk     : in  std_logic;			-- clk signal
        reset_n : in  std_logic;			-- initializes address register to 0
        en      : in  std_logic;			-- enables to switch to next address (i.e. +4 or use immediate value)
        sel_a   : in  std_logic;			-- set reg to value from input a
        sel_imm : in  std_logic;			-- set reg to immediate value shifted to left by 2
        add_imm : in  std_logic;			-- add immediate value to reg instead of adding 4
        imm     : in  std_logic_vector(15 downto 0);	-- immediate value to add to reg if sel_imm is enabled
        a       : in  std_logic_vector(15 downto 0);	-- 16 LSB from output a from register file
        addr    : out std_logic_vector(31 downto 0)	-- current register value extended to 32 bits with 0s
    );
end PC;

architecture synth of PC is
	-- PC holds address of next instruction, stored in 18-bit register,
	-- 2 least significant bits always 0
	signal reg : std_logic_vector(17 downto 0);
begin

increment_p : process(clk, reset_n, en)
begin
	if(reset_n = '0') then
		reg <= (others => '0');
	elsif(rising_edge(clk)) then
		if(en = '1') then
			if(add_imm = '1') then
				reg <= std_logic_vector(signed(reg) + signed(imm));
			elsif(sel_imm = '1') then
				reg <= imm & "00";
			elsif(sel_a = '1') then
				reg <= "00" & a;
			else
				reg <= std_logic_vector(unsigned(reg) + 4);
			end if;
		end if;
	end if;
end process;

addr <= (31 downto 16 => '0') & reg(15 downto 2) & "00";

end synth;
