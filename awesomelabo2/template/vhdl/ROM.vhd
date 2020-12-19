library ieee;
use ieee.std_logic_1164.all;

entity ROM is
    port(
        clk     : in  std_logic;
        cs      : in  std_logic;
        read    : in  std_logic;
        address : in  std_logic_vector(9 downto 0);
        rddata  : out std_logic_vector(31 downto 0)
    );
end ROM;

architecture synth of ROM is

	signal s_out : std_logic_vector(31 downto 0);
	signal s_enable : boolean;

component ROM_Block is
	port
	(
		address		: in std_logic_vector (9 downto 0);
		clock		: in std_logic  := '1';
		q		: out std_logic_vector (31 downto 0)
	);
end component;

begin

rom: ROM_Block port map (	
	address => address,
	clock => clk,
	q => s_out);

enable_p : process(clk, cs, read)
begin
	
	if(rising_edge(clk)) then
		if(cs = '1' and read = '1') then
			s_enable <= true;
		else
			s_enable <= false;
		end if;
	end if;

end process;

read_p : process(s_enable, s_out)
begin
	
	--if(rising_edge(clk)) then
		rddata <= (others => 'Z');
		if(s_enable = true) then
			rddata <= s_out;
		end if;
	--end if;

end process;

end synth;
