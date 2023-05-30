// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Collab Toys
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    COLLAB    //
//              //
//              //
//////////////////


contract COLLAB is ERC1155Creator {
    constructor() ERC1155Creator("Collab Toys", "COLLAB") {}
}