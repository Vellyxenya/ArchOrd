library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity add_sub is
    port(
        a        : in  std_logic_vector(31 downto 0);
        b        : in  std_logic_vector(31 downto 0);
        sub_mode : in  std_logic;
        carry    : out std_logic;
        zero     : out std_logic;
        r        : out std_logic_vector(31 downto 0)
    );
end add_sub;

architecture synth of add_sub is
  signal s_result : std_logic_vector(32 downto 0); -- bit for the carry
  signal s_xor : std_logic_vector(32 downto 0);
  signal s_sub_mode_vector : std_logic_vector(31 downto 0);
  signal s_a_extended : std_logic_vector(32 downto 0);
  constant zeros : std_logic_vector(31 downto 0) := (others => '0');
begin

  xor_p : process(sub_mode)
  begin
    if(sub_mode = '0') then
      s_sub_mode_vector <= (others => '0');
    else 
      s_sub_mode_vector <= (others => '1');
    end if;
  end process;

  s_a_extended <= '0' & a;

  s_xor <= '0' & (b xor s_sub_mode_vector);

  s_result <= std_logic_vector(unsigned(s_a_extended) + unsigned(s_xor) + unsigned'("" & sub_mode));

  carry <= s_result(32);

  zero_p : process(s_result)
  begin
    if(s_result(31 downto 0) = zeros) then
      zero <= '1';
    else
      zero <= '0';
    end if;
  end process;
  
  r <= s_result(31 downto 0);

end synth;
