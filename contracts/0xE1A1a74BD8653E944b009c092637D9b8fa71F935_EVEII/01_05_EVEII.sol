// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GiGi
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


contract EVEII is ERC1155Creator {
    constructor() ERC1155Creator("GiGi", "EVEII") {}
}