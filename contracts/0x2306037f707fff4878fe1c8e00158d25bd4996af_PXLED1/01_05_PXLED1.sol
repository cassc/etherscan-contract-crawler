// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PXLMYSTIC Editions v1
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    PXLMYSTIC Editions v1    //
//                             //
//                             //
/////////////////////////////////


contract PXLED1 is ERC1155Creator {
    constructor() ERC1155Creator("PXLMYSTIC Editions v1", "PXLED1") {}
}