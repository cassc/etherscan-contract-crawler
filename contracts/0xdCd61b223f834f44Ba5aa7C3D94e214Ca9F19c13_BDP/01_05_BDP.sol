// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blurdoublepunks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Blurdoublepunks    //
//                       //
//                       //
///////////////////////////


contract BDP is ERC721Creator {
    constructor() ERC721Creator("Blurdoublepunks", "BDP") {}
}