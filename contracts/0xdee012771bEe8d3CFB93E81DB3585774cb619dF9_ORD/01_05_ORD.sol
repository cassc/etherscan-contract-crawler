// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ordinal Inscription
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Ordinal Inscription    //
//                           //
//                           //
///////////////////////////////


contract ORD is ERC721Creator {
    constructor() ERC721Creator("Ordinal Inscription", "ORD") {}
}