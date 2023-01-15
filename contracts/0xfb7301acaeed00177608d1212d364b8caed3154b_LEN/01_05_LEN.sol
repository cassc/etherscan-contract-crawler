// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LordErwinNft
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    Blue    //
//            //
//            //
////////////////


contract LEN is ERC721Creator {
    constructor() ERC721Creator("LordErwinNft", "LEN") {}
}