// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gangland Ink by Eddie Gangland
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Gangland INK         //
//    by Eddie Gangland    //
//                         //
//                         //
/////////////////////////////


contract GANGINK is ERC721Creator {
    constructor() ERC721Creator("Gangland Ink by Eddie Gangland", "GANGINK") {}
}