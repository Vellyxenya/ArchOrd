library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decoder is
    port(
        address : in  std_logic_vector(15 downto 0);
        cs_LEDS : out std_logic;
        cs_RAM  : out std_logic;
        cs_ROM  : out std_logic;
	cs_buttons : out std_logic
    );
end decoder;

architecture synth of decoder is

	subtype ROM_type is integer range 16#0000# to 16#0FFF#;
	subtype RAM_type is integer range 16#1000# to 16#1FFF#;
	subtype LED_type is integer range 16#2000# to 16#200F#;
	subtype BUT_type is integer range 16#2030# to 16#2034#;

begin

decoder_p : process(address)
begin
	cs_LEDS <= '0';
	cs_RAM  <= '0';
	cs_ROM  <= '0';
	cs_buttons <= '0';
	case to_integer(unsigned(address)) is
		when ROM_type => cs_ROM <= '1';
		when RAM_type => cs_RAM <= '1';
		when LED_type => cs_LEDS <= '1';
		when BUT_type => cs_buttons <= '1';
		when others => 
	end case;
end process;

end synth;
