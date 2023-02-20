// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Grand Pepe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    The Grand PEPE    //
//                      //
//                      //
//////////////////////////


contract TGPP is ERC721Creator {
    constructor() ERC721Creator("The Grand Pepe", "TGPP") {}
}