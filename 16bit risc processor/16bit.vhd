library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity cpu_16 is
	Port (
		DB: inout std_logic_vector(15 downto 0);
		AB: inout std_logic_vector(15 downto 0);
		CI: out std_logic_vector(31 downto 0);	
		CO: out std_logic_vector(31 downto 0);	
		MUX: in std_logic_vector(0 to 2);		
      
		CLK, RESET, RUN: in std_logic;	
		MCLK: buffer std_logic;
	 	MWR, MRD, IOR, IOW, CWR, CRD: inout std_logic;
		PRIX, KRIX: in std_logic
	);
end cpu_16;


architecture Behavioral of cpu_16 is

	-- 时钟信号 --
	signal PCCK, LRCK, RCK, TMPCK, ADRCK, IRCK, IRTCK, MIRCK, CCK: std_logic;

	-- PC信号 --
	signal PRST, CC: std_logic;
	signal IRO: std_logic_vector(15 downto 0);--IR outputted to be decoded

	-- 微信号 --
	signal RE, LRE, PCE, IRE, IRTE, ADRE, WRE, RDE, CE: std_logic;

	-- 多路选择 --
	signal S: std_logic_vector(2 downto 0);
	signal MXA: std_logic_vector(1 downto 0);
	signal MXB: std_logic_vector(2 downto 0);
	signal MXC: std_logic;--select ADR & PC to AB
	signal MXIR: std_logic_vector(1 downto 0);--select from IRT & DB to IR
	signal MXDC: std_logic;--select from IR & IRN to PLA
	signal MXCC: std_logic_vector(1 downto 0);--condition code selector
	signal MXPC: std_logic_vector(1 downto 0);
	signal MXLR: std_logic;--select from FF & PC-1 to LR

	signal RS:std_logic_vector(2 downto 0);--register select 
	signal RSA:std_logic_vector(2 downto 0);--register select 
	signal RSB:std_logic_vector(2 downto 0);--register select 
	signal IMM: std_logic_vector(15 downto 0);
	signal IRN: std_logic_vector(15 downto 0);

	-- 寄存器组 --
	signal ADR: std_logic_vector(15 downto 0);
	signal R0, R1, R2, R3, R4, R5, R6, R7, ROUTA, ROUTB: std_logic_vector(15 downto 0);
	signal LR: std_logic_vector(15 downto 0);
	signal IR: std_logic_vector(15 downto 0);
	signal IRT: std_logic_vector(15 downto 0);
	signal PC: std_logic_vector(15 downto 0);
	signal DIN,DOUT: std_logic_vector(15 downto 0);

	-- CPU输入、输出和条件位 --
	signal FA,FB,FF: std_logic_vector(16 downto 0);--ALU's input and output
	signal CY: std_logic;
	
