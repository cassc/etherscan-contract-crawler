// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPE BAIL BONDS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//      \  |_) |                 ___|            |                //
//     |\/ | | |  /  _ \ |   |  |      _ \   __| __|  _ \_  /     //
//     |   | |   <   __/ |   |  |     (   | |    |    __/  /      //
//    _|  _|_|_|\_\\___|\__, | \____|\___/ _|   \__|\___|___|     //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract MCTZ is ERC1155Creator {
    constructor() ERC1155Creator("PEPE BAIL BONDS", "MCTZ") {}
}