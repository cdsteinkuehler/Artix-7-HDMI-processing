----------------------------------------------------------------------------------
-- Engineer:    Mike Field <hamster@snap.net.nz>
--
-- Create Date: 22.07.2015 21:10:34
-- Module Name: hdmi_design - Behavioral
-- Project Name:
--
-- Description: Top level of a video processing design
--
------------------------------------------------------------------------------------
-- The MIT License (MIT)
--
-- Copyright (c) 2015 Michael Alan Field
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
------------------------------------------------------------------------------------
----- Want to say thanks? ----------------------------------------------------------
------------------------------------------------------------------------------------
--
-- This design has taken many hours - with the industry metric of 30 lines
-- per day, it is equivalent to about 6 months of work. I'm more than happy
-- to share it if you can make use of it. It is released under the MIT license,
-- so you are not under any onus to say thanks, but....
--
-- If you what to say thanks for this design how about trying PayPal?
--  Educational use - Enough for a beer
--  Hobbyist use    - Enough for a pizza
--  Research use    - Enough to take the family out to dinner
--  Commercial use  - A weeks pay for an engineer (I wish!)
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity hdmi_design is
    Port (
        sysclk          : in    std_logic;  -- 125 MHz
        -- Control signals
        led             : out   std_logic_vector(3 downto 0) :=(others => '0');
        sw              : in    std_logic_vector(3 downto 0) :=(others => '0');
        jc              : out   std_logic_vector(7 downto 0) :=(others => '0');

        --HDMI input signals
        hdmi_rx_cec     : inout std_logic;
        hdmi_rx_hpd     : out   std_logic;
        hdmi_rx_scl     : in    std_logic;
        hdmi_rx_sda     : inout std_logic;
        hdmi_rx_clk_n   : in    std_logic;
        hdmi_rx_clk_p   : in    std_logic;
        hdmi_rx_n       : in    std_logic_vector(2 downto 0);
        hdmi_rx_p       : in    std_logic_vector(2 downto 0);

        --- HDMI out
        hdmi_tx_cec     : inout std_logic;
        hdmi_tx_clk_n   : out   std_logic;
        hdmi_tx_clk_p   : out   std_logic;
        hdmi_tx_hpd     : in    std_logic;
        hdmi_tx_rscl    : inout std_logic;
        hdmi_tx_rsda    : inout std_logic;
        hdmi_tx_p       : out   std_logic_vector(2 downto 0);
        hdmi_tx_n       : out   std_logic_vector(2 downto 0)
        -- For dumping symbols
        -- rs232_tx     : out std_logic
    );
end hdmi_design;

