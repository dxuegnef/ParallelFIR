
library ieee;
use     ieee.std_logic_1164.all;


package pkg_CoefficientsFi is

  type T_COEFFICIENTSFI is array (0 to 9-1) of std_logic_vector(16-1 downto 0);

  constant PKG_COEFFICIENTSFI : T_COEFFICIENTSFI := (
    "1111111100011111",
    "1111111011000111",
    "0000000100010100",
    "0000010011101100",
    "0000011011011001",
    "0000010011101100",
    "0000000100010100",
    "1111111011000111",
    "1111111100011111"
  );

  constant PKG_COEFFICIENTSFI_CONCAT : std_logic_vector(143 downto 0) := (
    "1111111100011111" & 
    "1111111011000111" & 
    "0000000100010100" & 
    "0000010011101100" & 
    "0000011011011001" & 
    "0000010011101100" & 
    "0000000100010100" & 
    "1111111011000111" & 
    "1111111100011111"
  );

end pkg_CoefficientsFi;
