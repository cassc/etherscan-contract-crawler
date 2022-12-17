// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: washinville-villager-Cantor
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    washinville-villager-Cantor    //
//                                   //
//                                   //
///////////////////////////////////////


contract wvc is ERC1155Creator {
    constructor() ERC1155Creator("washinville-villager-Cantor", "wvc") {}
}