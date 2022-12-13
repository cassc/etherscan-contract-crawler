// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HyperHex Editions V1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                                       //
//        __  ____  ___  ___    _____    //
//       / / / / / / / |/ / |  / <  /    //
//      / /_/ / /_/ /|   /| | / // /     //
//     / __  / __  //   | | |/ // /      //
//    /_/ /_/_/ /_//_/|_| |___//_/       //
//                                       //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract HHXV1 is ERC721Creator {
    constructor() ERC721Creator("HyperHex Editions V1", "HHXV1") {}
}