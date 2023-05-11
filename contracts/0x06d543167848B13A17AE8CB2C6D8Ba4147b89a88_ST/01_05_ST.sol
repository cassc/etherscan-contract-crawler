// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shelby Test
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    Shelby    //
//              //
//              //
//////////////////


contract ST is ERC1155Creator {
    constructor() ERC1155Creator("Shelby Test", "ST") {}
}