library ieee;
use ieee.std_logic_1164.all;


Entity MUX21 is 
  generic( N : natural := 32);
  port( A, B : in std_logic_vector(N-1 downto 0);
        COM  : in std_logic;
        S    : out std_logic_vector(N-1 downto 0));
end entity;

Architecture behav of MUX21 is
  Begin
    
    with COM select
      S <= A when '0',
           B when '1',
           (others => '0') when others;
    
end architecture behav;
