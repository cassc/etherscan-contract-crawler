// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: proof of art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    if ur reading this its 2 l8    //
//                                   //
//                                   //
///////////////////////////////////////


contract art is ERC721Creator {
    constructor() ERC721Creator("proof of art", "art") {}
}