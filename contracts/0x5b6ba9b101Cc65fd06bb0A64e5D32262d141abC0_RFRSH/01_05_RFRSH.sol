// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Refresh
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    Refreshing    //
//                  //
//                  //
//////////////////////


contract RFRSH is ERC1155Creator {
    constructor() ERC1155Creator("Refresh", "RFRSH") {}
}