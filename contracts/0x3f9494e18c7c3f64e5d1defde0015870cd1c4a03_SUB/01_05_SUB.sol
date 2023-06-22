// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sunshine
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    Winter    //
//              //
//              //
//////////////////


contract SUB is ERC721Creator {
    constructor() ERC721Creator("Sunshine", "SUB") {}
}