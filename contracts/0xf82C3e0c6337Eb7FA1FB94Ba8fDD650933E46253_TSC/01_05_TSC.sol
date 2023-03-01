// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Till She Comes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    ___________ __________________       //
//    \__    ___//   _____/\_   ___ \      //
//      |    |   \_____  \ /    \  \/      //
//      |    |   /        \\     \____     //
//      |____|  /_______  / \______  /     //
//                      \/         \/      //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract TSC is ERC721Creator {
    constructor() ERC721Creator("Till She Comes", "TSC") {}
}