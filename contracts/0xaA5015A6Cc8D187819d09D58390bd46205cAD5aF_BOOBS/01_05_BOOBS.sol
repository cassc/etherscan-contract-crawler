// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Boobs check
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    (o)(o)    //
//              //
//              //
//////////////////


contract BOOBS is ERC1155Creator {
    constructor() ERC1155Creator("Boobs check", "BOOBS") {}
}