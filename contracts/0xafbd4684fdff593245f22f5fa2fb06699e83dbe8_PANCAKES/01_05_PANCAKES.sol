// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PANCAKES!
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//    OooOOo.     Oo    o.     O  .oOOOo.     Oo    `o    O  o.OOoOoo .oOOOo.          //
//    O     `O   o  O   Oo     o .O     o    o  O    o   O    O       o     o          //
//    o      O  O    o  O O    O o          O    o   O  O     o       O.               //
//    O     .o oOooOoOo O  o   o o         oOooOoOo  oOo      ooOO     `OOoo.          //
//    oOooOO'  o      O O   o  O o         o      O  o  o     O             `O         //
//    o        O      o o    O O O         O      o  O   O    o              o         //
//    O        o      O o     Oo `o     .o o      O  o    o   O       O.    .O         //
//    o'       O.     O O     `o  `OoooO'  O.     O  O     O ooOooOoO  `oooO'          //
//                                                                                     //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract PANCAKES is ERC721Creator {
    constructor() ERC721Creator("PANCAKES!", "PANCAKES") {}
}