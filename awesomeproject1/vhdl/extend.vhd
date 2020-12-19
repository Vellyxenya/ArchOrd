library ieee;
use ieee.std_logic_1164.all;

entity extend is
    port(
        imm16  : in  std_logic_vector(15 downto 0);
        signed : in  std_logic;
        imm32  : out std_logic_vector(31 downto 0)
    );
end extend;

architecture synth of extend is
begin
with signed select imm32 <=
	-- simply pad zeros if the value is unsigned
	"0000000000000000" & imm16 when '0',
	-- or extend with 0's/1's depending on the sign of imm16, i.e. value of most
	-- significant bit : imm16(15)
	(31 downto 16 => imm16(15)) & imm16 when others;
end synth;
