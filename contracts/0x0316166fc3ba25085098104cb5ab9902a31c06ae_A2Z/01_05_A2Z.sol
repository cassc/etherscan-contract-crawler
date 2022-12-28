// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A to Z
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    A to Z    //
//              //
//              //
//////////////////


contract A2Z is ERC721Creator {
    constructor() ERC721Creator("A to Z", "A2Z") {}
}