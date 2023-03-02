// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: No Funny Stuff
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//     ███▄    █   █████▒ ██████     //
//     ██ ▀█   █ ▓██   ▒▒██    ▒     //
//    ▓██  ▀█ ██▒▒████ ░░ ▓██▄       //
//    ▓██▒  ▐▌██▒░▓█▒  ░  ▒   ██▒    //
//    ▒██░   ▓██░░▒█░   ▒██████▒▒    //
//    ░ ▒░   ▒ ▒  ▒ ░   ▒ ▒▓▒ ▒ ░    //
//    ░ ░░   ░ ▒░ ░     ░ ░▒  ░ ░    //
//       ░   ░ ░  ░ ░   ░  ░  ░      //
//             ░              ░      //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract NFS is ERC1155Creator {
    constructor() ERC1155Creator("No Funny Stuff", "NFS") {}
}