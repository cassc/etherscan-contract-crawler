// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rare Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    _____________________    //
//    \______   \_   _____/    //
//     |       _/|    __)_     //
//     |    |   \|        \    //
//     |____|_  /_______  /    //
//            \/        \/     //
//                             //
//                             //
/////////////////////////////////


contract RE is ERC1155Creator {
    constructor() ERC1155Creator("Rare Editions", "RE") {}
}