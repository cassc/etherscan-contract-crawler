// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Santa
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    REJELL    //
//              //
//              //
//////////////////


contract Santa is ERC721Creator {
    constructor() ERC721Creator("Santa", "Santa") {}
}