// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Exotic Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    Exotic Editions    //
//                       //
//                       //
///////////////////////////


contract EHERO is ERC1155Creator {
    constructor() ERC1155Creator("Exotic Editions", "EHERO") {}
}