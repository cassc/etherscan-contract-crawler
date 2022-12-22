// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JANK art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Artwork by JANK    //
//                       //
//                       //
///////////////////////////


contract JANKa is ERC721Creator {
    constructor() ERC721Creator("JANK art", "JANKa") {}
}