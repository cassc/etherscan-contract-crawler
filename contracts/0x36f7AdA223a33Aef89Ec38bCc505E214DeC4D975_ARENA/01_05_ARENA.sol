// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ArenaStar
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    ArenaStar support by suphub    //
//                                   //
//                                   //
///////////////////////////////////////


contract ARENA is ERC1155Creator {
    constructor() ERC1155Creator("ArenaStar", "ARENA") {}
}