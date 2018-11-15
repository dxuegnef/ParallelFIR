
library ieee                                                                  ;
use     ieee.std_logic_1164.all                                               ;
use     ieee.numeric_std.all                                                  ;


package pkg_Common is

  function are_symm(array_concat  : std_logic_vector                          ;
                    element_n     : integer                                   ;
                    element_w     : integer) return boolean                   ;

  function is_even(number : integer) return boolean                           ;

  function ternary_op(condition : boolean                                     ;
                      a, b      : integer) return integer                     ;

  function log2(n : integer) return integer                                   ;

end package pkg_Common                                                        ;



package body pkg_Common is

  function are_symm(array_concat  : std_logic_vector                          ;
                    element_n     : integer                                   ;
                    element_w     : integer) return boolean is
    variable PAIRS          : integer := element_n / 2                        ;
    variable is_symmetrical : boolean := true                                 ;
    variable a, b           : std_logic_vector(element_w-1 downto 0)          ;

  begin
    uComparePairs : for i in 0 to PAIRS-1 loop
      a := array_concat(element_w * (i+1) -1 downto element_w * i)            ;
      b := array_concat(element_w * ((element_n-1 - i)+1) -1 downto element_w * (element_n-1 - i));

      if a /= b then
        is_symmetrical := false                                               ;
      end if                                                                  ;
    end loop uComparePairs                                                    ;

    report "Is symmetrical " & boolean'image(is_symmetrical)                  ;

    return is_symmetrical                                                     ;
  end are_symm                                                                ;




  function is_even(number : integer) return boolean is
    variable number_slv : std_logic_vector(8-1 downto 0)                      ;

  begin
    number_slv := std_logic_vector(to_unsigned(number, 8 ))                   ;
    if ( number_slv(0) = '0' ) then
      return TRUE                                                             ;
    else
      return FALSE                                                            ;
    end if                                                                    ;
  end is_even                                                                 ;




  function ternary_op(condition : boolean                                     ;
                      a, b      : integer) return integer is

  begin
    if (condition) then
      return a                                                                ;
    else
      return b                                                                ;
    end if                                                                    ;
  end function ternary_op                                                     ;




  function log2(n : integer) return integer is
    variable i : integer := 0                                                 ;

  begin
    while (2**i < n) loop
      i := i + 1                                                              ;
    end loop                                                                  ;
    return i                                                                  ;
  end log2                                                                    ;


end package body pkg_Common                                                   ;
