// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chucks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    Chucks    //
//              //
//              //
//////////////////


contract CHKS is ERC721Creator {
    constructor() ERC721Creator("Chucks", "CHKS") {}
}