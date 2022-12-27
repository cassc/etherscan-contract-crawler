// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AC11
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    AC11    //
//            //
//            //
////////////////


contract AC11 is ERC721Creator {
    constructor() ERC721Creator("AC11", "AC11") {}
}