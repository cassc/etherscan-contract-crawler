// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: M.C. Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//    █▀▄▀█ ░ █▀▀ ░   █▀▀ █▀▄ █ ▀█▀ █ █▀█ █▄░█ █▀    //
//    █░▀░█ ▄ █▄▄ ▄   ██▄ █▄▀ █ ░█░ █ █▄█ █░▀█ ▄█    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract MCE is ERC1155Creator {
    constructor() ERC1155Creator("M.C. Editions", "MCE") {}
}