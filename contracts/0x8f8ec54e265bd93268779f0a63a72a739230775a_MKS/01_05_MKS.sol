// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mikasa Limited Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    Mikasa Limited Editions    //
//                               //
//                               //
///////////////////////////////////


contract MKS is ERC721Creator {
    constructor() ERC721Creator("Mikasa Limited Editions", "MKS") {}
}