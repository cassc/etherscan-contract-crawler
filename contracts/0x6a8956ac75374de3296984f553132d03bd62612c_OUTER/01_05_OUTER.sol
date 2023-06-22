// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Denizens of the Outer Rim
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    shit    //
//            //
//            //
////////////////


contract OUTER is ERC721Creator {
    constructor() ERC721Creator("Denizens of the Outer Rim", "OUTER") {}
}