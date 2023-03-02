// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hello
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Hello World    //
//                   //
//                   //
///////////////////////


contract HLL is ERC721Creator {
    constructor() ERC721Creator("Hello", "HLL") {}
}