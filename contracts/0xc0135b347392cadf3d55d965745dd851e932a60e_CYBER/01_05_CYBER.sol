// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cyberpunks of Nazkeba
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//    ______________.___._______________________________     //
//    \_   ___ \__  |   |\______   \_   _____/\______   \    //
//    /    \  \//   |   | |    |  _/|    __)_  |       _/    //
//    \     \___\____   | |    |   \|        \ |    |   \    //
//     \______  / ______| |______  /_______  / |____|_  /    //
//            \/\/               \/        \/         \/     //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract CYBER is ERC721Creator {
    constructor() ERC721Creator("Cyberpunks of Nazkeba", "CYBER") {}
}