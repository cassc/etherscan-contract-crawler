// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: In a dream
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Flying in a dream    //
//                         //
//                         //
/////////////////////////////


contract IDream is ERC1155Creator {
    constructor() ERC1155Creator("In a dream", "IDream") {}
}