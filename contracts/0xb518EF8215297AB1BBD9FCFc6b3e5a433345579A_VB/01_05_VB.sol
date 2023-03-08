// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VB
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//                       //
//                       //
//    .       ..--.      //
//     \     / |   )     //
//      \   /  |--:      //
//       \ /   |   )     //
//        '    '--'      //
//                       //
//                       //
///////////////////////////


contract VB is ERC1155Creator {
    constructor() ERC1155Creator("VB", "VB") {}
}