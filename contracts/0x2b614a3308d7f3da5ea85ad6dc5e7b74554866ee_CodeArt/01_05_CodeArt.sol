// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Code And Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Code And Art    //
//                    //
//                    //
////////////////////////


contract CodeArt is ERC721Creator {
    constructor() ERC721Creator("Code And Art", "CodeArt") {}
}