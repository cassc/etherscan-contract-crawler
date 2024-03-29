// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Proof Of Pixels
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//     ██▓███   ██▀███   ▒█████   ▒█████    █████▒    ▒█████    █████▒    ██▓███   ██▓▒██   ██▒▓█████  ██▓      ██████     //
//    ▓██░  ██▒▓██ ▒ ██▒▒██▒  ██▒▒██▒  ██▒▓██   ▒    ▒██▒  ██▒▓██   ▒    ▓██░  ██▒▓██▒▒▒ █ █ ▒░▓█   ▀ ▓██▒    ▒██    ▒     //
//    ▓██░ ██▓▒▓██ ░▄█ ▒▒██░  ██▒▒██░  ██▒▒████ ░    ▒██░  ██▒▒████ ░    ▓██░ ██▓▒▒██▒░░  █   ░▒███   ▒██░    ░ ▓██▄       //
//    ▒██▄█▓▒ ▒▒██▀▀█▄  ▒██   ██░▒██   ██░░▓█▒  ░    ▒██   ██░░▓█▒  ░    ▒██▄█▓▒ ▒░██░ ░ █ █ ▒ ▒▓█  ▄ ▒██░      ▒   ██▒    //
//    ▒██▒ ░  ░░██▓ ▒██▒░ ████▓▒░░ ████▓▒░░▒█░       ░ ████▓▒░░▒█░       ▒██▒ ░  ░░██░▒██▒ ▒██▒░▒████▒░██████▒▒██████▒▒    //
//    ▒▓▒░ ░  ░░ ▒▓ ░▒▓░░ ▒░▒░▒░ ░ ▒░▒░▒░  ▒ ░       ░ ▒░▒░▒░  ▒ ░       ▒▓▒░ ░  ░░▓  ▒▒ ░ ░▓ ░░░ ▒░ ░░ ▒░▓  ░▒ ▒▓▒ ▒ ░    //
//    ░▒ ░       ░▒ ░ ▒░  ░ ▒ ▒░   ░ ▒ ▒░  ░           ░ ▒ ▒░  ░         ░▒ ░      ▒ ░░░   ░▒ ░ ░ ░  ░░ ░ ▒  ░░ ░▒  ░ ░    //
//    ░░         ░░   ░ ░ ░ ░ ▒  ░ ░ ░ ▒   ░ ░       ░ ░ ░ ▒   ░ ░       ░░        ▒ ░ ░    ░     ░     ░ ░   ░  ░  ░      //
//                ░         ░ ░      ░ ░                 ░ ░                       ░   ░    ░     ░  ░    ░  ░      ░      //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract POP is ERC721Creator {
    constructor() ERC721Creator("Proof Of Pixels", "POP") {}
}