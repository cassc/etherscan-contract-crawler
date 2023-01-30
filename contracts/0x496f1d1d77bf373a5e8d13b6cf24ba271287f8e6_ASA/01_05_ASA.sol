// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AleyStoryArt
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//                          //
//      __   ____   __      //
//     / _\ / ___) / _\     //
//    /    \\___ \/    \    //
//    \_/\_/(____/\_/\_/    //
//                          //
//                          //
//                          //
//                          //
//////////////////////////////


contract ASA is ERC1155Creator {
    constructor() ERC1155Creator("AleyStoryArt", "ASA") {}
}