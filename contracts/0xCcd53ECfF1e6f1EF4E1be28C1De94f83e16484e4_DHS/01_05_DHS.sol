// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dragon Hero Sidekicks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//    ________    ___ ___  _________    //
//    \______ \  /   |   \/   _____/    //
//     |    |  \/    ~    \_____  \     //
//     |    `   \    Y    /        \    //
//    /_______  /\___|_  /_______  /    //
//            \/       \/        \/     //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract DHS is ERC1155Creator {
    constructor() ERC1155Creator("Dragon Hero Sidekicks", "DHS") {}
}