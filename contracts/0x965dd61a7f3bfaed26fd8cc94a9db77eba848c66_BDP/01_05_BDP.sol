// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Big Dark Pen
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//     ▄▄▄▄   ▓█████▄  ██▓███      //
//    ▓█████▄ ▒██▀ ██▌▓██░  ██▒    //
//    ▒██▒ ▄██░██   █▌▓██░ ██▓▒    //
//    ▒██░█▀  ░▓█▄   ▌▒██▄█▓▒ ▒    //
//    ░▓█  ▀█▓░▒████▓ ▒██▒ ░  ░    //
//    ░▒▓███▀▒ ▒▒▓  ▒ ▒▓▒░ ░  ░    //
//    ▒░▒   ░  ░ ▒  ▒ ░▒ ░         //
//     ░    ░  ░ ░  ░ ░░           //
//     ░         ░                 //
//          ░  ░            x.x    //
//                                 //
//                                 //
/////////////////////////////////////


contract BDP is ERC721Creator {
    constructor() ERC721Creator("Big Dark Pen", "BDP") {}
}