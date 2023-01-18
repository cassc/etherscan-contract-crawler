// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: hello world
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    hello world ^v^    //
//                       //
//                       //
///////////////////////////


contract xD is ERC721Creator {
    constructor() ERC721Creator("hello world", "xD") {}
}