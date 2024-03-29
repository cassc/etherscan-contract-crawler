// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DEATH + BEYOND 💀
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//     ▄▄▄      ▓█████▄  ██▀███   ██▓ ▄▄▄       ███▄    █     //
//    ▒████▄    ▒██▀ ██▌▓██ ▒ ██▒▓██▒▒████▄     ██ ▀█   █     //
//    ▒██  ▀█▄  ░██   █▌▓██ ░▄█ ▒▒██▒▒██  ▀█▄  ▓██  ▀█ ██▒    //
//    ░██▄▄▄▄██ ░▓█▄   ▌▒██▀▀█▄  ░██░░██▄▄▄▄██ ▓██▒  ▐▌██▒    //
//     ▓█   ▓██▒░▒████▓ ░██▓ ▒██▒░██░ ▓█   ▓██▒▒██░   ▓██░    //
//     ▒▒   ▓▒█░ ▒▒▓  ▒ ░ ▒▓ ░▒▓░░▓   ▒▒   ▓▒█░░ ▒░   ▒ ▒     //
//      ▒   ▒▒ ░ ░ ▒  ▒   ░▒ ░ ▒░ ▒ ░  ▒   ▒▒ ░░ ░░   ░ ▒░    //
//      ░   ▒    ░ ░  ░   ░░   ░  ▒ ░  ░   ▒      ░   ░ ░     //
//          ░  ░   ░       ░      ░        ░  ░         ░     //
//               ░                                            //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract DB is ERC1155Creator {
    constructor() ERC1155Creator(unicode"DEATH + BEYOND 💀", "DB") {}
}