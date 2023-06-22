// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: slowhed
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//      _________.____    ________  __      __     //
//     /   _____/|    |   \_____  \/  \    /  \    //
//     \_____  \ |    |    /   |   \   \/\/   /    //
//     /        \|    |___/    |    \        /     //
//    /_______  /|_______ \_______  /\__/\  /      //
//            \/         \/       \/      \/       //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract SLW is ERC721Creator {
    constructor() ERC721Creator("slowhed", "SLW") {}
}