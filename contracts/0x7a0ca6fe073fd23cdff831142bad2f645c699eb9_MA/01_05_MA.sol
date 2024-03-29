// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MULTIPLE-ARTS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//         ___           ___           ___           ___           ___          //
//         /  /\         /  /\         /__/\         /  /\         /__/\        //
//        /  /::\       /  /::\       |  |::\       /  /::\        \  \:\       //
//       /  /:/\:\     /  /:/\:\      |  |:|:\     /  /:/\:\        \  \:\      //
//      /  /:/~/::\   /  /:/~/:/    __|__|:|\:\   /  /:/~/::\   _____\__\:\     //
//     /__/:/ /:/\:\ /__/:/ /:/___ /__/::::| \:\ /__/:/ /:/\:\ /__/::::::::\    //
//     \  \:\/:/__\/ \  \:\/:::::/ \  \:\~~\__\/ \  \:\/:/__\/ \  \:\~~\~~\/    //
//      \  \::/       \  \::/~~~~   \  \:\        \  \::/       \  \:\  ~~~     //
//       \  \:\        \  \:\        \  \:\        \  \:\        \  \:\         //
//        \  \:\        \  \:\        \  \:\        \  \:\        \  \:\        //
//         \__\/         \__\/         \__\/         \__\/         \__\/        //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract MA is ERC1155Creator {
    constructor() ERC1155Creator("MULTIPLE-ARTS", "MA") {}
}