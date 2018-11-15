--|----------------------------------------------------------------------------
--!   \file                  FIR.vhd
--!   \author                Borja Miguel Peñuelas ( borja.penuelas@gmail.com )
--!   \version               01 / A
--!   \date                  24/06/2018
--|----------------------------------------------------------------------------
--|   Description:
--!    \class                FIR
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
-- FIR package                      (externally referenced types and constants)
-------------------------------------------------------------------------------

package pkg_FIR is

end package pkg_FIR                                                           ;




-------------------------------------------------------------------------------
-- FIR entity
-------------------------------------------------------------------------------

library ieee                                                                  ;
use     ieee.std_logic_1164.all                                               ;
use     ieee.numeric_std.all                                                  ;

use     work.pkg_Common.all                                                   ;
use     work.pkg_ComponentDeclaration.all                                     ;


entity FIR is
  generic (
    G_N_TAPS     : integer := 9                                               ;

    G_COEFF_W    : integer := 16                                              ;
    G_COEFF_SYMM : boolean := true                                            ;

    G_DATA_W     : integer := 16
  )                                                                           ;
  port (
    Clk          : in  std_logic                                              ;
    Reset        : in  std_logic                                              ;

    Coefficients : in  std_logic_vector((G_N_TAPS * G_COEFF_W)-1 downto 0)    ;
    DataIn       : in  std_logic_vector((G_N_TAPS * G_DATA_W)-1 downto 0)     ;
    DataInEn     : in  std_logic                                              ;

    DataOut      : out std_logic_vector((G_COEFF_W + G_DATA_W + G_N_TAPS-1)-1 downto 0);
    DataOutDV    : out std_logic
  )                                                                           ;
end FIR                                                                       ;




architecture RTL of FIR is

  constant C_N_TAPS_EVEN        : boolean := is_even(G_N_TAPS)                ;
  constant C_TAP_PAIRS          : integer := G_N_TAPS / 2                     ;


  -- Depending on the architecture, see how many mults are needed
  constant C_MULTIPLIERS        : integer
                                := ternary_op(G_COEFF_SYMM                    ,
                                              ternary_op(C_N_TAPS_EVEN, C_TAP_PAIRS, C_TAP_PAIRS + 1),
                                              G_N_TAPS                       );

  -- If the filter is symmetrical, input samples will be pre-added
  constant C_SAMP_ADDER_W       : integer := ternary_op(G_COEFF_SYMM, G_DATA_W + 1, G_DATA_W);

  -- In both cases, a registered input will be multiplied by a coefficient
  constant C_MULT_W             : integer := C_SAMP_ADDER_W + G_COEFF_W       ;




  -- Internal signals for ports (more convenient types)
  type     T_COEFFICIENTS       is array (0 to G_N_TAPS-1) 
                                   of    signed(G_COEFF_W-1 downto 0)         ;
  signal   internalCoefficients : T_COEFFICIENTS                              ;

  type     T_DATAIN             is array (0 to G_N_TAPS-1) 
                                   of    signed(G_DATA_W-1 downto 0)          ;
  signal   internalDataIn       : T_DATAIN                                    ;
  signal   internalDataEn       : std_logic := '0'                            ;

  type     T_ADD_DATAIN         is array (0 to G_N_TAPS-1) 
                                   of    signed(C_SAMP_ADDER_W-1 downto 0)    ;
  signal   addersDataIn         : T_ADD_DATAIN                                ;


  type     T_MULT_SAMP          is array (0 to C_MULTIPLIERS-1) 
                                   of    signed(C_SAMP_ADDER_W-1 downto 0)    ;
  signal   multInputSamp        : T_MULT_SAMP                                 ;

  type     T_MULTS              is array (0 to C_MULTIPLIERS-1) 
                                   of    signed(C_MULT_W-1 downto 0)          ;
  signal   multResult           : T_MULTS                                     ;
  signal   multResultDV         : std_logic                                   ;
  signal   multResultConcat     : std_logic_vector(C_MULTIPLIERS * C_MULT_W -1 downto 0);


  constant C_ADDERS_DATAOUT_W   : integer := C_MULTIPLIERS + C_MULT_W -1      ;
  signal   internalDataOut      : std_logic_vector(C_ADDERS_DATAOUT_W-1 downto 0);

  signal   enableSRL            : std_logic_vector(C_MULTIPLIERS-1 downto 0)  ;
  signal   addersDataOutDV      : std_logic                                   ;




