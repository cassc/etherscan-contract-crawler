// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Proeba
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    P1    //
//          //
//          //
//////////////


contract P1 is ERC1155Creator {
    constructor() ERC1155Creator("Proeba", "P1") {}
}