library ieee ;
use ieee.std_logic_1164.all ;

entity vscputb is end entity ;
architecture stim of vscputb is 

  constant INSTR_add : std_logic_vector( 1 downto 0 ) := "00" ;
  constant INSTR_and : std_logic_vector( 1 downto 0 ) := "01" ;
  constant INSTR_jmp : std_logic_vector( 1 downto 0 ) := "10" ;
  constant INSTR_inc : std_logic_vector( 1 downto 0 ) := "11" ;

  constant A_WIDTH : integer := 6 ; 
  constant D_WIDTH : integer := 8 ;
  
  signal clk , reset , start , write_en : std_logic ;
  signal addr : std_logic_vector( A_WIDTH-1 downto 0 ) ; 
  signal data : std_logic_vector ( D_WIDTH-1 downto 0 ) ;
  signal status : std_logic ;

  procedure do_synch_active_high_half_pulse ( 
      signal formal_p_clk : in std_logic ; 
      signal formal_p_sig : out std_logic 
    ) is
  begin
    wait until formal_p_clk='0' ;  formal_p_sig <= '1' ;
    wait until formal_p_clk='1' ;  formal_p_sig <= '0' ;
  end procedure ;

  procedure do_program ( 
      signal formal_p_clk : in std_logic ; 
      signal formal_p_write_en : out std_logic ; 
      signal formal_p_addr_out , formal_p_data_out : out std_logic_vector ;
      formal_p_ADDRESS_in , formal_p_DATA_in : in std_logic_vector     
    ) is
  begin
    wait until formal_p_clk='0' ;  formal_p_write_en <= '1' ;
    formal_p_addr_out <= formal_p_ADDRESS_in ; 
    formal_p_data_out <= formal_p_DATA_in ;
    wait until formal_p_clk='1' ;  formal_p_write_en <='0' ;
  end procedure ;

begin

  dut_vscpu : entity work.vscpu( rch )
      port map ( clock => clk , reset => reset , start => start ,
             write_in => write_en , addr => addr  , data => data ) ;
             
  process begin
    clk <= '0' ;
    for i in 0 to 99 loop 
      wait for 1 ns ; clk <= '1' ;  wait for 1 ns ; clk <= '0';
    end loop ;
    wait ;
  end process ;

  
  process begin
    reset <= '0' ;  start <= '0' ; write_en <= '0' ;
    addr <= "000000" ;  data <= "00000000" ;
    do_synch_active_high_half_pulse ( clk, reset ) ; -- acc=0
    do_program ( clk, write_en, addr, data, "000001" , INSTR_add & "00" & "0101"  ) ; 
    -- LABEL1 acc += mem [ 5 ]
    do_program ( clk, write_en, addr, data, "000010" , INSTR_and & "00" & "0110"  ) ; 
    -- acc &= mem [ 6 ]
    do_program ( clk, write_en, addr, data, "000011" , INSTR_inc & "00" & "0000"  ) ; 
    -- acc += 1
    do_program ( clk, write_en, addr, data, "000100" , INSTR_jmp & "00" & "0001"  ) ; 
    -- jmp to LABEL1
    do_program ( clk, write_en, addr, data, "000101" , X"27"  ) ; -- mem[ 5 ]
    do_program ( clk, write_en, addr, data, "000110" , X"39"  ) ; -- mem[ 6 ]
    do_synch_active_high_half_pulse ( clk, start ) ; 
    wait ;
  end process ;
end architecture ;

