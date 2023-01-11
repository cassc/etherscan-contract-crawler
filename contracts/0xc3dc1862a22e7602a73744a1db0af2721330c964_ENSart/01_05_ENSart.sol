// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ENSart by BBoyBlockchain
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    ENSart by BBoyBlockchain    //
//                                //
//                                //
////////////////////////////////////


contract ENSart is ERC1155Creator {
    constructor() ERC1155Creator("ENSart by BBoyBlockchain", "ENSart") {}
}