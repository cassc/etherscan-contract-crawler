// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LB
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    ➷ ⋆·˚ 🦋 ·˚ ༘ *    //
//                       //
//                       //
///////////////////////////


contract DL1 is ERC721Creator {
    constructor() ERC721Creator("LB", "DL1") {}
}