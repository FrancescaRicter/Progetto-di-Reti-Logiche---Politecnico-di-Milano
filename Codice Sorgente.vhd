library IEEE;
use ieee.STD_LOGIC_1164.ALL;
use ieee.std_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.ALL;
                              
entity project_reti_logiche is
port (
      i_clk : in std_logic;
      i_rst : in std_logic;
      i_start : in std_logic;
      i_data : in std_logic_vector(7 downto 0);
      o_address : out std_logic_vector(15 downto 0);
      o_done : out std_logic;
      o_en : out std_logic;
      o_we : out std_logic;
      o_data : out std_logic_vector (7 downto 0)
     );
end project_reti_logiche;
 
architecture Behavioral of project_reti_logiche is
 type state_type is (
       IDLE, --stato di partenza in cui si attende che il segnale i_start venga portato ad '1' prima di iniziare la computazione
       CALC_DIM, --vengono salvate le dimensioni della immagine: righe, colonne, numero totale di pixel
       WAIT_CLOCK,--stato di attesa di un ciclo di clock per interagire con la memoria in lettura o scrittura
       FETCH_NEXT, --stato per incrementare l'indirizzo corrente
       FIND_MAX_MIN,--lettura del valore di tutti i pixel dell'immagine per trovare il max e il min valore
       FIND_DELTA_VALUE,-- calcolo del delta value
       FIND_SHIFT_LEVEL, --lookup table con valori soglia per determinare lo 'shift level'
       CALC_PIXEL_VALUE, --applico lo shift ai valori dei pixel
       CHECK,--stato per settare '255' come massimo valore che può assumere un qualsiasi pixel
       WRITE_PIXEL_VALUE, --scrivo il nuovo valore dei pixel in memoria
       DONE_STATE --stato in cui porto alto il segnale 'done' che segna la fine della elaborazione 
       );
       
 signal current_state : state_type;
 
 signal N_col, N_rig, MAX_pixel, MIN_pixel, current_value, new_pixel_value, delta_value: std_logic_vector(7 downto 0);
 signal current_addr, addr_temp, read_addr, read_addr_temp,temp_pixel_value, dim_imm, write_addr, write_addr_temp: std_logic_vector(15 downto 0);
 signal shift_level: integer range 0 to 255;
 signal clock_tracker: integer range 0 to 4;
 signal next_tracker: integer range 0 to 2;
 signal calc_dim_step: integer range 0 to 2;

