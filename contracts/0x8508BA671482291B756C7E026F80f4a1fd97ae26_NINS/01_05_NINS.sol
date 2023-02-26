// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1997
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    1997    //
//            //
//            //
////////////////


contract NINS is ERC1155Creator {
    constructor() ERC1155Creator("1997", "NINS") {}
}