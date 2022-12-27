// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Amicu
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Chapter 1    //
//                 //
//                 //
/////////////////////


contract Amicu is ERC721Creator {
    constructor() ERC721Creator("Amicu", "Amicu") {}
}