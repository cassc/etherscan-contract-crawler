// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pixel Lovepepe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//     ██▓███  ▒██   ██▒ ██▓  ██▒   █▓    //
//    ▓██░  ██▒▒▒ █ █ ▒░▓██▒ ▓██░   █▒    //
//    ▓██░ ██▓▒░░  █   ░▒██░  ▓██  █▒░    //
//    ▒██▄█▓▒ ▒ ░ █ █ ▒ ▒██░   ▒██ █░░    //
//    ▒██▒ ░  ░▒██▒ ▒██▒░██████▒▒▀█░      //
//    ▒▓▒░ ░  ░▒▒ ░ ░▓ ░░ ▒░▓  ░░ ▐░      //
//    ░▒ ░     ░░   ░▒ ░░ ░ ▒  ░░ ░░      //
//    ░░        ░    ░    ░ ░     ░░      //
//              ░    ░      ░  ░   ░      //
//                                ░       //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract PXLV is ERC721Creator {
    constructor() ERC721Creator("Pixel Lovepepe", "PXLV") {}
}