// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GM Coffee Token
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//      ________    _____    _________     //
//     /  _____/   /     \   \______  \    //
//    /   \  ___  /  \ /  \      /    /    //
//    \    \_\  \/    Y    \    /    /     //
//     \______  /\____|__  /   /____/      //
//            \/         \/                //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract GMCT is ERC1155Creator {
    constructor() ERC1155Creator("GM Coffee Token", "GMCT") {}
}