// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1/1 abstract
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//    ░█─░█ ─█▀▀█ ▀█▀ ░█▀▀▀ ░█▀▀▀ ░█▄─░█     //
//    ░█▀▀█ ░█▄▄█ ░█─ ░█▀▀▀ ░█▀▀▀ ░█░█░█     //
//    ░█─░█ ░█─░█ ▄█▄ ░█─── ░█▄▄▄ ░█──▀█     //
//                                           //
//                                           //
///////////////////////////////////////////////


contract ABST is ERC721Creator {
    constructor() ERC721Creator("1/1 abstract", "ABST") {}
}