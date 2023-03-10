// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OddBuddy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    OddBuddy000    //
//                   //
//                   //
///////////////////////


contract ODD is ERC721Creator {
    constructor() ERC721Creator("OddBuddy", "ODD") {}
}