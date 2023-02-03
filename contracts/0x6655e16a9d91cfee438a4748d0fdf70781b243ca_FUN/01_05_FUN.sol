// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Funnies
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Trevor and Rich    //
//                       //
//                       //
///////////////////////////


contract FUN is ERC721Creator {
    constructor() ERC721Creator("The Funnies", "FUN") {}
}