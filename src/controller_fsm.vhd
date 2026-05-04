----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_clk : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is
    type state is (s_reset, s_op1, s_op2, s_math); -- Renamed to avoid keywords
    signal f_state_cur, f_state_next: state := s_reset;
begin

    -- 1. Sequential Process (The Register)
    -- This "moves" the FSM forward on each clock tick
    state_register : process(i_clk, i_reset)
    begin
        if i_reset = '1' then
            f_state_cur <= s_reset;
        elsif rising_edge(i_clk) then
            f_state_cur <= f_state_next;
        end if;
    end process;

    -- 2. Next State Logic (Combinational)
    -- This decides WHERE to go next
    f_state_next <= s_op1  when (f_state_cur = s_reset and i_adv = '1') else
                    s_op2  when (f_state_cur = s_op1   and i_adv = '1') else
                    s_math when (f_state_cur = s_op2   and i_adv = '1') else
                    s_reset when (f_state_cur = s_math  and i_adv = '1') else
                    f_state_cur;

    -- 3. Output Logic
    with f_state_cur select
        o_cycle <= "0001" when s_reset,
                   "0010" when s_op1,
                   "0100" when s_op2,
                   "1000" when s_math,
                   "0001" when others;

end FSM;
