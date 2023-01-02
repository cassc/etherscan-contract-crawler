// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: F A C E S
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//        .d888888b.                                                                 //
//     .dMM"""""""`MMb.                     oo            dP                         //
//    .8MMM  mmmm,  MMM8.                                 88                         //
//    88MMM        .MMM88 .d8888b. .d8888b. dP .d8888b. d8888P .d8888b. 88d888b.     //
//    88MMM  MMMb. "MMM88 88ooood8 88'  `88 88 Y8ooooo.   88   88ooood8 88'  `88     //
//    88MMM  MMMMM  MMM88 88.  ... 88.  .88 88       88   88   88.  ... 88           //
//    `8MMM  MMMMM  MMM8' `88888P' `8888P88 dP `88888P'   dP   `88888P' dP           //
//     `dMMMMMMMMMMMMb'                 .88                                          //
//        `d888888P'                d8888P                                           //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract FACES is ERC721Creator {
    constructor() ERC721Creator("F A C E S", "FACES") {}
}