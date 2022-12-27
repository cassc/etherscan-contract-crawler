// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AICHELANGELO
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//    British artist working from London and other exotic places.    //
//    Featured in Saatchi collections, he creates from painting      //
//    to mixed media, collage, digital and AI art.                   //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract AICH is ERC721Creator {
    constructor() ERC721Creator("AICHELANGELO", "AICH") {}
}