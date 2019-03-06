------------------------------------------------------------------
--																					--
--					PROCESSEUR MULTI-CYCLES									--
--				PROCESSEUR: CHEMIN DE DONNEES + MAE						--
--																					--
--						(c) 2010-2012											--
-- 		A.Mocco, N.Hamila, M.Fonseca, J.Denoulet, P.Garda		--
------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity arm is
port(
		clk			    : in std_logic;	-- Horloge
		rst			    : in std_logic;	-- Reset Asynchrone
		irq0,irq1 : std_logic;								-- Requetes d'Interruption
		resultat		: out std_logic_vector(31 downto 0)	-- Resultat pour Affichage
);
end arm;
  
architecture arc_arm of arm is


-- Declaration des composants MAE Et Chemin de Donnees
component DataPath is
port(
		clk,rst		: in std_logic;							-- Horloge + Reset Asynchrone
        
		-- Gestion des Interruptions
		irq0,irq1	: in std_logic;							-- Boutons Interruptions Externes
		irq     		: out std_logic;							-- Requete Interruption Transmise par le VIC
		irq_serv		: in std_logic;  							-- Acquittement Interruption
        
		-- Instructions
		Inst_Mem   	: out std_logic_vector(31 downto 0);	-- Instruction a Decoder (MEMOIRE)
		Inst_Reg    : out std_logic_vector(31 downto 0);	-- Instruction a Decoder (REG INST)
		N        	: out std_logic; 								-- Flag N memorise dans Registre d'Etat
        
		-- Memoire Interne
		AdrSel 		: in std_logic; 							-- Commande Mux Bus Adresses
		MemRdEn   	: in std_logic;							-- Read Enable
		MemWrEn    	: in std_logic;							-- Write Enable
        
		-- Registre Instruction
		IrWrEn     	: in std_logic;							-- Write Enable              
        
		-- Banc de Registres
		WSel			: in std_logic;								-- Commande Mux Bus W
		RegWrEn 		: in std_logic;								-- Write Enable  
        
		--signaux de controle pour l'alu
		AluSelA 		: in std_logic;								-- Selection Entree A ALU
		AluSelB  	: in std_logic_vector(1 downto 0);		-- Selection Entree B ALU
		AluOP    	: in std_logic_vector(1 downto 0);		-- Selecttion Operation ALU
        
		-- Registres d'Etat (CPSR, SPSR)
		CpsrSel		: in std_logic; 							-- Mux Selection Entree CPSR
		CpsrWrEn		: in std_logic;							-- Write Enable CPSR
		SpsrWrEn		: in std_logic;							-- Write Enable SPSR
        
		-- Registres PC et LR      
		PCSel 		: in std_logic_vector(1 downto 0);		-- Selection Entree Registre PC
		PCWrEn 		: in std_logic;							-- Write Enable PC
		LRWrEn 		: in std_logic;							-- Write Enable LR
        
		-- Registre Resultat
		Res    		: out std_logic_vector(31 downto 0);	-- Sortie Registre Resultat
		ResWrEn		: in std_logic							-- Write Enable
  );
  
end component DataPath;

component MAE is
port(
		  clk    	: in  std_logic;					-- Horloge
		  rst    	: in  std_logic;					-- Reset Asynchrone
        
		-- Gestion des Interruptions
		  irq     		: in std_logic ;					-- Requete d'Interruption
		  IRQServ		: out std_logic;					-- Acquittement Inerruption
        
		-- Gestion des Instructions
		  inst_mem		: in std_logic_vector(31 downto 0);	-- Instruction a Decoder (MEMOIRE)
		  inst_reg		: in std_logic_vector(31 downto 0);	-- Instruction a Decoder (REG INST)
		  N   			: in std_logic; 							-- Drapeau N de l'ALU
		  
		-- Memoire Interne
        AdrSel		: out std_logic;					-- Commande Mux Bus Adresses
        memRdEn	: out std_logic;					-- Read Enable
        memWrEn 	: out std_logic;					-- Write Enable
        
        -- Registre Instruction
        irWrEn  	: out std_logic;					-- Write Enable              
        
        -- Banc de Registres
        WSel    	: out std_logic;						-- Commande Mux Bus W
        RegWrEn	: out std_logic;       				-- Write Enable
        
        -- ALU
        AluSelA 	: out std_logic;							-- Selection Entree A ALU
        AluSelB	: out std_logic_vector(1 downto 0);	-- Selection Entree B ALU
        AluOP 		: out std_logic_vector(1 downto 0);	-- Selection Operation ALU
        
        --Registres d'Etat CPSR et SPSR
        CpsrSel	: out std_logic; 					-- Mux Selection Entree CPSR
        CpsrWrEn	: out std_logic;					-- Write Enable CPSR
        SpsrWrEn	: out std_logic;					-- Write Enable SPSR
        
        -- Registres PC et LR      
        PCSel 		: out std_logic_vector(1 downto 0);	-- Selection Entree Registre PC
        PCWrEn 	: out std_logic;							-- Write Enable PC
        LRWrEn 	: out std_logic;							-- Write Enable LR
        
        -- Registre Resultat
        ResWrEn	: out std_logic);					-- Write Enable Registre Resultat
