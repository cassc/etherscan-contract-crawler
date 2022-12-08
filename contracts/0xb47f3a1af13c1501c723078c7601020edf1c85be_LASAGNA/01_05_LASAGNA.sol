// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LASAGNA PROJECTS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    LASAGNA PROJECTS     //
//                         //
//                         //
/////////////////////////////


contract LASAGNA is ERC721Creator {
    constructor() ERC721Creator("LASAGNA PROJECTS", "LASAGNA") {}
}