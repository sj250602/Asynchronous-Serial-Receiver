----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/17/2022 11:43:38 PM
-- Design Name: 
-- Module Name: A7 - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity A7 is
 Port ( clk : in  std_logic; -- define a clock 
        reset : in std_logic;   -- define a reset button
        rx_data_in : in std_logic;  -- define a recieve data input
        segment : out std_logic_vector(6 downto 0); -- define a vector for seven segment display
        anode:out std_logic_vector(3 downto 0)); -- define a vector for the 4 anodes

        -- dv
end A7;

architecture Behavioral of A7 is
type rx_states is (rx_idle,rx_start,rx_data_shift,rx_stop); -- define a FSM with itls idle and start,stop state
signal rx_state :rx_states:=rx_idle; -- define intial state as idle
signal rx_data : std_logic := '0'; -- define intial data as 0
signal rx_clk_counter : integer range 0 to 10416:=0; -- define a clock counter
signal rx_index : integer range 0 to 7 :=0; -- define a index
signal rx_temp_data : std_logic_vector(7 downto 0):="00000000"; -- define a vector for seven segment display 
signal rx_perm_data : std_logic_vector(7 downto 0):="00000000"; -- define a vector for seven segment display
signal rx_stop_bit : std_logic := '0'; -- define a state for stop 

signal Bt:std_logic_vector(3 downto 0):="0000"; -- define a vector for 4 buttons
signal clk_input:std_logic:='0'; -- define a clock input for checking the glow the anode
signal refresh_clk :std_logic_vector(19 downto 0):=(others => '0'); -- define a clock counter


-- define  a process  for showing the output on the seven segment display
begin

    process(Bt)
    begin
    segment(0) <= (not Bt(3) and not Bt(2) and not Bt(1) and Bt(0)) or(not Bt(3) and Bt(2) and not Bt(1) and not Bt(0)) or (Bt(3) and Bt(2) and not Bt(1) and Bt(0)) or (Bt(3) and not Bt(2) and Bt(1) and Bt(0));
    segment(1) <= (Bt(2) and Bt(1) and not Bt(0)) or (Bt(3) and Bt(1) and Bt(0)) or (not Bt(3) and Bt(2) and not Bt(1) and Bt(0)) or (Bt(3) and Bt(2) and not Bt(1) and not Bt(0));
    segment(2) <= ((NOT Bt(3)) AND (NOT Bt(2)) AND Bt(1) AND (NOT Bt(0))) OR (Bt(3) AND Bt(2) AND Bt(1)) OR (Bt(3) AND Bt(2) AND (NOT Bt(0)));
    segment(3) <= ((NOT Bt(3)) AND (NOT Bt(2)) AND (NOT Bt(1)) AND Bt(0)) OR ((NOT Bt(3)) AND Bt(2) AND (NOT Bt(1)) AND (NOT Bt(0))) OR (Bt(3) AND (NOT Bt(2)) AND Bt(1) AND (NOT Bt(0))) OR (Bt(2) AND Bt(1) AND Bt(0));
    segment(4) <= ((NOT Bt(2)) AND (NOT Bt(1)) AND Bt(0)) OR ((NOT Bt(3)) AND Bt(0)) OR ((NOT Bt(3)) AND Bt(2) AND (NOT Bt(1)));
    segment(5) <= ((NOT Bt(3)) AND (NOT Bt(2)) AND Bt(0)) OR ((NOT Bt(3)) AND (NOT Bt(2)) AND (Bt(1))) OR ((NOT Bt(3)) AND Bt(1) AND Bt(0)) OR (Bt(3) AND Bt(2) AND (NOT Bt(1)) AND Bt(0));
    segment(6) <= ((NOT Bt(3)) AND (NOT Bt(2)) AND (NOT Bt(1))) OR ((NOT Bt(3)) AND Bt(2) AND Bt(1) AND Bt(0)) OR (Bt(3) AND Bt(2) AND (NOT Bt(1)) AND (NOT Bt(0)));

    end process;
    -- define a process over clock to increase the counter
    process(clk)
    begin 
    if rising_edge(clk) then
        refresh_clk <= refresh_clk + '1';
        end if ;
    end process;
    
    clk_input <= refresh_clk(19); -- define a clk_input for glow the anode

-- define a process over clk_input if it is 0 then we need to glow the rightmost anode and if it is 1 then we need to glow the 2nd right display.
    process(clk_input)
    begin
    case( clk_input ) is

        when '0' =>
            anode <= "1110";
            Bt <= rx_perm_data(3 downto 0);

        when '1' =>
            anode <= "1101";
            Bt <= rx_perm_data(7 downto 4);
        when others => anode <= "1111";

    end case ;
    end process;
-- define a process over clk and taking the input in rx_data over the rising_edge
    process (clk)
    begin
        if rising_edge(clk) then
            rx_data <= rx_data_in;        
        end if ;
    end process;

-- process for changing the states. 
    process(clk)
    begin
        if rising_edge(clk) then
            -- define a process over clk and check reste button is pressed then set the display output as 0 otherwise
            if reset = '1' then
                rx_temp_data <= (others => '0');
                rx_state <= rx_idle;
                rx_clk_counter <=0;
                rx_index <=0;
            end if;
            case( rx_state ) is
                -- when the state is idle then set the stop bit as 0 and clk counter as 0 and index as 0
                when rx_idle =>
                    rx_stop_bit <= '0';
                    rx_clk_counter <=0;
                    rx_index <=0;
                
                    if rx_data = '0' then
                        rx_state <= rx_start;
                    else
                        rx_state <= rx_idle;
                     end if ;
                -- similarly when the state is start than check if counter is 5208((clock rate/baud rate)/2) than if rx_data =0 than go to the next state otherwise go to the idle state
                when rx_start =>
                    if rx_clk_counter = 5208 then
                        if rx_data = '0' then
                            rx_clk_counter <=0;
                            rx_state <= rx_data_shift;
                        else
                            rx_state <= rx_idle;
                        end if ;
                    elsif rx_clk_counter < 5208 then
                        rx_clk_counter <= rx_clk_counter+1;
                        rx_state <= rx_start;
                    else
                        rx_state <= rx_idle;
                    end if ;
                -- similarly check if counter =10416((clock rate/baud rate)) than collect the data go to next state otheriwse stay on the same state
                when rx_data_shift =>
                    if rx_clk_counter = 10416 then
                        rx_clk_counter <= 0;
                        rx_temp_data(rx_index) <= rx_data;
                        if rx_index = 7 then
                            rx_index <= 0;
                            rx_state <= rx_stop;
                        else
                            rx_index<=rx_index+1;
                            rx_state <= rx_data_shift;
                        end if ;
                    else
                        rx_clk_counter<=rx_clk_counter+1;
                        rx_state<=rx_data_shift;
                    end if ;
                -- this is final state where we check if counter is 10416 than go to the idle state otheriwse stay on the stop state
                when rx_stop =>
                    if rx_clk_counter = 10416 then
                        rx_clk_counter <= 0;
                        if rx_data = '1' then
                            rx_stop_bit<='1';
                            rx_clk_counter <= 0;
                            rx_state<=rx_idle;
                        else
                            rx_clk_counter <= 0;
                            rx_state<=rx_idle;
                        end if ;
                    else
                        rx_clk_counter <= rx_clk_counter + 1;
                        rx_state <= rx_stop;
                    end if ;

                when others =>
                    rx_state <= rx_idle;
            end case ;
        end if ;
        rx_perm_data <= rx_temp_data;
    end process;

  

end Behavioral;