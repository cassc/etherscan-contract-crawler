// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mfer Prodookshons
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//       _____  _____________________ ________     _________     //
//      /     \ \_   _____/\______   \\______ \   /   _____/     //
//     /  \ /  \ |    __)   |     ___/ |    |  \  \_____  \      //
//    /    Y    \|     \    |    |     |    `   \ /        \     //
//    \____|__  /\___  /    |____|    /_______  //_______  /     //
//            \/     \/                       \/         \/      //
//                                                               //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract MFPDS is ERC1155Creator {
    constructor() ERC1155Creator("Mfer Prodookshons", "MFPDS") {}
}