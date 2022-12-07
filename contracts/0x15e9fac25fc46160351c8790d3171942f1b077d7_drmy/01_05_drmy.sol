// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: dreamy street
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    Shot and edit on iPhone by Yalım Vural.    //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract drmy is ERC721Creator {
    constructor() ERC721Creator("dreamy street", "drmy") {}
}