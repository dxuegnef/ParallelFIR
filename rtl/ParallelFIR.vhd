--|----------------------------------------------------------------------------
--!   \file                  ParallelFIR.vhd
--!   \author                Borja Miguel Peñuelas ( borja.penuelas@gmail.com )
--!   \version               01 / A
--!   \date                  24/06/2018
--|----------------------------------------------------------------------------
--|   Description:
--!    \mainpage             ParallelFIR
--!                          <img src="../img/logo.jpg">
--!
--!    \section              Description
--!                           Generalized N sample parallel inpunt MIMO FIR.
--!
--!    \subsection FIR       Finite Impulse Response filter
--!                           This is a symmetrical coefficients FIR filter.
--!
--!    \subsection SRL       Shift Register Left
--!                           Hold as many parallel inputs as all the individual
--!                           parallel FIR filters need.
--!
--!    \subsection Add       Adders
--!                           One for each pair of taps.
--!
--!    \subsection Mult      Multipliers
--!                           One for each adder.
--!
--!    \subsection AddTree   Adders
--!                           Add all mult outputs.
--!
--|----------------------------------------------------------------------------
--|   Change Log      |  01/A - First version                                 |
--|                   |                                                       |
--|                   |                                                       |
--'---------------------------------------------------------------------------'




-------------------------------------------------------------------------------
-- ParallelFIR package              (externally referenced types and constants)
-------------------------------------------------------------------------------
package pkg_ParallelFIR is

end package pkg_ParallelFIR                                                   ;




-------------------------------------------------------------------------------
-- ParallelFIR entity
-------------------------------------------------------------------------------

library ieee                                                                  ;
use     ieee.std_logic_1164.all                                               ;
use     ieee.numeric_std.all                                                  ;
use     ieee.math_real.all                                                    ;

use     work.pkg_ComponentDeclaration.all                                     ;



entity ParallelFIR is
  generic (
    G_N_TAPS           : integer := 8                                         ;

    G_COEFF_W          : integer := 16                                        ;
    G_COEFF_SYMM       : boolean := true                                      ;

    G_N_PARALLEL_SAMPS : integer := 2                                         ;
    G_DATA_W           : integer := 16                                        ;
    G_OUTPUT_W         : integer := 35
  )                                                                           ;
  port (
    Clk                : in  std_logic                                        ;
    Reset              : in  std_logic                                        ;

    Coefficients       : in  std_logic_vector((G_N_TAPS * G_COEFF_W)-1 downto 0);
    DataIn             : in  std_logic_vector((G_N_PARALLEL_SAMPS * G_DATA_W)-1 downto 0);
    DataInEn           : in  std_logic                                        ;

    DataOut            : out std_logic_vector((G_N_PARALLEL_SAMPS * G_OUTPUT_W)-1 downto 0);
    DataOutDV          : out std_logic
  )                                                                           ;
end ParallelFIR                                                               ;




architecture RTL of ParallelFIR is


  -- Port data conversion

  type     T_DATAIN          is array (0 to G_N_PARALLEL_SAMPS-1)
                                of    std_logic_vector(G_DATA_W-1 downto 0)   ;
  signal   internalDataIn    : T_DATAIN                                       ;
  signal   internalDataInEn  : std_logic := '0'                               ;



  -- Shift Register Left

  constant C_SRL_LENGTH      : integer := integer( ceil(real(G_N_TAPS) / real(G_N_PARALLEL_SAMPS)) ) +1;

  type     T_INPUT_SRL       is array (0 to C_SRL_LENGTH-1)
                                of    T_DATAIN                                ;
  signal   input_srl         : T_INPUT_SRL                                    ;

  type     T_REG_INPUTS      is array (0 to C_SRL_LENGTH * G_N_PARALLEL_SAMPS -1)
                                of    std_logic_vector(G_DATA_W-1 downto 0)   ;
  signal   registeredSamples : T_REG_INPUTS                                   ;



  -- Single FIR

  type     T_ONE_FIR_DATAIN  is array (0 to G_N_TAPS-1)
                                of    std_logic_vector(G_DATA_W-1 downto 0)   ;
  type     T_FIR_DATAIN      is array (0 to G_N_PARALLEL_SAMPS-1)
                                of    T_ONE_FIR_DATAIN                        ;
  signal   firDataIn         : T_FIR_DATAIN                                   ;

  type     T_FIR_DATAIN_CNC  is array (0 to G_N_PARALLEL_SAMPS-1)
                                of    std_logic_vector((G_N_TAPS * G_DATA_W)-1 downto 0);
  signal   firDataInConcat   : T_FIR_DATAIN_CNC                               ;



  type     T_FIR_DATAOUT     is array (0 to G_N_PARALLEL_SAMPS-1)
                                of    std_logic_vector((G_COEFF_W + G_DATA_W + G_N_TAPS-1)-1 downto 0);
  signal   firDataOut        : T_FIR_DATAOUT                                  ;
  signal   firDataOutDV      : std_logic_vector(G_N_PARALLEL_SAMPS-1 downto 0);
  
  type     T_DATAOUT         is array (0 to G_N_PARALLEL_SAMPS-1)
                                of    std_logic_vector(G_OUTPUT_W-1 downto 0) ;
  signal   internalDataOut   : T_DATAOUT                                      ;



