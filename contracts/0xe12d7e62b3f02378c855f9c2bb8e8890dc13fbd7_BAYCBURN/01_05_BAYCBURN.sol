// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BAYC BURN ~ Bordon Boner
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//     |BAYC BURN|       //
//    |BORDON BONER|     //
//    |OPEN EDITION|     //
//                       //
//                       //
///////////////////////////


contract BAYCBURN is ERC721Creator {
    constructor() ERC721Creator("BAYC BURN ~ Bordon Boner", "BAYCBURN") {}
}