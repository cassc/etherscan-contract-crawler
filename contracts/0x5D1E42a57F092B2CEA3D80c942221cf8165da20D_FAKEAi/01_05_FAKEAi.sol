// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FAKEAi
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//                         //
//    █〓 ▞▚ 🅺 █☰ ▞▚ █     //
//                         //
//                         //
/////////////////////////////


contract FAKEAi is ERC1155Creator {
    constructor() ERC1155Creator("FAKEAi", "FAKEAi") {}
}