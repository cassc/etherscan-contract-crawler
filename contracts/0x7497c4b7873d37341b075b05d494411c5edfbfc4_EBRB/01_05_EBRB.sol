// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Collectors Editions by Robin Baird
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    R0BIN [email protected] / EDITIONS    //
//                              //
//                              //
//////////////////////////////////


contract EBRB is ERC721Creator {
    constructor() ERC721Creator("Collectors Editions by Robin Baird", "EBRB") {}
}