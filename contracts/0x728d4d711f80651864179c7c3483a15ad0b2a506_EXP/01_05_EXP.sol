// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 6Sixty6 Expanded
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    Expand your artwork to expand your imagination    //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract EXP is ERC721Creator {
    constructor() ERC721Creator("6Sixty6 Expanded", "EXP") {}
}