// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ART=UTILITY
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    ART=UTILITY    //
//                   //
//                   //
///////////////////////


contract ARTU is ERC1155Creator {
    constructor() ERC1155Creator("ART=UTILITY", "ARTU") {}
}