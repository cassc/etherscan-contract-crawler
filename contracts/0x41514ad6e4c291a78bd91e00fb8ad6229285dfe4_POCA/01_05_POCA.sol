// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: STUDIO POCA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    POCA&MAKO    //
//                 //
//                 //
/////////////////////


contract POCA is ERC721Creator {
    constructor() ERC721Creator("STUDIO POCA", "POCA") {}
}