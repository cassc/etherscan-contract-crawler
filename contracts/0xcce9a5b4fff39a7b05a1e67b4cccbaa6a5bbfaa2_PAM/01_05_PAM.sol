// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PAM
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//     ██▓███   ▄▄▄      ███▄ ▄███▓    //
//    ▓██░  ██▒▒████▄   ▓██▒▀█▀ ██▒    //
//    ▓██░ ██▓▒▒██  ▀█▄ ▓██    ▓██░    //
//    ▒██▄█▓▒ ▒░██▄▄▄▄██▒██    ▒██     //
//    ▒██▒ ░  ░ ▓█   ▓██▒██▒   ░██▒    //
//    ▒▓▒░ ░  ░ ▒▒   ▓▒█░ ▒░   ░  ░    //
//    ░▒ ░       ▒   ▒▒ ░  ░      ░    //
//    ░░         ░   ▒  ░      ░       //
//                                     //
//                                     //
/////////////////////////////////////////


contract PAM is ERC1155Creator {
    constructor() ERC1155Creator("PAM", "PAM") {}
}