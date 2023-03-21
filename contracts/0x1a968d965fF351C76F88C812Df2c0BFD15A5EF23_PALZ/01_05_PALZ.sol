// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Palz
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//    __________  _____  .____     __________    //
//    \______   \/  _  \ |    |    \____    /    //
//     |     ___/  /_\  \|    |      /     /     //
//     |    |  /    |    \    |___  /     /_     //
//     |____|  \____|__  /_______ \/_______ \    //
//                     \/        \/        \/    //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract PALZ is ERC1155Creator {
    constructor() ERC1155Creator("Palz", "PALZ") {}
}