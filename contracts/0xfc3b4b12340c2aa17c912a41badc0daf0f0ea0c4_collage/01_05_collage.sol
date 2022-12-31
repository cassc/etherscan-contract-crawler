// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Collage by sato
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Collage by sato    //
//                       //
//                       //
///////////////////////////


contract collage is ERC721Creator {
    constructor() ERC721Creator("Collage by sato", "collage") {}
}