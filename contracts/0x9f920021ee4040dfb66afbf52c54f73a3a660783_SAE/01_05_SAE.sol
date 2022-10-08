// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Multi Abstraction
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//      ██████  ▄▄▄      ▓█████     //
//    ▒██    ▒ ▒████▄    ▓█   ▀     //
//    ░ ▓██▄   ▒██  ▀█▄  ▒███       //
//      ▒   ██▒░██▄▄▄▄██ ▒▓█  ▄     //
//    ▒██████▒▒ ▓█   ▓██▒░▒████▒    //
//    ▒ ▒▓▒ ▒ ░ ▒▒   ▓▒█░░░ ▒░ ░    //
//    ░ ░▒  ░ ░  ▒   ▒▒ ░ ░ ░  ░    //
//    ░  ░  ░    ░   ▒      ░       //
//          ░        ░  ░   ░  ░    //
//                                  //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract SAE is ERC721Creator {
    constructor() ERC721Creator("Multi Abstraction", "SAE") {}
}