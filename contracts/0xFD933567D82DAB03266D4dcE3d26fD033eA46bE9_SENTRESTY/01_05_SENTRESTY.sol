// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sensual Trendy Stylish
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    SENTRESTY    //
//                 //
//                 //
/////////////////////


contract SENTRESTY is ERC1155Creator {
    constructor() ERC1155Creator("Sensual Trendy Stylish", "SENTRESTY") {}
}