begin  process (i_clk, i_rst)
     begin
     if (i_rst= '1') then
          o_done <= '0';
          o_en <= '0';
          o_we <= '0';
          o_data <= "00000000";
          o_address <= "0000000000000000";
            N_col <= "00000000";
                  N_rig <= "00000000";
                  MAX_pixel <= "00000000";
                  MIN_pixel <= "00000000";
                  current_value <= "00000000";
                  write_addr <= "0000000000000000";
                  delta_value <= "00000000";
                  shift_level <= 0;
                  clock_tracker <= 0;
                  next_tracker <= 0;
                  calc_dim_step <= 0;
                  temp_pixel_value <= "0000000000000000";
                  new_pixel_value <= "00000000";
                  current_addr <= "0000000000000000";
                  addr_temp <= "0000000000000000";
                  read_addr <= "0000000000000000";
                  read_addr_temp <= "0000000000000000";
                  dim_imm <= "0000000000000000";
         current_state <= IDLE;
         
     elsif (rising_edge(i_clk)) then 
           case current_state is 
             when IDLE =>
             
                  N_col <= "00000000";
                  N_rig <= "00000000";
                  MAX_pixel <= "00000000";
                  MIN_pixel <= "00000000";
                  current_value <= "00000000";
                  write_addr <= "0000000000000000";
                  delta_value <= "00000000";
                  shift_level <= 0;
                  clock_tracker <= 0;
                  next_tracker <= 0;
                  calc_dim_step <= 0;
                  temp_pixel_value <= "0000000000000000";
                  new_pixel_value <= "00000000";
                  current_addr <= "0000000000000000";
                  addr_temp <= "0000000000000000";
                  read_addr <= "0000000000000000";
                  read_addr_temp <= "0000000000000000";
                  dim_imm <= "0000000000000000";
                   
                  if (i_start= '1' ) then 
                     current_state <= CALC_DIM;
                     
                  else
                     current_state <= IDLE;
                  end if;
                
              when CALC_DIM =>    
              case calc_dim_step is
                   when 0 =>
                        o_en <= '1';
                        o_we <= '0';
                        o_address <= "0000000000000000";
                        clock_tracker <= 0;
                        calc_dim_step <= 1;
                        current_state <= WAIT_CLOCK;     
                   when 1 => 
                        N_col <= i_data;
                        current_addr <= "0000000000000001";
                        o_en <= '1';
                        o_we <= '0';
                        o_address <= "0000000000000001";
                        calc_dim_step <= 2;
                        clock_tracker <= 0;
                        current_state <= WAIT_CLOCK;
                   when 2 =>
                        N_rig <= i_data;
                        o_en <= '0';
                        clock_tracker <= 1;
                        dim_imm <= std_logic_vector( unsigned(N_col) * unsigned(i_data));
                        current_state <= FIND_MAX_MIN;
                   end case;

              when WAIT_CLOCK =>
                   case clock_tracker is
                        when 0 =>
                         current_state <= CALC_DIM;
                        when 1 =>
                         current_state <= FIND_MAX_MIN;
                        when 2 => 
                         current_state <= CALC_PIXEL_VALUE;
                        when 3 =>  
                        write_addr <= write_addr_temp + "0000000000000001";
                        if ( read_addr <= dim_imm) then
                           next_tracker <=2;
                           current_state <= FETCH_NEXT;
                        else
                               current_state <= DONE_STATE;
                        end if;
                        when 4 =>
                          if (i_start = '0' ) then 
                              o_done <= '0';
                              o_en <= '0';
                              o_we <= '0';
                              o_data <= "00000000";
                              o_address <= "0000000000000000";
                              current_state <= IDLE;
                           else 
                               current_state <= WAIT_CLOCK;
                           end if;
                    end case;
             
               when FIND_MAX_MIN =>
                    if (dim_imm = "0000000000000000")then
                      current_state <= DONE_STATE;
                    else
                    o_en <= '0';
                       if (current_addr = "0000000000000001") then
                          addr_temp <= "0000000000000001";
                          next_tracker<= 1;
                          current_state <= FETCH_NEXT;
                       elsif(current_addr =  "0000000000000010") then
                           addr_temp <= current_addr;
                           current_value <= i_data;
                           MAX_pixel <= i_data;
                           MIN_pixel <= i_data;
                           next_tracker<= 1;
                           if (dim_imm = "00000001")then
                              current_state <= FIND_DELTA_VALUE;
                           else
                           current_state <= FETCH_NEXT;
                           end if;
                       elsif (current_addr = dim_imm + "0000000000000001")then
                             current_value <= i_data;
                             if(i_data >= MAX_pixel)then
                                MAX_pixel <= i_data;
                             end if;
                             if(i_data<=MIN_pixel)then
                                   MIN_pixel <= i_data;
                             end if;
                             current_state <=FIND_DELTA_VALUE;
                       else
                           current_value <= i_data;
                           addr_temp <= current_addr;
                           if(i_data >= MAX_pixel)then
                              MAX_pixel <= i_data;
                           end if;
                           if(i_data<=MIN_pixel)then
                                MIN_pixel <= i_data;
                           end if;
                           next_tracker <= 1;
                           current_state <= FETCH_NEXT;
                        end if;
                     end if;
                     
               when FETCH_NEXT =>
                    case next_tracker is 
                         when 0 =>
                             current_state <= IDLE;
                         when 1 => 
                              current_addr <= addr_temp + "0000000000000001";
                              o_en <= '1';
                              o_we <= '0';
                              o_address <= addr_temp + "0000000000000001";
                              clock_tracker <= 1;
                              current_state <= WAIT_CLOCK;       
                         when 2 => 
                               read_addr <= read_addr_temp + "0000000000000001";
                               o_en <= '1';
                               o_we <= '0';
                               o_address <= read_addr_temp + "0000000000000001";
                               clock_tracker <= 2;
                               current_state <= WAIT_CLOCK;
                      end case;
               
                when FIND_DELTA_VALUE =>
                     o_en <= '0';
                     delta_value <= std_logic_vector(unsigned(MAX_pixel - MIN_pixel));
                current_state <= FIND_SHIFT_LEVEL;
                
                when FIND_SHIFT_LEVEL =>
                     if (delta_value = "00000000")then
                        shift_level <= 8;
                     elsif (delta_value >= "00000001" AND delta_value <= "00000010")then
                          shift_level <= 7;
                     elsif (delta_value >= "00000011" AND delta_value <= "00000110")then
                              shift_level <= 6;
                     elsif (delta_value >= "00000111" AND delta_value <= "00001110")then
                              shift_level <= 5;
                     elsif (delta_value >= "00001111" AND delta_value <= "00011110")then
                              shift_level <= 4;
                     elsif (delta_value >= "00011111" AND delta_value <= "00111110")then
                              shift_level <= 3;
                     elsif (delta_value >= "00111111" AND delta_value <= "01111110")then
                              shift_level <= 2;
                     elsif (delta_value >= "01111111" AND delta_value <= "11111110")then
                              shift_level <= 1;
                     else
                              shift_level <= 0;  
                     end if;
                     write_addr <= dim_imm + "0000000000000010";
                     read_addr <= "0000000000000001";
                     current_value <= "00000000";
                     current_state <= CALC_PIXEL_VALUE;
                
                when CALC_PIXEL_VALUE =>
                     o_en <= '0';
                     if (read_addr = "0000000000000001")then
                         read_addr_temp <= read_addr;
                         next_tracker <= 2;
                         current_state <= FETCH_NEXT;
                     else
                         read_addr_temp <= read_addr;
                         current_value <= i_data;
                         
                         temp_pixel_value <= std_logic_vector(shift_left (unsigned ((i_data - MIN_pixel)* "00000001" ),shift_level));
                         current_state <= CHECK; 
                     end if;    
           
                 when CHECK =>
                      if (temp_pixel_value >= "0000000011111111")then
                              new_pixel_value <= "11111111";
                          current_state <= WRITE_PIXEL_VALUE; 
                      else
                          new_pixel_value <= temp_pixel_value (7 downto 0);
                      current_state <= WRITE_PIXEL_VALUE; 
                      end if; 
                current_state <= WRITE_PIXEL_VALUE; 
                
                when WRITE_PIXEL_VALUE =>     
                     o_we <= '1';
                     o_en <= '1';
                     o_address <= write_addr;
                     o_data <= new_pixel_value;
                     write_addr_temp <= write_addr;
                     clock_tracker <= 3;
                     current_state <= WAIT_CLOCK;
          
                when DONE_STATE =>
                       o_done <= '1';
                       o_we <= '0';
                       o_en <= '0';
                       clock_tracker <= 4;
                       current_state <= WAIT_CLOCK;
                              
              end case;
              end if;                
      end process;
end Behavioral;
