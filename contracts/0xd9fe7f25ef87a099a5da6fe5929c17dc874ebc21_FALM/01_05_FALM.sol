// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fleurs à la Main
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Fleurs à la Main    //
//                         //
//                         //
/////////////////////////////


contract FALM is ERC721Creator {
    constructor() ERC721Creator(unicode"Fleurs à la Main", "FALM") {}
}