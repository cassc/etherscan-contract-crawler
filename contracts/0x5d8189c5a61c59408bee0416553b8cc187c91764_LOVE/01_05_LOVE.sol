// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HOPE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    .____    ____________   _______________    //
//    |    |   \_____  \   \ /   /\_   _____/    //
//    |    |    /   |   \   Y   /  |    __)_     //
//    |    |___/    |    \     /   |        \    //
//    |_______ \_______  /\___/   /_______  /    //
//            \/       \/                 \/     //
//                                               //
//                                               //
//                                               //
//                                               //
//                                               //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract LOVE is ERC1155Creator {
    constructor() ERC1155Creator("HOPE", "LOVE") {}
}