begin

	
	-- 时钟信号 --
	process(MCLK, CLK)
	begin
		if (RUN='0') or (RESET='0') then
			MCLK <= '0';
		elsif (CLK'event and CLK = '0') then
			MCLK <= not MCLK;
	end if;
	end process;
	PCCK <= MCLK;
	LRCK <= MCLK;
	RCK <= MCLK;
	ADRCK <= MCLK;
	IRCK <= MCLK;
	IRTCK <= MCLK;
	MIRCK <= MCLK;
	CCK <= MCLK;

	
	-- 读写操作信号 --
	CWR <= WRE or not MCLK ;    -- CPU写信号(0)
	CRD <= RDE or not MCLK;    -- CPU读信号(0)
	MRD <= CRD or AB(15);    -- 读出控制线(0)
	MWR <= CWR or AB(15) or not CLK;    -- 写入控制线(0)
	IOW <= not AB(15) or not AB(1) or CWR or not CLK;    -- 键盘读出信号(0)
	IOR <= not AB(15) or not AB(0) or CRD;    -- 打印机输出信号(0)

	
	-- 通用寄存器Ri输入 --
	process(RCK, RE, RS)
	begin
		if (RCK'event and RCK = '0') then
			if RE = '0' then
				case RS is
				when "000" => R0 <= FF(15 downto 0);
				when "001" => R1 <= FF(15 downto 0);
				when "010" => R2 <= FF(15 downto 0);
				when "011" => R3 <= FF(15 downto 0);
				when "100" => R4 <= FF(15 downto 0);
				when "101" => R5 <= FF(15 downto 0);
				when "110" => R6 <= FF(15 downto 0);
				when others => R7 <= FF(15 downto 0);
				end case;
			end if;
		end if;
	end process;

	
	-- 通用寄存器Ri输出 --
	ROUTA <= R0 when RSA = "000" else
			R1 when RSA = "001" else
			R2 when RSA = "010" else
			R3 when RSA = "011" else
			R4 when RSA = "100" else
			R5 when RSA = "101" else
			R6 when RSA = "110" else
			R7;
	ROUTB <= R0 when RSB = "000" else
			R1 when RSB = "001" else
			R2 when RSB = "010" else
			R3 when RSB = "011" else
			R4 when RSB = "100" else
			R5 when RSB = "101" else
			R6 when RSB = "110" else
			R7;

			
	-- ALU操作数 --
	FA <= '0' & ROUTA when MXA = "00" else
		'0' & LR when MXA = "01" else
		'0' & PC when MXA = "10" else
		"00000000000000000";
	FB <= '0' & ROUTB when MXB = "000" else
		'0' & LR when MXB = "001" else
		'0' & PC when MXB = "010" else
		'0' & DIN when MXB = "011" else
		'0' & IMM when MXB = "100" else
		"00000000000000000";

		
	-- 地址总线AB --
	process(MXC, PC, ADR)
	begin
		if(MXC = '0')then
			AB <= PC;
		else AB <= ADR;
		end if;
	end process;

	
	-- 数据总线DB --
	process(CWR, CRD)
	begin
		if (CWR = '0') then
			DB <= DOUT;
		else DB <= "ZZZZZZZZZZZZZZZZ";
		end if;
		if (CRD = '0') then
			DIN <= DB;
		end if;
	end process;

	
	-- ALU运算 --
	Process(S)
	begin
		case S is
			when "000" => FF <= FA + FB;
			when "001" => FF <= FA - FB;
			when "010" => FF <= FA and FB;
			when "011" => FF <= '0' & FA(15 downto 8) & FB(7 downto 0);
			when "100" => FF <= '0' & FB(7 downto 0) & FA(7 downto 0);
			when "101" => FF <= FB;
			when "110" => FF <= FA or FB;
			when others => FF <= FA - 1 + FB;
		end case;
	end Process;
	DOUT <= FF(15 downto 0);

	
	-- 进位条件位 --
	process(CCK, CE)
	begin
		if (CCK = '0') then
			if (CE = '0') then
				CY <= FF(16);
			end if;
		end if;
	end process;

	
	-- PC信号CC --
	process(IRO, CY, PRIX, KRIX)
	begin
		case IRO(14 downto 12) is
			when "000" => CC <= '0';
			when "001" => CC <= not CY;
			when "010" => CC <= PRIX;
			when "011" => CC <= KRIX;
			when others => CC <= '0';
		end case;
	end process;

	
	-- 程序计数器PC --
	process(PCCK, RESET, MXPC)
	begin
		if (RESET = '0') then
			PC <= "0000000000000000";
		elsif (PCCK'event and PCCK = '0' and PCE = '0') then
			case MXPC is
				when "00" => PC <= PC + 1;
				when "01" => PC <= FF(15 downto 0);
				when "10" => PC <= PC;
				when others => PC <= ADR;
			end case;
		end if;
	end process;

	
	-- 返回地址LR --
	process(LRCK, LRE)
		begin
		if (LRCK'event and LRCK = '0' and LRE = '0') then
			if(MXLR = '0') then
				LR <= FF(15 downto 0);
			else
				LR <= PC - 1;
			end if;
		end if;
	end process;

	
	-- 指令寄存器IR --
	process(IRE, IRCK, MXIR, RESET)
	begin
		if (RESET = '0') then
			IR <= "0000000000000000";
		elsif (IRCK'event and IRCK = '0' and IRE = '0') then
			if (MXIR = "00") then
				IR <= DB;
			elsif (MXIR = "01") then
				IR <= IRT;
			else IR <= "0000000000000000";
			end if;
		end if;
	end process;

	
	-- IRT --
	process(IRE, IRCK, MXIR)
	begin
		if (IRTCK'event and IRTCK = '0' and IRTE = '0') then
			IRT <= DB;
		end if;
	end process;

	
	-- IRO --
	process(MXDC, IR, IRN)
	begin
		if(MXDC = '0') then
			IRO <= IR;
		else IRO <= IRN;
		end if;
	end process;

	
	-- ADR --
	process(ADRCK,ADRE)
	begin										
	if (ADRCK'event and ADRCK = '0' and ADRE = '0') then
		ADR <= FF(15 downto 0);
	end if; 
	end process;

	
	process(MIRCK, IRO)
	begin
		if(RESET = '0') then -- NOP
				RE <= '1'; LRE <= '1'; PCE <= '0'; IRE <= '0'; IRTE <= '1'; ADRE <= '1'; WRE <= '1'; RDE <= '0'; CE <= '1';
				MXPC <= "00"; MXDC <= '0'; MXIR <= "00"; MXC <= '0';
		elsif(MIRCK'event and MIRCK = '0') then
			if (IRO(15) = '1') then -- 跳转
				if (CC = '1') then
					RE <= '1'; LRE <= '1'; PCE <= '0'; IRE <= '0'; IRTE <= '1'; ADRE <= '1'; WRE <= '1'; RDE <= '0'; CE <= '1';
					MXPC <= "00"; MXDC <= '0'; MXIR <= "00"; MXC <= '0';
				elsif (IRO(14) = '0') then -- BJJ BC BP BK
					IMM(10 downto 0) <= IRO(11 downto 1); IMM(15 downto 11) <= (others => IRO(11));
					MXCC <= IRO(13 downto 12);
					RE <= '1'; LRE <= '1'; PCE <= '0'; ADRE <= '1'; WRE <= '1'; RDE <= '1'; CE <= '1';
					S <= "111"; MXA <= "10"; MXB <= "100"; MXPC <= "01";
					IRN <= "0000000000000000"; MXDC <= '1'; MXIR <= "10";-- 2 bubbles
					IRE <= '0'; IRTE <= '1'; -- stall
				elsif (IRO(12) = '0') then -- CALL
						IMM(10 downto 0) <= IRO(11 downto 1); IMM(15 downto 11) <= (others => IRO(11));
						MXCC <= "00";
						RE <= '1'; LRE <= '0'; PCE <= '0'; ADRE <= '1'; WRE <= '1'; RDE <= '1'; CE <= '1';
						S <= "111"; MXA <= "10"; MXB <= "100"; MXPC <= "01"; MXLR <= '1';
						IRN <= "0000000000000000"; MXDC <= '1'; MXIR <= "10"; -- 2 bubbles
						IRE <= '0'; IRTE <= '1'; -- stall
				else -- RET
						MXCC <= "00";
						RE <= '1'; LRE <= '1'; PCE <= '0'; ADRE <= '1'; WRE <= '1'; RDE <= '1'; CE <= '1'; 
						S <= "101"; MXB <= "001"; MXPC <= "01"; 
						IRN <= "0000000000000000"; MXDC <= '1'; MXIR <= "10"; --2 bubbles
						IRE <= '0'; IRTE <= '1'; -- stall
				end if; 
			elsif (IRO(14) = '1') then
				if (IRO(12) = '0') then -- STR/LDR [Rd, #imm6]
					IMM <= "0000000000" & IRO(11 downto 6);
					RSA <= IRO(5 downto 3);
					RE <= '1'; LRE <= '1'; PCE <= '0'; IRE <= '1'; IRTE <= '0'; ADRE <= '0'; WRE <= '1'; RDE <= '0'; CE <= '1'; 
					S <= "111"; MXA <= "00"; MXB <= "100"; MXDC <= '1'; MXPC <= "00"; MXC <= '0'; 
					IRN <= "00001" & IRO(13 downto 12) & IRO(2 downto 0) & "000000";
				else -- STR/LDR 8001H/8002H
					if(IRO(13) = '0') then
						IMM <= "1000000000000001";
					else IMM <= "1000000000000010";
					end if;
					RE <= '1'; LRE <= '1'; PCE <= '0'; IRE <= '1'; IRTE <= '0'; ADRE <= '0'; WRE <= '1'; RDE <= '0'; CE <= '1'; 
					S <= "101"; MXB <= "100"; MXDC <= '1'; MXPC <= "00"; MXC <= '0'; 
					IRN <= "00001" & IRO(13 downto 9) & "000000";
				end if;
			elsif (IRO(13) = '1') then
				if (IRO(11) = '0') then -- MOVL
					IMM <= "00000000" & IRO(7 downto 0);
					RSA <= IRO(10 downto 8); RS <= IRO(10 downto 8); 
					RE <= '0'; LRE <= '1'; PCE <= '0'; IRE <= '0'; IRTE <= '1'; ADRE <= '1'; WRE <= '1'; RDE <= '0'; CE <= '1'; 
					S <= "011"; MXA <= "00"; MXB <= "100"; MXDC <= '0'; MXPC <= "00"; MXIR <= "00"; MXC <= '0';
				else -- MOVH
					IMM <= "00000000" & IRO(7 downto 0);
					RSA <= IRO(10 downto 8); RS <= IRO(10 downto 8); 
					RE <= '0'; LRE <= '1'; PCE <= '0'; IRE <= '0'; IRTE <= '1'; ADRE <= '1'; WRE <= '1'; RDE <= '0'; CE <= '1'; 
					S <= "100"; MXA <= "00"; MXB <= "100"; MXDC <= '0'; MXPC <= "00"; MXIR <= "00"; MXC <= '0';
				end if;
			elsif (IRO(12) = '1') then -- ADD SUB AND OR
					RSB <= IRO(8 downto 6); RSA <= IRO(5 downto 3); RS <= IRO(2 downto 0); 
					RE <= '0'; LRE <= '1'; PCE <= '0'; IRE <= '0'; IRTE <= '1'; ADRE <= '1'; WRE <= '1'; RDE <= '0'; CE <= '0'; 
					S <= IRO(11 downto 9); MXA <= "00"; MXB <= "000"; MXDC <= '0'; MXPC <= "00"; MXIR <= "00"; MXC <= '0';
			elsif (IRO(11) = '1') then
				if (IRO(10) = '0') then -- LDR Rd, DIN
						RS <= IRO(8 downto 6);
						RE <= '0'; LRE <= '1'; PCE <= '1'; IRE <= '0'; IRTE <= '1'; ADRE <= '1'; WRE <= '1'; RDE <= '0'; CE <= '1'; 
						S <= "101"; MXB <= "011"; MXDC <= '0'; MXIR <= "01"; MXC <= '1';
				else -- STR DOUT, Rd
						RSB <= IRO(8 downto 6);
						RE <= '1'; LRE <= '1'; PCE <= '1'; IRE <= '0'; IRTE <= '1'; ADRE <= '1'; WRE <= '0'; RDE <= '1'; CE <= '1'; 
						S <= "101"; MXB <= "000"; MXDC <= '0'; MXIR <= "01"; MXC <= '1';
				end if;
			else -- NOP
				RE <= '1'; LRE <= '1'; PCE <= '0'; IRE <= '0'; IRTE <= '1'; ADRE <= '1'; WRE <= '1'; RDE <= '0'; CE <= '1'; 
				MXPC <= "00"; MXDC <= '0'; MXIR <= "00"; MXC <= '0';
			end if;
		end if;
	end process;
	
	
	-- 输出 --
	CI(31 downto 16) <= R0 when MUX = "000" else
						R1 when MUX = "001" else
						R2 when MUX = "010" else
						R3 when MUX = "011" else
						R4 when MUX = "100" else
						R5 when MUX = "101" else
						R6 when MUX = "110" else
						R7;
	CI(15 downto 0) <= ROUTA when MUX = "000" else
						ROUTB when MUX = "001" else
						ADR when MUX = "010" else
						LR when MUX = "011" else
						IR when MUX = "100" else
						PC when MUX = "101" else
						DIN when MUX = "110" else
						DOUT;

end Behavioral;