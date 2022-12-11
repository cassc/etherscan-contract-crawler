// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Geometrical Essence
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    GE    //
//          //
//          //
//////////////


contract GE is ERC721Creator {
    constructor() ERC721Creator("Geometrical Essence", "GE") {}
}