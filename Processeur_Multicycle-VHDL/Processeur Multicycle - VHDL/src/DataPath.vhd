------------------------------------------------------------------
--																                --
--					PROCESSEUR MULTI-CYCLES					             --
--						CHEMIN DE DONNEES						             --
--																                --
--  						(c) 2010-2012							          --
-- 		A.Mocco, N.Hamila, M.Fonseca, J.Denoulet, P.Garda		 --
-----------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all; 

entity DataPath is 
port(
		clk,rst		: in std_logic;								-- Horloge + Reset Asynchrone
        
		-- Gestion des Interruptions
		irq0,irq1	: in std_logic;								-- Boutons Interruptions Externes
		irq     		: out std_logic;								-- Requete Interruption Transmise par le VIC
		irq_serv		: in std_logic;  								-- Acquittement Interruption
        
		-- Instructions
		Inst_Mem   	: out std_logic_vector(31 downto 0);	-- Instruction a Decoder (MEMOIRE)
		Inst_Reg    : out std_logic_vector(31 downto 0);	-- Instruction a Decoder (REG INST)
		N        	: out std_logic; 								-- Flag N memorise dans Registre d'Etat
        
		-- Memoire Interne
		AdrSel 		: in std_logic; 								-- Commande Mux Bus Adresses
		MemRdEn   	: in std_logic;								-- Read Enable
		MemWrEn    	: in std_logic;								-- Write Enable
        
		-- Registre Instruction
		IrWrEn     	: in std_logic;								-- Write Enable              
        
		-- Banc de Registres
		WSel			: in std_logic;								-- Commande Mux Bus W
		RegWrEn 		: in std_logic;								-- Write Enable  
        
		--signaux de controle pour l'alu
		AluSelA 		: in std_logic;								-- Selection Entree A ALU
		AluSelB  	: in std_logic_vector(1 downto 0);		-- Selection Entree B ALU
		AluOP    	: in std_logic_vector(1 downto 0);		-- Selecttion Operation ALU
        
		-- Registres d'Etat (CPSR, SPSR)
		CpsrSel		: in std_logic; 								-- Mux Selection Entree CPSR
		CpsrWrEn		: in std_logic;								-- Write Enable CPSR
		SpsrWrEn		: in std_logic;								-- Write Enable SPSR
        
		-- Registres PC et LR      
		PCSel 		: in std_logic_vector(1 downto 0);		-- Selection Entree Registre PC
		PCWrEn 		: in std_logic;								-- Write Enable PC
		LRWrEn 		: in std_logic;								-- Write Enable LR
        
		-- Registre Resultat
		Res    		: out std_logic_vector(31 downto 0);	-- Sortie Registre Resultat
		ResWrEn		: in std_logic									-- Write Enable
  );
end DataPath;


architecture archi of DataPath is