end component MAE;

-- Signaux Internes

signal inst_mem			: std_logic_vector(31 downto 0);--irout
signal inst_reg			: std_logic_vector(31 downto 0);--irout
signal N       			: std_logic;
signal AdrSel        	: std_logic;
signal MemRdEn       	: std_logic;
signal MemWrEn       	: std_logic;
signal IrWrEn       		: std_logic;              
signal WSel      			: std_logic;
signal RegWrEn      		: std_logic;       
signal AluSelA     		: std_logic;
signal AluSelB     		: std_logic_vector(1 downto 0);
signal AluOP     			: std_logic_vector(1 downto 0);
signal CpsrSel    		: std_logic; 
signal CpsrWrEn     		: std_logic;
signal SpsrWrEn    	 	: std_logic;
signal PCSel    			: std_logic_vector(1 downto 0);
signal PCWrEn      		: std_logic;
signal LRWrEn     		: std_logic;
signal ResWrEn     	 	: std_logic;
signal irq, irq_serv		: std_logic;

begin
 
 
MAE1:MAE port map(
      clk    		=>	clk,
		rst     		=> rst,
		irq     		=>	irq,
		IRQServ		=>	irq_serv,
		inst_mem		=>	inst_mem,
		inst_reg		=> inst_reg,
      N   			=> N,
		AdrSel		=> AdrSel,
		memRdEn		=>	MemRdEn,
		memWrEn		=>	MemWrEn,
		IrWrEn		=>	IrWrEn,
      WSel    		=>	WSel,
		RegWrEn		=>	RegWrEn,
		AluSelA 		=>	AluSelA,
		AluSelB		=>	AluSelB,
      AluOP 		=>	AluOP,
		CpsrSel		=>	CpsrSel,
		CpsrWrEn		=>	CpsrWrEn,
		SpsrWrEn		=>	SpsrWrEn,
      PCSel 		=> PCSel,
      PCWrEn 		=>	PCWrEn,
		LRWrEn 		=> LRWrEn,
      ResWrEn		=>	ResWrEn);
  
DataPath1: DataPath port map(
      clk    		=>	clk,
		rst     		=> rst,
		irq0     	=>	irq0,
		irq1     	=>	irq1,
		irq     		=>	irq,
		irq_serv		=>	irq_serv,
		inst_mem		=>	inst_mem,
		inst_reg		=> inst_reg,
      N   			=> N,
		AdrSel		=> AdrSel,
		memRdEn		=>	MemRdEn,
		memWrEn		=>	MemWrEn,
		IrWrEn		=>	IrWrEn,
      WSel    		=>	WSel,
		RegWrEn		=>	RegWrEn,
		AluSelA 		=>	AluSelA,
		AluSelB		=>	AluSelB,
      AluOP 		=>	AluOP,
		CpsrSel		=>	CpsrSel,
		CpsrWrEn		=>	CpsrWrEn,
		SpsrWrEn		=>	SpsrWrEn,
      PCSel 		=> PCSel,
      PCWrEn 		=>	PCWrEn,
		LRWrEn 		=> LRWrEn,
		Res			=>	Resultat,
      ResWrEn		=>	ResWrEn);
    
end architecture arc_arm;







