// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PepeLovesTheRain?
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    PepeCulture Through The Edits Of JussDrew    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract PepeCulture is ERC1155Creator {
    constructor() ERC1155Creator("PepeLovesTheRain?", "PepeCulture") {}
}