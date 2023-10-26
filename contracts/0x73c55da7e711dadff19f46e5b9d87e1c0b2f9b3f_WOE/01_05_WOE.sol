// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: w0e
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//     __      __  ________    ___________     //
//    /  \    /  \ \_____  \   \_   _____/     //
//    \   \/\/   /  /   |   \   |    __)_      //
//     \        /  /    |    \  |        \     //
//      \__/\  /   \_______  / /_______  /     //
//           \/            \/          \/      //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract WOE is ERC1155Creator {
    constructor() ERC1155Creator("w0e", "WOE") {}
}