library ieee;
use ieee.std_logic_1164.all;

Entity MAE is Port(
  CLK, RST                    : in std_logic;
  IRQ                         : in std_logic;
  INST_MEM                    : in std_logic_vector(31 downto 0);
  INST_REG                    : in std_logic_vector(31 downto 0);
  N                           : in std_logic;
  IRQServ                     : out std_logic;
  PCSel                       : out std_logic_vector(1 downto 0);
  PCWrEn, LRWrEn              : out std_logic;
  AdrSel, MemRden, MemWrEn    : out std_logic;
  IRWrEn, WSel, RegWrEn       : out std_logic;
  ALUSelA                     : out std_logic;
  ALUSelB, ALUOP              : out std_logic_vector(1 downto 0);
  CPSRSel, CPSRWrEn, SPSRWrEn : out std_logic;
  ResWrEn                     : out std_logic);
end entity;

Architecture behav of MAE is 

  type enum_instruction is (MOV, ADDi, ADDr, CMP, LDR, STR, BAL, BLT, BX);
  type state is (ETAT0, ETAT1, ETAT2, ETAT3, ETAT4, ETAT5, ETAT6, ETAT7, ETAT8, ETAT9, ETAT10, ETAT11, ETAT12, ETAT13, ETAT14, ETAT15, ETAT16, ETAT17);
    
  signal instr_courante           : enum_instruction;
  signal ETAT_PRESENT, ETAT_FUTUR : state;
  signal isr                      : std_logic;

  Begin
    
      clocked : process(clk, rst)
        Begin
          
          if(rst = '1') then
          
            ETAT_PRESENT <= ETAT0;
            
          elsif rising_edge(clk) then
            
            ETAT_PRESENT <= ETAT_FUTUR;
            
          end if;
          
        end process;
        
    
    Process(INST_MEM)
      begin
        if INST_MEM(27 downto 26) = "00" then -- (ADD, MOV, CMP)
          
          if INST_MEM(24 downto 21) = "0100" then -- ADD
            
            if INST_MEM(25) = '1' then    -- ADD (Immediate)
            
              instr_courante <= ADDi;
              
            else 	-- ADD (register)
              
              instr_courante <= ADDr;
              
           end if;
           
          elsif INST_MEM(24 downto 21) = "1101" then -- MOV
            
            instr_courante <= MOV;
          
          else  -- CMP
            
            instr_courante <= CMP;
            
          end if;
          
        elsif INST_MEM(27 downto 26) = "01" then -- (LDR, STR)
          
          if INST_MEM(20) = '1' then  -- LDR
            
            instr_courante <= LDR;
            
          else  -- STR
            
            instr_courante <= STR;
            
          end if;
            
        else  -- (BAL, BLT, BX)
          
          if INST_MEM(31 downto 28) = "1110" then  -- (BAL, BX)
            
            if INST_MEM(24) = '0' then  -- BAL
            
              instr_courante <= BAL;
              
            else                        -- BX
              
              instr_courante <= BX;
              
            end if;
            
          else   -- BLT
            
            instr_courante <= BLT;
            
          end if;
          
        end if;
        
      end process;
    
    
    nextstate : process(ETAT_PRESENT, instr_courante, isr, IRQ, N)
    
      begin
        
        CASE ETAT_PRESENT is 
          
          when ETAT0 => 
            IRQServ <= '0';
				    PCSel <= "--";
            PCWrEn <= '0';
            LRWrEn <= '0';
            AdrSel <= '0';
            MemRdEn <= '1';
            MemWrEn <= '0';
            IRWrEn <= '1';
				    WSel <= '-';
            RegWrEn <= '0';
				    ALUSelA <= '-';
            ALUSelB <= "--";
				    ALUOp <= "--";
				    CPSRSel <= '-';
            CPSRWrEn <= '0';
            SPSRWrEn <= '0';
            ResWrEn <= '0';
            
            ETAT_FUTUR <= ETAT1;
            
            
          when ETAT1 =>
            IRQServ <= '0';
				    PCSel <= "--";
            PCWrEn <= '0';
            LRWrEn <= '0';
            AdrSel <= '-';
            MemRdEn <= '0';
            MemWrEn <= '0';
            IRWrEn <= '1';
				    WSel <= '-';
            RegWrEn <= '0';
				    ALUSelA <= '-';
            ALUSelB <= "--";
				    ALUOp <= "--";
				    CPSRSel <= '-';
            CPSRWrEn <= '0';
            SPSRWrEn <= '0';
            ResWrEn <= '0';
            
            if IRQ = '1' and isr = '0' then
              ETAT_FUTUR <= ETAT16;
            elsif isr = '1' and instr_courante = BX then
              ETAT_FUTUR <= ETAT15;
            else
              if((instr_courante = LDR) or (instr_courante = STR) or (instr_courante = ADDr) or (instr_courante = ADDi) or (instr_courante = CMP) or (instr_courante = MOV)) then
                ETAT_FUTUR <= ETAT2;
              elsif (instr_courante = BAL) or ((instr_courante = BLT) and (N = '1')) then
                ETAT_FUTUR <= ETAT3;
              else
                ETAT_FUTUR <= ETAT4;
              end if;
            end if;
            
            
          when ETAT2 =>
            IRQServ <= '0';
            PCSel <= "00";
            PCWrEn <= '1';
            LRWrEn <= '0';
				    AdrSel <= '-';
            MemRdEn <= '0';
            MemWrEn <= '0';
            IRWrEn <= '0';
				    WSel <= '-';
            RegWrEn <= '0';
            ALUSelA <= '0';
            ALUSelB <= "11";
            ALUOp <= "00";
				    CPSRSel <= '-';
            CPSRWrEn <= '0';
            SPSRWrEn <= '0';
            ResWrEn <= '0';
				
            ETAT_FUTUR <= ETAT5;
            
            
          when ETAT3 =>
            IRQServ <= '0';
            PCSel <= "00";
            PCWrEn <= '1';
            LRWrEn <= '0';
				    AdrSel <= '0';
            MemRdEn <= '1';
            MemWrEn <= '0';
            IRWrEn <= '0';
				    WSel <= '-';
            RegWrEn <= '0';
            ALUSelA <= '0';
            ALUSelB <= "10";
            ALUOp <= "00";
				    CPSRSel <= '-';
            CPSRWrEn <= '0';
            SPSRWrEn <= '0';
            ResWrEn <= '0';
				
            ETAT_FUTUR <= ETAT0;
            
            
          when ETAT4 =>
            IRQServ <= '0';
            PCSel <= "00";
            PCWrEn <= '1';
            LRWrEn <= '0';
				    AdrSel <= '0';
            MemRdEn <= '1';
            MemWrEn <= '0';
            IRWrEn <= '0';
				    WSel <= '-';
            RegWrEn <= '0';
            ALUSelA <= '0';
            ALUSelB <= "11";
            ALUOp <= "00";
				    CPSRSel <= '-';
            CPSRWrEn <= '0';
            SPSRWrEn <= '0';
            ResWrEn <= '0';
            
            ETAT_FUTUR <= ETAT0;
            
            
          when ETAT5 =>
            IRQServ <= '0';
				    PCSel <= "--";
            PCWrEn <= '0';
            LRWrEn <= '0';
				    AdrSel <= '-';
            MemRdEn <= '0';
            MemWrEn <= '0';
            IRWrEn <= '0';
				    WSel <= '-';
            RegWrEn <= '0';
				    ALUSelA <= '-';
            ALUSelB <= "--";
				    ALUOp <= "--";
				    CPSRSel <= '-';
            CPSRWrEn <= '0';
            SPSRWrEn <= '0';
            ResWrEn <= '0';
            
            if ((instr_courante = LDR) or (instr_courante = STR) or (instr_courante = ADDi)) then
              ETAT_FUTUR <= ETAT6;
            elsif instr_courante = ADDr then
              ETAT_FUTUR <= ETAT7;
            elsif instr_courante = MOV then
              ETAT_FUTUR <= ETAT8;
            else
              ETAT_FUTUR <= ETAT9;
            end if;
            
            
          when ETAT6 => 
            IRQServ <= '0';
				    PCSel <= "--";
            PCWrEn <= '0';
            LRWrEn <= '0';
				    AdrSel <= '-';
            MemRdEn <= '0';
            MemWrEn <= '0';
            IRWrEn <= '0';
				    WSel <= '-';
            RegWrEn <= '0';
            ALUSelA <= '1';
            ALUSelB <= "01";
            ALUOp <= "00";
				    CPSRSel <= '-';
            CPSRWrEn <= '0';
            SPSRWrEn <= '0';
            ResWrEn <= '0';
				
            
            if instr_courante = LDR then
              ETAT_FUTUR <= ETAT10;
            elsif instr_courante = STR then
              ETAT_FUTUR <= ETAT11;
            else
              ETAT_FUTUR <= ETAT12;
            end if;
            
            
          when ETAT7 =>
            IRQServ <= '0';
				    PCSel <= "--";
            PCWrEn <= '0';
            LRWrEn <= '0';
				    AdrSel <= '-';
            MemRdEn <= '0';
            MemWrEn <= '0';
            IRWrEn <= '0';
				    WSel <= '-';
            RegWrEn <= '0';
            ALUSelA <= '1';
            ALUSelB <= "00";
            ALUOp <= "00";
				    CPSRSel <= '-';
            CPSRWrEn <= '0';
            SPSRWrEn <= '0';
            ResWrEn <= '0';
				
            ETAT_FUTUR <= ETAT12;
            
            
          when ETAT8 =>
            IRQServ <= '0';
				    PCSel <= "--";
            PCWrEn <= '0';
            LRWrEn <= '0';
				    AdrSel <= '-';
            MemRdEn <= '0';
            MemWrEn <= '0';
            IRWrEn <= '0';
				    WSel <= '-';
            RegWrEn <= '0';
				    ALUSelA <= '-';
            ALUSelB <= "01";
            ALUOp <= "01";
				    CPSRSel <= '-';
            CPSRWrEn <= '0';
            SPSRWrEn <= '0';
            ResWrEn <= '0';
				
            ETAT_FUTUR <= ETAT12;
            
            
          when ETAT9 => 
            IRQServ <= '0';
				    PCSel <= "--";
            PCWrEn <= '0';
            LRWrEn <= '0';
				    AdrSel <= '0';
            MemRdEn <= '1';
            MemWrEn <= '0';
            IRWrEn <= '0';
				    WSel <= '-';
            RegWrEn <= '0';
            ALUSelA <= '1';
            ALUSelB <= "01";
            ALUOp <= "10";
            CPSRSel <= '0';
            CPSRWrEn <= '1';
            SPSRWrEn <= '0';
            ResWrEn <= '0';
				
            ETAT_FUTUR <= ETAT0;
              
            
          when ETAT10 =>
            IRQServ <= '0';
				    PCSel <= "--";
            PCWrEn <= '0';
            LRWrEn <= '0';
            AdrSel <= '1';
            MemRdEn <= '1';
            MemWrEn <= '0';
            IRWrEn <= '0';
            WSel <= '-';
            RegWrEn <= '0';
				    ALUSelA <= '-';
            ALUSelB <= "--";
				    ALUOp <= "--";
				    CPSRSel <= '-';
            CPSRWrEn <= '0';
            SPSRWrEn <= '0';
            ResWrEn <= '0';
            
            ETAT_FUTUR <= ETAT13;
            
            
          when ETAT11 =>
            IRQServ <= '0';
				    PCSel <= "--";
            PCWrEn <= '0';
            LRWrEn <= '0';
            AdrSel <= '1';
            MemRdEn <= '0';
            MemWrEn <= '1';
            IRWrEn <= '0';
				    WSel <= '-';
            RegWrEn <= '0';
				    ALUSelA <= '-';
            ALUSelB <= "--";
				    ALUOp <= "--";
				    CPSRSel <= '-';
            CPSRWrEn <= '0';
            SPSRWrEn <= '0';
            ResWrEn <= '1';
            
            ETAT_FUTUR <= ETAT0;
            
            
          when ETAT12 =>
            IRQServ <= '0';
				    PCSel <= "--";
            PCWrEn <= '0';
            LRWrEn <= '0';
				    AdrSel <= '0';
            MemRdEn <= '1';
            MemWrEn <= '0';
            IRWrEn <= '0';
            WSel <= '1';
            RegWrEn <= '1';
				    ALUSelA <= '-';
            ALUSelB <= "--";
				    ALUOp <= "--";
				    CPSRSel <= '-';
            CPSRWrEn <= '0';
            SPSRWrEn <= '0';
            ResWrEn <= '0';
            
            ETAT_FUTUR <= ETAT0;
            
            
          when ETAT13 =>
            IRQServ <= '0';
				    PCSel <= "--";
            PCWrEn <= '0';
            LRWrEn <= '0';
				    AdrSel <= '-';
            MemRdEn <= '0';
            MemWrEn <= '0';
            IRWrEn <= '0';
				    WSel <= '-';
            RegWrEn <= '0';
				    ALUSelA <= '-';
            ALUSelB <= "--";
			     	ALUOp <= "--";
				    CPSRSel <= '-';
            CPSRWrEn <= '0';
            SPSRWrEn <= '0';
            ResWrEn <= '0';
            
            ETAT_FUTUR <= ETAT14;
            
            
          when ETAT14 =>
            IRQServ <= '0';
				    PCSel <= "--";
            PCWrEn <= '0';
            LRWrEn <= '0';
				    AdrSel <= '0';
            MemRdEn <= '1';
            MemWrEn <= '0';
            IRWrEn <= '0';
            WSel <= '0';
            RegWrEn <= '1';
				    ALUSelA <= '-';
            ALUSelB <= "--";
				    ALUOp <= "--";
				    CPSRSel <= '-';
            CPSRWrEn <= '0';
            SPSRWrEn <= '0';
            ResWrEn <= '0';
            
            ETAT_FUTUR <= ETAT0;
            
            
          when ETAT15 =>
            IRQServ <= '1';
            PCSel <= "10";
            PCWrEn <= '1';
            LRWrEn <= '0';
				    AdrSel <= '0';
            MemRdEn <= '1';
            MemWrEn <= '0';
            IRWrEn <= '0';
				    WSel <= '-';
            RegWrEn <= '0';
				    ALUSelA <= '-';
            ALUSelB <= "--";
				    ALUOp <= "--";
            CPSRSel <= '1';
            CPSRWrEn <= '1';
            SPSRWrEn <= '0';
            ResWrEn <= '0';
            
            ETAT_FUTUR <= ETAT0;
            
            
          when ETAT16 => 
            IRQServ <= '0';
				    PCSel <= "--";
            PCWrEn <= '0';
            LRWrEn <= '1';
				    AdrSel <= '-';
            MemRdEn <= '0';
            MemWrEn <= '0';
            IRWrEn <= '0';
				    WSel <= '-';
            RegWrEn <= '0';
				    ALUSelA <= '-';
            ALUSelB <= "--";
				    ALUOp <= "--";
				    CPSRSel <= '-';
            CPSRWrEn <= '0';
            SPSRWrEn <= '1';
            ResWrEn <= '0';
            
            ETAT_FUTUR <= ETAT17;
            
            
          when ETAT17 =>
            IRQServ <= '0';
            PCSel <= "11";
            PCWrEn <= '1';
            LRWrEn <= '0';
				    AdrSel <= '0';
            MemRdEn <= '1';
            MemWrEn <= '0';
            IRWrEn <= '0';
				    WSel <= '-';
            RegWrEn <= '0';
				    ALUSelA <= '-';
            ALUSelB <= "--";
				    ALUOp <= "--";
				    CPSRSel <= '-';
            CPSRWrEn <= '0';
            SPSRWrEn <= '0';
            ResWrEn <= '0';
            
            ETAT_FUTUR <= ETAT0;
            
        end case;
      end process;
		
		change_ISR : process(CLK, RST)
			Begin
			
			if RST = '1' then
				isr <= '0';
				
			elsif rising_edge(CLK) then
				
				if ETAT_PRESENT = ETAT15 then
						isr <= '0';
				elsif ETAT_PRESENT = ETAT17 then
						isr <= '1';
				end if;
			end if;
		end process;
					
				
    
    
end behav;