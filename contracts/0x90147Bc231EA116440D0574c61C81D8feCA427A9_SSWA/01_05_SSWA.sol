// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: So Say We All
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//    RYAN GREEN STUDIOS    //
//                          //
//                          //
//////////////////////////////


contract SSWA is ERC1155Creator {
    constructor() ERC1155Creator("So Say We All", "SSWA") {}
}