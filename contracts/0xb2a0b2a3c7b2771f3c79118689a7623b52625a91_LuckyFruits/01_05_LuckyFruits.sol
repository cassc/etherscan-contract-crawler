// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LuckyFruits
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    dieses ist der Vertrag    //
//                              //
//                              //
//////////////////////////////////


contract LuckyFruits is ERC721Creator {
    constructor() ERC721Creator("LuckyFruits", "LuckyFruits") {}
}