library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller is
    port(
        clk     : in  std_logic;
        reset_n : in  std_logic;
        read    : out std_logic;
        write   : out std_logic;
        address : out std_logic_vector(15 downto 0);
        rddata  : in  std_logic_vector(31 downto 0);
        wrdata  : out std_logic_vector(31 downto 0)
    );
end controller;

architecture synth of controller is
	type state_type is (S0, S1, S2, S3, S4, SIdle);
	signal state, next_state : state_type;
	signal rom_address, next_rom_address : std_logic_vector(15 downto 0);

	signal src_address : std_logic_vector(15 downto 0);
	signal dest_address : std_logic_vector(15 downto 0);
	signal length : unsigned(15 downto 0);

begin


state_p : process(clk, reset_n)
begin
	if (reset_n = '0') then
		state <= S0;
		rom_address <= (others => '0');
	elsif (falling_edge(clk)) then
	--elsif(rising_edge(clk)) then
		state <= next_state;
		rom_address <= next_rom_address;
	end if;
end process;

fsm_p : process(state, rom_address)--, rddata)--, src_address, dest_address)
begin
	read <= '0';
	write <= '0';
	wrdata <= rddata;
	next_state <= state;
	next_rom_address <= rom_address;

	case state is
		when S0 =>
			read <= '1';
			address <= rom_address;
			next_rom_address <= std_logic_vector(unsigned(rom_address) + 4);
			next_state <= S1;
		when S1 =>
			if(to_integer(unsigned(rddata(15 downto 0))) = 0) then
				next_state <= SIdle;
			else
				length <= unsigned(rddata(15 downto 0));
				read <= '1';
				address <= rom_address;
				next_rom_address <= std_logic_vector(unsigned(rom_address) + 4);
				next_state <= S2;
			end if;
		when S2 =>
			src_address <= rddata(31 downto 16);
			dest_address <= rddata(15 downto 0);
			next_state <= S3;
		when S3 =>
			if(length = 0) then
				next_state <= S0;
			else
				length <= length - 1;
				read <= '1';
				address <= src_address;
				src_address <= std_logic_vector(unsigned(src_address) + 4);
				next_state <= S4;
			end if;
		when S4 =>
			write <= '1';
			address <= dest_address;
			dest_address <= std_logic_vector(unsigned(dest_address) + 4);
			next_state <= S3;
		when SIdle =>
			wrdata <= (others => '0');
			next_state <= SIdle;
	end case;
end process;

end synth;