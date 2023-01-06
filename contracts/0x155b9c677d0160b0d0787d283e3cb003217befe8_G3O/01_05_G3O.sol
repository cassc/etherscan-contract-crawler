// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Geometric Art
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    Geometric Art    //
//                     //
//                     //
/////////////////////////


contract G3O is ERC1155Creator {
    constructor() ERC1155Creator("Geometric Art", "G3O") {}
}