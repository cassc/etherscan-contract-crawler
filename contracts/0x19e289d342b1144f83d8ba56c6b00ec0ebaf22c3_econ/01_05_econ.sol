// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: circular economy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//      ▄████ ▓█████  ██▓  ██████ ▄▄▄█████▓    //
//     ██▒ ▀█▒▓█   ▀ ▓██▒▒██    ▒ ▓  ██▒ ▓▒    //
//    ▒██░▄▄▄░▒███   ▒██▒░ ▓██▄   ▒ ▓██░ ▒░    //
//    ░▓█  ██▓▒▓█  ▄ ░██░  ▒   ██▒░ ▓██▓ ░     //
//    ░▒▓███▀▒░▒████▒░██░▒██████▒▒  ▒██▒ ░     //
//     ░▒   ▒ ░░ ▒░ ░░▓  ▒ ▒▓▒ ▒ ░  ▒ ░░       //
//      ░   ░  ░ ░  ░ ▒ ░░ ░▒  ░ ░    ░        //
//    ░ ░   ░    ░    ▒ ░░  ░  ░    ░          //
//          ░    ░  ░ ░        ░               //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract econ is ERC721Creator {
    constructor() ERC721Creator("circular economy", "econ") {}
}