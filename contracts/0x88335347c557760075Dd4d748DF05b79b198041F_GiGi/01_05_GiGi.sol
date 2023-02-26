// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 💢Eve
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

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


contract GiGi is ERC721Creator {
    constructor() ERC721Creator(unicode"💢Eve", "GiGi") {}
}