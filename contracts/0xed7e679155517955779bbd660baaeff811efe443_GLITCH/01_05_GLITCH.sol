// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glitch by 0xMerc
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//      ________.____    ._______________________   ___ ___      //
//     /  _____/|    |   |   \__    ___/\_   ___ \ /   |   \     //
//    /   \  ___|    |   |   | |    |   /    \  \//    ~    \    //
//    \    \_\  \    |___|   | |    |   \     \___\    Y    /    //
//     \______  /_______ \___| |____|    \______  /\___|_  /     //
//            \/        \/                      \/       \/      //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract GLITCH is ERC721Creator {
    constructor() ERC721Creator("Glitch by 0xMerc", "GLITCH") {}
}