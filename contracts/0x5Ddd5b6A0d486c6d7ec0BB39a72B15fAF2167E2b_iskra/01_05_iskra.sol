// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Iskra Velitchkova
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    ·_    //
//          //
//          //
//////////////


contract iskra is ERC721Creator {
    constructor() ERC721Creator("Iskra Velitchkova", "iskra") {}
}