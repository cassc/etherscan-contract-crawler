// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Surreality
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    S-U-R-R-E-A-L-I-T-Y    //
//                           //
//                           //
///////////////////////////////


contract SBP is ERC721Creator {
    constructor() ERC721Creator("Surreality", "SBP") {}
}