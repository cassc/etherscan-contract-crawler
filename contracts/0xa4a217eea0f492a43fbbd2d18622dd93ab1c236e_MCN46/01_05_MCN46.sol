// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LUMAS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                                       //
//     _     _     _      ____  ____     //
//    / \   / \ /\/ \__/|/  _ \/ ___\    //
//    | |   | | ||| |\/||| / \||    \    //
//    | |_/\| \_/|| |  ||| |-||\___ |    //
//    \____/\____/\_/  \|\_/ \|\____/    //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract MCN46 is ERC1155Creator {
    constructor() ERC1155Creator("LUMAS", "MCN46") {}
}