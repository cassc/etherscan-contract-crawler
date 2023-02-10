// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RIP Daily Dose
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    GN Daily Dosers    //
//                       //
//                       //
///////////////////////////


contract RIPDD is ERC1155Creator {
    constructor() ERC1155Creator("RIP Daily Dose", "RIPDD") {}
}