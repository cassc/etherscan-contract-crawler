// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pixel Turts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    PT    //
//          //
//          //
//////////////


contract PT is ERC721Creator {
    constructor() ERC721Creator("Pixel Turts", "PT") {}
}