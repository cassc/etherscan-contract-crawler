// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: simizuwakako_artwork
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    SIMIZU    //
//              //
//              //
//////////////////


contract SIMIZU is ERC721Creator {
    constructor() ERC721Creator("simizuwakako_artwork", "SIMIZU") {}
}