------------------------------------------------------------------------------
-- DECLARATION COMPONENTS DE LA PARTIE OPERATIVE

	----------------------------------------------------
	-- Controleur d'Interruptions
	component VIC is
	port	(
		clk        	: in 	std_logic;						
		reset      	: in	std_logic; 					
		serv_irq   	: in	std_logic; 					
		irq0, irq1 	: in	std_logic;
		irq			: out	std_logic;
		VICPC			: out	std_logic_vector(31 downto 0)	
	);
	end component VIC;
	----------------------------------------------------

	----------------------------------------------------
	-- Memoire Interne
	component RAM64x32 IS
	PORT (
		clock		   : IN 	STD_LOGIC ;
		data		   : IN 	STD_LOGIC_VECTOR (31 DOWNTO 0);
		rdaddress 	: IN 	STD_LOGIC_VECTOR (5 DOWNTO 0);
		rden		   : IN 	STD_LOGIC  := '1';
		wraddress 	: IN 	STD_LOGIC_VECTOR (5 DOWNTO 0);
		wren		   : IN 	STD_LOGIC  := '1';
		q			   : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
	END component RAM64x32;
	----------------------------------------------------

	----------------------------------------------------
	-- Registre
	component REG32 is
	port  (
		datain	: in 	std_logic_vector(31 downto 0);
		rst,clk	: in 	std_logic;
		dataout	: out std_logic_vector(31 downto 0)
	);
	end component REG32;
	----------------------------------------------------

	----------------------------------------------------
	-- Registre avec Commande de Chargement
	component RegLd is
	port  (
		datain		   : in 	std_logic_vector(31 downto 0);
		rst,clk,we		: in 	std_logic;
		dataout		  	: out std_logic_vector(31 downto 0)
	);
	end component RegLd;
	----------------------------------------------------

	----------------------------------------------------
	-- Banc de Registres
	component register_bank is
	port	(
		clk	: IN 	STD_LOGIC ;
		w		: IN 	STD_LOGIC_VECTOR (31 DOWNTO 0);
		ra		: IN 	STD_LOGIC_VECTOR (3 DOWNTO 0);
		rb		: IN 	STD_LOGIC_VECTOR (3 DOWNTO 0);
		rw		: IN 	STD_LOGIC_VECTOR (3 DOWNTO 0);
		we		: IN 	STD_LOGIC  := '1';
		a		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		b		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);  
	end component register_bank;
	----------------------------------------------------

	----------------------------------------------------
	-- Mux 2 -> 1
	component MUX21 is
	generic (n: natural:=32);
	port	(
		a,b	: in 	std_logic_vector (n-1 downto 0);
		com	: in 	std_logic;
		s		: out std_logic_vector (n-1 downto 0)
	);
	end component MUX21;
	----------------------------------------------------

	----------------------------------------------------
	-- Mux 4 -> 1
	component MUX41 is
	generic (n: natural:=32);
	port	(
		a,b,c,d		: in 	std_logic_vector (n-1 downto 0);
		com		   : in 	std_logic_vector(1 downto 0);
		s			  	: out std_logic_vector (n-1 downto 0)
	);
	end component MUX41;
	----------------------------------------------------

	----------------------------------------------------
	-- Extenseur 32 Bits
	component imm_extender is
	generic(n: natural:=8);
	port(
		e	: in 	std_logic_vector(n-1 downto 0);
		s	: out std_logic_vector(31 downto 0)  
	);
	end component;
	----------------------------------------------------

	----------------------------------------------------
	-- ALU
	component ALU is
	port	(
		a, b	 : in 	std_logic_vector(31 downto 0);
		op		 : in 	std_logic_vector(1 downto 0);
		s		 : out 	std_logic_vector(31 downto 0);
		n		 : out 	std_logic
	);
	end component ALU;
	----------------------------------------------------
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- DECLARATION SIGNAUX INTERNES


	-- Memoire Interne
	signal MemAdr    		:  std_logic_vector(5 downto 0);	-- Bus Adresses Memoire
	signal MemDataOut    :  std_logic_vector(31 downto 0); -- Bus Donnees LEcture Memoire

	-- Registres LR, A, B, ALU, IR, et DR
	signal RegA		: std_logic_vector(31 downto 0);
	signal RegB		: std_logic_vector(31 downto 0); -- Registre B + Bus Donnees Memoire
	signal RegALU  : std_logic_vector(31 downto 0);
	signal LR      : std_logic_vector(31 downto 0);
	signal IR		: std_logic_vector(31 downto 0); 
	signal DR		: std_logic_vector(31 downto 0);

	-- Registre PC
	signal PC      : std_logic_vector (31 downto 0);
	signal PCIn    : std_logic_vector(31 downto 0); -- Entree du Registre PC
	
	-- Banc de Registres
	signal MuxBusW    : std_logic_vector(31 downto 0);
	signal MuxRBSel	: std_logic;
	signal MuxBusRB   : std_logic_vector(3 downto 0);
	signal BusA       : std_logic_vector(31 downto 0);
	signal BusB       : std_logic_vector(31 downto 0);

	-- Extenseurs 32 bits
	signal Imm8_32  : std_logic_vector(31 downto 0);
	signal Imm24_32 : std_logic_vector(31 downto 0);

	-- Sortie du VIC
	signal VICAdr     : std_logic_vector(31 downto 0); -- Sortie du VIC

	-- ALU
	signal AluOut     		: std_logic_vector(31 downto 0);	-- Sortie
	signal AluInA,AluInB		: std_logic_vector(31 downto 0);-- Entrees	
	signal plus1    			: std_logic_vector(31 downto 0); -- Constante: 1
	signal FlagN: std_logic;	-- Drapeau N

	-- Registres d'Etat (SPSR et CPSR)
	signal CpsrFlag   : std_logic_vector(31 downto 0); -- CPSR avec Flag a jour
	signal CpsrIn  	: std_logic_vector(31 downto 0);	-- Entree Registre CPSR
	signal Cpsr 		: std_logic_vector(31 downto 0);	-- Registre CPSR
	signal Spsr 		: std_logic_vector(31 downto 0); 	-- Registre SPSR
 
begin

--Controleur d'Interruptions
VIC0:	VIC port map(
		clk		=>	clk,
		reset		=>	rst,
		serv_irq	=>	irq_serv,
		irq0		=>	irq0,
		irq1		=>	irq1,
		irq		=>	irq,
		VICPC		=>	VICAdr );

-- Mux Selection PC
MuxPC : MUX41 port map(
			a				=>	AluOut,
			b				=>	RegALU,
			c				=>	LR,
			d				=>	VICAdr,
			com			=>	PCSel,
			s				=>	PCIn);

-- Registre PC
RegPC : RegLd port map(
			datain		=>	PCIn,
			rst			=>	rst,
			clk			=>	clk,
			we				=>	PCWrEn,
			dataout		=>	PC);

-- Link Register
LR0 : RegLd port map( 
			datain		=>	PC,
			rst			=>	rst,
			clk			=>	clk,
			we				=>	LRWrEn,
			dataout		=>	LR);

MuxMem: MUX21 generic map(6) port map(
			a				=>	PC(5 downto 0),
			b				=>	RegALU(5 downto 0),
			com			=>	AdrSel,
			s				=>	MemAdr);

-- Memoire Interne
Memoire:	RAM64x32 port map(
			clock			=>	clk,
			data			=>	RegB,
			rdaddress	=>	MemAdr,
			rden			=>	MemRdEn,
			wraddress	=>	MemAdr,
			wren			=>	MemWrEn,
			q				=>	MemDataOut);

-- Registre IR			
RegistreInstr	: RegLd port map(
			datain		=>	MemDataOut,
			rst			=>	rst,
			clk			=>	clk,
			we				=>	IrWrEn,
			dataout		=>	IR);

-- Registre DR			
RegistreData  	: REG32 port map(
			datain		=>	MemDataOut,
			rst			=>	rst,
			clk			=>	clk,
			dataout		=>	DR);

--instanciation du mux2v1s32 qui sert � selectionner busW 
MuxW0	: MUX21 port map(
			a				=>	DR,
			b				=>	RegALU,
			com			=>	WSel,
			s				=>	MuxBusW);

-- MuxRBSel=1 si STORE
MuxRBSel <= NOT(IR(27) OR IR(20)) AND IR(26);

-- Mux Bus W du Banc de Registres
MuxRB0 : MUX21 generic map(4) port map(
			a				=>	IR(3 downto 0),
			b				=>	IR(15 downto 12),
			com			=>	MuxRBSel,
			s				=>	MuxBusRB);

-- Banc de Registres
BancReg: register_bank port map(
			clk			=>	clk,
			w				=>	MuxBusW,
			ra				=>	IR(19 downto 16),
			rb				=>	MuxBusRB,
			rw				=>	IR(15 downto 12),
			we				=>	RegWrEn,
			a				=>	BusA,
			b				=>	BusB);
			
-- Registre A
RegA0: REG32 port map(
			datain		=>	BusA,
			rst			=>	rst,
			clk			=>	clk,
			dataout		=>	RegA);

-- Registre B
RegB0: REG32 port map(
			datain		=>	BusB,
			rst			=>	rst,
			clk			=>	clk,
			dataout		=>	RegB);

-- Extenseur 8=>32
Ext8_32 : imm_extender generic map(8) port map(
			e				=>	IR(7 downto 0),
			s				=>	Imm8_32);

-- Extenseur 24=>32
Ext24_32: imm_extender generic map(24) port map(
			e				=>	IR(23 downto 0),
			s				=>	Imm24_32);

-- Mux Selection Entree A ALU
MuxAluA: MUX21 port map(
			a				=>	PC,
			b				=>	RegA,
			com			=>	AluSelA,
			s				=>	AluInA);

-- Constante a 1 pour Operation ALU
plus1<=X"00000001";

-- Mux Selection Entree B ALU
MuxAluB : MUX41 port map(
			a				=>	RegB,
			b				=>	Imm8_32,
			c				=>	Imm24_32,
			d				=>	plus1,
			com			=>	AluSelB,
			s				=>	AluInB);

-- ALU
ALU0 : ALU port map(
			a				=> AluInA,
			b				=>	AluInB,
			op				=>	AluOP,
			s				=>	AluOut,
			n				=>	FlagN);

-- Registre ALU
RegALU0: REG32 port map(
			datain		=>	AluOut,
			rst			=>	rst,
			clk			=>	clk,
			dataout		=>	RegALU);

CpsrFlag<=FlagN & Cpsr(30 downto 0);

-- Mux CPSR
cpsrmux : MUX21 port map(
			a				=>	CpsrFlag,
			b				=>	Spsr,
			com			=>	CpsrSel,
			s				=>	CpsrIn);

-- Registre CPSR
CPSR0: RegLd port map(
			datain		=>	CpsrIn,
			rst			=>	rst,
			clk			=>	clk,
			we				=>	CpsrWrEn,
			dataout		=>	cpsr);

-- Registre SPSR
SPSR0: RegLd port map(
			datain		=>	Cpsr,
			rst			=>	rst,
			clk			=>	clk,
			we				=>	SpsrWrEn,
			dataout		=>	Spsr);

-- Registre Resultat
RegRes: RegLd port map(
			datain		=>	RegB,
			rst			=>	rst,
			clk			=>	clk,
			we				=>	ResWrEn,
			dataout		=>	Res);


-- Sortie Instruction vers Machine a Etat
Inst_Mem	<=	MemDataOut;
Inst_Reg	<=	IR;
N			<=	Cpsr(31);

end archi;
