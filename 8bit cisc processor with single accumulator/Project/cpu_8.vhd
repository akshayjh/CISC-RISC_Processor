library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity cpu_8 is
	Port (
		DB: inout std_logic_vector(7 downto 0);
		AB: inout std_logic_vector(15 downto 0);
		CI: out std_logic_vector(31 downto 0);	
		CO: in std_logic_vector(31 downto 0);	
		MUX: in std_logic_vector(2 downto 0);		
      
		CLK, RESET, RUN: in std_logic;	
	 	MWR, MRD, IOR, IOW, MCLK: buffer std_logic;
		PRIX, KRIX: in std_logic
	);
end cpu_8;


architecture Behavioral of cpu_8 is

	signal CWR, CRD: std_logic;
	signal CWRX, CRDX: std_logic;

	signal A: std_logic_vector(7 downto 0);
	signal GA, CA: std_logic;
	
	signal ACT: std_logic_vector(7 downto 0);
	signal GC, CC: std_logic;

	signal TMP: std_logic_vector(7 downto 0);
	signal GT, CT: std_logic;

	signal R0, R1, R2, R3, R4, R5, R6, R7, ROUT: std_logic_vector(7 downto 0);
	signal MXA, WRE, WRC: std_logic;
	signal RS: std_logic_vector(2 downto 0);

	signal FA, FB, FF: std_logic_vector(8 downto 0);
	signal S: std_logic_vector(2 downto 0);

	signal CY, CP, CCK: std_logic;
	signal ZY, ZP, ZCK: std_logic;

	signal MXB: std_logic_vector(1 downto 0);
	signal OB: std_logic;
	
	signal MXE: std_logic;

	signal PC: std_logic_vector(15 downto 0);
	signal PCK, PINC, PRST: std_logic;
	signal PLD: std_logic_vector(2 downto 0);
	signal PLDR: std_logic;

	signal IR: std_logic_vector(7 downto 0);
	signal GI, CCI: std_logic;
																		  
	signal ADRH: std_logic_vector(7 downto 0);
	signal GA1, CA1, AHS: std_logic;
	signal ADRL: std_logic_vector(7 downto 0);
	signal GA2, CA2: std_logic;
	signal ADR: std_logic_vector(15 downto 0);	

	signal MPC, MD: std_logic_vector(9 downto 0);
	signal MCLR, MPCK, MPLD: std_logic;

	signal SP: std_logic_vector(15 downto 0);
	signal SSP: std_logic_vector(1 downto 0);
	signal SCK: std_logic;

	signal MXC: std_logic_vector(1 downto 0);

	signal MIR: std_logic_vector(31 downto 0);
	signal MICK: std_logic;
	
	signal RRC: std_logic;
	
