// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aubergine Checks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////
//             //
//             //
//    8===D    //
//             //
//             //
/////////////////


contract BDE is ERC1155Creator {
    constructor() ERC1155Creator("Aubergine Checks", "BDE") {}
}