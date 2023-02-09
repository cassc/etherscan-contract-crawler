// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ankhae
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    ankhae    //
//              //
//              //
//////////////////


contract ankh is ERC1155Creator {
    constructor() ERC1155Creator("ankhae", "ankh") {}
}