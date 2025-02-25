library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
    port(
        clk     : in  std_logic;
        cs      : in  std_logic;
        read    : in  std_logic;
        write   : in  std_logic;
        address : in  std_logic_vector(9 downto 0);
        wrdata  : in  std_logic_vector(31 downto 0);
        rddata  : out std_logic_vector(31 downto 0));
end RAM;

architecture synth of RAM is
	type reg_type is array(0 to 1023) of std_logic_vector(31 downto 0);
	signal reg: reg_type;

	signal last_address : std_logic_vector(9 downto 0);
	signal last_cs : std_logic;
	signal last_read : std_logic;

begin

read1_p : process(clk)
begin
	if(rising_edge(clk)) then
		last_address <= address;
		last_cs <= cs;
		last_read <= read;
	end if;
end process;

read2_p : process(last_address, last_read, last_cs)
begin
	
	--if(rising_edge(clk)) then
		rddata <= (others => 'Z');
		if(last_cs = '1' and last_read = '1') then
			rddata <= reg(to_integer(unsigned(last_address)));
		end if;
	--end if;

end process;

write_p : process(clk, write, cs, address)
begin
	if(rising_edge(clk)) then
		if(write = '1' and cs = '1') then
			reg(to_integer(unsigned(address))) <= wrdata;
		end if;
	end if;

end process;


end synth;
