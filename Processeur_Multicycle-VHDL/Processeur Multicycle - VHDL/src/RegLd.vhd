library ieee;
use ieee.std_logic_1164.all;

Entity RegLd is Port(
  DATAIN         : in std_logic_vector(31 downto 0);
  CLK, RST, WE   : in std_logic;
  DATAOUT        : out std_logic_vector(31 downto 0));
end entity;

Architecture RTL of RegLd is
  
  signal data : std_logic_vector(31 downto 0);
  
  Begin
    
    
   DATAOUT <= data; 
    
    Process(CLK, RST)
      begin 
        
        if rst = '1' then
         
          data <= (others => '0');
        
        elsif rising_edge(clk) then
          
          if WE = '1' then
            
            data <= DATAIN;
            
          end if;
    
        end if;
      end process;
    
end RTL;