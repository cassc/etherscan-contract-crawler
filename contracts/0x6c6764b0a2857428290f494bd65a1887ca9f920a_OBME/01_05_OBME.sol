// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Oh Ether
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    I'm obm too    //
//                   //
//                   //
///////////////////////


contract OBME is ERC721Creator {
    constructor() ERC721Creator("Oh Ether", "OBME") {}
}