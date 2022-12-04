// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Frope Bidder Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Frope Bidder Editions    //
//                             //
//                             //
/////////////////////////////////


contract FBE is ERC721Creator {
    constructor() ERC721Creator("Frope Bidder Editions", "FBE") {}
}