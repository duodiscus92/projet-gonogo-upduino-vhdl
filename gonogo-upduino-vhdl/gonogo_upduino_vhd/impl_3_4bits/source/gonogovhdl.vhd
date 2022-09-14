library ieee;
use ieee.std_logic_1164.all;

package gonogo_types is
	constant NBITS : integer := 4;
	constant RAZ_NBITS : std_logic_vector(NBITS-1 downto 0) := "0000";
	constant GO : std_logic := '1';
	constant NOGO : std_logic := '0';
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; 
use ieee.numeric_std.all;
use work.gonogo_types.all;

entity gonogo is
	port(	clk, pb0 : in std_logic;

			sel_go, sel_nogo : in std_logic;
			sw_go, sw_nogo : in std_logic_vector(NBITS-1 downto 0);
--			rpi_sel_go, rpi_sel_nogo : in std_logic;
--			rpi_go, rpi_nogo : in std_logic_vector(NBITS-1 downto 0);
			pinsecond : out std_logic;
			pingonogo : out std_logic;
			ledgonogo, ledsecond : out std_logic
--			a0,a1,a2 : out std_logic
	);
end entity;


architecture tick of gonogo is
	signal tick_cntr : std_logic_vector(4 downto 0);
	signal tick_cntr_max, rst : std_logic;
	signal usecond_cntr : std_logic_vector(9 downto 0);
	signal usecond_cntr_max : std_logic;
	signal msecond_cntr : std_logic_vector(9 downto 0);
	signal msecond_cntr_max : std_logic;
	signal second_cntr : std_logic_vector(5 downto 0);
	signal second_cntr_max : std_logic;
	signal second, minute : std_logic;
	signal clk_go, clk_nogo : std_logic;
	signal clr : std_logic;
---------------------------
-- reset
---------------------------
begin
	RESET : process(pb0)
	begin
		if pb0 = '1' then rst <='0'; else rst <= '1'; end if;
	end process;

---------------------------
-- tick counter
---------------------------
	TICK : process(clk, rst)
	begin
		if rst = '1' then
			tick_cntr <= "00000";
			tick_cntr_max <= '0';
		else
			if clk 'event and clk = '1' then 
				if tick_cntr_max = '1' then tick_cntr <= "00000"; else tick_cntr <= tick_cntr + 1;end if;
				if tick_cntr = 8 then tick_cntr_max <= '1'; else tick_cntr_max <= '0';end if;
			end if;
		end if;
	end process;

---------------------------
-- count off 1000 us to form 1ms
---------------------------
	MICROSEC : process(clk, rst)
	begin
		if rst = '1' then
			usecond_cntr <= "0000000000";
			usecond_cntr_max <= '0';
		else
			if clk 'event and clk = '1' then 
				if tick_cntr_max = '1'then
					if usecond_cntr_max = '1' then usecond_cntr <= "0000000000"; else usecond_cntr <= usecond_cntr + 1;end if;
					if usecond_cntr = 998 then usecond_cntr_max <= '1'; else usecond_cntr_max <= '0';end if;
				end if;
			end if;
		end if;
	end process;
	
---------------------------
-- count off 1000 ms to form 1s
---------------------------
	MILISEC : process(clk, rst)
	begin
		if rst = '1' then
			msecond_cntr <= "0000000000";
			msecond_cntr_max <= '0';
		elsif (clr = '1') then
			msecond_cntr <= "0000000000";
			msecond_cntr_max <= '0';		
		else
			if clk 'event and clk = '1' then
				if (usecond_cntr_max = '1' and tick_cntr_max = '1') then 
					if msecond_cntr_max = '1' then msecond_cntr <= "0000000000"; else msecond_cntr <= msecond_cntr + 1;end if;
					if msecond_cntr = 998 then msecond_cntr_max <= '1'; else msecond_cntr_max <= '0';end if;
				end if;
			end if;
		end if;
		second <= msecond_cntr(9);
		ledsecond <= second;
		pinsecond <= second;
	end process;

---------------------------
-- count of 60s to form 1m
---------------------------
	SEC : process(clk, rst)
	begin
		if (rst = '1' ) then
			second_cntr <= "000000";
			second_cntr_max <= '0';
		elsif (clr = '1') then
			second_cntr <= "000000";
			second_cntr_max <= '0';		
		else
			if clk 'event and clk = '1' then
				if (msecond_cntr_max = '1' and usecond_cntr_max = '1' and tick_cntr_max = '1') then 
					if second_cntr_max = '1' then second_cntr <= "000000"; else second_cntr <= second_cntr + 1;end if;
					if second_cntr = 58 then second_cntr_max <= '1'; else second_cntr_max <= '0';end if;
				end if;
			end if;
		end if;
		minute <= second_cntr(5);
	end process;

---------------------------
-- Mux to select second or minute clk
---------------------------
	SELCLKNOGO : process(clk)
	begin
		if (sel_nogo = '1') 
--		if (rpi_sel_nogo = '1') 
			then clk_nogo <= msecond_cntr_max; 
			else clk_nogo <=  (second_cntr_max and msecond_cntr_max);
		end if;
	end process;
	SELCLKGO : process(clk)
	begin
		if (sel_go = '1') 
--		if (rpi_sel_go = '1') 
			then clk_go <= msecond_cntr_max; 
			else clk_go <=  (second_cntr_max and msecond_cntr_max);
		end if;
	end process;

----------------------------
-- address setup of MCP23017
----------------------------
--	SETADRESS : process(clk)
--	begin
--		a0 <= '0';
--		a1 <= '0';
--		a2 <= '0';
--	end process;

----------------------------
-- GO and NOGO counter
----------------------------
   GONOGOCTR : process(clk, rst)
		variable cntr_go, cntr_nogo : std_logic_vector(NBITS-1 downto 0);
		variable flag : std_logic;
	begin
		if rst = '1' then
			cntr_go := RAZ_NBITS;
			cntr_nogo := RAZ_NBITS;
			flag := GO;
			clr <= '0';
		elsif (clk 'event and clk = '1') then
			clr <= '0';
			case flag is
				when GO =>
					if (clk_go = '1' and usecond_cntr_max = '1' and tick_cntr_max = '1') then
						cntr_go := cntr_go + 1;
						if (cntr_go = sw_go) then
--						if (cntr_go = rpi_go) then
							clr <= '1';
							cntr_go := RAZ_NBITS;
							flag := NOGO;
						end if;
					end if;
				when NOGO =>
					if (clk_nogo = '1' and usecond_cntr_max = '1' and tick_cntr_max = '1') then
						cntr_nogo := cntr_nogo + 1;
						if (cntr_nogo = sw_nogo) then
--						if (cntr_nogo = rpi_nogo) then
							clr <= '1';
							cntr_nogo := RAZ_NBITS;
							flag := GO;
						end if; 
					end if;
			end case;
		end if;
		ledgonogo <= flag;
		pingonogo <= flag;
	end process;
	
end architecture;
