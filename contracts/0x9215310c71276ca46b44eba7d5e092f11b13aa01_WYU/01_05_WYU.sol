// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: World YU
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//                    //
//    __  ____  __    //
//    \ \/ / / / /    //
//     \  / / / /     //
//     / / /_/ /      //
//    /_/\____/       //
//                    //
//                    //
//                    //
//                    //
////////////////////////


contract WYU is ERC1155Creator {
    constructor() ERC1155Creator("World YU", "WYU") {}
}