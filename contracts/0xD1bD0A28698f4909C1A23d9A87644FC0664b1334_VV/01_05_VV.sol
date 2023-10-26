// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Visions From The Void
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//    ____   ________   ____    //
//    \   \ /   /\   \ /   /    //
//     \   Y   /  \   Y   /     //
//      \     /    \     /      //
//       \___/      \___/       //
//                              //
//                              //
//                              //
//                              //
//////////////////////////////////


contract VV is ERC1155Creator {
    constructor() ERC1155Creator("Visions From The Void", "VV") {}
}