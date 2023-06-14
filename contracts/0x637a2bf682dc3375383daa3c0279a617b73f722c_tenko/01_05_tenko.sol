// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: tenko pixel collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    tenko         //
//    pixel         //
//    collection    //
//                  //
//                  //
//////////////////////


contract tenko is ERC721Creator {
    constructor() ERC721Creator("tenko pixel collection", "tenko") {}
}