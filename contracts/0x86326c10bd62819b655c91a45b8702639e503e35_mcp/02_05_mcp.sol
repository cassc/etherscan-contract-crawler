// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mafu-cho-pretty？
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//     ███▄ ▄███▓ ▄▄▄        █████▒█    ██     //
//    ▓██▒▀█▀ ██▒▒████▄    ▓██   ▒ ██  ▓██▒    //
//    ▓██    ▓██░▒██  ▀█▄  ▒████ ░▓██  ▒██░    //
//    ▒██    ▒██ ░██▄▄▄▄██ ░▓█▒  ░▓▓█  ░██░    //
//    ▒██▒   ░██▒ ▓█   ▓██▒░▒█░   ▒▒█████▓     //
//    ░ ▒░   ░  ░ ▒▒   ▓▒█░ ▒ ░   ░▒▓▒ ▒ ▒     //
//    ░  ░      ░  ▒   ▒▒ ░ ░     ░░▒░ ░ ░     //
//    ░      ░     ░   ▒    ░ ░    ░░░ ░ ░     //
//           ░         ░  ░          ░         //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract mcp is ERC721Creator {
    constructor() ERC721Creator(unicode"mafu-cho-pretty？", "mcp") {}
}