// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: proxima centauri b
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//                                                                          //
//    █▀█ █▀█ █▀█ ▀▄▀ █ █▀▄▀█ ▄▀█   █▀▀ █▀▀ █▄░█ ▀█▀ ▄▀█ █░█ █▀█ █   █▄▄    //
//    █▀▀ █▀▄ █▄█ █░█ █ █░▀░█ █▀█   █▄▄ ██▄ █░▀█ ░█░ █▀█ █▄█ █▀▄ █   █▄█    //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract PROX is ERC721Creator {
    constructor() ERC721Creator("proxima centauri b", "PROX") {}
}