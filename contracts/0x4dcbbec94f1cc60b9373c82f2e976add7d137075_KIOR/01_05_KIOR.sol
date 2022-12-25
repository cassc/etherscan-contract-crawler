// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kior
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                              //
//                                                                                                              //
//    oO         Oo      oO        `OooOOo.  o      'O        o                         .oOOOo.          oO     //
//    OO         O O    o o         o     `o O       o       O                          o     o          OO     //
//    oO  o   O  o  o  O  O         O      O o       O       o                          O.        o   O  oO     //
//    Oo   O O   O   Oo   O         o     .O o       o       o                           `OOoo.    O O   Oo     //
//    oO oooOooo O        o .oOoO'  OOooOO'  O      O' .oOo. O       .oOo. O   o  .oOo        `O oooOooo oO     //
//         O O   o        O O   o   o    o   `o    o   OooO' O       O   o o   O  `Ooo.        o   O O          //
//    Oo  O  `o  o        O o   O   O     O   `o  O    O     o     . o   O O   o      O O.    .O  O  `o  Oo     //
//    oO         O        o `OoO'o  O      o   `o'     `OoO' OOoOooO `OoO' `OoO'o `OoO'  `oooO'          oO     //
//                                                                                                              //
//                                                                                                              //
//                                                                                                              //
//                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KIOR is ERC721Creator {
    constructor() ERC721Creator("Kior", "KIOR") {}
}