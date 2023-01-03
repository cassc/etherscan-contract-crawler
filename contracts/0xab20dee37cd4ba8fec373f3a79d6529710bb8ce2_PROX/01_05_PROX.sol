// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: proxima centauri b
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//                                                                          //
//    █▀█ █▀█ █▀█ ▀▄▀ █ █▀▄▀█ ▄▀█   █▀▀ █▀▀ █▄░█ ▀█▀ ▄▀█ █░█ █▀█ █   █▄▄    //
//    █▀▀ █▀▄ █▄█ █░█ █ █░▀░█ █▀█   █▄▄ ██▄ █░▀█ ░█░ █▀█ █▄█ █▀▄ █   █▄█    //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract PROX is ERC1155Creator {
    constructor() ERC1155Creator("proxima centauri b", "PROX") {}
}