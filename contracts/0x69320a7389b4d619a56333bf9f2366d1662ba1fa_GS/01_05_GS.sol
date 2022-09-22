// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glitched Soul
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    GLITCHED SOUL     //
//                      //
//                      //
//////////////////////////


contract GS is ERC721Creator {
    constructor() ERC721Creator("Glitched Soul", "GS") {}
}