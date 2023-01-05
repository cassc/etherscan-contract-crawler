// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Start Line
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    Start Line | OE    //
//                       //
//                       //
///////////////////////////


contract SLOE is ERC1155Creator {
    constructor() ERC1155Creator("Start Line", "SLOE") {}
}