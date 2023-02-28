// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Open Fortune
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////
//             //
//             //
//     ooo     //
//    o   o    //
//    o P o    //
//    o   o    //
//     ooo     //
//             //
//             //
/////////////////


contract OF is ERC1155Creator {
    constructor() ERC1155Creator("Open Fortune", "OF") {}
}