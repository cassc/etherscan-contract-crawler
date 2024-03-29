// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Neo Tokyo by LeBoomington
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                   //
//                                                                                                                                   //
//                                                                                                                                   //
//                                                                                                                                   //
//     _   _          _____     _               ______       _         ______                       _             _                  //
//    | \ | |        |_   _|   | |              | ___ \     | |        | ___ \                     (_)           | |                 //
//    |  \| | ___  ___ | | ___ | | ___   _  ___ | |_/ /_   _| |     ___| |_/ / ___   ___  _ __ ___  _ _ __   __ _| |_ ___  _ __      //
//    | . ` |/ _ \/ _ \| |/ _ \| |/ / | | |/ _ \| ___ \ | | | |    / _ \ ___ \/ _ \ / _ \| '_ ` _ \| | '_ \ / _` | __/ _ \| '_ \     //
//    | |\  |  __/ (_) | | (_) |   <| |_| | (_) | |_/ / |_| | |___|  __/ |_/ / (_) | (_) | | | | | | | | | | (_| | || (_) | | | |    //
//    \_| \_/\___|\___/\_/\___/|_|\_\\__, |\___/\____/ \__, \_____/\___\____/ \___/ \___/|_| |_| |_|_|_| |_|\__, |\__\___/|_| |_|    //
//                                    __/ |             __/ |                                                __/ |                   //
//                                   |___/             |___/                                                |___/                    //
//                                                                                                                                   //
//                                                                                                                                   //
//                                                                                                                                   //
//                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NTLB is ERC1155Creator {
    constructor() ERC1155Creator("Neo Tokyo by LeBoomington", "NTLB") {}
}