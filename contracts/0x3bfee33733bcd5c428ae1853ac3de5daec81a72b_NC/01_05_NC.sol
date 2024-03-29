// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Natural Causes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//     ███▄    █  ▄▄▄     ▄▄▄█████▓ █    ██  ██▀███   ▄▄▄       ██▓           //
//     ██ ▀█   █ ▒████▄   ▓  ██▒ ▓▒ ██  ▓██▒▓██ ▒ ██▒▒████▄    ▓██▒           //
//    ▓██  ▀█ ██▒▒██  ▀█▄ ▒ ▓██░ ▒░▓██  ▒██░▓██ ░▄█ ▒▒██  ▀█▄  ▒██░           //
//    ▓██▒  ▐▌██▒░██▄▄▄▄██░ ▓██▓ ░ ▓▓█  ░██░▒██▀▀█▄  ░██▄▄▄▄██ ▒██░           //
//    ▒██░   ▓██░ ▓█   ▓██▒ ▒██▒ ░ ▒▒█████▓ ░██▓ ▒██▒ ▓█   ▓██▒░██████▒       //
//    ░ ▒░   ▒ ▒  ▒▒   ▓▒█░ ▒ ░░   ░▒▓▒ ▒ ▒ ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░░ ▒░▓  ░       //
//    ░ ░░   ░ ▒░  ▒   ▒▒ ░   ░    ░░▒░ ░ ░   ░▒ ░ ▒░  ▒   ▒▒ ░░ ░ ▒  ░       //
//       ░   ░ ░   ░   ▒    ░       ░░░ ░ ░   ░░   ░   ░   ▒     ░ ░          //
//     ▄████▄  ░▄▄▄    ░  █    ██   ██████ ▓█████   ██████ ░  ░    ░  ░       //
//    ▒██▀ ▀█  ▒████▄     ██  ▓██▒▒██    ▒ ▓█   ▀ ▒██    ▒                    //
//    ▒▓█    ▄ ▒██  ▀█▄  ▓██  ▒██░░ ▓██▄   ▒███   ░ ▓██▄                      //
//    ▒▓▓▄ ▄██▒░██▄▄▄▄██ ▓▓█  ░██░  ▒   ██▒▒▓█  ▄   ▒   ██▒                   //
//    ▒ ▓███▀ ░ ▓█   ▓██▒▒▒█████▓ ▒██████▒▒░▒████▒▒██████▒▒                   //
//    ░ ░▒ ▒  ░ ▒▒   ▓▒█░░▒▓▒ ▒ ▒ ▒ ▒▓▒ ▒ ░░░ ▒░ ░▒ ▒▓▒ ▒ ░                   //
//      ░  ▒     ▒   ▒▒ ░░░▒░ ░ ░ ░ ░▒  ░ ░ ░ ░  ░░ ░▒  ░ ░                   //
//    ░          ░   ▒    ░░░ ░ ░ ░  ░  ░     ░   ░  ░  ░                     //
//    ░ ░            ░  ░   ░           ░     ░  ░      ░                     //
//    ░                                                                       //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract NC is ERC721Creator {
    constructor() ERC721Creator("Natural Causes", "NC") {}
}