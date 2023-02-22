// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Check Dealer
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//      _   _             _           _        _          _             //
//     | |_| |_  ___   __| |_  ___ __| |__  __| |___ __ _| |___ _ _     //
//     |  _| ' \/ -_) / _| ' \/ -_) _| / / / _` / -_) _` | / -_) '_|    //
//      \__|_||_\___| \__|_||_\___\__|_\_\ \__,_\___\__,_|_\___|_|      //
//                                                                      //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract CHKDLR is ERC1155Creator {
    constructor() ERC1155Creator("The Check Dealer", "CHKDLR") {}
}