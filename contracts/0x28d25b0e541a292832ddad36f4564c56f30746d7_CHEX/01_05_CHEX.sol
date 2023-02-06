// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ChexChecks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//                               //
//       ___         ____  __    //
//      / __\ /\  /\/__\ \/ /    //
//     / /   / /_/ /_\  \  /     //
//    / /___/ __  //__  /  \     //
//    \____/\/ /_/\__/ /_/\_\    //
//                               //
//                               //
//                               //
//                               //
///////////////////////////////////


contract CHEX is ERC721Creator {
    constructor() ERC721Creator("ChexChecks", "CHEX") {}
}