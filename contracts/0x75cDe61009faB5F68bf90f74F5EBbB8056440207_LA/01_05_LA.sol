// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lost Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    1057427X8    //
//                 //
//                 //
/////////////////////


contract LA is ERC721Creator {
    constructor() ERC721Creator("Lost Art", "LA") {}
}