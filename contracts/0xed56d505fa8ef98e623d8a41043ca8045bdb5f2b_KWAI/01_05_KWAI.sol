// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KwainoiCOIN
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    Everything is possible, its depends on u     //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract KWAI is ERC721Creator {
    constructor() ERC721Creator("KwainoiCOIN", "KWAI") {}
}