// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DKHD
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    DKHD    //
//            //
//            //
////////////////


contract DKHD is ERC721Creator {
    constructor() ERC721Creator("DKHD", "DKHD") {}
}