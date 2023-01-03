// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: tiny dancer
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    -----        //
//     \,          //
//      |\         //
//     / \         //
//    -----        //
//    marooned     //
//                 //
//                 //
/////////////////////


contract TD is ERC1155Creator {
    constructor() ERC1155Creator("tiny dancer", "TD") {}
}