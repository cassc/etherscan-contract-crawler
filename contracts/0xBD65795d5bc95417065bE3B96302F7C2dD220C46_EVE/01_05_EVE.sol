// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GiGi
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


contract EVE is ERC721Creator {
    constructor() ERC721Creator("GiGi", "EVE") {}
}