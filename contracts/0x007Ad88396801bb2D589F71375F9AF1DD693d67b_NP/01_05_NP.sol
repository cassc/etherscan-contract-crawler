// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Negative Pepe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    Feels good man    //
//                      //
//                      //
//////////////////////////


contract NP is ERC721Creator {
    constructor() ERC721Creator("Negative Pepe", "NP") {}
}