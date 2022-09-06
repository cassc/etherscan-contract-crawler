// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Art of Evolution
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    ╔╦╗╦ ╦╔═╗  ╔═╗╦═╗╔╦╗  ╔═╗╔═╗    //
//     ║ ╠═╣║╣   ╠═╣╠╦╝ ║   ║ ║╠╣     //
//     ╩ ╩ ╩╚═╝  ╩ ╩╩╚═ ╩   ╚═╝╚      //
//    ╔═╗╦  ╦╔═╗╦  ╦ ╦╔╦╗╦╔═╗╔╗╔      //
//    ║╣ ╚╗╔╝║ ║║  ║ ║ ║ ║║ ║║║║      //
//    ╚═╝ ╚╝ ╚═╝╩═╝╚═╝ ╩ ╩╚═╝╝╚╝      //
//    ╔╗ ╦ ╦  ╔╗ ╔═╗╦  ╦  ╔═╗         //
//    ╠╩╗╚╦╝  ╠╩╗║╣ ║  ║  ║╣          //
//    ╚═╝ ╩   ╚═╝╚═╝╩═╝╩═╝╚═╝         //
//                                    //
//                                    //
////////////////////////////////////////


contract THE is ERC721Creator {
    constructor() ERC721Creator("The Art of Evolution", "THE") {}
}