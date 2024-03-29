// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Isometric Pepe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                                                                              //
//     /$$$$$$                                               /$$               /$$              //
//    |_  $$_/                                              | $$              |__/              //
//      | $$    /$$$$$$$  /$$$$$$  /$$$$$$/$$$$   /$$$$$$  /$$$$$$    /$$$$$$  /$$  /$$$$$$$    //
//      | $$   /$$_____/ /$$__  $$| $$_  $$_  $$ /$$__  $$|_  $$_/   /$$__  $$| $$ /$$_____/    //
//      | $$  |  $$$$$$ | $$  \ $$| $$ \ $$ \ $$| $$$$$$$$  | $$    | $$  \__/| $$| $$          //
//      | $$   \____  $$| $$  | $$| $$ | $$ | $$| $$_____/  | $$ /$$| $$      | $$| $$          //
//     /$$$$$$ /$$$$$$$/|  $$$$$$/| $$ | $$ | $$|  $$$$$$$  |  $$$$/| $$      | $$|  $$$$$$$    //
//    |______/|_______/  \______/ |__/ |__/ |__/ \_______/   \___/  |__/      |__/ \_______/    //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                             /$$$$$$$                                                         //
//                            | $$__  $$                                                        //
//                            | $$  \ $$ /$$$$$$   /$$$$$$   /$$$$$$                            //
//                            | $$$$$$$//$$__  $$ /$$__  $$ /$$__  $$                           //
//                            | $$____/| $$$$$$$$| $$  \ $$| $$$$$$$$                           //
//                            | $$     | $$_____/| $$  | $$| $$_____/                           //
//                            | $$     |  $$$$$$$| $$$$$$$/|  $$$$$$$                           //
//                            |__/      \_______/| $$____/  \_______/                           //
//                                               | $$                                           //
//                                               | $$                                           //
//                                               |__/                                           //
//                                                                                              //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////


contract IP is ERC721Creator {
    constructor() ERC721Creator("Isometric Pepe", "IP") {}
}