// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LUNAR
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    Collectible Cards Game    //
//                              //
//                              //
//////////////////////////////////


contract LUN is ERC1155Creator {
    constructor() ERC1155Creator("LUNAR", "LUN") {}
}