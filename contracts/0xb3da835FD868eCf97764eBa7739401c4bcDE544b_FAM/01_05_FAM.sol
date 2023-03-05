// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: fam
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//      █████▄▄▄      ███▄ ▄███▓       //
//    ▓██   ▒████▄   ▓██▒▀█▀ ██▒       //
//    ▒████ ▒██  ▀█▄ ▓██    ▓██░       //
//    ░▓█▒  ░██▄▄▄▄██▒██    ▒██        //
//    ░▒█░   ▓█   ▓██▒██▒   ░██▒       //
//     ▒ ░   ▒▒   ▓▒█░ ▒░   ░  ░       //
//     ░      ▒   ▒▒ ░  ░      ░       //
//     ░ ░    ░   ▒  ░      ░          //
//                ░  ░      ░          //
//                                     //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract FAM is ERC1155Creator {
    constructor() ERC1155Creator("fam", "FAM") {}
}