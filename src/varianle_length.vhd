


signal valid_out : std_logic := '0';
signal count_leading_zeros : unsigned(1 downto 0) := (others=>'0');

process (clk)
    if rising_edge(clk) then

        if reset = '1' then
            count_leading_zeros <= (others=>'0');
            valid_out <= '0';
        else
            if data_in = '1' then
                data_out <= std_logic_vector(count_leading_zeros);
                valid_out <= '1';
                count_leading_zeros <= (others=>'0');
            else
                valid_out <= '0';
                count_leading_zeros <= count_leading_zeros + 1;
            end if;
        end if;

    end if;
end process;


-- data_in(3 downto 0);
-- data_in_valid : std_logic;

-- "0011" => (C, A)?
-- "0010", "1001" => (001, 01, 001)

type slv_table is (natural range <>) of 
constant PARSING_TABLE : slv_table := (
-- jwei@evertz.com
    

type state_t is (
    ST_IDLE,
    ST_CONTINUATION
);

signal state : state_t := ST_IDLE;

process (clk)
begin
    if rising_edge(clk) then
        if reset = '1' then
            state <= ST_IDLE;
        else

            case state is
                when ST_IDLE =>
                when ST_CONTINUATION =>
            end case;

        end if;
    end if;
end process;
