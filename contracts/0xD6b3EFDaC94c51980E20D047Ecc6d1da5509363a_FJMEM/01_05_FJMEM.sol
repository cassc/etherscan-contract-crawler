// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: For The Culture
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//     ██▓███  ▓█████  ██▓███  ▓█████     //
//    ▓██░  ██▒▓█   ▀ ▓██░  ██▒▓█   ▀     //
//    ▓██░ ██▓▒▒███   ▓██░ ██▓▒▒███       //
//    ▒██▄█▓▒ ▒▒▓█  ▄ ▒██▄█▓▒ ▒▒▓█  ▄     //
//    ▒██▒ ░  ░░▒████▒▒██▒ ░  ░░▒████▒    //
//    ▒▓▒░ ░  ░░░ ▒░ ░▒▓▒░ ░  ░░░ ▒░ ░    //
//    ░▒ ░      ░ ░  ░░▒ ░      ░ ░  ░    //
//    ░░          ░   ░░          ░       //
//                ░  ░            ░  ░    //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract FJMEM is ERC1155Creator {
    constructor() ERC1155Creator("For The Culture", "FJMEM") {}
}