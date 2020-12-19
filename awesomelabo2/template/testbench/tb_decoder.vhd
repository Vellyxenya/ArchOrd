library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_decoder is
end;

architecture bench of tb_decoder is

    -- declaration of register_file interface
    -- INSERT COMPONENT DECLARATION HERE

	component decoder is
    port(
        address : in  std_logic_vector(15 downto 0);
        cs_LEDS : out std_logic;
        cs_RAM  : out std_logic;
        cs_ROM  : out std_logic
    );
	end component;

	signal address : std_logic_vector(15 downto 0);
	signal cs_LEDS, cs_RAM, cs_ROM : std_logic; 

begin

    -- register_file instance
    -- INSERT REGISTER FILE INSTANCE HERE
	decoder_0 : decoder
	port map(
		address => address,
		cs_LEDS => cs_LEDS,
        cs_RAM  => cs_RAM,
        cs_ROM  => cs_ROM
	);

    process
    begin

		address <= std_logic_vector(to_unsigned(0, 16));
		wait for 20 ns;

		address <= std_logic_vector(to_unsigned(3001, 16));
		wait for 20 ns;

		address <= std_logic_vector(to_unsigned(4092, 16));
		wait for 20 ns;


		address <= std_logic_vector(to_unsigned(4096, 16));
		wait for 20 ns;

		address <= std_logic_vector(to_unsigned(8000, 16));
		wait for 20 ns;

		address <= std_logic_vector(to_unsigned(8188, 16));
		wait for 20 ns;


		address <= std_logic_vector(to_unsigned(8192, 16));
		wait for 20 ns;

		address <= std_logic_vector(to_unsigned(8193, 16));
		wait for 20 ns;

		address <= std_logic_vector(to_unsigned(8204, 16));
		wait for 20 ns;


		address <= std_logic_vector(to_unsigned(8208, 16));
		wait for 20 ns;

		address <= std_logic_vector(to_unsigned(65532, 16));
		wait for 20 ns;

		address <= std_logic_vector(to_unsigned(4093, 16));
		wait for 20 ns;

		wait;
    end process;
end bench;
