// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Unlocked Content
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    XOXOXO UNLOCKEE    //
//                       //
//                       //
///////////////////////////


contract ULCK is ERC721Creator {
    constructor() ERC721Creator("Unlocked Content", "ULCK") {}
}