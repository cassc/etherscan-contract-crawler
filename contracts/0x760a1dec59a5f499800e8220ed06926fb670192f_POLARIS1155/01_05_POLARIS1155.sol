// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Polaris 1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//                       //
//     REINE             //
//                       //
//       |               //
//      +|+              //
//     ——*——             //
//      +|+              //
//       |               //
//                       //
//    POLARIS            //
//                       //
//                       //
//                       //
///////////////////////////


contract POLARIS1155 is ERC1155Creator {
    constructor() ERC1155Creator("Polaris 1155", "POLARIS1155") {}
}