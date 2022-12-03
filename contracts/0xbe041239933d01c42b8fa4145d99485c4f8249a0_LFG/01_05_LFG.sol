// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JB Rocket Open Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//       _       _____    ____              //
//      |"|     |" ___|U /"___|u            //
//    U | | u  U| |_  u\| |  _ /            //
//     \| |/__ \|  _|/  | |_| |             //
//      |_____| |_|      \____|             //
//      //  \\  )(\\,-   _)(|_              //
//     (_")("_)(__)(_/  (__)__)             //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract LFG is ERC721Creator {
    constructor() ERC721Creator("JB Rocket Open Edition", "LFG") {}
}