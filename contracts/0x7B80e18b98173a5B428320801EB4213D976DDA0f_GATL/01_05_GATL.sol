// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: glass afterlife
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//      ▄████  ▄▄▄     ▄▄▄█████▓ ██▓        //
//     ██▒ ▀█▒▒████▄   ▓  ██▒ ▓▒▓██▒        //
//    ▒██░▄▄▄░▒██  ▀█▄ ▒ ▓██░ ▒░▒██░        //
//    ░▓█  ██▓░██▄▄▄▄██░ ▓██▓ ░ ▒██░        //
//    ░▒▓███▀▒ ▓█   ▓██▒ ▒██▒ ░ ░██████▒    //
//     ░▒   ▒  ▒▒   ▓▒█░ ▒ ░░   ░ ▒░▓  ░    //
//      ░   ░   ▒   ▒▒ ░   ░    ░ ░ ▒  ░    //
//    ░ ░   ░   ░   ▒    ░        ░ ░       //
//          ░       ░  ░            ░  ░    //
//                                          //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract GATL is ERC721Creator {
    constructor() ERC721Creator("glass afterlife", "GATL") {}
}