// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: One day at the museum
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//    71 119 101 110 110 121 32 69 101 99 107 101 108 115      //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract GE is ERC1155Creator {
    constructor() ERC1155Creator("One day at the museum", "GE") {}
}