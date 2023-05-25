// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Femme Enigma
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//     █████▒ ▓████  ▓██   ██▓       //
//    ▒██   ▒ ▓█     ▒██  ██▒        //
//    ▒████ ░▒███▓    ▒██ ██░        //
//    ▒██▒  ░▒▓█     ░ ▐██▓░         //
//    ░█▓░   ░████▒ ░   ██▒▓░        //
//     ▒ ░    ░░ ▒░ ░    █▒▒▒        //
//     ░       ░ ░      ░ ░▒░        //
//     ░ ░       ░      ▒ ▒ ░░       //
//               ░      ░░ ░         //
//                      ░ ░          //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract FEY is ERC721Creator {
    constructor() ERC721Creator("Femme Enigma", "FEY") {}
}