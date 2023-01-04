// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Steinology 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    this is a contract for 1/1 pieces by steinology.     //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract ONE is ERC721Creator {
    constructor() ERC721Creator("Steinology 1/1s", "ONE") {}
}