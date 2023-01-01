// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Maestro’s Gallery
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Maestro’s Gallery     //
//                          //
//                          //
//////////////////////////////


contract MSTRO is ERC721Creator {
    constructor() ERC721Creator(unicode"Maestro’s Gallery", "MSTRO") {}
}