// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sweets and Treats by Suburban Bombshell
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    💣😘    //
//            //
//            //
////////////////


contract STSB is ERC721Creator {
    constructor() ERC721Creator("Sweets and Treats by Suburban Bombshell", "STSB") {}
}