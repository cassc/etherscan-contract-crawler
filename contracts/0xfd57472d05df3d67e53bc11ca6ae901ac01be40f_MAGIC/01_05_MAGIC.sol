// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Two Worlds Apart
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//                           //
//    __________.___.___     //
//    \____    /|   |   |    //
//      /     / |   |   |    //
//     /     /_ |   |   |    //
//    /_______ \|___|___|    //
//            \/             //
//                           //
//                           //
//                           //
///////////////////////////////


contract MAGIC is ERC721Creator {
    constructor() ERC721Creator("Two Worlds Apart", "MAGIC") {}
}