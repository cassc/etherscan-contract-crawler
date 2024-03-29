// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: XcopyCats
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//    ____  ____________ __________ _________ ___________ _________     //
//    \   \/  /\_   ___ \\______   \\_   ___ \\__    ___//   _____/     //
//     \     / /    \  \/ |     ___//    \  \/  |    |   \_____  \      //
//     /     \ \     \____|    |    \     \____ |    |   /        \     //
//    /___/\  \ \______  /|____|     \______  / |____|  /_______  /     //
//          \_/        \/                   \/                  \/      //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract XCPCTS is ERC1155Creator {
    constructor() ERC1155Creator("XcopyCats", "XCPCTS") {}
}