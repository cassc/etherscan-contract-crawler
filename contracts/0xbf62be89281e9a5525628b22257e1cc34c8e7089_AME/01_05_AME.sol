// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Artist McArtist Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Artist McArtist    //
//                       //
//                       //
///////////////////////////


contract AME is ERC721Creator {
    constructor() ERC721Creator("Artist McArtist Editions", "AME") {}
}