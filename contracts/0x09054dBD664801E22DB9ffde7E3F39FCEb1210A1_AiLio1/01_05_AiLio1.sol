// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ainaliora 1/1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//                                                           //
//                                                           //
//    ,---.o          |    o                    '|   / '|    //
//    |---|.,---.,---.|    .,---.,---.,---.      |  /   |    //
//    |   |||   |,---||    ||   ||    ,---|      | /    |    //
//    `   '``   '`---^`---'``---'`    `---^      `/     `    //
//                                                           //
//                                                           //
//                                                           //
//                                                           //
//                                                           //
//                                                           //
//                                                           //
//                                                           //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract AiLio1 is ERC721Creator {
    constructor() ERC721Creator("Ainaliora 1/1", "AiLio1") {}
}