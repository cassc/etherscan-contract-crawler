// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sewer   Pass
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Sewer Pass    //
//                  //
//                  //
//////////////////////


contract BAYCSP is ERC721Creator {
    constructor() ERC721Creator("Sewer   Pass", "BAYCSP") {}
}