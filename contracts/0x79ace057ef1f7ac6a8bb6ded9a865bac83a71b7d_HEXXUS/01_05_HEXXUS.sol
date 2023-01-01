// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HEXXUS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//                                                               //
//    o      O o.OOoOoo o      O o      O O       o .oOOOo.      //
//    O      o  O        O    o   O    o  o       O o     o      //
//    o      O  o         o  O     o  O   O       o O.           //
//    OoOooOOo  ooOO       oO       oO    o       o  `OOoo.      //
//    o      O  O          Oo       Oo    o       O       `O     //
//    O      o  o         o  o     o  o   O       O        o     //
//    o      o  O        O    O   O    O  `o     Oo O.    .O     //
//    o      O ooOooOoO O      o O      o  `OoooO'O  `oooO'      //
//                                                               //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract HEXXUS is ERC721Creator {
    constructor() ERC721Creator("HEXXUS", "HEXXUS") {}
}