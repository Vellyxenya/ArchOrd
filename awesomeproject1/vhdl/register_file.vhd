library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file is
	-- /!\ register at address 0 has fixed value 0 /!\
    port(
        clk    : in  std_logic;
        aa     : in  std_logic_vector(4 downto 0);  -- select 1st register to read
        ab     : in  std_logic_vector(4 downto 0);  -- select 2nd register to read
        aw     : in  std_logic_vector(4 downto 0);	 -- address to write to
        wren   : in  std_logic;							 -- enables writing data
        wrdata : in  std_logic_vector(31 downto 0); -- data to write
        a      : out std_logic_vector(31 downto 0); -- 1st data read from register
        b      : out std_logic_vector(31 downto 0)  -- 2nd date read from register
    );
end register_file;

architecture synth of register_file is
	type reg_type is array(0 to 31) of std_logic_vector(31 downto 0);
	-- init all registers to 0 and forbid modification of reg(0) => reg(0) is always 0
	signal reg: reg_type := (others => (others => '0'));
	signal s_enable: boolean;
	
begin
	--reg(0) <= (others => '0'); Why does this have no effect??

	a <= reg(to_integer(unsigned(aa)));
	b <= reg(to_integer(unsigned(ab)));
	
	enable_p : process(wren, aw)
	begin
		if(wren = '1' and to_integer(unsigned(aw)) /= 0) then
			s_enable <= true;
		else
			s_enable <= false;
		end if;
	end process;
	
	write_p : process(clk)
	begin
		--reg(0) <= (others => '0');
		if(rising_edge(clk)) then
			if(s_enable = true) then
				reg(to_integer(unsigned(aw))) <= wrdata;
			end if;
		--else
			--reg(0) <= (others => '0');
		end if;
	end process;
end synth;
