// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Where Stars Land
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//     __      __  _________.____          //
//    /  \    /  \/   _____/|    |         //
//    \   \/\/   /\_____  \ |    |         //
//     \        / /        \|    |___      //
//      \__/\  / /_______  /|_______ \     //
//           \/          \/         \/     //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract WSL is ERC721Creator {
    constructor() ERC721Creator("Where Stars Land", "WSL") {}
}