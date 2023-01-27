// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pointless
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    don't mint this, it's pointless    //
//                                       //
//                                       //
///////////////////////////////////////////


contract PNTLSS is ERC1155Creator {
    constructor() ERC1155Creator("Pointless", "PNTLSS") {}
}