// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE WEB3 VAULT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//     __      ___________________________________   ____    //
//    /  \    /  \_   _____/\______   \_____  \   \ /   /    //
//    \   \/\/   /|    __)_  |    |  _/ _(__  <\   Y   /     //
//     \        / |        \ |    |   \/       \\     /      //
//      \__/\  / /_______  / |______  /______  / \___/       //
//           \/          \/         \/       \/              //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract WEB3V is ERC721Creator {
    constructor() ERC721Creator("THE WEB3 VAULT", "WEB3V") {}
}