// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: shadowz i see
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    ▓██   ██▓  ██████  ██▓  ██████     //
//     ▒██  ██▒▒██    ▒ ▓██▒▒██    ▒     //
//      ▒██ ██░░ ▓██▄   ▒██▒░ ▓██▄       //
//      ░ ▐██▓░  ▒   ██▒░██░  ▒   ██▒    //
//      ░ ██▒▓░▒██████▒▒░██░▒██████▒▒    //
//       ██▒▒▒ ▒ ▒▓▒ ▒ ░░▓  ▒ ▒▓▒ ▒ ░    //
//     ▓██ ░▒░ ░ ░shadowz i see▒  ░ ░    //
//     ▒ ▒ ░░  ░  ░  ░   ▒ ░░  ░  ░      //
//     ░ ░           ░   ░        ░      //
//     ░ ░                               //
//                                       //
//                                       //
///////////////////////////////////////////


contract ySIS is ERC721Creator {
    constructor() ERC721Creator("shadowz i see", "ySIS") {}
}