// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Exotic Raccoon Open Edition #1
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Exotic Raccoon OE    //
//                         //
//                         //
/////////////////////////////


contract ERAC is ERC1155Creator {
    constructor() ERC1155Creator("Exotic Raccoon Open Edition #1", "ERAC") {}
}