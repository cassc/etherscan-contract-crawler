// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Godric Artwork
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    Godric Artwork    //
//                      //
//                      //
//////////////////////////


contract Godric is ERC721Creator {
    constructor() ERC721Creator("Godric Artwork", "Godric") {}
}