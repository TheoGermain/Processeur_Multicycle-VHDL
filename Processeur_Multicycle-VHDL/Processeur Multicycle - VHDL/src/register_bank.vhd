library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity register_bank is Port(
  CLK        : in std_logic;
  W          : in std_logic_vector(31 downto 0);
  RA, RB, RW : in std_logic_vector(3 downto 0);
  WE         : in std_logic;
  A, B       : out std_logic_vector(31 downto 0));
end entity;


Architecture RTL of register_bank is
  
  type table is array (15 downto 0) of std_logic_vector(31 downto 0);
  
  -- Fonction d'initialisation 
  function init_banc return table is
  
  variable result : table;
  
  begin
    
    for i in 14 downto 0 loop 
      result(i) := (others =>'0');
    end loop;
    
    result(15) := X"00000030";
    return result;
    
  end init_banc;
  
  -- Declaration et initialisation du Banc de registre 
  signal Banc : table := init_banc;
  
  Begin
  
  A <= Banc(to_integer(unsigned(RA)));
  B <= Banc(to_integer(unsigned(RB)));
  
  process(CLK)
    begin
      
      if rising_edge(clk) then
        if WE ='1' then
          
          Banc(to_integer(unsigned(RW))) <= W;
          
        end if;
      end if;
         
  end process;
  
end RTL;