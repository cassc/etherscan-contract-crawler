// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Monique
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                                 //
//    |\/| () |\| | ()_ |_| [-     //
//                                 //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract IMM is ERC721Creator {
    constructor() ERC721Creator("Monique", "IMM") {}
}