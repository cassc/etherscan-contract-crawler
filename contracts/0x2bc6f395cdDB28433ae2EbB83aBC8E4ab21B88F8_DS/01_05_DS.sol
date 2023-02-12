// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DSTV
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//                             //
//                             //
//    ________    _________    //
//    \______ \  /   _____/    //
//     |    |  \ \_____  \     //
//     |    `   \/        \    //
//    /_______  /_______  /    //
//            \/        \/     //
//                             //
//                             //
//                             //
//                             //
/////////////////////////////////


contract DS is ERC721Creator {
    constructor() ERC721Creator("DSTV", "DS") {}
}