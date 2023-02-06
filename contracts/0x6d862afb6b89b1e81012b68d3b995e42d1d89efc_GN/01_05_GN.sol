// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GN - Good Night
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//      ________  _______       //
//     /  _____/  \      \      //
//    /   \  ___  /   |   \     //
//    \    \_\  \/    |    \    //
//     \______  /\____|__  /    //
//            \/         \/     //
//                              //
//                              //
//////////////////////////////////


contract GN is ERC1155Creator {
    constructor() ERC1155Creator("GN - Good Night", "GN") {}
}