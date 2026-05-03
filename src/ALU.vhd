----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is

signal o_temp : std_logic_vector(8 downto 0);
    
begin
    
    with i_op select
        o_temp <= std_logic_vector(unsigned('0' & i_A) + unsigned('0' & i_B)) when "000",
                    std_logic_vector(unsigned('0' & i_A) - unsigned('0' & i_B)) when "001",
                    ('0' & i_A and '0' & i_B) when "010",
                    ('0' & i_A or '0' & i_B) when "011",
                    (others => '0') when others;
                    
        o_result <= o_temp(7 downto 0);
        
        o_flags(3) <= o_temp(7); --N
        
        o_flags(2) <= '1' when o_temp(7 downto 0) = "00000000" else '0';--Z
                      
        o_flags(1) <= o_temp(8) when i_op = "000" else
                      not o_temp(8) when i_op = "001" else
                      '0';--C
        
        o_flags(0) <= ((i_A(7) xnor i_B(7)) and (i_A(7) xor o_temp(7))) when i_op = "000" else -- Add logic
              ((i_A(7) xor i_B(7))  and (i_A(7) xor o_temp(7))) when i_op = "001" else -- Sub logic
              '0';--V
        
            
    
end Behavioral;
