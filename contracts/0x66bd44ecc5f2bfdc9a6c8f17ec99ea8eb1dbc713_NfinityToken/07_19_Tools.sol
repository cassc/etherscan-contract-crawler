// SPDX-License-Identifier: GPL-3.0

/*
             ░┴W░
             ▒m▓░
           ╔▄   "╕
         ╓▓╣██,   '
       ,▄█▄▒▓██▄    >
      é╣▒▒▀███▓██▄
     ▓▒▒▒▒▒▒███▓███         ███╗   ██╗███████╗████████╗    ██╗███╗   ██╗███████╗██╗███╗   ██╗██╗████████╗██╗   ██╗
  ,╢▓▀███▒▒▒██▓██████       ████╗  ██║██╔════╝╚══██╔══╝    ██║████╗  ██║██╔════╝██║████╗  ██║██║╚══██╔══╝╚██╗ ██╔╝
 @╢╢Ñ▒╢▒▀▀▓▓▓▓▓██▓████▄     ██╔██╗ ██║█████╗     ██║       ██║██╔██╗ ██║█████╗  ██║██╔██╗ ██║██║   ██║    ╚████╔╝
╙▓╢╢╢╢╣Ñ▒▒▒▒██▓███████▀▀    ██║╚██╗██║██╔══╝     ██║       ██║██║╚██╗██║██╔══╝  ██║██║╚██╗██║██║   ██║     ╚██╔╝
   "╩▓╢╢╢╣╣▒███████▀▀       ██║ ╚████║██║        ██║       ██║██║ ╚████║██║     ██║██║ ╚████║██║   ██║      ██║
      `╨▓╢╢╢████▀           ╚═╝  ╚═══╝╚═╝        ╚═╝       ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝      ╚═╝
          ╙▓█▀

*/


pragma solidity ^0.8.17;

library Tools {
    function Random8Bits(uint256 seed, uint8 part, uint8 minInclusive, uint8 maxInclusive) internal pure returns (uint8) {
        return uint8((0xFF & (seed >> (part << 3))) * (maxInclusive - minInclusive + 1) / 0x100 + minInclusive);
    }

    function Random16Bits(uint256 seed, uint8 part, uint16 minInclusive, uint16 maxInclusive) internal pure returns (uint16) {
        return uint16((0xFFFF & (seed >> (part << 3))) * (maxInclusive - minInclusive + 1) / 0x10000 + minInclusive);
    }
}