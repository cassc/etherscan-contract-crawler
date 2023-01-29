// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pixel Beasts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    beasts    //
//              //
//              //
//////////////////


contract PBT is ERC721Creator {
    constructor() ERC721Creator("Pixel Beasts", "PBT") {}
}