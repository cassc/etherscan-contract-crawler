// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WWWGallery
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    WWWGallery    //
//                  //
//                  //
//////////////////////


contract gal is ERC721Creator {
    constructor() ERC721Creator("WWWGallery", "gal") {}
}