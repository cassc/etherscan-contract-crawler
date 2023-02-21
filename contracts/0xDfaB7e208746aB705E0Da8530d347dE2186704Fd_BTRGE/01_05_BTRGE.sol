// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Buitrago Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//    o.oOOOo.  O       o ooOoOOo oOoOOoOOo `OooOOo.     Oo     .oOOOo.   .oOOOo.      //
//     o     o  o       O    O        o      o     `o   o  O   .O     o  .O     o.     //
//     O     O  O       o    o        o      O      O  O    o  o         O       o     //
//     oOooOO.  o       o    O        O      o     .O oOooOoOo O         o       O     //
//     o     `O o       O    o        o      OOooOO'  o      O O   .oOOo O       o     //
//     O      o O       O    O        O      o    o   O      o o.      O o       O     //
//     o     .O `o     Oo    O        O      O     O  o      O  O.    oO `o     O'     //
//     `OooOO'   `OoooO'O ooOOoOo     o'     O      o O.     O   `OooO'   `OoooO'      //
//                                                                                     //
//                                                                                     //
//    o.OOoOoo o.OOOo.   ooOoOOo oOoOOoOOo ooOoOOo  .oOOOo.  o.     O .oOOOo.          //
//     O        O    `o     O        o        O    .O     o. Oo     o o     o          //
//     o        o      O    o        o        o    O       o O O    O O.               //
//     ooOO     O      o    O        O        O    o       O O  o   o  `OOoo.          //
//     O        o      O    o        o        o    O       o O   o  O       `O         //
//     o        O      o    O        O        O    o       O o    O O        o         //
//     O        o    .O'    O        O        O    `o     O' o     Oo O.    .O         //
//    ooOooOoO  OooOO'   ooOOoOo     o'    ooOOoOo  `OoooO'  O     `o  `oooO'          //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract BTRGE is ERC1155Creator {
    constructor() ERC1155Creator("Buitrago Editions", "BTRGE") {}
}