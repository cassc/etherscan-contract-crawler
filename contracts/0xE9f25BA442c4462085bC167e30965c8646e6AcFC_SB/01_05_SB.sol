// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sedulous Black
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//      ___________________      //
//     /   _____/\______   \     //
//     \_____  \  |    |  _/     //
//     /        \ |    |   \     //
//    /_______  / |______  /     //
//            \/         \/      //
//                               //
//                               //
//                               //
///////////////////////////////////


contract SB is ERC721Creator {
    constructor() ERC721Creator("Sedulous Black", "SB") {}
}