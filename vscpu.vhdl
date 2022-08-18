library ieee ; 
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all;

entity vscpu is
  generic (
    VSCPU_A_WIDTH : integer := 6 ; 
    VSCPU_D_WIDTH : integer := 8 ;
    -- MEMSIZE : integer := ((2**VSCPU_A_WIDTH)-1) ;
    MEMSIZE : integer := ((2**6)-1) ;
    PC_STARTS_AT : std_logic_vector( 5 downto 0) := "000001" ) ;
  port (  
    clock , reset ,  start , write_in : in std_logic ;   
    addr : in std_logic_vector( VSCPU_A_WIDTH-1 downto 0 ) ;
    data : in std_logic_vector( VSCPU_D_WIDTH-1 downto 0 ) ; 
    status : out std_logic ) ;
end entity ;

architecture rch of vscpu is

constant INSTR_add : std_logic_vector (1 downto 0) := "00" ;
constant	INSTR_and : std_logic_vector (1 downto 0) := "01" ;
constant	INSTR_jmp : std_logic_vector (1 downto 0) := "10" ;
constant	INSTR_inc : std_logic_vector (1 downto 0) := "11" ;



type t_state is (stfetch1, stfetch2, stfetch3,stadd1,stadd2,
		  sthalt, stand1, stand2, stinc1, stjmp1);
signal stvar_ff, stvar_ns : t_state := sthalt;
signal AC_ff, AC_ns : std_logic_vector (VSCPU_D_WIDTH-1 downto 0) := (others => '0');
signal PC_ff : std_logic_vector (VSCPU_A_WIDTH-1 downto 0) := PC_STARTS_AT;
signal PC_ns : std_logic_vector (VSCPU_A_WIDTH-1 downto 0) := (others => '0');
signal AR_ff, AR_ns : std_logic_vector (VSCPU_A_WIDTH-1 downto 0) := (others => '0');
signal IR_ff, IR_ns : std_logic_vector (1 downto 0) := (others => '0');
signal DR_ff, DR_ns : std_logic_vector (VSCPU_D_WIDTH-1 downto 0) := (others => '0');

signal mem_address : std_logic_vector (VSCPU_A_WIDTH-1 downto 0) := (others => '0');
signal mem_write, mem_read : std_logic := '0';

type t_ram is array (0 to 63 ) of std_logic_vector (7 downto 0);
signal mem : t_ram;


begin

mem_address <= addr when (sthalt = stvar_ff)  
			else 	AR_ff;

process 
begin
	wait until clock = '1';
	if (reset = '1') then 
				for i in 0 to MEMSIZE-1 loop
					mem(i) <= (others => '0');
				end loop;

	elsif ( write_in = '1' and mem_read = '0') then 
						mem(  to_integer (unsigned(mem_address))) <= data;
	end if;

end process;

dbus <= mem(  to_integer (unsigned(mem_address))) when ( mem_read = '1') 
				else (others => 'Z');

process 
begin
	wait until clock = '1';
	if ( reset = '1' ) then stvar_ff <= sthalt;
	elsif (start = '1' ) then stvar_ff <= stfetch1;
	else stvar_ff <= stvar_ns;
	end if;

end process; 

process( stvar_ff) 
begin
	if ( stvar_ff = stfetch2 or stvar_ff = stadd1 or stvar_ff = stand1 ) then mem_read <='1';
	else mem_read <= '0';
	end if;
	
end process;
	
-- combinational controller state
process( stvar_ff, start, IR_ff)  
begin
	stvar_ns <= stvar_ff;
	case (stvar_ff) is
		when sthalt => if ( start = '1') then stvar_ns <= stfetch1; end if;
		when stfetch1 => stvar_ns <= stfetch2;
		when stfetch2 => stvar_ns <= stfetch3;
		when stfetch3 => case (IR_ff) is
								when INSTR_add => stvar_ns <= stadd1;
								when INSTR_and => stvar_ns <= stand1;
								when INSTR_inc => stvar_ns <= stinc1;
								when INSTR_jmp => stvar_ns <= stjmp1;
								when others => null;
								end case;
		when stadd1 => stvar_ns <= stadd2;
		when stadd2 => stvar_ns <= stfetch1;
		when stand1=> stvar_ns <= stand2;
		when stand2 => stvar_ns <= stfetch1;
		when stinc1 => stvar_ns <= stfetch1;
		when stjmp1 => stvar_ns <= stfetch1;
		when others => null;
	end case;
end process;

process 
  begin
    wait until clock = '1'; 
		AR_ff <= AR_ns; PC_ff <= PC_ns; AC_ff <= AC_ns;
		IR_ff <= IR_ns; DR_ff <= DR_ns;
	 
end process ;

-- combinational datapath
process( stvar_ff, PC_ff, AC_ff, DR_ff, AR_ff, IR_ff, data )  
begin
	PC_ns <= PC_ff; AC_ns <= AC_ff; 
	AR_ns <= AR_ff; IR_ns <= IR_ff; DR_ns <= DR_ff;
	case (stvar_ff) is
		when sthalt => null;
		when stfetch1 => AR_ns <= PC_ff;
		when stfetch2 =>PC_ns <= std_logic_vector( unsigned(PC_ff) + 1);
							 DR_ns <= data; 
							 AR_ns <= data( 5 downto 0); 
							 IR_ns <= data( 7 downto 6);
		when stfetch3 => null;
		when stadd1 => DR_ns <=data;
		when stadd2 => AC_ns <= std_logic_vector( unsigned(AC_ff) +unsigned(DR_ff));
		when stand1 => DR_ns <= data;
		when stand2 => AC_ns <= AC_ff and DR_ff;
		when stjmp1 => PC_ns <= DR_ff( 5 downto 0 );
		when stinc1 => AC_ns <= std_logic_vector( unsigned(AC_ff) + 1);
		
		when others => null;
	end case;
end process;



-- memory
process begin
	wait until clock = '1';
	if (mem_write ='1') then 
			mem( to_integer (unsigned(mem_address)) ) <= data; 
	end if;
end process;


process 
begin
	wait until clock ='1' ;
	if (stvar_ff = stfetch1) then
			report " AC_ff "& integer'image(to_integer(unsigned(AC_ff)));
	end if;		

end process;



end architecture ;

