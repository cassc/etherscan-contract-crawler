// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CHAOS CREATIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    CHAOS CREATIONS    //
//                       //
//                       //
///////////////////////////


contract CHAOS is ERC1155Creator {
    constructor() ERC1155Creator("CHAOS CREATIONS", "CHAOS") {}
}