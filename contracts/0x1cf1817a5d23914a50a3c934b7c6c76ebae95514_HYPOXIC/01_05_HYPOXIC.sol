// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hypoxic
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//              __   __         __               //
//    |__| \ / |__) /  \ \_/ | /  `              //
//    |  |  |  |    \__/ / \ | \__,              //
//                                   / Fakeye    //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract HYPOXIC is ERC1155Creator {
    constructor() ERC1155Creator("Hypoxic", "HYPOXIC") {}
}