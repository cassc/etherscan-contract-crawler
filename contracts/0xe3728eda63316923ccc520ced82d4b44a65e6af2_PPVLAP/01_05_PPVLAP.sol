// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pudgy Penguin Victory Lap
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    Pudgy Penguin Victory Lap!    //
//                                  //
//                                  //
//////////////////////////////////////


contract PPVLAP is ERC1155Creator {
    constructor() ERC1155Creator("Pudgy Penguin Victory Lap", "PPVLAP") {}
}