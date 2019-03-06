library ieee;
use ieee.std_logic_1164.all;

Entity imm_extender is 
  generic( N : natural := 8);
  port( E    : in std_logic_vector(N-1 downto 0);
        S    : out std_logic_vector(31 downto 0));
end entity;
  
Architecture RTL of imm_extender is
  Begin
    
    process(E)
      begin
    
      for i in 31 downto N loop
       S(i) <= E(N-1);
      end loop;
    
      for i in 0 to N-1 loop
        S(i) <= E(i);
      end loop;
    
    end process;
    
end RTL;