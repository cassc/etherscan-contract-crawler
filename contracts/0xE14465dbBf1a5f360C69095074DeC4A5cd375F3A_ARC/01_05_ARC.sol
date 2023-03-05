// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Arclight
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    Pieces made with my heart on my sleeve.    //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract ARC is ERC721Creator {
    constructor() ERC721Creator("Arclight", "ARC") {}
}