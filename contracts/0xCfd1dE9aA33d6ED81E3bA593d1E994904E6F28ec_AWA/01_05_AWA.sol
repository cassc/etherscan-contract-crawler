// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A World Apart
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//    _____.___._______    _________    //
//    \__  |   |\      \  /   _____/    //
//     /   |   |/   |   \ \_____  \     //
//     \____   /    |    \/        \    //
//     / ______\____|__  /_______  /    //
//     \/              \/        \/     //
//      Ai Artist | Motion Designer     //
//                                      //
//                                      //
//////////////////////////////////////////


contract AWA is ERC721Creator {
    constructor() ERC721Creator("A World Apart", "AWA") {}
}