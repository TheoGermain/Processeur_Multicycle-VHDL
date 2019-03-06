library ieee;
use ieee.std_logic_1164.all;

Entity REG32 is Port(
  CLK, RST  : in std_logic;
  DATAIN    : in std_logic_vector(31 downto 0);
  DATAOUT   : out std_logic_vector(31 downto 0));
end entity;

Architecture RTL of REG32 is
  signal data : std_logic_vector(31 downto 0);
  Begin

    DATAOUT <= data;

    process(clk, rst)

      begin

        if rst = '1' then

          data <= (others => '0');

        elsif rising_edge(clk) then

          data <= DATAIN;

        end if;

    end process;

end RTL;
