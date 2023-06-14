// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mediolanum 1/1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Mediolanum     //
//                   //
//                   //
///////////////////////


contract MMM is ERC721Creator {
    constructor() ERC721Creator("Mediolanum 1/1", "MMM") {}
}