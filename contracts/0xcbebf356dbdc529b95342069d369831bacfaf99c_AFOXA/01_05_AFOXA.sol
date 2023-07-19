// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AFOX ART
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    AFOXINWEB3    //
//                  //
//                  //
//////////////////////


contract AFOXA is ERC721Creator {
    constructor() ERC721Creator("AFOX ART", "AFOXA") {}
}