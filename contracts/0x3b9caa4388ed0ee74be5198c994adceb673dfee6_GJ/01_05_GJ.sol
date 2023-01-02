// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glitch Juice
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    glitch juice • created 2023    //
//                                   //
//                                   //
///////////////////////////////////////


contract GJ is ERC721Creator {
    constructor() ERC721Creator("Glitch Juice", "GJ") {}
}