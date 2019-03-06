library ieee;
use ieee.std_logic_1164.all;

entity test_arm is
end entity test_arm;

architecture arc_test_arm of test_arm is

--declaration des composants:
component arm
port(
       clk          : in std_logic;
       irq0,irq1    : std_logic;
       rst          : in std_logic;
       resultat     : out std_logic_vector(31 downto 0)
);
end component;


--declaration des signaux:
signal      rstt : std_logic;
signal      clkt : std_logic;
signal		irq0T,irq1t: std_logic;
signal		res: std_logic_vector(31 downto 0);


begin
 
--instanciation des composants
arm_1: arm
port map(clk => clkt, irq0 => irq0t, irq1 => irq1t, rst => rstt, resultat => res);

--processus de simulation
 rstt<='0','1' after 25 ns,'0' after 35 ns;
   generate_clock :process 
   begin 
     clkt<='0';
     wait for 10 ns;
     clkt<='1';
     wait for 10 ns;
     
     
   end process generate_clock;

irq0t<='0';
irq1t<='0';  

end architecture arc_test_arm;


