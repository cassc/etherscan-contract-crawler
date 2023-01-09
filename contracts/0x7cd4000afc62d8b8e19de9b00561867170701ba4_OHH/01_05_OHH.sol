// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OhHungryArtist_OE &LE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    OhHungryArtist, open and limited editions    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract OHH is ERC1155Creator {
    constructor() ERC1155Creator("OhHungryArtist_OE &LE", "OHH") {}
}