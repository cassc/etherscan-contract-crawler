// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Monochrome//721
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    beaudenison.eth    //
//                       //
//                       //
///////////////////////////


contract mono is ERC721Creator {
    constructor() ERC721Creator("Monochrome//721", "mono") {}
}