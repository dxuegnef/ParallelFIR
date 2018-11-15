--|----------------------------------------------------------------------------
--!   \file                  ParallelFIR_tb.vhd
--!   \author                Borja Miguel Peñuelas ( borja.penuelas@gmail.com )
--!   \version               01 / A
--!   \date                  24/06/2018
--|----------------------------------------------------------------------------
--|   Description:
--!    \class                ParallelFIR_tb
--!    \brief                 Linear phase (symmetrical coefficients) FIR flt.
--!    \section inputs       L Samples
--!                           One sample per tap.
--!
--!    \section outputs      Sample
--!                           One filtered sample.
--!
--|----------------------------------------------------------------------------
--|   Change Log      |  01/A - First version                                 |
--|                   |                                                       |
--|                   |                                                       |
--'---------------------------------------------------------------------------'




-------------------------------------------------------------------------------
-- ParallelFIR_tb entity
-------------------------------------------------------------------------------

library ieee                                                                  ;
use     ieee.std_logic_1164.all                                               ;
use     ieee.numeric_std.all                                                  ;
use     ieee.std_logic_textio.all                                             ;

library std                                                                   ;
use     std.textio.all                                                        ;

use     work.pkg_ComponentDeclaration.all                                     ;
use     work.pkg_Common.all                                                   ;
use     work.pkg_CoefficientsFi.all                                           ;
use     work.pkg_InputSamplesFi.all                                           ;
use     work.pkg_OutputSamplesFi.all                                          ;



entity ParallelFIR_tb is
  generic (
    G_N_TAPS           : integer := 9                                         ;
    G_COEFF_W          : integer := 16                                        ;
    G_N_PARALLEL_SAMPS : integer := 2                                         ;
    G_DATA_W           : integer := 16                                        ;
    G_OUTPUT_W         : integer := 35
  )                                                                           ;
end ParallelFIR_tb                                                            ;




architecture RTL of ParallelFIR_tb is

  constant C_CLK_PERIOD     : time    := 8 ns                                 ;
  constant C_RESET_TIME     : time    := 10 ns                                ;
  constant C_RUN_SAMPLES    : integer := PKG_INPUTSAMPLESFI'length / 2 - G_N_TAPS;

  signal   finishedSim      : boolean := false                                ;
  signal   sample_in_index  : integer := 0                                    ;
  signal   sample_out_index : integer := 0                                    ;

  signal   sample_wr_index  : integer := 0                                    ;
  signal   fileOpened       : boolean := false                                ;
  signal   fileClosed       : boolean := false                                ;



  -- Signals for ParallelFIR

  signal   Clk              : std_logic                                       ;
  signal   Reset            : std_logic                                       ;


  constant C_COEFF_SYMM     : boolean
                            := are_symm(PKG_COEFFICIENTSFI_CONCAT, G_N_TAPS, G_COEFF_W);

  signal   Coefficients     : std_logic_vector((G_N_TAPS * G_COEFF_W)-1 downto 0)
                            := PKG_COEFFICIENTSFI_CONCAT                      ;

  signal   DataIn           : std_logic_vector((G_N_PARALLEL_SAMPS * G_DATA_W)-1 downto 0);
  signal   DataInEn         : std_logic := '0'                                ;

  signal   DataOut          : std_logic_vector((G_N_PARALLEL_SAMPS * G_OUTPUT_W)-1 downto 0);
  
  signal   DataOutDV        : std_logic                                       ;
  
  signal   referenceDataOut : std_logic_vector((G_N_PARALLEL_SAMPS * G_OUTPUT_W)-1 downto 0);
  signal   DataoutDUT       : std_logic_vector((G_N_PARALLEL_SAMPS * G_OUTPUT_W)-1 downto 0);
  signal   DataoutDvDUT     : std_logic                                       ;


  -- Results store

  file     DataOutFile      : text                                            ;
  constant C_DATAOUT_PATH   : string := "./results/results_DataOut.txt"       ;



