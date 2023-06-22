// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PepeRock
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    pepe    //
//            //
//            //
////////////////


contract Peperock is ERC721Creator {
    constructor() ERC721Creator("PepeRock", "Peperock") {}
}