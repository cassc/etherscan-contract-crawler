// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BEES - ELEMENTS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    BEEEEEES...    //
//                   //
//                   //
///////////////////////


contract BEES is ERC721Creator {
    constructor() ERC721Creator("BEES - ELEMENTS", "BEES") {}
}