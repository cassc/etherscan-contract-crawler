// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reneils Manifold Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    created by reneil.eth    //
//                             //
//                             //
/////////////////////////////////


contract RME is ERC1155Creator {
    constructor() ERC1155Creator("Reneils Manifold Editions", "RME") {}
}