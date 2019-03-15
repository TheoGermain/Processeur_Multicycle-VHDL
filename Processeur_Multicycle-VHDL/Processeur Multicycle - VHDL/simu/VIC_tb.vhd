library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test_VIC is Port(
  OK : out boolean
  );
end entity;

Architecture TB of test_VIC is
  
  signal CLK, RST             : std_logic;
  signal SERV_IRQ, IRQ0, IRQ1 : std_logic;
  signal IRQ                  : std_logic;
  signal VICPC                : std_logic_vector(31 downto 0);
  
  begin
    
    clocked : process
    begin
      CLK <= '0';
      wait for 10 ns;
      CLK <= '1';
      wait for 10 ns;
    end process;
    
    process
      begin
    
      OK <= True;
      IRQ0 <= '0';
      IRQ1 <= '0';
      RST <= '1';
      wait for 15 ns;
      RST <= '0';
      wait for 5 ns;
    
      if VICPC /= std_logic_vector(to_unsigned(0,32)) and IRQ /= '0' then
        OK <= False;
      else
        OK <= True;
      end if;
      
      wait for 10 ns;
      IRQ0 <= '1';
      wait for 10 ns;
      
      if VICPC /= x"00000009" and IRQ /= '1' then
        OK <= False;
      else
        OK <= True;
      end if;
    
      wait for 10 ns;
      IRQ0 <= '0';
      SERV_IRQ <= '1';
      wait for 10 ns;
      SERV_IRQ <= '0';
    
      if VICPC /= std_logic_vector(to_unsigned(0,32)) and IRQ /= '0' then
        OK <= False;
      else
        OK <= True;
      end if;
    
      wait for 10 ns;
      IRQ1 <= '1';
      wait for 10 ns;
      
      if VICPC /= x"00000015" and IRQ /= '1' then
        OK <= False;
      else
        OK <= True;
      end if;
      
      wait for 10 ns;
      IRQ1 <= '0';
      SERV_IRQ <= '1';
      wait for 10 ns;
      SERV_IRQ <= '0';
    
      if VICPC /= std_logic_vector(to_unsigned(0,32)) and IRQ /= '0' then
        OK <= False;
      else
        OK <= True;
      end if;
    
      wait for 10 ns;
      IRQ0 <= '1';
      IRQ1 <= '1';
      wait for 10 ns;
      
      if VICPC /= x"00000009" and IRQ /= '1' then
        OK <= False;
      else
        OK <= True;
      end if;
      
      wait for 10 ns;
      IRQ0 <= '0';
      IRQ1 <= '0';
      SERV_IRQ <= '1';
      wait for 10 ns;
      SERV_IRQ <= '0';
    
      if VICPC /= std_logic_vector(to_unsigned(0,32)) and IRQ /= '0' then
        OK <= False;
      else
        OK <= True;
      end if;
    
    wait;
  end process;
  
  UTT : entity work.VIC(RTL) port map(CLK => CLK, reset => RST, SERV_IRQ => SERV_IRQ, IRQ0 => IRQ0, IRQ1 => IRQ1, IRQ => IRQ, VICPC => VICPC);
    
end TB;