architecture Behavioral of hdmi_design is
    component hdmi_io is
    Port (
        clk100        : in STD_LOGIC;
        clk200        : in STD_LOGIC;
        -------------------------------
        -- Control signals
        -------------------------------
        clock_locked  : out std_logic;
        data_synced   : out std_logic;
        debug         : out std_logic_vector(7 downto 0);
        -------------------------------
        --HDMI input signals
        -------------------------------
        hdmi_rx_cec   : inout std_logic;
        hdmi_rx_hpa   : out   std_logic;
        hdmi_rx_scl   : in    std_logic;
        hdmi_rx_sda   : inout std_logic;
        hdmi_rx_txen  : out   std_logic;
        hdmi_rx_clk_n : in    std_logic;
        hdmi_rx_clk_p : in    std_logic;
        hdmi_rx_n     : in    std_logic_vector(2 downto 0);
        hdmi_rx_p     : in    std_logic_vector(2 downto 0);

        -------------
        -- HDMI out
        -------------
        hdmi_tx_cec   : inout std_logic;
        hdmi_tx_clk_n : out   std_logic;
        hdmi_tx_clk_p : out   std_logic;
        hdmi_tx_hpd   : in    std_logic;
        hdmi_tx_rscl  : inout std_logic;
        hdmi_tx_rsda  : inout std_logic;
        hdmi_tx_p     : out   std_logic_vector(2 downto 0);
        hdmi_tx_n     : out   std_logic_vector(2 downto 0);

        pixel_clk     : out std_logic;
        -------------------------------
        -- VGA data recovered from HDMI
        -------------------------------
        in_hdmi_detected : out std_logic;
        in_blank        : out std_logic;
        in_hsync        : out std_logic;
        in_vsync        : out std_logic;
        in_red          : out std_logic_vector(7 downto 0);
        in_green        : out std_logic_vector(7 downto 0);
        in_blue         : out std_logic_vector(7 downto 0);
        is_interlaced   : out std_logic;
        is_second_field : out std_logic;

        -------------------------------------
        -- Audio Levels
        -------------------------------------
        audio_channel : out std_logic_vector(2 downto 0);
        audio_de      : out std_logic;
        audio_sample  : out std_logic_vector(23 downto 0);

        -----------------------------------
        -- VGA data to be converted to HDMI
        -----------------------------------
        out_blank     : in  std_logic;
        out_hsync     : in  std_logic;
        out_vsync     : in  std_logic;
        out_red       : in  std_logic_vector(7 downto 0);
        out_green     : in  std_logic_vector(7 downto 0);
        out_blue      : in  std_logic_vector(7 downto 0);
        -----------------------------------
        -- For symbol dump or retransmit
        -----------------------------------
        symbol_sync  : out std_logic; -- indicates a fixed reference point in the frame.
        symbol_ch0   : out std_logic_vector(9 downto 0);
        symbol_ch1   : out std_logic_vector(9 downto 0);
        symbol_ch2   : out std_logic_vector(9 downto 0)
    );
    end component;
    signal symbol_sync  : std_logic;
    signal symbol_ch0   : std_logic_vector(9 downto 0);
    signal symbol_ch1   : std_logic_vector(9 downto 0);
    signal symbol_ch2   : std_logic_vector(9 downto 0);

    component pixel_processing is
        Port ( clk : in STD_LOGIC;
            switches  : in std_logic_vector(7 downto 0);
            ------------------
            -- Incoming pixels
            ------------------
            in_blank  : in std_logic;
            in_hsync  : in std_logic;
            in_vsync  : in std_logic;
            in_red    : in std_logic_vector(7 downto 0);
            in_green  : in std_logic_vector(7 downto 0);
            in_blue   : in std_logic_vector(7 downto 0);
            is_interlaced   : in  std_logic;
            is_second_field : in  std_logic;

            -------------------
            -- Processed pixels
            -------------------
            out_blank : out std_logic;
            out_hsync : out std_logic;
            out_vsync : out std_logic;
            out_red   : out std_logic_vector(7 downto 0);
            out_green : out std_logic_vector(7 downto 0);
            out_blue  : out std_logic_vector(7 downto 0);

            -------------------------------------
            -- Audio samples for metering
            -------------------------------------
            audio_channel : in std_logic_vector(2 downto 0);
            audio_de      : in std_logic;
            audio_sample  : in std_logic_vector(23 downto 0)
    );
    end component;

    component symbol_dump is
        port (
            clk          : in std_logic;
            clk100       : in std_logic;
            symbol_sync  : in std_logic; -- indicates a fixed reference point in the frame.
            symbol_ch0   : in std_logic_vector(9 downto 0);
            symbol_ch1   : in std_logic_vector(9 downto 0);
            symbol_ch2   : in std_logic_vector(9 downto 0);
            rs232_tx     : out std_logic);
    end component;

    signal pixel_clk : std_logic;
    signal in_blank  : std_logic;
    signal in_hsync  : std_logic;
    signal in_vsync  : std_logic;
    signal in_red    : std_logic_vector(7 downto 0);
    signal in_green  : std_logic_vector(7 downto 0);
    signal in_blue   : std_logic_vector(7 downto 0);
    signal is_interlaced   : std_logic;
    signal is_second_field : std_logic;
    signal out_blank : std_logic;
    signal out_hsync : std_logic;
    signal out_vsync : std_logic;
    signal out_red   : std_logic_vector(7 downto 0);
    signal out_green : std_logic_vector(7 downto 0);
    signal out_blue  : std_logic_vector(7 downto 0);

    signal audio_channel : std_logic_vector(2 downto 0);
    signal audio_de      : std_logic;
    signal audio_sample  : std_logic_vector(23 downto 0);

    signal debug        : std_logic_vector(7 downto 0);
    signal switches     : std_logic_vector(7 downto 0);
    signal clk100       : std_logic;
    signal clk100_raw   : std_logic;
    signal clk200       : std_logic;
    signal clk200_raw   : std_logic;
    signal clkfb_1      : std_logic;