begin

  -----------------------------------------------------------------------------
  -- Connect ports to internal signals with more convenient data types.
  -----------------------------------------------------------------------------

  uGenDeconcat : for i in 0 to G_N_TAPS-1 generate
    internalCoefficients(i) <= signed( Coefficients(G_COEFF_W * (i+1) -1 downto G_COEFF_W * i) );
    internalDataIn(i)       <= signed( DataIn(G_DATA_W * (i+1) -1 downto G_DATA_W * i) );
  end generate uGenDeconcat                                                   ;


  DataOut                   <= std_logic_vector( resize( signed(internalDataOut), DataOut'length ) );




  -----------------------------------------------------------------------------
  -- Symmetrical architecture
  -----------------------------------------------------------------------------

  uGenSymmFilter : if G_COEFF_SYMM generate

    uCheckCoeffSymmetry : process( Clk )
    begin
      if( rising_edge(Clk) ) then
        uCheckCoeffSymmetry : for i in 0 to C_TAP_PAIRS-1 loop
          assert internalCoefficients(i) = internalCoefficients(G_N_TAPS-1 - i)
           report integer'image(to_integer(internalCoefficients(i)))
                & integer'image(to_integer(internalCoefficients(G_N_TAPS-1 - i)))
                & "To use this architecture, coeffs must be symmetrical"
           severity FAILURE                                                   ;
        end loop uCheckCoeffSymmetry                                          ;
      end if                                                                  ;
    end process uCheckCoeffSymmetry                                           ;


    -- Add input samples in pairs (symmetrical index)
    -- Reduce multipliers usage by half.

    uGenGrowAdderInputs : for i in 0 to G_N_TAPS-1 generate
      addersDataIn(i) <= resize(internalDataIn(i), C_SAMP_ADDER_W)            ;
    end generate uGenGrowAdderInputs                                          ;


    uGenSampAdders : for i in 0 to C_TAP_PAIRS-1 generate
      uAddInputSampsPair : process( Clk )
      begin
        if( rising_edge(Clk) ) then
          multInputSamp(i) <= addersDataIn(i) + addersDataIn(G_N_TAPS-1 - i)  ;
        end if                                                                ;
      end process uAddInputSampsPair                                          ;
    end generate uGenSampAdders                                               ;

    uGenRegisterCenterSamp : if not(C_N_TAPS_EVEN) generate
      uRegisterCenterSamp : process( Clk )
      begin
        if( rising_edge(Clk) ) then
          multInputSamp(C_TAP_PAIRS-1 +1) <= addersDataIn(C_TAP_PAIRS-1 +1)   ;
          internalDataEn                  <= DataInEn                         ;
        end if                                                                ;
      end process uRegisterCenterSamp                                         ;
    end generate uGenRegisterCenterSamp                                       ;


  end generate uGenSymmFilter                                                 ;



  -----------------------------------------------------------------------------
  -- Non-Symmetrical architecture
  -----------------------------------------------------------------------------

  uGenNonSymmFilter : if not(G_COEFF_SYMM) generate

    -- Since inputs are already registered (they come from the SRL), connect
    -- them directly.

    uConnectInputsToMults : for i in 0 to G_N_TAPS-1 generate
      multInputSamp(i) <= internalDataIn(i)                                   ;
    end generate uConnectInputsToMults                                        ;

    internalDataEn <= DataInEn                                                ;

  end generate uGenNonSymmFilter                                              ;




  -- VECTOR MULTIPLIER

  -----------------------------------------------------------------------------
  -- Multiply samps by coeff
  -----------------------------------------------------------------------------

  uGenMults : for i in 0 to C_MULTIPLIERS-1 generate
    uMultiply : process( Clk )
    begin
      if( rising_edge(Clk) ) then
        multResult(i) <= multInputSamp(i) * internalCoefficients(i)           ;
        multResultDV  <= internalDataEn                                       ;
      end if                                                                  ;
    end process uMultiply                                                     ;
  end generate uGenMults                                                      ;




  -----------------------------------------------------------------------------
  -- Add multiplier results
  -----------------------------------------------------------------------------

  uConcatMultResult : for i in 0 to C_MULTIPLIERS-1 generate
    multResultConcat(C_MULT_W * (i+1) -1 downto C_MULT_W * i)
                                            <= std_logic_vector(multResult(i));
  end generate uConcatMultResult                                              ;


  -- For max clocking freq, use constant log2(n) latency adders tree.

  AddersTree_inst : AddersTree
  generic map(
    G_N_INPUTS => C_MULTIPLIERS                                               ,
    G_DATA_W   => C_MULT_W
  )
  port map(
    Clk        => Clk                                                         ,
    Reset      => Reset                                                       ,

    DataIn     => multResultConcat                                            ,
    DataInEn   => multResultDV                                                ,

    DataOut    => internalDataOut                                             ,
    DataOutDV  => addersDataOutDV
  )                                                                           ;



  -- Propagate Data Valid

  enableSRL(0) <= addersDataOutDV                                                    ;
  uShiftEn : process( Clk )
  begin
    if( rising_edge(Clk) ) then
      enableSRL(enableSRL'high downto 1) <= enableSRL(enableSRL'high-1 downto 0);
    end if                                                                    ;
  end process uShiftEn                                                        ;

  DataOutDV <= enableSRL(enableSRL'high)                                      ;




end RTL                                                                       ;