begin

	-- ΢�����ź� --
	CWRX <= MIR(29);
	CRDX <= MIR(28);
	MPLD <= MIR(27);
	MXC <= MIR(26 downto 25);
	SSP <= MIR(24 downto 23);
	PINC <= MIR(22);
	PLD <= MIR(21 downto 19);
	MXA <= MIR(18);
	S <= MIR(17 downto 15);
	MXE <= MIR(14);
	CP <= MIR(13);
	ZP <= MIR(12);
	MXB <= MIR(11 downto 10);
	OB <= MIR(9);
	GA2 <= MIR(8);
	AHS <= MIR(7);
	GA1 <= MIR(6);
	GI <= MIR(5);
	GT <= MIR(4);
	GC <= MIR(3);
	RRC <= MIR(2);
	GA <= MIR(1);
	WRE <= MIR(0);

	
	-- ʱ���ź� --
	process(CLK, RUN, RESET)
	begin
		if(RUN = '0') or (RESET = '0') then MCLK <= '0';
			elsif(CLK' event and CLK = '0') then MCLK <= not MCLK;
		end if;
	end process;
	MPCK <= not MCLK and CLK;    -- ΢���������MPCʱ��
	MICK <= not MPCK;    -- ΢ָ��Ĵ���MIRʱ��	
	WRC <= MCLK;    -- ͨ�üĴ���Riʱ��
	PCK <= MCLK;    -- ���������PCʱ��
	CA <= MCLK;    -- �ۼ���Aʱ��
	CT <= MCLK;    -- �ݴ���TMPʱ��
	CC <= MCLK;    -- �ݴ�Ĵ���ACTʱ��
	CCI <= MCLK;    -- ָ��Ĵ���IRʱ��
	CA1 <= MCLK;    -- ��λ��ַ�Ĵ���ADRHʱ��
	CA2 <= MCLK;    -- ��λ��ַ�Ĵ���ADRLʱ��
	CCK <= MCLK;    -- CY�Ĵ���ʱ��
	ZCK <= MCLK;    -- ZY�Ĵ���ʱ��
	SCK <= MCLK;    -- SPʱ��
	

	-- ��д�����ź� --
	CWR <= CWRX or not MCLK ;    -- CPUд�ź�(0)
	CRD <= CRDX or not MCLK;    -- CPU���ź�(0)
	MRD <= CRD or AB(15);    -- ����������(0)
	MWR <= CWR or AB(15) or not CLK;    -- д�������(0)
	IOW <= not AB(15) or not AB(1) or CWR or not CLK;    -- ���̶����ź�(0)
	IOR <= not AB(15) or not AB(0) or CRD;    -- ��ӡ������ź�(0)
	PRST <= RESET;


	-- ͨ�üĴ���Ri���� --
	process(WRC, WRE, RS)
	begin	 
		if (WRC' event and WRC = '0') then	   
			if (WRE = '0') then			 
				case RS is				
					when "000" => R0 <= DB;  
					when "001" => R1 <= DB;   
					when "010" => R2 <= DB;
					when "011" => R3 <= DB;  
					when "100" => R4 <= DB;   
					when "101" => R5 <= DB;
					when "110" => R6 <= DB;  
					when others => R7 <= DB; 
				end case;				
			 end if;			    
		end if;						
	end process;
	RS <= IR(2 downto 0);
	

	-- ͨ�üĴ���Ri��� --
	ROUT <= R0 when RS = "000" else
			R1 when RS = "001" else
			R2 when RS = "010" else
			R3 when RS = "011" else
			R4 when RS = "100" else
			R5 when RS = "101" else
			R6 when RS = "110" else
			R7;
	
	
	-- ͨ�üĴ���Ri���ݴ���TMP��·ѡ�񿪹�MUXA --
	process(MXA)
	begin	    
		if (MXA = '0') then		  
			 FB(7 downto 0) <= ROUT;
		else					    
			 FB(7 downto 0) <= TMP;   
		end if;
		FB(8) <= '0';
	end process;
	
	
	-- ALU��һ������ --
	FA(7 downto 0) <= ACT;
	FA(8) <= '0';
	
	
	-- �ۼ���Aд�� --
	process(CA, GA, DB) 
	begin
		if(CA' event and CA = '0') then
			if(GA = '0') then A <= DB;
			end if;
		end if;
	end process;
	

	-- �ݴ�Ĵ���ACTд�� --
	process(CC, GC, A) 
	begin
		if(CC' event and CC = '0') then
			if(GC = '0') then ACT <= A;
			end if;
		end if;
	end process;
	

	-- �ݴ���TMPд�� --
	process(CT, GT, DB)
	begin
		if(CT' event and CT = '0') then
			if(GT = '0') then TMP <= DB;
			end if;
		end if;
	end process;

	
	-- ALU���� --
	process(S)
	begin  
		case S is			
			when "000" => FF <= FA + FB;  
			when "001" => FF <= FA - FB;    
			when "010" => FF <= FA;				    
			when "011" => FF <= FB;	 
			when "100" => FF <= not FA;	  
			when "101" => FF <= FA xor FB;		 
			when "110" => FF(7 downto 0) <= FA(8 downto 1); FF(8) <= '0';
			when others => FF <= "000000000";		
		end case;   
	end process;
	

	-- ��λ�Ĵ���CY --
	process(CP, CCK, FF) begin	  
		if (CCK'event and CCK = '0') then 
	     	if (CP = '0') then
				CY <= FF(8);  
	     	end if;	   
		end if;		    
	end process;
	

	-- ��Ĵ���ZY --
	process(ZP, ZCK, FF) begin   
		if (ZCK'event and ZCK = '0') then	 
	     	if (ZP = '0') then			 
				if (FF = "000000000") then	 
					ZY <= '1';	   
				else		    
					ZY <= '0';	 
				end if;	
	     	end if;		  
		end if;
	end process;


	-- ���Ƴ��������PC����Ķ�·ѡ����MUXD --
	process (PLD, CY, ZY, KRIX, PRIX)
	begin  
		case PLD is
			when "000" => PLDR <= '0';  
			when "001" => PLDR <= CY; 
			when "010" => PLDR <= not ZY;  
			when "011" => PLDR <= not KRIX;
			when "100" => PLDR <= not PRIX;
			when "101" => PLDR <= '1';
			when others => PLDR <= '0';
		end case;			  
	end process;

    
	-- ���������PC --
	process(PCK, PRST, PLDR, PINC, AB)
	begin
		if (PRST = '0') then PC <= "0000000000000000";
		elsif (PCK' event and PCK = '0') then
			if (PLDR = '1') then PC <= AB;
			elsif (PINC = '0') then PC <= PC + 1;
			end if;
		end if;
	end process;

	
	-- ��λ��ַ�Ĵ���ADRHд�� --
	process(CA1, GA1, AHS, DB)
	begin
		if (CA1' event and CA1 = '0') then
			if (AHS = '0')	then ADRH <= "01111110";
			elsif (GA1 = '0') then ADRH <= DB;
			end if;
		end if;
	end process;

	
	-- ��λ��ַ�Ĵ���ADRLд�� --
	process(CA2, GA2, DB)
	begin
		if(CA2' event and CA2 = '0') then
			if(GA2 = '0') then ADRL <= DB;
		end if;
	end if;
	end process;

	
	-- ��������DB��·ѡ����MUXB --
	DB <= FF(7 downto 0) when MXB = "00" else
		  PC(15 downto 8) when MXB = "01" else
		  PC(7 downto 0) when MXB = "10" else
		  "ZZZZZZZZ";


	-- ָ��Ĵ���IRд�� --
	process(DB, MICK, GI, RESET)
	begin
		if (RESET = '0') then
			IR <= "00000000";
		elsif (CCI' event and CCI = '0') then
			if(GI = '0') then IR <= DB;
			end if;
		end if;
	end process;


	-- ΢������������MD --
	MD(2 downto 0) <= "111";
	MD(7 downto 3) <= IR(7 downto 3);
	MD(9 downto 8) <= "00";
	

	-- ΢���������MPC��0�ź�MCLR --
	process(MCLK, RESET, RUN)
	begin
		if (RESET = '0') then MCLR <= '0';
		elsif (MCLK' event and MCLK = '1') then MCLR <= RUN;
		end if;
	end process;
	

	-- ΢���������MPCд��д�� --
	process(MPLD, MPCK, MCLR)
	begin	
		if(MCLR='0') then MPC <= "0000000000";
		elsif (MPCK' event and MPCK = '1') then
			if(MPLD = '0') then MPC <= MD;
			else MPC <= MPC + 1;
			end if;
		end if;
	end process;
	

	-- ΢ָ��Ĵ���MIRд�� --
	process(MICK, CO)
	begin
		if(MICK' event and MICK = '1') then MIR <= CO;
		end if;
	end process;

	
	-- ��ջָ��SP���� --
	process(SSP, SCK, RESET, RUN)
	begin
		if(RESET = '0' or RUN = '0') then SP <= "0111111111111111";
		elsif(SCK' event and SCK = '0')	then
			if(SSP = "01")	then SP <= SP - 1;
			elsif(SSP = "10") then	SP <= SP + 1;	
			elsif(SSP = "11") then SP <= "0111111111111111";
			end if;
		end if;
	end process;


	-- ��ַ����AB��·ѡ����MUXC --
	ADR(15 downto 8)<= ADRH;
	ADR(7 downto 0)<= ADRL;
	process(MXC, PC, ADR, SP)
	begin
		case MXC is
			when "00" => AB <= PC;
			when "01" => AB <= ADR;
			when others => AB <= SP;
		end case;
	end process;
	

	-- ���CI --
	CI(31 downto 24) <= A when MUX = "000" else
						PC(15 downto 8) when MUX = "001" else
						SP(15 downto 8) when MUX = "010" else
						ADRH when MUX = "011" else
						R0 when MUX = "100" else
						R2 when MUX = "101" else
						R4 when MUX = "110" else
						R6;
	CI(23 downto 16) <= TMP when MUX = "000" else
						PC(7 downto 0) when MUX = "001" else
						SP(7 downto 0) when MUX = "010" else
						ADRL when MUX = "011" else
						R1 when MUX = "100" else
						R3 when MUX = "101" else
						R5 when MUX = "110" else
						R7;
	CI(15 downto 12) <= ROUT(7 downto 4) when MUX = "000" else
						ROUT(3 downto 0) when MUX = "001" else
						FF(7 downto 4) when MUX = "010" else
						FF(3 downto 0) when MUX = "011" else
						DB(7 downto 4) when MUX = "100" else
						DB(3 downto 0) when MUX = "101" else
						AB(7 downto 4) when MUX = "110" else
						AB(3 downto 0);
	CI(10) <= PRIX when MUX = "000" else
			KRIX when MUX = "001" else
			PLDR when MUX = "010" else
			CY when MUX = "011" else
			ZY;						
	CI(9 downto 0) <= MPC;
	
end Behavioral;
