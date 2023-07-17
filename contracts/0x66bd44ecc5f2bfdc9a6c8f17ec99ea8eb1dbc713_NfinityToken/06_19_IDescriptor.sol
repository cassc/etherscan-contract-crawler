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

interface IDescriptor {
    struct CardInfo {
        uint seed;
        uint8 nation;
        uint8 rarity;        // [0, 4]
        uint8 attack;       // range
        uint8 defensive;    // range
        uint8 physical;     // range
        uint8 tactical;     // range
        uint8 luck;         // range
//        uint8 team1Max;
//        uint8 team2Max;
    }

    function renderMeta(CardInfo calldata card, uint256 tokenId) external pure returns (string memory);
}