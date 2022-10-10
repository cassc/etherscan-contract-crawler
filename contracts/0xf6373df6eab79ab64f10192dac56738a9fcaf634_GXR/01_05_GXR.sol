// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GUXTER
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//      ▄████ ▒██   ██▒ ██▀███      //
//     ██▒ ▀█▒▒▒ █ █ ▒░▓██ ▒ ██▒    //
//    ▒██░▄▄▄░░░  █   ░▓██ ░▄█ ▒    //
//    ░▓█  ██▓ ░ █ █ ▒ ▒██▀▀█▄      //
//    ░▒▓███▀▒▒██▒ ▒██▒░██▓ ▒██▒    //
//     ░▒   ▒ ▒▒ ░ ░▓ ░░ ▒▓ ░▒▓░    //
//      ░   ░ ░░   ░▒ ░  ░▒ ░ ▒░    //
//    ░ ░   ░  ░    ░    ░░   ░     //
//          ░  ░    ░     ░         //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract GXR is ERC721Creator {
    constructor() ERC721Creator("GUXTER", "GXR") {}
}