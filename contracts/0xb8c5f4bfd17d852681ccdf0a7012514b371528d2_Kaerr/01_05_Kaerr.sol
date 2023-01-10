// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ReMemes by Kaerr
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//     ____  __   _____  _______________________________     //
//    |    |/ _| /  _  \ \_   _____/\______   \______   \    //
//    |      <  /  /_\  \ |    __)_  |       _/|       _/    //
//    |    |  \/    |    \|        \ |    |   \|    |   \    //
//    |____|__ \____|__  /_______  / |____|_  /|____|_  /    //
//            \/       \/        \/         \/        \/     //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract Kaerr is ERC1155Creator {
    constructor() ERC1155Creator("ReMemes by Kaerr", "Kaerr") {}
}