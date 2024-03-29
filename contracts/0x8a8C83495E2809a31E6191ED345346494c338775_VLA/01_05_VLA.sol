// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VIORIKA-new art
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                          //
//                                                                                                          //
//     ██▒   █▓ ██▓ ▒█████   ██▀███   ██▓ ██ ▄█▀▄▄▄      ▄▄▄       ██▀███  ▄▄▄█████▓                        //
//    ▓██░   █▒▓██▒▒██▒  ██▒▓██ ▒ ██▒▓██▒ ██▄█▒▒████▄   ▒████▄    ▓██ ▒ ██▒▓  ██▒ ▓▒                        //
//     ▓██  █▒░▒██▒▒██░  ██▒▓██ ░▄█ ▒▒██▒▓███▄░▒██  ▀█▄ ▒██  ▀█▄  ▓██ ░▄█ ▒▒ ▓██░ ▒░                        //
//      ▒██ █░░░██░▒██   ██░▒██▀▀█▄  ░██░▓██ █▄░██▄▄▄▄██░██▄▄▄▄██ ▒██▀▀█▄  ░ ▓██▓ ░                         //
//       ▒▀█░  ░██░░ ████▓▒░░██▓ ▒██▒░██░▒██▒ █▄▓█   ▓██▒▓█   ▓██▒░██▓ ▒██▒  ▒██▒ ░                         //
//       ░ ▐░  ░▓  ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░░▓  ▒ ▒▒ ▓▒▒▒   ▓▒█░▒▒   ▓▒█░░ ▒▓ ░▒▓░  ▒ ░░                           //
//       ░ ░░   ▒ ░  ░ ▒ ▒░   ░▒ ░ ▒░ ▒ ░░ ░▒ ▒░ ▒   ▒▒ ░ ▒   ▒▒ ░  ░▒ ░ ▒░    ░                            //
//         ░░   ▒ ░░ ░ ░ ▒    ░░   ░  ▒ ░░ ░░ ░  ░   ▒    ░   ▒     ░░   ░   ░                              //
//          ░   ░      ░ ░     ░      ░  ░  ░        ░  ░     ░  ░   ░                                      //
//     Creator: Viorika_art    ░                                                                            //
//                                                                                                          //
//                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VLA is ERC1155Creator {
    constructor() ERC1155Creator("VIORIKA-new art", "VLA") {}
}