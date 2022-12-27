// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Energy Study
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    feelthroughthis    //
//                       //
//                       //
///////////////////////////


contract energetic is ERC721Creator {
    constructor() ERC721Creator("Energy Study", "energetic") {}
}