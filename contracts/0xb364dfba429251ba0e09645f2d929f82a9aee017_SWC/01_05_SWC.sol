// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SPAM WOW
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                                                                                                                                           //
//                                                                                                                                           //
//      /$$$$$$  /$$$$$$$   /$$$$$$  /$$      /$$       /$$      /$$  /$$$$$$  /$$      /$$                                                  //
//     /$$__  $$| $$__  $$ /$$__  $$| $$$    /$$$      | $$  /$ | $$ /$$__  $$| $$  /$ | $$                                                  //
//    | $$  \__/| $$  \ $$| $$  \ $$| $$$$  /$$$$      | $$ /$$$| $$| $$  \ $$| $$ /$$$| $$        /$$$$$$$  /$$$$$$   /$$$$$$   /$$$$$$     //
//    |  $$$$$$ | $$$$$$$/| $$$$$$$$| $$ $$/$$ $$      | $$/$$ $$ $$| $$  | $$| $$/$$ $$ $$       /$$_____/ /$$__  $$ /$$__  $$ /$$__  $$    //
//     \____  $$| $$____/ | $$__  $$| $$  $$$| $$      | $$$$_  $$$$| $$  | $$| $$$$_  $$$$      | $$      | $$  \ $$| $$  \__/| $$  \ $$    //
//     /$$  \ $$| $$      | $$  | $$| $$\  $ | $$      | $$$/ \  $$$| $$  | $$| $$$/ \  $$$      | $$      | $$  | $$| $$      | $$  | $$    //
//    |  $$$$$$/| $$      | $$  | $$| $$ \/  | $$      | $$/   \  $$|  $$$$$$/| $$/   \  $$      |  $$$$$$$|  $$$$$$/| $$      | $$$$$$$/    //
//     \______/ |__/      |__/  |__/|__/     |__/      |__/     \__/ \______/ |__/     \__/       \_______/ \______/ |__/      | $$____/     //
//                                                                                                                             | $$          //
//                                                                                                                             | $$          //
//                                                                                                                             |__/          //
//                                                                                                                                           //
//                                                                                                                                           //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SWC is ERC1155Creator {
    constructor() ERC1155Creator("SPAM WOW", "SWC") {}
}