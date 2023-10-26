// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

/*

        .
      ,i \
    ,' 8b \
  ,;o  `8b \
 ;  Y8. d8  \
-+._ 8: d8. i:
    `:8 `8i `8
      `._Y8  8:  ___
         `'---Yjdp  "8m._
              ,"' _,o9   `m._
              | o8P"   _.8d8P`-._
              :8'   _oodP"   ,dP'`-._
               `: dd8P'   ,odP'  do8'`.
                 `-'   ,o8P'  ,o8P' ,8P`.
                   `._dP'   ddP'  ,8P' ,..
                      "`._ PP'  ,8P' _d8'L..__
                          `"-._88'  .PP,'7 ,8.`-.._
                               ``'"--"'  | d8' :8i `i.
                                         l d8  d8  dP/
                                          \`' J8' `P'
                                           \ ,8F  87
                                           `.88  ,'
                                            `.,-' 

*/

contract LolliPump is ERC20 {
    constructor() ERC20("LolliPump", "LLLPMP") {
        _mint(msg.sender, 888_888_888_888 * 10 ** 18);
    }
}