begin


  -- Generate concatenations / deconcatenations for more convenient routing

  uGenConcatsPerSamp : for i in 0 to G_N_PARALLEL_SAMPS-1 generate
    uGenPerTap : for j in 0 to G_N_TAPS-1 generate
      firDataInConcat(i)(G_DATA_W * (j+1) -1 downto G_DATA_W * j) <= firDataIn(i)(j);
    end generate uGenPerTap                                                   ;

    internalDataIn(i) <= DataIn(G_DATA_W * (i+1) -1 downto G_DATA_W * i)      ;



    internalDataOut(i) <= std_logic_vector( resize( signed(firDataOut(i)), G_OUTPUT_W) );

    DataOut(G_OUTPUT_W * (i+1) -1 downto G_OUTPUT_W * i) <= internalDataOut(G_N_PARALLEL_SAMPS-1 - i);
             
  end generate uGenConcatsPerSamp                                             ;

  internalDataInEn <= DataInEn                                                ;
  DataOutDV        <= firDataOutDV(0)                                         ;




  -- Parallel FIR architecture from individual Symmetrical FIR filters
  -- the appropriate samples are taken from a Shift Register Left.

  -- SRL

  uGenSrlInput : for i in 0 to G_N_PARALLEL_SAMPS-1 generate
    input_srl(0)(i) <= internalDataIn(i)                                      ;
  end generate uGenSrlInput                                                   ;

  uGenSrl : for i in 1 to C_SRL_LENGTH-1 generate
    uRegisterLeft : process( Clk )
    begin
      if( rising_edge(Clk) ) then
        input_srl(i)     <= input_srl(i-1)                                    ;
      end if                                                                  ;
    end process uRegisterLeft                                                 ;
  end generate uGenSrl                                                        ;



  -- Map the samples in the SRL to sample index.

  uGenMapIndividualSamples : for i in 0 to C_SRL_LENGTH-1 generate
    uLength : for j in 0 to G_N_PARALLEL_SAMPS-1 generate
      registeredSamples(i*G_N_PARALLEL_SAMPS + (G_N_PARALLEL_SAMPS-1 - j)) <= input_srl(i)(j);
    end generate uLength                                                      ;
  end generate uGenMapIndividualSamples                                       ;



  -- Connect the appropriate samples inside the SRL to feed the individual FIR.

  uGenPerDestinationFIR : for i in 0 to G_N_PARALLEL_SAMPS-1 generate
    uGenPerTap : for j in 0 to G_N_TAPS-1 generate
      firDataIn(i)(j) <= registeredSamples(i + j)                             ;
    end generate uGenPerTap                                                   ;
  end generate uGenPerDestinationFIR                                          ;




  -- Instantiate individual Symmetrical FIR filters.

  uGenFIR_inst : for i in 0 to G_N_PARALLEL_SAMPS-1 generate
    FIR_inst : FIR
    generic map (
      G_N_TAPS     => G_N_TAPS                                                ,

      G_COEFF_W    => G_COEFF_W                                               ,
      G_COEFF_SYMM => G_COEFF_SYMM                                            ,

      G_DATA_W     => G_DATA_W
    )
    port map (
      Clk          => Clk                                                     ,
      Reset        => Reset                                                   ,

      Coefficients => Coefficients                                            ,
      DataIn       => firDataInConcat(i)                                      ,
      DataInEn     => internalDataInEn                                        ,

      DataOut      => firDataOut(i)                                           ,
      DataOutDV    => firDataOutDV(i)
    )                                                                         ;
  end generate uGenFIR_inst                                                   ;



end RTL                                                                       ;
