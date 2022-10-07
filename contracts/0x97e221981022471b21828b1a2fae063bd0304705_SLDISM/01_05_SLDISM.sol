// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sludgism
/// @author: manifold.xyz

import "./ERC721Creator.sol";

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


contract SLDISM is ERC721Creator {
    constructor() ERC721Creator("Sludgism", "SLDISM") {}
}