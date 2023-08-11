// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bit-Friends
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Bit-Friends    //
//                   //
//                   //
///////////////////////


contract BIT is ERC721Creator {
    constructor() ERC721Creator("Bit-Friends", "BIT") {}
}