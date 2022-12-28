// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Elsif Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    +-+-+-+-+-+    //
//    |E|L|S|I|F|    //
//    +-+-+-+-+-+    //
//                   //
//                   //
///////////////////////


contract ELSIF is ERC721Creator {
    constructor() ERC721Creator("Elsif Art", "ELSIF") {}
}