// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Slayer
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    Machines of destruction    //
//                               //
//                               //
///////////////////////////////////


contract SLR is ERC721Creator {
    constructor() ERC721Creator("Slayer", "SLR") {}
}