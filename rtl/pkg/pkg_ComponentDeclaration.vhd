
library ieee                                                                  ;
use     ieee.std_logic_1164.all                                               ;


package pkg_ComponentDeclaration is

  component ParallelFIR
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
  end component ParallelFIR                                                   ;



  component FIR
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
  end component FIR                                                           ;



  component AddersTree
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
end component AddersTree                                                      ;


end package pkg_ComponentDeclaration                                          ;
