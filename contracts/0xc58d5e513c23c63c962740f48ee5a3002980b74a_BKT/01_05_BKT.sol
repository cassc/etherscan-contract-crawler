// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Byōtekina
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//    1111111111111110000000000000000000000000011111111111111111111111111111000000000000000    //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract BKT is ERC721Creator {
    constructor() ERC721Creator(unicode"Byōtekina", "BKT") {}
}