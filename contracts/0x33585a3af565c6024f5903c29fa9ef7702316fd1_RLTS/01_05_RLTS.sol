// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RealArts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//       _ \                |     \           |             //
//      |   |   _ \   _` |  |    _ \     __|  __|   __|     //
//      __ <    __/  (   |  |   ___ \   |     |   \__ \     //
//     _| \_\ \___| \__,_| _| _/    _\ _|    \__| ____/     //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract RLTS is ERC721Creator {
    constructor() ERC721Creator("RealArts", "RLTS") {}
}