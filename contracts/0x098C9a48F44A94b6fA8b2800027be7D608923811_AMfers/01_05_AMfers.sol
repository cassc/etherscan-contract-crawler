// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: amfers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    mfers by am    //
//                   //
//                   //
///////////////////////


contract AMfers is ERC721Creator {
    constructor() ERC721Creator("amfers", "AMfers") {}
}