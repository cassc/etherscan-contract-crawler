// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ekranoplan - Deutsch Italienische Freundschaft
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//      _____ _____ ____ _____                           _     _     //
//     |  ___| ____/ ___|_   _| __ ___  ___ ___  _ __ __| |___/ |    //
//     | |_  |  _|| |     | || '__/ _ \/ __/ _ \| '__/ _` / __| |    //
//     |  _| | |__| |___  | || | |  __/ (_| (_) | | | (_| \__ \ |    //
//     |_|   |_____\____| |_||_|  \___|\___\___/|_|  \__,_|___/_|    //
//                                                                   //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract FR1 is ERC1155Creator {
    constructor() ERC1155Creator("Ekranoplan - Deutsch Italienische Freundschaft", "FR1") {}
}