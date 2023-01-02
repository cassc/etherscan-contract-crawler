// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: -Norton
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//          /|\            //
//         |||||           //
//         |||||           //
//     /\  |||||           //
//    |||| |||||           //
//    |||| |||||  /\       //
//    |||| ||||| ||||      //
//     \|`-'|||| ||||      //
//      \__ |||| ||||      //
//         ||||`-'|||      //
//         |||| ___/       //
//         |||||           //
//         |||||           //
//    -----------------    //
//                         //
//                         //
/////////////////////////////


contract NRTN is ERC721Creator {
    constructor() ERC721Creator("-Norton", "NRTN") {}
}