// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks - Prim Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//    This artwork may or may not be delivered with Prim.    //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract CHKP is ERC721Creator {
    constructor() ERC721Creator("Checks - Prim Edition", "CHKP") {}
}