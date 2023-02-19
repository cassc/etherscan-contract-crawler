// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GIRL1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    GIRL    //
//            //
//            //
////////////////


contract GL1 is ERC721Creator {
    constructor() ERC721Creator("GIRL1", "GL1") {}
}