begin

  -----------------------------------------------------------------------------
  -- DUT Instance
  -----------------------------------------------------------------------------


  ParallelFIR_inst : ParallelFIR
  generic map (
    G_N_TAPS           => G_N_TAPS                                            ,

    G_COEFF_W          => G_COEFF_W                                           ,
    G_COEFF_SYMM       => C_COEFF_SYMM                                        ,

    G_N_PARALLEL_SAMPS => G_N_PARALLEL_SAMPS                                  ,
    G_DATA_W           => G_DATA_W                                            ,
    G_OUTPUT_W         => G_OUTPUT_W
  )
  port map (
    Clk                => Clk                                                 ,
    Reset              => Reset                                               ,

    Coefficients       => Coefficients                                        ,

    DataIn             => DataIn                                              ,
    DataInEn           => DataInEn                                            ,

    DataOut            => DataOut                                             ,
    DataOutDV          => DataOutDV
  )                                                                           ;




  -----------------------------------------------------------------------------
  -- Stim gen
  -----------------------------------------------------------------------------

  Clk_gen :process
  begin
    Clk <= '0'                                                                ;
    wait for C_CLK_PERIOD/2                                                   ;
    Clk <= '1'                                                                ;
    wait for C_CLK_PERIOD/2                                                   ;
  end process Clk_gen                                                         ;



  Reset_gen :process
  begin
    Reset <= '1'                                                              ;
    wait for C_RESET_TIME                                                     ;
    Reset <= '0'                                                              ;
    wait                                                                      ;
  end process Reset_gen                                                       ;



  uReadInputs : process( Clk )
  begin
    if( rising_edge(Clk) ) then
      if Reset = '0' then
        sample_in_index <= sample_in_index + G_N_PARALLEL_SAMPS               ;

        if sample_in_index <= C_RUN_SAMPLES - 1 then
          uGenParallelInputs : for i in 0 to G_N_PARALLEL_SAMPS-1 loop
            DataIn(G_DATA_W * (i+1) -1 downto G_DATA_W * i)
                                    <= PKG_INPUTSAMPLESFI(sample_in_index + i);
            DataInEn <= '1'                                                   ;
          end loop uGenParallelInputs                                         ;

        else
          DataInEn <= '0'                                                     ;

          if not(finishedSim) then
            report "Simulation finished, all input samples tested." severity warning;
            finishedSim <= true                                               ;
          end if                                                              ;
        end if                                                                ;

      end if                                                                  ;
    end if                                                                    ;
  end process uReadInputs                                                     ;




  -----------------------------------------------------------------------------
  -- Result check
  -----------------------------------------------------------------------------

  uReadOutputs : process( Clk )
  begin
    if( rising_edge(Clk) ) then
      if Reset = '0' then
        
        if DataOutDV = '1' then
          sample_out_index <= sample_out_index + G_N_PARALLEL_SAMPS           ;

          if sample_out_index <= C_RUN_SAMPLES - 1 then
            uGenParallelInputs : for i in 0 to G_N_PARALLEL_SAMPS-1 loop
              referenceDataOut(G_OUTPUT_W * (i+1) -1 downto G_OUTPUT_W * i)
                                    <= PKG_OUTPUTSAMPLESFI(sample_out_index + i);
            end loop uGenParallelInputs                                       ;
          end if                                                              ;
        end if                                                                ;

        DataoutDUT   <= DataOut                                               ;
        DataoutDvDUT <= DataOutDV                                             ;

      end if                                                                  ;
    end if                                                                    ;
  end process uReadOutputs                                                    ;




  uWriteOutputsToFile : process( Clk )
    variable v_OLINE                : line                                    ;
     
  begin
    if rising_edge(Clk) then
 
      if not(fileOpened) then
        fileOpened <= true                                                    ;
        file_open(DataOutFile, C_DATAOUT_PATH, write_mode)                    ;
      end if                                                                  ;
    
      if not(finishedSim) then
        write(v_OLINE, DataOut, right, DataOut'length)                        ;
        writeline(DataOutFile, v_OLINE)                                       ;
        sample_wr_index <= sample_wr_index + G_N_PARALLEL_SAMPS               ;
      else
        if not(fileClosed) then
          fileClosed <= true                                                  ;
          file_close(DataOutFile)                                             ;
        end if                                                                ;
      end if                                                                  ;

    end if                                                                    ;
  end process uWriteOutputsToFile                                             ;




  -----------------------------------------------------------------------------
  -- VERIFY THAT THE DUT OUTPUTS MATCH THE REFERENCE RESULTS FROM MATLAB
  -----------------------------------------------------------------------------

  uVerifyDUToutputs : process( Clk )
  begin
    if( rising_edge(Clk) ) then
      if DataoutDvDUT = '1' and not(finishedSim) then
        assert DataoutDUT = referenceDataOut
         report "Verification FAILED, DUT output does not match reference."
         severity FAILURE                                                     ;
      end if                                                                  ;
    end if                                                                    ;
  end process uVerifyDUToutputs                                               ;


end RTL                                                                       ;
