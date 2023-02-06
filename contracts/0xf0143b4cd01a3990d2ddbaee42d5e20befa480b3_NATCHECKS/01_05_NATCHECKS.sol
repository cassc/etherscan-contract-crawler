// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NOTEANDTABLE CHECKS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//    o.     O    Oo    oOoOOoOOo  .oOOOo.  o      O o.OOoOoo  .oOOOo.  `o    O  .oOOOo.      //
//    Oo     o   o  O       o     .O     o  O      o  O       .O     o   o   O   o     o      //
//    O O    O  O    o      o     o         o      O  o       o          O  O    O.           //
//    O  o   o oOooOoOo     O     o         OoOooOOo  ooOO    o          oOo      `OOoo.      //
//    O   o  O o      O     o     o         o      O  O       o          o  o          `O     //
//    o    O O O      o     O     O         O      o  o       O          O   O          o     //
//    o     Oo o      O     O     `o     .o o      o  O       `o     .o  o    o  O.    .O     //
//    O     `o O.     O     o'     `OoooO'  o      O ooOooOoO  `OoooO'   O     O  `oooO'      //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract NATCHECKS is ERC1155Creator {
    constructor() ERC1155Creator("NOTEANDTABLE CHECKS", "NATCHECKS") {}
}