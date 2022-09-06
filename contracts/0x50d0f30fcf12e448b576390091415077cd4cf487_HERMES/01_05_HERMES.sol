// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hermes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//         ____.  _____    _______      ________         //
//        |    | /  _  \   \      \    /  _____/         //
//        |    |/  /_\  \  /   |   \  /   \  ___         //
//    /\__|    /    |    \/    |    \ \    \_\  \        //
//    \________\____|__  /\____|__  /  \______  / /\     //
//                     \/         \/          \/  \/     //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract HERMES is ERC721Creator {
    constructor() ERC721Creator("Hermes", "HERMES") {}
}