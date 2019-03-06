library ieee;
use ieee.std_logic_1164.all;


Entity MUX41 is 
generic( N : natural := 32);
port( 
    A, B, C, D : in std_logic_vector(n-1 downto 0);
    COM        : in std_logic_vector(1 downto 0);
    S          : out std_logic_vector(n-1 downto 0));
end entity;

Architecture behav of MUX41 is
  Begin

    with COM select
      S <= A when "00",
           B when "01",
           C when "10",
           D when "11",
           (others => '0') when others;

end architecture behav;
