// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sketches by Cam Smith
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    B     //
//          //
//          //
//////////////


contract SCS is ERC721Creator {
    constructor() ERC721Creator("Sketches by Cam Smith", "SCS") {}
}