// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glitchtopia
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    Glitchtopia    //
//                   //
//                   //
///////////////////////


contract GTT is ERC1155Creator {
    constructor() ERC1155Creator("Glitchtopia", "GTT") {}
}