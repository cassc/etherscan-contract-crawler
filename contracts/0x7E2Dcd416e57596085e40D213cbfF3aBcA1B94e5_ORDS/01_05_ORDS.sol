// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ethereum Ordinals
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Ethereum Ordinals    //
//                         //
//                         //
/////////////////////////////


contract ORDS is ERC721Creator {
    constructor() ERC721Creator("Ethereum Ordinals", "ORDS") {}
}