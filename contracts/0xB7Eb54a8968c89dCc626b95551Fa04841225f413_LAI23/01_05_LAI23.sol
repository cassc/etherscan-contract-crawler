// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LAI23
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//        __    ___    _______  _____    //
//       / /   /   |  /  _/__ \|__  /    //
//      / /   / /| |  / / __/ / /_ <     //
//     / /___/ ___ |_/ / / __/___/ /     //
//    /_____/_/  |_/___//____/____/      //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract LAI23 is ERC721Creator {
    constructor() ERC721Creator("LAI23", "LAI23") {}
}