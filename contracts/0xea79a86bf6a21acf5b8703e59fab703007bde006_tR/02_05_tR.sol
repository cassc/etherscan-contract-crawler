// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: theTrinity
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    tR    //
//          //
//          //
//////////////


contract tR is ERC1155Creator {
    constructor() ERC1155Creator("theTrinity", "tR") {}
}