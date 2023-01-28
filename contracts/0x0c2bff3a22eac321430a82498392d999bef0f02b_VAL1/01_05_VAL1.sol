// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Values
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    ..........The Values..........    //
//                                      //
//                                      //
//////////////////////////////////////////


contract VAL1 is ERC721Creator {
    constructor() ERC721Creator("The Values", "VAL1") {}
}