library ieee;
use ieee.std_logic_1164.all;

entity IR is
    port(
        clk    : in  std_logic;
        enable : in  std_logic;
        D      : in  std_logic_vector(31 downto 0);
        Q      : out std_logic_vector(31 downto 0)
    );
end IR;

architecture synth of IR is

begin

store_p : process(clk, enable)
begin
	--clocked
	--if enable signal is active, output Q takes data value of input D
	if(rising_edge(clk)) then
		if(enable = '1') then
			Q <= D;
		end if;
	end if;
end process;
		
end synth;
