// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE DISINHERITED
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                       //
//                                                                                                                                                       //
//    oOoOOoOOo o      O o.OOoOoo       o.OOOo.   ooOoOOo .oOOOo.  ooOoOOo o.     O o      O o.OOoOoo `OooOOo.  ooOoOOo oOoOOoOOo o.OOoOoo o.OOOo.       //
//        o     O      o  O              O    `o     O    o     o     O    Oo     o O      o  O        o     `o    O        o      O        O    `o      //
//        o     o      O  o              o      O    o    O.          o    O O    O o      O  o        O      O    o        o      o        o      O     //
//        O     OoOooOOo  ooOO           O      o    O     `OOoo.     O    O  o   o OoOooOOo  ooOO     o     .O    O        O      ooOO     O      o     //
//        o     o      O  O              o      O    o          `O    o    O   o  O o      O  O        OOooOO'     o        o      O        o      O     //
//        O     O      o  o              O      o    O           o    O    o    O O O      o  o        o    o      O        O      o        O      o     //
//        O     o      o  O              o    .O'    O    O.    .O    O    o     Oo o      o  O        O     O     O        O      O        o    .O'     //
//        o'    o      O ooOooOoO        OooOO'   ooOOoOo  `oooO'  ooOOoOo O     `o o      O ooOooOoO  O      o ooOOoOo     o'    ooOooOoO  OooOO'       //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DISIN is ERC721Creator {
    constructor() ERC721Creator("THE DISINHERITED", "DISIN") {}
}