// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FLEURS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    FLEURS    //
//              //
//              //
//////////////////


contract FLEURS is ERC721Creator {
    constructor() ERC721Creator("FLEURS", "FLEURS") {}
}