begin
    jc      <= debug;
    led     <= debug(led'range);

    --------------------------------------------
    -- a 200MHz clock for the IDELAY reference
    --------------------------------------------
    clk_MMCME2_BASE_inst : MMCME2_BASE
    generic map (
        BANDWIDTH => "OPTIMIZED",      -- Jitter programming (OPTIMIZED, HIGH, LOW)
        DIVCLK_DIVIDE   => 1,          -- Master division value (1-106)
        CLKFBOUT_MULT_F => 8.0,        -- Multiply value for all CLKOUT (2.000-64.000).
        CLKFBOUT_PHASE => 0.0,         -- Phase offset in degrees of CLKFB (-360.000-360.000).
        CLKIN1_PERIOD => 8.0, -- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
        -- CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
        CLKOUT0_DIVIDE_F => 5.0,       -- Divide amount for CLKOUT0 (1.000-128.000).
        CLKOUT1_DIVIDE   => 10,
        CLKOUT2_DIVIDE   => 1,
        CLKOUT3_DIVIDE   => 1,
        CLKOUT4_DIVIDE   => 1,
        CLKOUT5_DIVIDE   => 1,
        CLKOUT6_DIVIDE   => 1,
        -- CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
        CLKOUT0_DUTY_CYCLE => 0.5,
        CLKOUT1_DUTY_CYCLE => 0.5,
        CLKOUT2_DUTY_CYCLE => 0.5,
        CLKOUT3_DUTY_CYCLE => 0.5,
        CLKOUT4_DUTY_CYCLE => 0.5,
        CLKOUT5_DUTY_CYCLE => 0.5,
        CLKOUT6_DUTY_CYCLE => 0.5,
        -- CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
        CLKOUT0_PHASE => 0.0,
        CLKOUT1_PHASE => 0.0,
        CLKOUT2_PHASE => 0.0,
        CLKOUT3_PHASE => 0.0,
        CLKOUT4_PHASE => 0.0,
        CLKOUT5_PHASE => 0.0,
        CLKOUT6_PHASE => 0.0,
        CLKOUT4_CASCADE => FALSE,  -- Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
        REF_JITTER1 => 0.0,        -- Reference input jitter in UI (0.000-0.999).
        STARTUP_WAIT => FALSE      -- Delays DONE until MMCM is locked (FALSE, TRUE)
    )
    port map (
        -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
        CLKOUT0   => clk200_raw,   -- 1-bit output: CLKOUT0
        CLKOUT0B  => open,         -- 1-bit output: Inverted CLKOUT0
        CLKOUT1   => clk100_raw,   -- 1-bit output: CLKOUT1
        CLKOUT1B  => open,         -- 1-bit output: Inverted CLKOUT1
        CLKOUT2   => open,         -- 1-bit output: CLKOUT2
        CLKOUT2B  => open,         -- 1-bit output: Inverted CLKOUT2
        CLKOUT3   => open,         -- 1-bit output: CLKOUT3
        CLKOUT3B  => open,         -- 1-bit output: Inverted CLKOUT3
        CLKOUT4   => open,         -- 1-bit output: CLKOUT4
        CLKOUT5   => open,         -- 1-bit output: CLKOUT5
        CLKOUT6   => open,         -- 1-bit output: CLKOUT6
        -- Feedback Clocks: 1-bit (each) output: Clock feedback ports
        CLKFBOUT  => clkfb_1,      -- 1-bit output: Feedback clock
        CLKFBOUTB => open,         -- 1-bit output: Inverted CLKFBOUT
        -- Status Ports: 1-bit (each) output: MMCM status ports
        LOCKED    => open,         -- 1-bit output: LOCK
        -- Clock Inputs: 1-bit (each) input: Clock input
        CLKIN1    => sysclk,       -- 1-bit input: Clock
        -- Control Ports: 1-bit (each) input: MMCM control ports
        PWRDWN    => '0',          -- 1-bit input: Power-down
        RST       => '0',          -- 1-bit input: Reset
        -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
        CLKFBIN   => clkfb_1       -- 1-bit input: Feedback clock
    );

    i_BUFG_200: BUFG PORT MAP (
        I => clk200_raw,
        O => clk200
    );

    i_BUFG_100: BUFG PORT MAP (
        I => clk100_raw,
        O => clk100
    );

i_hdmi_io: hdmi_io port map (
        clk100          => clk100,
        clk200          => clk200,
        ---------------------
        -- Control signals
        ---------------------
        clock_locked     => open,
        data_synced      => open,
        debug            => debug,
        ---------------------
        -- HDMI input signals
        ---------------------
        hdmi_rx_cec   => hdmi_rx_cec,
        hdmi_rx_hpa   => hdmi_rx_hpd,
        hdmi_rx_scl   => hdmi_rx_scl,
        hdmi_rx_sda   => hdmi_rx_sda,
        hdmi_rx_txen  => open,
        hdmi_rx_clk_n => hdmi_rx_clk_n,
        hdmi_rx_clk_p => hdmi_rx_clk_p,
        hdmi_rx_p     => hdmi_rx_p,
        hdmi_rx_n     => hdmi_rx_n,

        ----------------------
        -- HDMI output signals
        ----------------------
        hdmi_tx_cec   => hdmi_tx_cec,
        hdmi_tx_clk_n => hdmi_tx_clk_n,
        hdmi_tx_clk_p => hdmi_tx_clk_p,
        hdmi_tx_hpd   => hdmi_tx_hpd,
        hdmi_tx_rscl  => hdmi_tx_rscl,
        hdmi_tx_rsda  => hdmi_tx_rsda,
        hdmi_tx_p     => hdmi_tx_p,
        hdmi_tx_n     => hdmi_tx_n,


        pixel_clk => pixel_clk,
        -------------------------------
        -- VGA data recovered from HDMI
        -------------------------------
        in_blank        => in_blank,
        in_hsync        => in_hsync,
        in_vsync        => in_vsync,
        in_red          => in_red,
        in_green        => in_green,
        in_blue         => in_blue,
        is_interlaced   => is_interlaced,
        is_second_field => is_second_field,

        -----------------------------------
        -- For symbol dump or retransmit
        -----------------------------------
        audio_channel => audio_channel,
        audio_de      => audio_de,
        audio_sample  => audio_sample,

        -----------------------------------
        -- VGA data to be converted to HDMI
        -----------------------------------
        out_blank => out_blank,
        out_hsync => out_hsync,
        out_vsync => out_vsync,
        out_red   => out_red,
        out_green => out_green,
        out_blue  => out_blue,

        symbol_sync  => symbol_sync,
        symbol_ch0   => symbol_ch0,
        symbol_ch1   => symbol_ch1,
        symbol_ch2   => symbol_ch2
    );

switches <= x"0" & sw;

i_processing: pixel_processing Port map (
        clk => pixel_clk,
        switches => switches,
        ------------------
        -- Incoming pixels
        ------------------
        in_blank        => in_blank,
        in_hsync        => in_hsync,
        in_vsync        => in_vsync,
        in_red          => in_red,
        in_green        => in_green,
        in_blue         => in_blue,
        is_interlaced   => is_interlaced,
        is_second_field => is_second_field,
        audio_channel   => audio_channel,
        audio_de        => audio_de,
        audio_sample    => audio_sample,
        -------------------
        -- Processed pixels
        -------------------
        out_blank => out_blank,
        out_hsync => out_hsync,
        out_vsync => out_vsync,
        out_red   => out_red,
        out_green => out_green,
        out_blue  => out_blue
    );

    -- Swap to this if you want to capture the HDMI symbols
    -- and send them up the RS232 port
    --rs232_tx <= '1';
i_symbol_dump: symbol_dump port map (
            clk         => pixel_clk,
            clk100      => clk100,
            symbol_sync => symbol_sync,
            symbol_ch0  => symbol_ch0,
            symbol_ch1  => symbol_ch1,
            symbol_ch2  => symbol_ch2,
            rs232_tx    => open);

end Behavioral;
