// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: gmgn
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    gmgn    //
//            //
//            //
////////////////


contract gmgn is ERC1155Creator {
    constructor() ERC1155Creator("gmgn", "gmgn") {}
}