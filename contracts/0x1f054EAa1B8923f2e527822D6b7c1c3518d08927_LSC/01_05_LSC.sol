// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lazzy Sheep Club
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    Zaidin    //
//              //
//              //
//////////////////


contract LSC is ERC721Creator {
    constructor() ERC721Creator("Lazzy Sheep Club", "LSC") {}
}