// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yaima Nouns
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Yaima Nouns    //
//                   //
//                   //
///////////////////////


contract YIMN is ERC721Creator {
    constructor() ERC721Creator("Yaima Nouns", "YIMN") {}
}