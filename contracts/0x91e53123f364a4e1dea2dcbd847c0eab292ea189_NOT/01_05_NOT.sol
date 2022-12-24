// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A New Beginning
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//     _______   ___________________    //
//     \      \  \_____  \__    ___/    //
//     /   |   \  /   |   \|    |       //
//    /    |    \/    |    \    |       //
//    \____|__  /\_______  /____|       //
//            \/         \/             //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract NOT is ERC1155Creator {
    constructor() ERC1155Creator("A New Beginning", "NOT") {}
}