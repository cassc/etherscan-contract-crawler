// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: build my Punk
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//     ▄▄▄▄    ███▄ ▄███▓ ██▓███      //
//    ▓█████▄ ▓██▒▀█▀ ██▒▓██░  ██▒    //
//    ▒██▒ ▄██▓██    ▓██░▓██░ ██▓▒    //
//    ▒██░█▀  ▒██    ▒██ ▒██▄█▓▒ ▒    //
//    ░▓█  ▀█▓▒██▒   ░██▒▒██▒ ░  ░    //
//    ░▒▓███▀▒░ ▒░   ░  ░▒▓▒░ ░  ░    //
//    ▒░▒   ░ ░  ░      ░░▒ ░         //
//     ░    ░ ░      ░   ░░           //
//     ░             ░                //
//          ░                         //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract BMP is ERC1155Creator {
    constructor() ERC1155Creator("build my Punk", "BMP") {}
}