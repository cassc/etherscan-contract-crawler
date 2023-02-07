// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: F Copy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//                                                                               //
//    oooooooooooo        .oooooo.     .oooooo.   ooooooooo.   oooooo   oooo     //
//    `888'     `8       d8P'  `Y8b   d8P'  `Y8b  `888   `Y88.  `888.   .8'      //
//     888              888          888      888  888   .d88'   `888. .8'       //
//     888oooo8         888          888      888  888ooo88P'     `888.8'        //
//     888    "         888          888      888  888             `888'         //
//     888              `88b    ooo  `88b    d88'  888              888          //
//    o888o              `Y8bood8P'   `Y8bood8P'  o888o            o888o         //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////


contract FCOPY is ERC1155Creator {
    constructor() ERC1155Creator("F Copy", "FCOPY") {}
}