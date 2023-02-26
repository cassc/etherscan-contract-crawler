// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 💢Eve
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//                       //
//       ____________    //
//      / ____/ ____/    //
//     / / __/ / __      //
//    / /_/ / /_/ /      //
//    \____/\____/       //
//                       //
//                       //
//                       //
//                       //
///////////////////////////


contract GiGi is ERC1155Creator {
    constructor() ERC1155Creator(unicode"💢Eve", "GiGi") {}
}