// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Channing Test
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    d    //
//         //
//         //
/////////////


contract CHANNINGTEST is ERC721Creator {
    constructor() ERC721Creator("Channing Test", "CHANNINGTEST") {}
}