
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity packet_check is
    generic (
        WORD_SIZE              : natural := 64;
        HEADER_WORDS           : natural := 16;
        PACKET_WORDS           : natural := 100
    );
    port (
        clk                    : in  std_logic;
        data_in                : in  std_logic_vector(WORD_SIZE-1 downto 0);
        data_in_valid          : in  std_logic;
        data_in_sop            : in  std_logic;
        data_out               : out std_logic_vector(WORD_SIZE-1 downto 0);
        data_out_sop           : out std_logic
    );
end entity;

architecture rtl of packet_check is

    function chksum(
        existing_chksum        : unsigned;
        new_word               : unsigned
    ) return unsigned is
    begin
        -- I'm not sure what the exact checksum algorithm is.
        -- I don't know if there is some standard, widely used one,
        -- but I haven't implemented it myself.
        return existing_chksum + new_word;
    end function chksum;

    type state_t is (
        ST_IDLE,
        ST_HEADER,
        ST_CHECKSUM,
        ST_DATA,
        ST_OUTPUT
    );

    signal state               : state_t := ST_IDLE;
    signal next_state          : state_t := ST_IDLE;
    signal goal_checksum       : unsigned(WORD_SIZE-1 downto 0) := (others=>'0');
    signal calc_checksum       : unsigned(WORD_SIZE-1 downto 0) := (others=>'0');
    signal bram_we             : std_logic := '0';
    signal bram_wr_data        : std_logic_vector(WORD_SIZE-1 downto 0) := (others=>'0');
    signal bram_wr_addr        : unsigned(ADDR_WIDTH-1 downto 0) := (others=>'0');
    signal bram_rd_data        : std_logic_vector(WORD_SIZE-1 downto 0) := (others=>'0');
    signal bram_rd_addr        : unsigned(ADDR_WIDTH-1 downto 0) := (others=>'0');

begin

    fsm: process (data_in_valid, data_in_sop)
    is
    begin
        if rising_edge(clk) then
            -- By default, this is 0.
            -- In one specific case lower in this process,
            -- this assignment is overridden.
            data_out_sop <= '0';
            case state is
                when ST_IDLE =>
                    if data_in_sop = '1' then
                        calc_checksum <= chksum(0, data_in);
                        state <= ST_HEADER;
                    end if;
                when ST_HEADER =>
                    if data_in_valid = '1' then
                        calc_checksum <= chksum(calc_checksum, data_in);
                        if bram_wr_addr = (PACKET_WORDS-1) then
                            goal_checksum <= data_in; -- ???
                            state <= ST_CHECKSUM;
                        end if;
                    end if;
                when ST_CHECKSUM =>
                    if goal_checksum = calc_checksum then
                        state <= ST_DATA;
                    else
                        state <= ST_IDLE;
                    end if;
                when ST_DATA =>
                    -- Remember that the writing is being done
                    -- in another process.
                    if bram_wr_addr = (PACKET_WORDS-1) then
                        state <= ST_OUTPUT;
                        data_out_sop <= '1';
                    end if;
                when ST_OUTPUT =>
                    -- When this is done, set checksum back to 0
                    if bram_rd_addr = (PACKET_WORDS-1) then
                        state <= ST_IDLE;
                    end if;
            end case;
        end if;
    end process;

    bram_ctrl: process (clk)
    is
    begin
        if rising_edge(clk) then
            ----------------------------------
            -- WRITE SIDE
            ----------------------------------
            -- Everything going to BRAM is delayed
            -- one cycle after it comes in input line.
            bram_wr_data <= data_in;
            bram_we <= data_in_valid;
            if data_in_sop = '1' then
                bram_wr_addr <= 0;
            elsif data_in_valid = '1' then
                bram_wr_addr <= bram_wr_addr + 1;
            end if;

            ----------------------------------
            -- READ SIDE
            ----------------------------------
            -- Note that these read operations assume the following cycles (moving down is later in time)
            -- State | Address | Data | SOP
            -- DATA  | 0       | D0   | 0
            -- OUTPUT| 1       | D0   | 1
            -- OUTPUT| 2       | D1   | 0
            -- OUTPUT| 3       | D2   | 0
            -- ....
            if state = ST_OUTPUT then
                -- Can't read and write at the same time,
                -- at least not without address checks.
                -- That is, we can't get data in while sending data out.
                -- Can assume 1000s of cycles between,
                -- but call this an explicit statement of assumptions.
                assert data_in_sop = '0' and data_in_valid='0' severity failure;
                bram_rd_addr <= bram_rd_addr + 1;
            else
                bram_rd_addr <= 0;
            end if;
        end if;
    end process;

    data_out_valid <= '1' when (state = ST_OUTPUT) else '0';

    packet_storage: BRAM
    generic map (
        DATA_WIDTH             => WORD_SIZE,
        ADDR_WIDTH             => ADDR_WIDTH
    )
    port map (
        clk                    => clk,
        we                     => bram_we,
        write_address          => bram_wr_addr,
        write_data             => bram_wr_data,
        read_address           => bram_rd_addr,
        read_data              => data_out
    );
            

end rtl;

