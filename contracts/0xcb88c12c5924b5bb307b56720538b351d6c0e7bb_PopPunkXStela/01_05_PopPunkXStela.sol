// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pop Punk x Stela
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    PopPunkXStela    //
//                     //
//                     //
/////////////////////////


contract PopPunkXStela is ERC1155Creator {
    constructor() ERC1155Creator("Pop Punk x Stela", "PopPunkXStela") {}
}