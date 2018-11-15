--|----------------------------------------------------------------------------
--!   \file                  AddersTree.vhd
--!   \author                Borja Miguel Peñuelas ( borja.penuelas@gmail.com )
--!   \version               01 / A
--!   \date                  30/06/2018
--|----------------------------------------------------------------------------
--|   Description:
--!    \class                AddersTree
--!    \brief                 Add samples in pairs for max operating frequency.
--!                           Latency is constant and equal to log2(n inputs).
--!
--|----------------------------------------------------------------------------
--|   Change Log      |  01/A - First version                                 |
--|                   |                                                       |
--|                   |                                                       |
--'---------------------------------------------------------------------------'




-------------------------------------------------------------------------------
-- AddersTree package               (externally referenced types and constants)
-------------------------------------------------------------------------------

package pkg_AddersTree is

end package pkg_AddersTree                                                    ;




-------------------------------------------------------------------------------
-- AddersTree entity
-------------------------------------------------------------------------------

library ieee                                                                  ;
use     ieee.std_logic_1164.all                                               ;
use     ieee.numeric_std.all                                                  ;

use     work.pkg_Common.all                                                   ;



entity AddersTree is
  generic (
    G_N_INPUTS   : integer := 9                                               ;
    G_DATA_W     : integer := 16
  )                                                                           ;
  port (
    Clk          : in  std_logic                                              ;
    Reset        : in  std_logic                                              ;

    DataIn       : in  std_logic_vector((G_N_INPUTS * G_DATA_W)-1 downto 0)   ;
    DataInEn     : in  std_logic                                              ;

    DataOut      : out std_logic_vector((G_DATA_W + G_N_INPUTS-1) -1 downto 0);
    DataOutDV    : out std_logic
  )                                                                           ;
end AddersTree                                                                ;




architecture RTL of AddersTree is

  constant C_N_INPUTS_EVEN      : boolean := is_even(G_N_INPUTS)              ;
  constant C_INPUT_PAIRS        : integer := G_N_INPUTS / 2                   ;
  constant C_INPUTS_EXTEND_LOG2 : integer := 2 ** log2(G_N_INPUTS)            ;
  constant C_STAGES             : integer := log2(G_N_INPUTS) + 1             ;


  -- Internal signals for ports (more convenient types)

  type     T_DATAIN             is array (0 to G_N_INPUTS-1)
                                   of    signed(G_DATA_W-1 downto 0)          ;
  signal   internalDataIn       : T_DATAIN                                    ;


  constant C_DATAOUT_W          : integer := DataOut'length                   ;
  signal   internalDataOut      : signed(C_DATAOUT_W-1 downto 0)              ;

  signal   internalDataOutDv    : std_logic                                   ;
  signal   enableSRL            : std_logic_vector(C_STAGES-1 downto 0)       ;


  type     T_ADD_RESULT         is array (0 to C_INPUTS_EXTEND_LOG2-1)
                                   of    signed(C_DATAOUT_W-1 downto 0)       ;
  type     T_STAGE_RESULT       is array (0 to C_STAGES-1)
                                   of    T_ADD_RESULT                         ;

  signal   addersResult         : T_STAGE_RESULT := (others=>(others=>(others=>'0')));




begin

  -----------------------------------------------------------------------------
  -- Deconcatenate inputs to internal signals with more convenient data types.
  -----------------------------------------------------------------------------

  uGenDeconcat : for i in 0 to G_N_INPUTS-1 generate
    internalDataIn(i) <= signed( DataIn(G_DATA_W * (i+1) -1 downto G_DATA_W * i) );
  end generate uGenDeconcat                                                   ;




  -- Stage 0 Input Samples

  uGenStage0 : for i in 0 to G_N_INPUTS-1 generate
    addersResult(0)(i) <= resize( internalDataIn(i), C_DATAOUT_W)             ;
  end generate uGenStage0                                                     ;



  -- Generate DV from EN accounting for the module latency

  enableSRL(0) <= DataInEn                                                    ;

  uShiftEn : process( Clk )
  begin
    if( rising_edge(Clk) ) then
      enableSRL(enableSRL'high downto 1) <= enableSRL(enableSRL'high-1 downto 0);
    end if                                                                    ;
  end process uShiftEn                                                        ;

  DataOutDV <= enableSRL(enableSRL'high)                                      ;




  -- Add all available pairs per stage

  uGenStages : for stage in 1 to C_STAGES-1 generate

    uGenAdders : for i in 0 to (C_INPUTS_EXTEND_LOG2 / (2 ** stage)) -1 generate

      uAddStage : process( Clk )
      begin
        if( rising_edge(Clk) ) then
          addersResult(stage)(i) <= addersResult(stage-1)(2*i + 0) +
                                    addersResult(stage-1)(2*i + 1)            ;
        end if                                                                ;
      end process uAddStage                                                   ;

    end generate uGenAdders                                                   ;

  end generate uGenStages                                                     ;




  -----------------------------------------------------------------------------
  -- Connect the result to the output port.
  -----------------------------------------------------------------------------

  internalDataOut <= addersResult(C_STAGES -1)(0)                             ;

  DataOut         <= std_logic_vector(internalDataOut)                        ;



end RTL                                                                       ;
