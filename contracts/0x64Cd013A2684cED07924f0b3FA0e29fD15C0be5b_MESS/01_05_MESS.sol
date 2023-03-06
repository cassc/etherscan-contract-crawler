// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Life's a Mess
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    MESS    //
//            //
//            //
////////////////


contract MESS is ERC721Creator {
    constructor() ERC721Creator("Life's a Mess", "MESS") {}
}