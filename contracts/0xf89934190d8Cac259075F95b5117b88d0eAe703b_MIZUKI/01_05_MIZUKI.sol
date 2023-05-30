// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mizuki
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//     _______ _____ ______ _     _ _     _ _____    //
//     |  |  |   |    ____/ |     | |____/    |      //
//     |  |  | __|__ /_____ |_____| |    \_ __|__    //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract MIZUKI is ERC721Creator {
    constructor() ERC721Creator("Mizuki", "MIZUKI") {}
}