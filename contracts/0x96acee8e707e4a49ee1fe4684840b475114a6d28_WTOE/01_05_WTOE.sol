// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Will Takeover Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//     __      _____________________  ___________    //
//    /  \    /  \__    ___/\_____  \ \_   _____/    //
//    \   \/\/   / |    |    /   |   \ |    __)_     //
//     \        /  |    |   /    |    \|        \    //
//      \__/\  /   |____|   \_______  /_______  /    //
//           \/                     \/        \/     //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract WTOE is ERC1155Creator {
    constructor() ERC1155Creator("Will Takeover Editions", "WTOE") {}
}