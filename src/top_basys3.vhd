--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
component controller_fsm is
    port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end component controller_fsm;

component ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end component ALU;

component clock_divider is
	generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
											   -- Effectively, you divide the clk double this 
											   -- number (e.g., k_DIV := 2 --> clock divider of 4)
	port ( 	i_clk    : in std_logic;
			i_reset  : in std_logic;		   -- asynchronous
			o_clk    : out std_logic		   -- divided (slow) clock
	);
end component clock_divider;

component twos_comp is
    port (
        i_bin: in std_logic_vector(7 downto 0);
        o_sign: out std_logic;
        o_hund: out std_logic_vector(3 downto 0);
        o_tens: out std_logic_vector(3 downto 0);
        o_ones: out std_logic_vector(3 downto 0)
    );
end component  twos_comp;

component TDM4 is
	generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
    Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC;
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	);
end component TDM4;

component button_debounce is
	Port(	clk: in  STD_LOGIC;
			reset : in  STD_LOGIC;
			button: in STD_LOGIC;
			action: out STD_LOGIC);
end component button_debounce;



signal reg_a, reg_b, alu_out, o_led_mux: std_logic_vector (7 downto 0) := (others => '0');
signal w_cycle, w_hunds, w_tens, w_ones, w_anode, w_hex, o_an: std_logic_vector (3 downto 0):= (others => '0');
signal w_clock, w_adv: std_logic := '0';
signal w_sign: std_logic;
signal w_sel, o_seg, o_sign_mux : std_logic_vector (6 downto 0);
signal w_sign_padded : std_logic_vector (1 downto 0);


  
begin

    state_register : process(w_clock)           
    begin                                     
       if rising_edge(w_clock) then         
          if btnU = '1' then           
              reg_a <= (others => '0');
              reg_b <= (others => '0');     
          elsif w_adv = '1' then
            case w_cycle is
                when "0001" => 
                    reg_a <= sw;
                when "0010" => 
                    reg_b <= sw;
                when others => 
                    null;
            end case;
        end if;
    end if;
end process state_register;
                      
	-- PORT MAPS ----------------------------------------
	clk_div : clock_divider -- How many clk cycles until slow clock toggle
										   -- number (e.g., k_DIV := 2 --> clock divider of 4)
	port map( 	
	        i_clk => clk,
			i_reset	=> btnU,	   -- asynchronous
			o_clk => w_clock	   -- divided (slow) clock
	);
	
	button_debounce_1: button_debounce
	   port map(
	   	clk => w_clock,
		reset => btnU,
		button => btnC,
		action => w_adv
		);
	
    controller_fsm_1 : controller_fsm
        port map(
            i_reset => btnU,
            i_adv => w_adv,
            o_cycle => w_cycle
            );
    
    ALU_1 : ALU 
    port map( 
           i_A => reg_a,
           i_B => reg_b,
           i_op => sw(2 downto 0),
           o_result => alu_out,
           o_flags => led(15 downto 12)
           );

    with w_cycle select
        o_led_mux <= 
            x"00" when "0001",
            reg_a when "0010",
            reg_b when "0100",
            alu_out when "1000",
            x"00" when others;
    
    twos_comp_1: twos_comp
    port map(
        i_bin => o_led_mux,
        o_sign => w_sign,
        o_hund => w_hunds,
        o_tens => w_tens,
        o_ones => w_ones
    );
    
    
    TDM4_1 : TDM4
    port map( 
           i_clk => w_clock,	
           i_reset => btnU,	
           i_D3 => w_sign,
		   i_D2 => w_hunds,
		   i_D1 => w_tens,
		   i_D0 => w_ones,
		   o_data => w_hex,
		   o_sel =>	w_anode	
	);
	
	sevenseg_decoder_1 : sevenseg_decoder
        port map(
            i_Hex => w_hex,
            o_seg_n => w_sel
        );
    
    with w_sign select
       o_sign_mux <=
        "1111111" when '0',
        "0111111" when '1';
    
    with w_anode select
       o_seg <=
        o_sign_mux when "0111",
        w_sel when others;
    
--    with w_cycle select
--       o_an <=
--        "1111" when "0001",
--        w_sel when others;
        
	
	-- CONCURRENT STATEMENTS ----------------------------
	an <= w_anode;
	seg <= o_seg;
	led(3 downto 0) <= w_cycle;
	
end top_basys3_arch;
