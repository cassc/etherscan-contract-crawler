// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Battles
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//     ██▓███  ▄▄▄█████▓ ██▀███      //
//    ▓██░  ██▒▓  ██▒ ▓▒▓██ ▒ ██▒    //
//    ▓██░ ██▓▒▒ ▓██░ ▒░▓██ ░▄█ ▒    //
//    ▒██▄█▓▒ ▒░ ▓██▓ ░ ▒██▀▀█▄      //
//    ▒██▒ ░  ░  ▒██▒ ░ ░██▓ ▒██▒    //
//    ▒▓▒░ ░  ░  ▒ ░░   ░ ▒▓ ░▒▓░    //
//    ░▒ ░         ░      ░▒ ░ ▒░    //
//    ░░         ░        ░░   ░     //
//                         ░         //
//                                   //
//                                   //
///////////////////////////////////////


contract BATT is ERC1155Creator {
    constructor() ERC1155Creator("Battles", "BATT") {}
}