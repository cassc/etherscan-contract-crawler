// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MURDUR DUCK
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    █▀▄▀█ █░█ █▀█ █▀▄ █░█ █▀█ █▀▄ █░█ █▀▀ █▄▀    //
//    █░▀░█ █▄█ █▀▄ █▄▀ █▄█ █▀▄ █▄▀ █▄█ █▄▄ █░█    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract MURDUR is ERC1155Creator {
    constructor() ERC1155Creator("MURDUR DUCK", "MURDUR") {}
}