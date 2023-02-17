// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: twinkle by reespect
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    meta reespect.    //
//                      //
//                      //
//////////////////////////


contract twink is ERC721Creator {
    constructor() ERC721Creator("twinkle by reespect", "twink") {}
}