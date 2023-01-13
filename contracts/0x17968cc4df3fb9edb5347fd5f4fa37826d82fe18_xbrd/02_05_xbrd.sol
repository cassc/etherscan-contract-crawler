// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Xbirds
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    BLEO    //
//            //
//            //
////////////////


contract xbrd is ERC1155Creator {
    constructor() ERC1155Creator("Xbirds", "xbrd") {}
}