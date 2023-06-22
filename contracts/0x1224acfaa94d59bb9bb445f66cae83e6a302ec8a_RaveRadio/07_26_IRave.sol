// SPDX-License-Identifier: MIT

/*
                                                                                                                                                                        
RRRRRRRRRRRRRRRRR                                                          FFFFFFFFFFFFFFFFFFFFFF                                                                        
R::::::::::::::::R                                                         F::::::::::::::::::::F                                                                        
R::::::RRRRRR:::::R                                                        F::::::::::::::::::::F                                                                        
RR:::::R     R:::::R                                                       FF::::::FFFFFFFFF::::F                                                                        
  R::::R     R:::::R  aaaaaaaaaaaaavvvvvvv           vvvvvvv eeeeeeeeeeee    F:::::F       FFFFFFaaaaaaaaaaaaa      cccccccccccccccc    eeeeeeeeeeee        ssssssssss   
  R::::R     R:::::R  a::::::::::::av:::::v         v:::::vee::::::::::::ee  F:::::F             a::::::::::::a   cc:::::::::::::::c  ee::::::::::::ee    ss::::::::::s  
  R::::RRRRRR:::::R   aaaaaaaaa:::::av:::::v       v:::::ve::::::eeeee:::::eeF::::::FFFFFFFFFF   aaaaaaaaa:::::a c:::::::::::::::::c e::::::eeeee:::::eess:::::::::::::s 
  R:::::::::::::RR             a::::a v:::::v     v:::::ve::::::e     e:::::eF:::::::::::::::F            a::::ac:::::::cccccc:::::ce::::::e     e:::::es::::::ssss:::::s
  R::::RRRRRR:::::R     aaaaaaa:::::a  v:::::v   v:::::v e:::::::eeeee::::::eF:::::::::::::::F     aaaaaaa:::::ac::::::c     ccccccce:::::::eeeee::::::e s:::::s  ssssss 
  R::::R     R:::::R  aa::::::::::::a   v:::::v v:::::v  e:::::::::::::::::e F::::::FFFFFFFFFF   aa::::::::::::ac:::::c             e:::::::::::::::::e    s::::::s      
  R::::R     R:::::R a::::aaaa::::::a    v:::::v:::::v   e::::::eeeeeeeeeee  F:::::F            a::::aaaa::::::ac:::::c             e::::::eeeeeeeeeee        s::::::s   
  R::::R     R:::::Ra::::a    a:::::a     v:::::::::v    e:::::::e           F:::::F           a::::a    a:::::ac::::::c     ccccccce:::::::e           ssssss   s:::::s 
RR:::::R     R:::::Ra::::a    a:::::a      v:::::::v     e::::::::e        FF:::::::FF         a::::a    a:::::ac:::::::cccccc:::::ce::::::::e          s:::::ssss::::::s
R::::::R     R:::::Ra:::::aaaa::::::a       v:::::v       e::::::::eeeeeeeeF::::::::FF         a:::::aaaa::::::a c:::::::::::::::::c e::::::::eeeeeeee  s::::::::::::::s 
R::::::R     R:::::R a::::::::::aa:::a       v:::v         ee:::::::::::::eF::::::::FF          a::::::::::aa:::a cc:::::::::::::::c  ee:::::::::::::e   s:::::::::::ss  
RRRRRRRR     RRRRRRR  aaaaaaaaaa  aaaa        vvv            eeeeeeeeeeeeeeFFFFFFFFFFF           aaaaaaaaaa  aaaa   cccccccccccccccc    eeeeeeeeeeeeee    sssssssssss    
                                                                                                                                                                         
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRave is IERC20 {
  function burnFrom(address account, uint256 amount) external;

  function mint(address to, uint256 amount) external;
}