// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cocoon
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//     .oOOOo.   .oOOOo.   .oOOOo.   .oOOOo.   .oOOOo.  o.     O     //
//    .O     o  .O     o. .O     o  .O     o. .O     o. Oo     o     //
//    o         O       o o         O       o O       o O O    O     //
//    o         o       O o         o       O o       O O  o   o     //
//    o         O       o o         O       o O       o O   o  O     //
//    O         o       O O         o       O o       O o    O O     //
//    `o     .o `o     O' `o     .o `o     O' `o     O' o     Oo     //
//     `OoooO'   `OoooO'   `OoooO'   `OoooO'   `OoooO'  O     `o     //
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract Coco is ERC721Creator {
    constructor() ERC721Creator("Cocoon", "Coco") {}
}