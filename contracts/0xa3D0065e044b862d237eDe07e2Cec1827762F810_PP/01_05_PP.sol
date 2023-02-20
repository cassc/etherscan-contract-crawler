// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Soul Bound Token Test
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    PP    //
//          //
//          //
//////////////


contract PP is ERC721Creator {
    constructor() ERC721Creator("Soul Bound Token Test", "PP") {}
}