// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Telly
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    Slideonsnow    //
//                   //
//                   //
///////////////////////


contract MDJ is ERC1155Creator {
    constructor() ERC1155Creator("Telly", "MDJ") {}
}