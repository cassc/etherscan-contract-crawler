// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Whispers From the Other Side
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//     __      _____________________    _________    //
//    /  \    /  \_   _____/\_____  \  /   _____/    //
//    \   \/\/   /|    __)   /   |   \ \_____  \     //
//     \        / |     \   /    |    \/        \    //
//      \__/\  /  \___  /   \_______  /_______  /    //
//           \/       \/            \/        \/     //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract WFOS is ERC1155Creator {
    constructor() ERC1155Creator("Whispers From the Other Side", "WFOS") {}
}