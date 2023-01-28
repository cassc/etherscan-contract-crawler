// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: extremism
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    8bit    //
//            //
//            //
////////////////


contract BIT is ERC1155Creator {
    constructor() ERC1155Creator("extremism", "BIT") {}
}