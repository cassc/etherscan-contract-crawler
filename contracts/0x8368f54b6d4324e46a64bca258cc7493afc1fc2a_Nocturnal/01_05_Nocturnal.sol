// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nocturnal Silence
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Nocturnal Silence     //
//                          //
//                          //
//////////////////////////////


contract Nocturnal is ERC721Creator {
    constructor() ERC721Creator("Nocturnal Silence", "Nocturnal") {}
}