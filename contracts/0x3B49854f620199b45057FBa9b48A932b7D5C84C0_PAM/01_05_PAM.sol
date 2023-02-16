// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks - M4R10 Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//     ██▓███   ▄▄▄       ███▄ ▄███▓    //
//    ▓██░  ██▒▒████▄    ▓██▒▀█▀ ██▒    //
//    ▓██░ ██▓▒▒██  ▀█▄  ▓██    ▓██░    //
//    ▒██▄█▓▒ ▒░██▄▄▄▄██ ▒██    ▒██     //
//    ▒██▒ ░  ░ ▓█   ▓██▒▒██▒   ░██▒    //
//    ▒▓▒░ ░  ░ ▒▒   ▓▒█░░ ▒░   ░  ░    //
//    ░▒ ░       ▒   ▒▒ ░░  ░      ░    //
//    ░░         ░   ▒   ░      ░       //
//                   ░  ░       ░       //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract PAM is ERC1155Creator {
    constructor() ERC1155Creator("Checks - M4R10 Editions", "PAM") {}
}