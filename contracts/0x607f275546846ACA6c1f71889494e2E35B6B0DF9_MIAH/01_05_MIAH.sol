// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mia Head
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//    I'm Mia Japanese artist.                                                   //
//    Japanese traditional art style illustration with calligraphy technique.    //
//                                                                               //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////


contract MIAH is ERC721Creator {
    constructor() ERC721Creator("Mia Head", "MIAH") {}
}