// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Colorful Assort
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//    Icon-sized illustration collection of the original character Neo-chan    //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract CAF is ERC721Creator {
    constructor() ERC721Creator("Colorful Assort", "CAF") {}
}