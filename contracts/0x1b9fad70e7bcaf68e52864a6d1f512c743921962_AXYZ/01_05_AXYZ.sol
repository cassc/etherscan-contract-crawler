// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AlienXYZ
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//                                                                                //
//     ▄▄▄       ██▓     ██▓▓█████  ███▄    █    ▒██   ██▒▓██   ██▓▒███████▒      //
//    ▒████▄    ▓██▒    ▓██▒▓█   ▀  ██ ▀█   █    ▒▒ █ █ ▒░ ▒██  ██▒▒ ▒ ▒ ▄▀░      //
//    ▒██  ▀█▄  ▒██░    ▒██▒▒███   ▓██  ▀█ ██▒   ░░  █   ░  ▒██ ██░░ ▒ ▄▀▒░       //
//    ░██▄▄▄▄██ ▒██░    ░██░▒▓█  ▄ ▓██▒  ▐▌██▒    ░ █ █ ▒   ░ ▐██▓░  ▄▀▒   ░      //
//     ▓█   ▓██▒░██████▒░██░░▒████▒▒██░   ▓██░   ▒██▒ ▒██▒  ░ ██▒▓░▒███████▒      //
//     ▒▒   ▓▒█░░ ▒░▓  ░░▓  ░░ ▒░ ░░ ▒░   ▒ ▒    ▒▒ ░ ░▓ ░   ██▒▒▒ ░▒▒ ▓░▒░▒      //
//      ▒   ▒▒ ░░ ░ ▒  ░ ▒ ░ ░ ░  ░░ ░░   ░ ▒░   ░░   ░▒ ░ ▓██ ░▒░ ░░▒ ▒ ░ ▒      //
//      ░   ▒     ░ ░    ▒ ░   ░      ░   ░ ░     ░    ░   ▒ ▒ ░░  ░ ░ ░ ░ ░      //
//          ░  ░    ░  ░ ░     ░  ░         ░     ░    ░   ░ ░       ░ ░          //
//                                                         ░ ░     ░              //
//    01000001 01101100 01101001 01100101 01101110  01011000 01011001 01011010    //
//                                                                                //
//    'Unusual organisms abound，including chemical-eating bacteria which hide     //
//    out deep in the ocean and organisms that thrive in boiling-hot springs，     //
//    but that doesn't mean they're different life forms entirely.'               //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract AXYZ is ERC721Creator {
    constructor() ERC721Creator("AlienXYZ", "AXYZ") {}
}