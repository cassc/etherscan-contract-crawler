// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1155 blind11
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    testrruns    //
//                 //
//                 //
/////////////////////


contract bmrn is ERC1155Creator {
    constructor() ERC1155Creator("1155 blind11", "bmrn") {}
}